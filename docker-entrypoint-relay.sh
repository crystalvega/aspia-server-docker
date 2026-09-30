#!/bin/sh
set -e

CONFIG="/etc/aspia/relay.conf"
SHARED_KEY="/shared-keys/relay.pub"

ROUTER_ADDR="${ROUTER_ADDRESS:-aspia-router}"
PUBLIC_ADDR="${RELAY_PUBLIC_ADDRESS:-}"
PEER_PORT="${RELAY_PEER_PORT:-8070}"
ROUTER_PORT="${RELAY_ROUTER_PORT:-8063}"
IDLE_TIMEOUT="${RELAY_IDLE_TIMEOUT:-5}"
MAX_COUNT="${RELAY_MAX_COUNT:-100}"

TIMEOUT=60
ELAPSED=0
while [ ! -f "$SHARED_KEY" ] && [ $ELAPSED -lt $TIMEOUT ]; do
    echo "[INIT] Waiting for router public key... (${ELAPSED}s/${TIMEOUT}s)"
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

if [ ! -f "$SHARED_KEY" ]; then
    echo "[ERROR] Router public key not found after ${TIMEOUT}s."
    exit 1
fi

PUB_KEY=$(cat "$SHARED_KEY")
echo "[INIT] Got router public key."

if [ ! -f "$CONFIG" ]; then
    echo "[INIT] Generating relay.conf..."
    cat > "$CONFIG" <<EOF
[peer]
idle_timeout=${IDLE_TIMEOUT}
listen_interface=
max_count=${MAX_COUNT}
port=${PEER_PORT}
public_address=${PUBLIC_ADDR}

[router]
address=${ROUTER_ADDR}
port=${ROUTER_PORT}
public_key=${PUB_KEY}
EOF
    echo "[INIT] relay.conf created."
else
    echo "[INIT] Checking relay.conf for updates..."
    UPDATED=0

    update_field() {
        local key="$1"
        local new_val="$2"
        local current
        current=$(grep "^${key}=" "$CONFIG" | head -1 | cut -d= -f2-)
        if [ "$current" != "$new_val" ]; then
            sed -i "s|^${key}=.*|${key}=${new_val}|" "$CONFIG"
            echo "[INIT] Updated ${key} = ${new_val}"
            UPDATED=1
        fi
    }

    update_field "address" "$ROUTER_ADDR"
    update_field "port" "$ROUTER_PORT"
    update_field "public_key" "$PUB_KEY"
    update_field "public_address" "$PUBLIC_ADDR"
    update_field "port" "$PEER_PORT"
    update_field "idle_timeout" "$IDLE_TIMEOUT"
    update_field "max_count" "$MAX_COUNT"

    CURRENT_PEER_PORT=$(awk '/^\[peer\]/,/^\[/{if(/^port=/) print}' "$CONFIG" | cut -d= -f2)
    CURRENT_ROUTER_PORT=$(awk '/^\[router\]/,/^\[/{if(/^port=/) print}' "$CONFIG" | cut -d= -f2)

    if [ "$CURRENT_PEER_PORT" != "$PEER_PORT" ]; then
        awk -v val="$PEER_PORT" '/^\[peer\]/,/^$/{if(/^port=/){sub(/port=.*/,"port="val)};print;next}{print}' "$CONFIG" > "$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"
        echo "[INIT] Updated [peer] port = ${PEER_PORT}"
        UPDATED=1
    fi

    if [ "$CURRENT_ROUTER_PORT" != "$ROUTER_PORT" ]; then
        awk -v val="$ROUTER_PORT" '/^\[router\]/,/^$/{if(/^port=/){sub(/port=.*/,"port="val)};print;next}{print}' "$CONFIG" > "$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"
        echo "[INIT] Updated [router] port = ${ROUTER_PORT}"
        UPDATED=1
    fi

    [ $UPDATED -eq 0 ] && echo "[INIT] Config is up to date."
fi

exec "$@"