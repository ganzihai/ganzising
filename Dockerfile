# 使用 Alpine 基础镜像
FROM alpine:3.18

# 安装最小依赖
RUN apk add --no-cache curl

# 设置固定参数（注意：使用单行环境变量定义避免语法错误）
ENV UUID="d342d11e-daaa-4639-a0a9-02608e4a1d5e" PORT="80" DOMAIN="cla.ganzi.fun" TOKEN="eyJhIjoiNmU4NGY2ODhiZmUwNjI4MzQ0NzAwNzBhMmQ5NDZiZTUiLCJ0IjoiZTY2NTFlZWYtNWQ2ZC00NDM0LWJlNWEtMmY2MTMzYjhiOGZmIiwicyI6Ik4yVmpNR1JqWVRRdE9UVmpZeTAwTnpoaExUbGhORFV0WW1GaU5qUmpPV0UxTjJRMyJ9"

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
RUN mkdir -p /etc/singbox

# 生成精简的 sing-box 配置
RUN cat <<EOF > /etc/singbox/config.json
{
  "log": {
    "level": "error",
    "timestamp": false
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

# 复制启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 设置入口点
ENTRYPOINT ["/entrypoint.sh"]
