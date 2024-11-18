#!/bin/bash

# Включаем строгий режим
set -euo pipefail

# Максимальное количество попыток подключения
MAX_RETRIES=30
RETRY_INTERVAL=5

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

# Функция для проверки подключения
check_connection() {
    $CLIENT --host mongo1:27017 \
           -u "$MONGO_ROOT_USERNAME" \
           -p "$MONGO_ROOT_PASSWORD" \
           --authenticationDatabase admin \
           --eval "rs.status().ok" \
           2>&1 | tee /tmp/mongo_check_rs_status.log

    return ${PIPESTATUS[0]}
}

# Функция для анализа ошибок
analyze_error() {
    if grep -q "Connection refused" /tmp/mongo_check_rs_status.log; then
        echo "Error: Connection refused. MongoDB server might not be running."
    elif grep -q "Authentication failed" /tmp/mongo_check_rs_status.log; then
        echo "Error: Authentication failed. Please check credentials."
    elif grep -q "NetworkTimeout" /tmp/mongo_check_rs_status.log; then
        echo "Error: Network timeout occurred."
    else
        echo "Error: Unknown connection issue. Check the logs for details."
    fi
}

# Основной цикл подключения
attempt=1
while [ $attempt -le $MAX_RETRIES ]; do
    echo "Connection attempt $attempt of $MAX_RETRIES..."

    if check_connection; then
        if grep -q "1" /tmp/mongo_check_rs_status.log && ! grep -q "failed" /tmp/mongo_check_rs_status.log; then
            echo "Success: MongoDB replica set is ready!"
            exit 0
        fi
    fi

    analyze_error

    if [ $attempt -eq $MAX_RETRIES ]; then
        echo "Error: Maximum connection attempts reached. Giving up."
        exit 1
    fi

    echo "Retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
    attempt=$((attempt + 1))
done