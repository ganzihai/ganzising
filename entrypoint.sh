#!/bin/sh

# 设置可靠DNS（关键修复）
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
2. 服务启动中...
=======================================
EOF

# 启动服务（精简日志输出）
sing-box run -c /etc/singbox/config.json > /dev/null 2>&1 &

# 等待服务启动
sleep 3

# 启动 cloudflared 隧道（精简日志）
cloudflared tunnel --config /etc/cloudflared/config.yml run > /dev/null 2>&1

# 保持容器运行
tail -f /dev/null
