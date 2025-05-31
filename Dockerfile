FROM alpine:3.18

# 安装最小依赖
RUN apk add --no-cache curl jq

# 设置固定参数
ENV UUID="d342d11e-daaa-4639-a0a9-02608e4a1d5e" \
    PORT="8001" \
    DOMAIN="cla.ganzi.fun" \
    TOKEN="eyJhIjoiNmU4NGY2ODhiZmUwNjI4MzQ0NzAwNzBhMmQ5NDZiZTUiLCJ0IjoiZTY2NTFlZWYtNWQ2ZC00NDM0LWJlNWEtMmY2MTMzYjhiOGZmIiwicyI6Ik4yVmpNR1JqWVRRdE9UVmpZeTAwTnpoaExUbGhORFV0WW1GaU5qUmpPV0UxTjJRMyJ9"

# 安装 cloudflared
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') \
    && curl -L -o /usr/local/bin/cloudflared "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}" \
    && chmod +x /usr/local/bin/cloudflared

# 安装 sing-box
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') \
    && LATEST_VERSION=$(curl -sL "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -Lo sing-box.tar.gz "https://github.com/SagerNet/sing-box/releases/download/${LATEST_VERSION}/sing-box-${LATEST_VERSION#v}-linux-${ARCH}.tar.gz" \
    && tar -xzf sing-box.tar.gz \
    && cp sing-box-*/sing-box /usr/local/bin/ \
    && rm -rf sing-box.tar.gz sing-box-*

# 创建配置目录
RUN mkdir -p /etc/singbox /etc/cloudflared

# 生成凭证文件
RUN echo "${TOKEN}" | base64 -d > /etc/cloudflared/creds.json \
    && chmod 600 /etc/cloudflared/creds.json

# 精简后的 sing-box 配置
RUN cat <<EOF > /etc/singbox/config.json
{
  "log": {
    "level": "warn",  # 减少日志级别
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vmess",
      "tag": "vmess-in",
      "listen": "0.0.0.0",
      "listen_port": ${PORT},
      "users": [
        {
          "uuid": "${UUID}",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": "/vpath"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
EOF

# 精简后的 cloudflared 配置
RUN TUNNEL_ID=$(echo "${TOKEN}" | base64 -d | jq -r '.t') \
    && cat <<EOF > /etc/cloudflared/config.yml
tunnel: ${TUNNEL_ID}
credentials-file: /etc/cloudflared/creds.json
no-autoupdate: true
protocol: http2
# 最小化日志输出
loglevel: error
disable-quic: true
disable-gre: true

ingress:
  - hostname: ${DOMAIN}
    service: http://localhost:${PORT}
  - service: http_status:404
EOF

# 复制启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 设置入口点
ENTRYPOINT ["/entrypoint.sh"]
