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

# Подключаемся к MongoDB и инициализируем реплика-сет
$CLIENT --host mongo1:27017 -u "$MONGO_ROOT_USERNAME" -p "$MONGO_ROOT_PASSWORD" --authenticationDatabase admin <<EOF
config = {
  "_id": "rs0",
  "members": [
    { "_id": 0, "host": "mongo1:27017", "priority": 2 },
    { "_id": 2, "host": "mongo2:27017", "priority": 1 }
  ]
};
rs.initiate(config);
EOF

echo "Replica init complete"

echo "Waiting for MongoDB replica set to be ready..."
sleep 5

# Проверяем статус реплика-сета
until $CLIENT --host mongo1:27017 -u "$MONGO_ROOT_USERNAME" -p "$MONGO_ROOT_PASSWORD" --authenticationDatabase admin --eval "rs.status().ok" | grep -q "1"; do
    echo "Waiting for MongoDB replica set to be ready..."
    sleep 5
done

echo "reduce oplog"
#
$CLIENT --host mongo1:27017 -u "$MONGO_ROOT_USERNAME" -p "$MONGO_ROOT_PASSWORD" --authenticationDatabase admin <<EOF
  use admin
  db.runCommand({ replSetResizeOplog: 1, size: 1024 })
EOF

echo "MongoDB replica set is ready."

# Здесь вы можете добавить дополнительные команды для настройки реплика-сета, если это необходимо

exit 0