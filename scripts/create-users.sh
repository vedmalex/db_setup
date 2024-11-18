#!/bin/bash
set -e

# Проверка наличия переменной MONGO_VERSION
if [ -z "${MONGO_VERSION}" ]; then
    echo "Error: MONGO_VERSION environment variable is not set"
    exit 1
fi

# Проверка наличия обязательных переменных окружения
if [ -z "${MONGO_ROOT_USERNAME}" ] || [ -z "${MONGO_ROOT_PASSWORD}" ]; then
    echo "Error: MONGO_ROOT_USERNAME and/or MONGO_ROOT_PASSWORD environment variables are not set"
    exit 1
fi

# Определяем какой клиент использовать в зависимости от версии MongoDB
if [[ "${MONGO_VERSION}" < "5.0" ]]; then
    CLIENT="mongo"
else
    CLIENT="mongosh"
fi

echo "Creating users..."

# Проверяем существование файла users.json
if [ ! -f "users.json" ]; then
    echo "Warning: users.json file not found. Only root user will be created."

    # Создаем только root пользователя без дополнительных пользователей
    $CLIENT mongo1_setup:27017/admin <<EOF
    db.getSiblingDB("admin").createUser({
      user: "$MONGO_ROOT_USERNAME",
      pwd: "$MONGO_ROOT_PASSWORD",
      roles: ["root"]
    });
EOF
else
    # Проверяем, что файл users.json содержит валидный JSON
    if ! jq empty users.json 2>/dev/null; then
        echo "Error: users.json is not a valid JSON file"
        exit 1
    fi

    # Загружаем конфигурацию пользователей из JSON файла
    USERS_CONFIG=$(cat users.json)

    # Подключаемся к MongoDB и создаем пользователей
    $CLIENT mongo1_setup:27017/admin <<EOF
    try {
        // Создаем root пользователя
        db.getSiblingDB("admin").createUser({
          user: "$MONGO_ROOT_USERNAME",
          pwd: "$MONGO_ROOT_PASSWORD",
          roles: ["root"]
        });

        // Парсим конфигурацию пользователей
        const usersConfig = JSON.parse(\`$USERS_CONFIG\`);

        // Создаем админа если он указан
        if (usersConfig.admin && usersConfig.admin.username!== "$MONGO_ROOT_USERNAME") {
            db.getSiblingDB("admin").createUser({
                user: usersConfig.admin.username,
                pwd: usersConfig.admin.password,
                roles: ["root"]
            });
            print("Admin user created successfully");
        }

        // Создаем дополнительных пользователей если они указаны
        if (usersConfig.additional_users) {
            usersConfig.additional_users.forEach(user => {
                db.getSiblingDB("admin").createUser({
                    user: user.username,
                    pwd: user.password,
                    roles: user.roles
                });
                print("Additional user " + user.username + " created successfully");
            });
        }
    } catch (e) {
        print("Error occurred while creating users: " + e);
        quit(1);
    }
EOF
fi

echo "User creation completed."