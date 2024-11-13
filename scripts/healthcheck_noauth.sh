#!/bin/bash

if [[ "${MONGO_VERSION}" < "5.0" ]]; then
    mongo --eval "db.adminCommand('ping');" | grep -q "1"
else
    mongosh --eval "db.adminCommand('ping');" | grep -q "1"
fi