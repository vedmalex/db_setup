#!/bin/bash

docker run -it --rm \
  -p 3102:3102 \
  -v ./:/app \
  -w /app/apps/sharan/applications/Sharan/ \
  -e NODE_OPTIONS=--max_old_space_size=12288 \
  node:23 npx grainjs edit
