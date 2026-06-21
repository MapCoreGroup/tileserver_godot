#!/usr/bin/bash

docker run --rm -it --network=host \
  -v "$PWD/data:/data" \
  -v "$PWD/styles:/styles" \
  -v "$PWD/config:/config" \
  -p 8080:80 \
  maptiler/tileserver-gl \
  --config=/config/config.json
#  --verbose
#   -v "$PWD/public:/usr/src/app/public" \

