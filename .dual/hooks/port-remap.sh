#!/bin/bash

# port-remap.sh - Automatically remap service PORTs when worktree is created
#
# This hook runs on postWorktreeCreate and outputs environment variable overrides
# in the format dual expects:
#   - GLOBAL:KEY=VALUE for global overrides (all services)
#   - service:KEY=VALUE for service-specific overrides
#
# dual will parse these outputs and:
#   1. Store them in the registry (.dual/registry.json)
#   2. Generate service-local .env files (.dual/.local/service/<service>/.env)

set -e

# Verify this is the correct event
if [ "$DUAL_EVENT" != "postWorktreeCreate" ]; then
  echo "[port-remap] ERROR: This hook should only run on postWorktreeCreate (got: $DUAL_EVENT)" >&2
  exit 1
fi

echo "[port-remap] Remapping PORTs for context: $DUAL_CONTEXT_NAME" >&2
echo "[port-remap] Worktree path: $DUAL_CONTEXT_PATH" >&2
echo "[port-remap] Project root: $DUAL_PROJECT_ROOT" >&2

# Remap offset - add 100 to each base port
REMAP_OFFSET=100

echo "[port-remap] Using remap offset: +$REMAP_OFFSET" >&2

# Remap each service's PORT (hardcoded base ports)
# Output to stdout in the format: service:PORT=value
# These will be captured by dual and written to the registry

# api: 4101 -> 4201
API_PORT=$((4101 + REMAP_OFFSET))
echo "[port-remap]   api: PORT 4101 → $API_PORT" >&2
echo "api:PORT=$API_PORT"

# web: 4102 -> 4202
WEB_PORT=$((4102 + REMAP_OFFSET))
echo "[port-remap]   web: PORT 4102 → $WEB_PORT" >&2
echo "web:PORT=$WEB_PORT"

# worker: 4103 -> 4203
WORKER_PORT=$((4103 + REMAP_OFFSET))
echo "[port-remap]   worker: PORT 4103 → $WORKER_PORT" >&2
echo "worker:PORT=$WORKER_PORT"

# You can also set global environment variables:
# echo "GLOBAL:DATABASE_URL=postgres://localhost/mydb_${DUAL_CONTEXT_NAME}"
# echo "GLOBAL:DEBUG=true"

echo "[port-remap] PORT remapping complete!" >&2
echo "[port-remap] dual will write these overrides to the registry and generate .env files" >&2
