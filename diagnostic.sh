#!/bin/bash

# 诊断信息输出函数
log_diag() {
    echo "[DIAG] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# 1. 检查网络连通性
log_diag "===== 网络诊断开始 ====="
log_diag "检查 Cloudflare IP 连通性:"
ping -c 2 1.1.1.1 | awk '{print "[DIAG] " $0}'

log_diag "检查 DNS 解析:"
nslookup $DOMAIN 1.1.1.1 | awk '{print "[DIAG] " $0}'

# 2. 检查服务状态
log_diag "检查 Sing-box 监听端口:"
netstat -tuln | grep ":$PORT" | awk '{print "[DIAG] " $0}'

# 3. 检查配置文件
log_diag "检查 Cloudflared 凭证文件:"
ls -l /etc/cloudflared/creds.json | awk '{print "[DIAG] " $0}'
head -c 100 /etc/cloudflared/creds.json | awk '{print "[DIAG] " $0}'

log_diag "检查 Cloudflared 配置文件:"
cat /etc/cloudflared/config.yml | awk '{print "[DIAG] " $0}'

# 4. 检查隧道 ID
TUNNEL_ID=$(echo "${TOKEN}" | base64 -d | jq -r '.t')
log_diag "隧道 ID: $TUNNEL_ID"

# 5. 检查服务响应
log_diag "测试本地服务响应:"
timeout 5 curl -v http://localhost:$PORT 2>&1 | awk '{print "[DIAG] " $0}'

log_diag "===== 网络诊断结束 ====="
