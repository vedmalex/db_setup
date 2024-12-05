#!/bin/bash
set -e

# Проверка наличия переменной MONGO_VERSION
if [ -z "${MONGO_VERSION}" ]; then
    echo "MONGO_VERSION environment variable is not set"
    exit 1
fi

# Определяем какой клиент использовать в зависимости от версии MongoDB
if [[ "${MONGO_VERSION}" < "5.0" ]]; then
    CLIENT="mongo"
else
    CLIENT="mongosh"
fi


until $CLIENT --host mongo1:27017 -u "$MONGO_ROOT_USERNAME" -p "$MONGO_ROOT_PASSWORD" --authenticationDatabase admin --eval "rs.status().ok" 2>&1 | tee /tmp/mongo_dump_status.log | grep -q "1" && ! grep -q "connect failed" /tmp/mongo_dump_status.log; do
    if grep -q "connect failed" /tmp/mongo_dump_status.log; then
        echo "Connection failed, retrying in 5 seconds..."
    else
        echo "Waiting for MongoDB replica set to be ready..."
    fi
    sleep 5
done

echo "MongoDB replica set is ready!"

echo "Starting dump process..."

# Создаем директорию для дампа если она не существует
mkdir -p /dump


# Получаем список всех баз данных с проверкой на ошибки
# Измените блок получения списка баз данных на следующий:
databases=$($CLIENT --host mongo1:27017 -u "$MONGO_ROOT_USERNAME" -p "$MONGO_ROOT_PASSWORD" \
    --quiet --authenticationDatabase \
    admin --eval "db.getMongo().getDBNames()" | tr ',' '\n' | tr -d "[]' \"" | grep -v '^admin$' | grep -v '^local$' | grep -v '^config$') || {
    echo "Failed to get database list"
    exit 1
}

# Проверяем, не пустой ли результат
if [ -z "$databases" ]; then
    echo "No databases found or error occurred while fetching database list"
    exit 0
fi

echo "Databases found: $databases"

# Проверяем, нет ли слова "Failed" или "Error" в выводе
if echo "$databases" | grep -qi "Failed\|Error"; then
    echo "Error occurred while fetching database list"
    exit 0
fi

echo "Databases to dump: $databases"

for db_name in $databases; do
    echo "Processing database: $db_name"

    # Проверяем, нужно ли пропустить dump
    if [ -f "/dump/$db_name/.skip_dump" ]; then
        echo "Skipping dump for $db_name (found .skip_dump file)"
        continue
    fi

    # Создаем директорию для базы данных
    mkdir -p "/dump/$db_name"

    echo "Dumping $db_name..."

    # Настройки для mongodump
    DUMP_OPTS="--host mongo1:27017 \
        --username \"$MONGO_ROOT_USERNAME\" \
        --password \"$MONGO_ROOT_PASSWORD\" \
        --authenticationDatabase admin \
        --db \"$db_name\" \
        --out \"/dump\""

    # Добавляем параллельные коллекции, если установлена переменная
    if [ ! -z "${PARALLEL_COLLECTIONS}" ]; then
        DUMP_OPTS="$DUMP_OPTS --numParallelCollections=${PARALLEL_COLLECTIONS}"
    else
        DUMP_OPTS="$DUMP_OPTS --numParallelCollections=4"
    fi

    # Выполняем dump
    eval "mongodump $DUMP_OPTS"

    if [ $? -eq 0 ]; then
        echo "Successfully dumped $db_name"
        # Создаем файл-маркер успешного dump
        touch "/dump/$db_name/.dumped"
    else
        echo "Failed to dump $db_name"
        continue
    fi
done

echo "Dump process completed"