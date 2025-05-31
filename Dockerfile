# 使用 Alpine 基础镜像
FROM alpine:3.18

# 安装依赖
RUN apk add --no-cache curl jq bash

# 设置固定参数
ENV UUID="d342d11e-daaa-4639-a0a9-02608e4a1d5e" \
    PORT="8001" \
    DOMAIN="claw.ganzi.fun" \
    TOKEN="eyJhIjoiNmU4NGY2ODhiZmUwNjI4MzQ0NzAwNzBhMmQ5NDZiZTUiLCJ0IjoiNWNiOTFhYTEtNWUzYy00ZTlkLWJlNzgtNTY0NTRmMDFkMzE1IiwicyI6Ik9XTmpPV1pqT0RBdE0yUmlZaTAwTW1NekxXSXlObVF0TTJFd05USXlaVFV4TUdNeiJ9"

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

# 写入 cloudflared 凭证
RUN echo "${TOKEN}" | base64 -d > /etc/cloudflared/creds.json

# 修复：使用 listen_port 替代 port
RUN cat <<EOF > /etc/singbox/config.json
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vmess",
      "tag": "vmess-in",
      "listen": "0.0.0.0",
      "listen_port": ${PORT},  # 修复此处字段名
      "sniff": true,
      "sniff_override_destination": true,
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

# 生成 cloudflared 配置文件
RUN cat <<EOF > /etc/cloudflared/config.yml
tunnel: $(echo ${TOKEN} | base64 -d | jq -r .t)
credentials-file: /etc/cloudflared/creds.json

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
