#!/bin/bash
# set -e

echo "stop and remove containers"

docker compose -f docker-compose.db-single.yaml down

echo "clean data"
rm -rf data/{mongo1}
rm -rf logs/{mongo1}

echo "create directories"
mkdir -p data/{mongo1}
mkdir -p logs/{mongo1}

scripts/generate-key.sh

chmod 777 logs/mongo1
chmod 777 data/mongo1

docker compose -f docker-compose.db-single.yaml up -d
