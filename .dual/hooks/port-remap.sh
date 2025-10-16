#!/bin/bash

# port-remap.sh - Example hook for setting context-specific environment variables
#
# This hook runs on postWorktreeCreate and demonstrates how to set different
# environment values based on the context name.
#
# IMPORTANT: Environment overrides are stored in the PARENT REPO at:
#   <parent-repo>/.dual/.local/service/<service>/.env
#
# This means all worktrees SHARE the same overrides. If you need per-worktree
# isolation, you can use this hook to set context-specific values using the
# DUAL_CONTEXT_NAME variable.

set -e

# Verify this is the correct event
if [ "$DUAL_EVENT" != "postWorktreeCreate" ]; then
  echo "[port-remap] ERROR: This hook should only run on postWorktreeCreate (got: $DUAL_EVENT)" >&2
  exit 1
fi

echo "[port-remap] Setting up environment for context: $DUAL_CONTEXT_NAME" >&2
echo "[port-remap] Worktree path: $DUAL_CONTEXT_PATH" >&2
echo "[port-remap] Project root: $DUAL_PROJECT_ROOT" >&2

# Example: Set a database URL that includes the context name
# This creates isolation even though the overrides are shared
cd "$DUAL_PROJECT_ROOT"

echo "[port-remap] Setting DATABASE_URL with context name..." >&2
dual env set DATABASE_URL "postgres://localhost/${DUAL_CONTEXT_NAME}_db"

echo "[port-remap] Setting DEBUG flag..." >&2
dual env set DEBUG "true"

# Example: Set service-specific ports based on context
# You could calculate ports based on context name hash or use sequential assignment
echo "[port-remap] Setting service-specific PORTs..." >&2

# Simple approach: use a base port offset
case "$DUAL_CONTEXT_NAME" in
  "dev")
    API_PORT=4101
    WEB_PORT=4102
    WORKER_PORT=4103
    ;;
  "feature-auth")
    API_PORT=4201
    WEB_PORT=4202
    WORKER_PORT=4203
    ;;
  "feature-payments")
    API_PORT=4301
    WEB_PORT=4302
    WORKER_PORT=4303
    ;;
  *)
    # Default: use hash of context name for deterministic port assignment
    # This ensures consistent ports for the same context name
    HASH=$(echo -n "$DUAL_CONTEXT_NAME" | md5sum | cut -c1-4)
    BASE_OFFSET=$((0x$HASH % 1000 * 100))
    API_PORT=$((4000 + BASE_OFFSET + 1))
    WEB_PORT=$((4000 + BASE_OFFSET + 2))
    WORKER_PORT=$((4000 + BASE_OFFSET + 3))
    ;;
esac

dual env set --service api PORT "$API_PORT"
dual env set --service web PORT "$WEB_PORT"
dual env set --service worker PORT "$WORKER_PORT"

echo "[port-remap] Environment setup complete!" >&2
echo "[port-remap]   DATABASE_URL: postgres://localhost/${DUAL_CONTEXT_NAME}_db" >&2
echo "[port-remap]   api PORT: $API_PORT" >&2
echo "[port-remap]   web PORT: $WEB_PORT" >&2
echo "[port-remap]   worker PORT: $WORKER_PORT" >&2
