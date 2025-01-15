#!/bin/bash

# Set the config directory
CONFIG_DIR="./config"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Generate random key
MONGO_REPLICA_SET_KEY=$(openssl rand -base64 756 | tr -d '\n')

# Update .env file
if grep -q "MONGO_REPLICA_SET_KEY=" .env; then
    ESCAPED_KEY=$(echo "$MONGO_REPLICA_SET_KEY" | sed 's/[\/&]/\\&/g')
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/MONGO_REPLICA_SET_KEY=.*/MONGO_REPLICA_SET_KEY=$ESCAPED_KEY/" .env
    else
        sed -i "s/MONGO_REPLICA_SET_KEY=.*/MONGO_REPLICA_SET_KEY=$ESCAPED_KEY/" .env
    fi
else
    echo "MONGO_REPLICA_SET_KEY=$MONGO_REPLICA_SET_KEY" >> .env
fi

# Create keyfile with correct permissions
echo "$MONGO_REPLICA_SET_KEY" > "$CONFIG_DIR/keyfile"

# Set proper permissions (required by MongoDB)
chmod 600 "$CONFIG_DIR/keyfile"

# Set ownership to mongodb user (UID 999 in official mongo image)
if command -v docker &> /dev/null; then
    # If running in a system with Docker
    chown 999:999 "$CONFIG_DIR/keyfile"
else
    echo "Warning: Docker not found. Please ensure keyfile ownership is set to mongodb user in your environment."
fi

echo "Replica set key generated and saved with correct permissions"