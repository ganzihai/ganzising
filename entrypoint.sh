#!/bin/bash

# 解决DNS问题：在运行时设置DNS
echo "nameserver 8.8.8.8" > /tmp/resolv.conf
echo "nameserver 1.1.1.1" >> /tmp/resolv.conf
cat /tmp/resolv.conf > /etc/resolv.conf

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

# 启动服务
echo "===== 启动 Sing-box 服务 ====="
sing-box run -c /etc/singbox/config.json 2>&1 | awk '{print "[Sing-box] " $0}' &

# 等待服务启动
echo "等待 Sing-box 启动..."
sleep 5

# 检查服务状态
echo "===== 服务状态检查 ====="
netstat -tuln | awk '{print "[Status] " $0}'

# 测试本地服务
echo "测试本地服务:"
curl -v http://localhost:${PORT} 2>&1 | awk '{print "[Test] " $0}'

# 启动 cloudflared 隧道
echo "===== 启动 Cloudflared 隧道 ====="
cloudflared tunnel --config /etc/cloudflared/config.yml run 2>&1 | awk '{print "[Cloudflared] " $0}'
