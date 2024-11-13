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

#!/bin/bash
set -e

echo "Creating users..."
# Загружаем конфигурацию пользователей из JSON файла
USERS_CONFIG=$(cat users.json)

# Подключаемся к MongoDB и инициализируем реплика-сет
$CLIENT mongo1_setup:27017/admin <<EOF
// Создаем админа
const usersConfig = JSON.parse(\`$USERS_CONFIG\`);
const adminUser = usersConfig.admin;

db.getSiblingDB("admin").createUser({
  user: "$MONGO_ROOT_USERNAME",
  pwd: "$MONGO_ROOT_PASSWORD",
  roles: ["root"]
});

db.getSiblingDB("admin").createUser({
  user: adminUser.username,
  pwd: adminUser.password,
  roles: ["root"]
});

// Создаем дополнительных пользователей если нужно
usersConfig.additional_users.forEach(user => {
  db.getSiblingDB("admin").createUser({
    user: user.username,
    pwd: user.password,
    roles: user.roles
  });
});
EOF

echo "User creation completed."