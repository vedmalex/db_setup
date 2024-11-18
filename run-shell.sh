#!/bin/bash

docker run -it --rm \
  -p 3102:3102 \
  -v ./:/app \
  -w /app/applications/Sharan/ \
  -e NODE_OPTIONS=--max_old_space_size=12288 \
  --network grainjs_network \
  node:23 bash