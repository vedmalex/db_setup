#!/bin/bash

# Генерируем случайный ключ длиной 756 байт в base64 и удаляем переносы строк
MONGO_REPLICA_SET_KEY=$(openssl rand -base64 756 | tr -d '\n')

# Обновляем .env файл
if grep -q "MONGO_REPLICA_SET_KEY=" .env; then
    # Экранируем специальные символы в ключе для sed
    ESCAPED_KEY=$(echo "$MONGO_REPLICA_SET_KEY" | sed 's/[\/&]/\\&/g')
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS версия
        sed -i '' "s/MONGO_REPLICA_SET_KEY=.*/MONGO_REPLICA_SET_KEY=$ESCAPED_KEY/" .env
    else
        # Linux версия
        sed -i "s/MONGO_REPLICA_SET_KEY=.*/MONGO_REPLICA_SET_KEY=$ESCAPED_KEY/" .env
    fi
else
    # Добавляем новый ключ
    echo "MONGO_REPLICA_SET_KEY=$MONGO_REPLICA_SET_KEY" >> .env
fi

# Создаем keyfile
echo "$MONGO_REPLICA_SET_KEY" > config/keyfile
# chmod 400 config/keyfile
# sudo chown 999:999 config/keyfile  # 999 это UID пользователя mongodb в контейнере

echo "Replica set key generated and saved"
