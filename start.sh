#!/bin/bash
# set -e

echo "stop and remove containers"

docker compose -f docker-compose.db.yaml down

echo "clean data"
rm -rf data/{mongo1,mongo2}
rm -rf logs/{mongo1,mongo2}

echo "create directories"
mkdir -p data/{mongo1,mongo2}
mkdir -p logs/{mongo1,mongo2}

scripts/generate-key.sh

chmod 777 logs/mongo1 logs/mongo2
chmod 777 data/mongo1 data/mongo2

docker compose -f docker-compose.db.yaml up -d

# docker inspect --format="{{json .State.Health}}"