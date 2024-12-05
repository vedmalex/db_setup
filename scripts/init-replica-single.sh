#!/bin/bash

# Включаем строгий режим
set -euo pipefail

# Конфигурационные параметры
MAX_RETRIES=30
RETRY_INTERVAL=5
OPLOG_SIZE=1024  # Размер оплога в МБ

# Проверка наличия необходимых переменных окружения
required_vars=("MONGO_VERSION" "MONGO_ROOT_USERNAME" "MONGO_ROOT_PASSWORD")
for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
        echo "Error: Required environment variable $var is not set"
        exit 1
    fi
done

# Определяем какой клиент использовать в зависимости от версии MongoDB
if [[ "${MONGO_VERSION}" < "5.0" ]]; then
    CLIENT="mongo"
else
    CLIENT="mongosh"
fi

# Проверяем наличие клиента
if ! command -v $CLIENT &> /dev/null; then
    echo "Error: $CLIENT client is not installed"
    exit 1
fi

# Функция проверки доступности MongoDB
check_mongodb_available() {
    local host="$1"
    local max_attempts="$2"
    local wait_time="$3"
    local attempt=1

    echo "Checking MongoDB availability at $host..."
    while [ $attempt -le $max_attempts ]; do
        if $CLIENT --host "$host" --eval "db.adminCommand('ping')" &>/dev/null; then
            echo "MongoDB is available at $host"
            return 0
        fi
        echo "Attempt $attempt/$max_attempts: MongoDB is not available yet, waiting $wait_time seconds..."
        sleep "$wait_time"
        attempt=$((attempt + 1))
    done

    echo "Error: MongoDB is not available after $max_attempts attempts"
    return 1
}

# Функция для выполнения MongoDB команд с аутентификацией
execute_mongo_command() {
    local command="$1"
    local error_msg="$2"
    local output

    output=$($CLIENT --host mongo1:27017 \
                     -u "$MONGO_ROOT_USERNAME" \
                     -p "$MONGO_ROOT_PASSWORD" \
                     --authenticationDatabase admin \
                     --eval "$command" 2>&1)

    if [ $? -ne 0 ]; then
        echo "Error executing MongoDB command: $error_msg"
        echo "Output: $output"
        return 1
    fi
    echo "$output"
}

# Функция инициализации реплика-сета без аутентификации
init_replica_set() {
    echo "Initializing replica set..."

    local config='
    config = {
      "_id": "rs0",
      "members": [
        { "_id": 0, "host": "mongo1:27017", "priority": 2 },
      ]
    };
    rs.initiate(config);
    '

    # Инициализация без аутентификации
    $CLIENT --host mongo1:27017 -u "$MONGO_ROOT_USERNAME" -p "$MONGO_ROOT_PASSWORD" --authenticationDatabase admin --eval "$config"

    echo "Replica set initialization command executed"
}

# Функция проверки статуса реплика-сета с аутентификацией
check_replica_status() {
    execute_mongo_command "rs.status().ok;" "Failed to check replica status" | grep -q "1"
}

# # Функция изменения размера оплога
# resize_oplog() {
#     echo "Resizing oplog to ${OPLOG_SIZE}MB..."

#     local command="
#     use admin;
#     db.runCommand({ replSetResizeOplog: 1, size: ${OPLOG_SIZE} });
#     "

#     echo command: $command

#     execute_mongo_command "$command" "Failed to resize oplog" || return 1
#     echo "Oplog resize completed"
# }

# Основная логика скрипта
echo "Starting MongoDB replica set initialization..."

# Проверяем доступность основного сервера MongoDB
if ! check_mongodb_available "mongo1" "$MAX_RETRIES" "$RETRY_INTERVAL"; then
    echo "Error: Primary MongoDB server is not available"
    exit 1
fi

# Даём дополнительное время для полной инициализации серверов
echo "Waiting additional 5 seconds for servers to fully initialize..."
sleep 5

# Инициализация реплика-сета
if ! init_replica_set; then
    echo "Failed to initialize replica set"
    exit 1
fi

# Ожидание готовности реплика-сета
echo "Waiting for MongoDB replica set to be ready..."
attempt=1
while [ $attempt -le $MAX_RETRIES ]; do
    echo "Checking replica set status (attempt $attempt of $MAX_RETRIES)..."

    if check_replica_status; then
        echo "Replica set is ready!"
        break
    fi

    if [ $attempt -eq $MAX_RETRIES ]; then
        echo "Error: Maximum attempts reached waiting for replica set"
        exit 1
    fi

    echo "Waiting $RETRY_INTERVAL seconds before next check..."
    sleep $RETRY_INTERVAL
    attempt=$((attempt + 1))
done

# # Изменение размера оплога
# if ! resize_oplog; then
#     echo "Warning: Failed to resize oplog, but continuing..."
#     exit 0
# fi

echo "MongoDB replica set initialization completed successfully"
exit 0