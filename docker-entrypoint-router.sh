#!/bin/sh
set -e

CONFIG="/etc/aspia/router.conf"
SHARED_DIR="/shared-keys"

HOST_PORT="${ASPIA_HOST_PORT:-8061}"
HOST_LEGACY_PORT="${ASPIA_HOST_LEGACY_PORT:-8060}"
CLIENT_PORT="${ASPIA_CLIENT_PORT:-8062}"
RELAY_PORT="${ASPIA_RELAY_PORT:-8063}"
STUN_PORT="${ASPIA_STUN_PORT:-8065}"

if [ ! -f "$CONFIG" ]; then
    echo "[INIT] Configuration not found. Generating..."
    aspia_router --create-config
    echo ""
    echo "=========================================="
    echo " RELAY PUBLIC KEY:"
    cat /etc/aspia/relay.pub
    echo ""
    echo " HOST PUBLIC KEY:"
    cat /etc/aspia/host.pub
    echo ""
    echo " Default credentials: admin / admin"
    echo " CHANGE PASSWORD ON FIRST LOGIN!"
    echo "=========================================="
else
    echo "[INIT] Configuration found."
fi

update_port() {
    local section="$1"
    local key="$2"
    local value="$3"

    if grep -q "^\[${section}\]" "$CONFIG"; then
        if grep -q "^${key}=" "$CONFIG" 2>/dev/null; then
            CURRENT=$(grep "^${key}=" "$CONFIG" | head -1 | cut -d= -f2)
            if [ "$CURRENT" != "$value" ]; then
                sed -i "/^\[${section}\]/,/^\[/{s/^${key}=.*/${key}=${value}/}" "$CONFIG"
                echo "[INIT] Updated [${section}] ${key} = ${value}"
            fi
        fi
    fi
}

update_port "host" "port" "$HOST_PORT"
update_port "host" "legacy_port" "$HOST_LEGACY_PORT"
update_port "client" "port" "$CLIENT_PORT"
update_port "relay" "port" "$RELAY_PORT"
update_port "stun" "port" "$STUN_PORT"

cp -f /etc/aspia/relay.pub "$SHARED_DIR/relay.pub"
cp -f /etc/aspia/host.pub "$SHARED_DIR/host.pub"
echo "[INIT] Public keys exported to shared volume."

exec "$@"