#!/bin/bash

if [[ "${MONGO_VERSION}" < "5.0" ]]; then
    mongo -u "$MONGO_ROOT_USERNAME" -p "$MONGO_ROOT_PASSWORD" --authenticationDatabase admin --eval "db.adminCommand('ping');" | grep -q "1"
else
    mongosh -u "$MONGO_ROOT_USERNAME" -p "$MONGO_ROOT_PASSWORD" --authenticationDatabase admin --eval "db.adminCommand('ping');" | grep -q "1"
fi