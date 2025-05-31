#!/bin/sh
# entrypoint.sh

# 设置DNS
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

# 打印节点配置信息
cat <<EOF
=======================================
Clash 节点配置 (VMESS over WS + TLS)
=======================================
- name: "SingBox-Cloudflare"
  type: vmess
  server: ${DOMAIN}
  port: 443
  uuid: ${UUID}
  alterId: 0
  cipher: auto
  tls: true
  skip-cert-verify: false
  network: ws
  ws-opts:
    path: "/vpath"
    headers:
      Host: ${DOMAIN}
  udp: true
=======================================
1. 以上配置可直接导入Clash客户端
2. 服务已启动
=======================================
EOF

# 启动服务
start_service() {
    while true; do
        echo "[$(date)] 启动 $1..."
        $2
        echo "[$(date)] $1 服务退出, 3秒后重启..."
        sleep 3
    done
}

# 启动 sing-box
start_service "sing-box" "sing-box run -c /etc/singbox/config.json" &

# 启动 cloudflared（使用纯令牌方式）
start_service "cloudflared" "cloudflared tunnel run --url http://localhost:${PORT} --hostname ${DOMAIN} --token ${TOKEN}" &

# 监控日志
tail -f /dev/null
