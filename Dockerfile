FROM alpine:latest

# --- ARGs for versions (optional, but good practice) ---
ARG SINGBOX_VERSION="1.9.2" # 查阅 https://github.com/SagerNet/sing-box/releases 获取最新稳定版
ARG CLOUDFLARED_VERSION="latest" # 或者指定版本如 2023.10.0

# --- Environment Variables ---
ENV SINGBOX_PATH /usr/local/bin/sing-box
ENV CLOUDFLARED_PATH /usr/local/bin/cloudflared
ENV SUPERVISOR_CONF_PATH /etc/supervisord.conf
ENV SINGBOX_CONF_DIR /etc/sing-box

# --- Install Dependencies ---
RUN apk add --no-cache \
    curl \
    tar \
    gzip \
    supervisor \
    ca-certificates \
    tzdata # For correct timezone in logs

# --- Install Sing-box ---
RUN curl -Lo sing-box.tar.gz "https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-amd64.tar.gz" && \
    tar -xzf sing-box.tar.gz && \
    mv "sing-box-${SINGBOX_VERSION}-linux-amd64/sing-box" "${SINGBOX_PATH}" && \
    rm -rf sing-box.tar.gz "sing-box-${SINGBOX_VERSION}-linux-amd64" && \
    chmod +x "${SINGBOX_PATH}"

# --- Install Cloudflared ---
RUN curl -Lo "${CLOUDFLARED_PATH}" "https://github.com/cloudflare/cloudflared/releases/${CLOUDFLARED_VERSION}/download/cloudflared-linux-amd64" && \
    chmod +x "${CLOUDFLARED_PATH}"

# --- Create directories and copy configurations ---
RUN mkdir -p "${SINGBOX_CONF_DIR}" /var/log/supervisor

COPY configs/sing-box-config.json "${SINGBOX_CONF_DIR}/config.json"
COPY configs/supervisord.conf "${SUPERVISOR_CONF_PATH}"
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

# Healthcheck (Optional but recommended)
# Cloudflared has a health check endpoint, Sing-box would need a specific inbound for it
# For simplicity, we'll skip a detailed healthcheck for now.

# --- Set entrypoint ---
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Expose the internal Sing-box port (for documentation, not strictly needed for Cloudflare Tunnel)
EXPOSE 8001
