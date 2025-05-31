
#!/bin/bash

echo "nameserver 8.8.8.8" > /tmp/resolv.conf
echo "nameserver 1.1.1.1" >> /tmp/resolv.conf
cat /tmp/resolv.conf > /etc/resolv.conf

# 输出节点配置（唯一可见内容）
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

# 静默启动服务
sing-box run -c /etc/singbox/config.json >/dev/null 2>&1 &
sleep 5
TUNNEL_TOKEN="${TOKEN}" cloudflared tunnel --config /etc/cloudflared/config.yml run >/dev/null 2>&1 &
