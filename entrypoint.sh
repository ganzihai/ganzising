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

# 运行诊断检查
/diagnostic.sh

# 启动 cloudflared 隧道（前台运行）
echo "===== 启动 Cloudflared 隧道 ====="
cloudflared tunnel --config /etc/cloudflared/config.yml run 2>&1 | awk '{print "[Cloudflared] " $0}' &

# 启动 sing-box（前台运行）
echo "===== 启动 Sing-box 服务 ====="
exec sing-box run -c /etc/singbox/config.json 2>&1 | awk '{print "[Sing-box] " $0}'
