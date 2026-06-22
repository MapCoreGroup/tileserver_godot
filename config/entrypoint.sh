#!/bin/bash
# Graceful tileserver-gl entrypoint: prune the config to the map data (mbtiles) present in /data,
# then start the server. Lets `docker compose up` work on any machine even if some/all .mbtiles are
# missing (the repo does NOT ship the multi-GB data) — missing layers are skipped, never crash.
set -e
CONFIG="${1:-/config/config.json}"
PRUNED="$(node /config/prune-config.mjs "$CONFIG")"
exec /usr/src/app/docker-entrypoint.sh --config="$PRUNED"
