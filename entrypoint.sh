#!/bin/sh
set -e

# --- 配置变量 (与 sing-box-config.json 和 Clash 输出匹配) ---
SINGBOX_PORT="8001" # 内部 Sing-box 监听端口
CLOUDFLARE_DOMAIN="cla.ganzi.fun"
# 这个 UUID 必须与 sing-box-config.json 中的 users.uuid 严格一致
VLESS_UUID="a1b2c3d4-e5f6-7890-1234-567890abcdef" # 请替换成你 sing-box-config.json 中使用的 UUID
WS_PATH="/ws-path" # 必须与 sing-box-config.json 中的 transport.path 一致

# --- Supervisor 和日志文件 ---
SUPERVISOR_LOG_DIR="/var/log/supervisor"
SINGBOX_LOG_FILE="${SUPERVISOR_LOG_DIR}/sing-box.log"
CLOUDFLARED_LOG_FILE="${SUPERVISOR_LOG_DIR}/cloudflared.log"

# 创建 supervisor 日志目录和文件，以防 supervisor 无法创建
mkdir -p "$SUPERVISOR_LOG_DIR"
touch "$SINGBOX_LOG_FILE" "$CLOUDFLARED_LOG_FILE"
# 如果 supervisor 以非 root 运行，可能需要 chown

echo "Starting Supervisor to manage Sing-box and Cloudflared..."
/usr/bin/supervisord -c /etc/supervisord.conf

# 等待服务启动，特别是 Cloudflared 建立隧道连接
# 这个等待时间可能需要根据实际情况调整
echo "Waiting for services to initialize (15 seconds)..."
sleep 15

echo ""
echo "-----------------------------------------------------------------------"
echo "Clash Configuration Node (copy and paste into your Clash config proxies):"
echo "-----------------------------------------------------------------------"
cat <<EOF
proxies:
  - name: "Singbox-CF-${CLOUDFLARE_DOMAIN}"
    type: vless
    server: ${CLOUDFLARE_DOMAIN}
    port: 443 # Cloudflare Tunnel 通常使用 443 (HTTPS)
    uuid: ${VLESS_UUID}
    network: ws
    tls: true
    servername: ${CLOUDFLARE_DOMAIN} # SNI, 必须是你的隧道域名
    # client-fingerprint: chrome # 可选, 有些服务端需要
    ws-opts:
      path: "${WS_PATH}"
      headers:
        Host: ${CLOUDFLARE_DOMAIN}
EOF
echo "-----------------------------------------------------------------------"
echo "Example proxy-groups and rules (add to your Clash config):"
echo "proxy-groups:"
echo "  - name: \"🚀 Proxy Tunnel\""
echo "    type: select"
echo "    proxies:"
echo "      - \"Singbox-CF-${CLOUDFLARE_DOMAIN}\""
echo "      - DIRECT"
echo "rules:"
echo "  - MATCH, \"🚀 Proxy Tunnel\"" # 或者你定义的其他策略组
echo "-----------------------------------------------------------------------"
echo ""
echo "Sing-box and Cloudflared are running in the background."
echo "You can view logs using 'docker logs <container_id>' or by checking files in $SUPERVISOR_LOG_DIR inside the container."
echo "Tailing logs now (Ctrl+C to stop and remove the container if run with --rm):"
echo ""

# 保持容器运行并显示日志
# 使用 tail -f 多个文件时，如果一个文件不存在，tail 会报错退出
# 所以我们先确保它们存在 (已在上面 touch)
tail -n 50 -f "$SINGBOX_LOG_FILE" "$CLOUDFLARED_LOG_FILE"
