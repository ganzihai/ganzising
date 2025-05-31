FROM alpine:3.18 as builder

ARG SINGBOX_VERSION="1.9.2"

# Install required tools
RUN apk add --no-cache curl tar gzip

# Download and install sing-box
RUN curl -Lo sing-box.tar.gz "https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-amd64-slim.tar.gz" && \
    tar -xzf sing-box.tar.gz && \
    mv "sing-box-${SINGBOX_VERSION}-linux-amd64-slim/sing-box" /sing-box && \
    chmod +x /sing-box

# Download and install cloudflared
RUN curl -Lo /cloudflared "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" && \
    chmod +x /cloudflared

FROM alpine:3.18

ENV SINGBOX_PATH=/usr/local/bin/sing-box \
    CLOUDFLARED_PATH=/usr/local/bin/cloudflared \
    SUPERVISOR_CONF_PATH=/etc/supervisord.conf \
    SINGBOX_CONF_DIR=/etc/sing-box

# Install minimal required packages
RUN apk add --no-cache supervisor tzdata

# Copy binaries from builder
COPY --from=builder /sing-box ${SINGBOX_PATH}
COPY --from=builder /cloudflared ${CLOUDFLARED_PATH}

# Create necessary directories
RUN mkdir -p "${SINGBOX_CONF_DIR}" /var/log/supervisor

# Copy configuration files
COPY configs/sing-box-config.json "${SINGBOX_CONF_DIR}/config.json"
COPY configs/supervisord.conf "${SUPERVISOR_CONF_PATH}"
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Set permissions
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8001

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
