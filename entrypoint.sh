#!/bin/sh
set -e

SINGBOX_PORT="8001"
CLOUDFLARE_DOMAIN="cla.ganzi.fun"
VLESS_UUID="a1b2c3d4-e5f6-7890-1234-567890abcdef"
WS_PATH="/ws-path"

SUPERVISOR_LOG_DIR="/var/log/supervisor"
mkdir -p "$SUPERVISOR_LOG_DIR"

# Start supervisor
echo "Starting services..."
exec /usr/bin/supervisord -n -c /etc/supervisord.conf
