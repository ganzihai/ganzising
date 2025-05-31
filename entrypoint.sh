#!/bin/sh

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

# 创建日志文件
touch /var/log/cloudflared.log /var/log/singbox.log
chmod 644 /var/log/*.log

# 启动服务并监控
start_service() {
    while true; do
        # 启动服务并记录错误日志
        "$@" >> "/var/log/$1.log" 2>&1
        
        # 如果服务退出，记录并重启
        echo "[$(date)] Service $1 exited. Restarting..." >> "/var/log/$1.log"
        sleep 3
    done
}

# 后台启动服务监控
start_service cloudflared tunnel --config /etc/cloudflared/config.yml run &
start_service sing-box run -c /etc/singbox/config.json &

# 监控日志文件，显示关键错误
tail -f /var/log/cloudflared.log | grep -E 'ERR|WARN|INF'
