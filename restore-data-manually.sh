#!/bin/bash
set -e

# Чтение переменных из файла.env
source .env

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

echo "Starting restore process..."

# Проверяем наличие дампа
if [ -d "./dump" ]; then
    for db_dump in ./dump/*/; do
        if [ -d "$db_dump" ]; then
            db_name=$(basename "$db_dump")
            echo "Restoring database: $db_name"

            # Проверяем, нужно ли пропустить восстановление
            if [ -f "./dump/$db_name/.skip_restore" ]; then
                echo "Skipping restore for $db_name (found .skip_restore file)"
                continue
            fi

            # Проверяем, существует ли база данных
            db_exists=$($CLIENT --host mongo1:27017 -u $MONGO_ROOT_USERNAME -p $MONGO_ROOT_PASSWORD --authenticationDatabase admin --quiet --eval "db.getMongo().getDBNames().indexOf('$db_name') !== -1")

            if [ "$db_exists" = "true" ] && [ -f "./dump/$db_name/.no_override" ]; then
                echo "Database $db_name exists and .no_override file found, skipping..."
                continue
            fi

            echo "Restoring $db_name from dump..."

            # Настройки для mongorestore
            RESTORE_OPTS="--host mongo1:27017 \
                -u $MONGO_ROOT_USERNAME -p $MONGO_ROOT_PASSWORD\
                --authenticationDatabase admin \
                --db \"$db_name\" \
                --dir \"./dump/$db_name\" \
                --drop"

            # Добавляем параллельные коллекции, если установлена переменная
            if [ ! -z "${PARALLEL_COLLECTIONS}" ]; then
                RESTORE_OPTS="$RESTORE_OPTS --numParallelCollections=${PARALLEL_COLLECTIONS}"
            else
                RESTORE_OPTS="$RESTORE_OPTS --numParallelCollections=4"
            fi

            # Добавляем размер batch, если установлена переменная
            if [ ! -z "${BATCH_SIZE}" ]; then
                RESTORE_OPTS="$RESTORE_OPTS --batchSize=${BATCH_SIZE}"
            fi

            # Выполняем восстановление
            eval "mongorestore $RESTORE_OPTS --writeConcern=majority"

            if [ $? -eq 0 ]; then
                echo "Successfully restored $db_name"
                # Создаем файл-маркер успешного восстановления
                touch "./dump/$db_name/.restored"
            else
                echo "Failed to restore $db_name"
                exit 1
            fi
        fi
    done
    echo "Restore process completed"
else
    echo "No dump directory found, skipping restore"
fi