FROM alpine:3.18 as builder

ARG SINGBOX_VERSION="1.9.2"
ARG CLOUDFLARED_VERSION="latest"

RUN apk add --no-cache curl tar gzip && \
    curl -Lo sing-box.tar.gz "https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-amd64-slim.tar.gz" && \
    tar -xzf sing-box.tar.gz && \
    mv "sing-box-${SINGBOX_VERSION}-linux-amd64/sing-box" /sing-box && \
    chmod +x /sing-box && \
    curl -Lo /cloudflared "https://github.com/cloudflare/cloudflared/releases/${CLOUDFLARED_VERSION}/download/cloudflared-linux-amd64" && \
    chmod +x /cloudflared

FROM alpine:3.18

ENV SINGBOX_PATH=/usr/local/bin/sing-box \
    CLOUDFLARED_PATH=/usr/local/bin/cloudflared \
    SUPERVISOR_CONF_PATH=/etc/supervisord.conf \
    SINGBOX_CONF_DIR=/etc/sing-box

RUN apk add --no-cache supervisor tzdata

COPY --from=builder /sing-box ${SINGBOX_PATH}
COPY --from=builder /cloudflared ${CLOUDFLARED_PATH}

RUN mkdir -p "${SINGBOX_CONF_DIR}" /var/log/supervisor

COPY configs/sing-box-config.json "${SINGBOX_CONF_DIR}/config.json"
COPY configs/supervisord.conf "${SUPERVISOR_CONF_PATH}"
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8001

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
