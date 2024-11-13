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

until $CLIENT --host mongo1:27017 -u "$MONGO_ROOT_USERNAME" -p "$MONGO_ROOT_PASSWORD" --authenticationDatabase admin --eval "rs.status().ok" 2>&1 | tee /tmp/mongo_status.log | grep -q "1" && ! grep -q "connect failed" /tmp/mongo_status.log; do
    if grep -q "connect failed" /tmp/mongo_status.log; then
        echo "Connection failed, retrying in 5 seconds..."
    else
        echo "Waiting for MongoDB replica set to be ready..."
    fi
    sleep 5
done

echo "MongoDB replica set is ready!"