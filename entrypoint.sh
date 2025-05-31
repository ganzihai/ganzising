#!/bin/bash

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

# 修复：使用 nohup 启动 cloudflared 避免后台进程退出
nohup cloudflared tunnel --config /etc/cloudflared/config.yml run > /tmp/cloudflared.log 2>&1 &

# 启动 sing-box
exec sing-box run -c /etc/singbox/config.json
