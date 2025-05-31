# SingBox with Cloudflare Tunnel Docker Image

此仓库包含一个集成了 SingBox 和 Cloudflare Tunnel 的 Docker 镜像，自动生成 Clash 客户端配置。

## 功能特点

- 自动配置 SingBox 作为 VMESS 服务器
- 集成 Cloudflare 固定隧道
- 启动时输出 Clash 客户端配置
- 固定 UUID 和路径，保证重启后节点信息不变
- 支持多架构 (amd64/arm64)

## 使用说明

### 1. 运行容器

```bash
docker run -d \
  --name=singbox-tunnel \
  --restart=always \
  --cap-add=NET_ADMIN \
  --device=/dev/net/tun \
  -p 8001:8001 \
  [DOCKERHUB_USERNAME]/singbox-cf-tunnel:latest
