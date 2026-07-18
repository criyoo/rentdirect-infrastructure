FROM cloudflare/cloudflared:latest AS cloudflared

FROM alpine:3.22

RUN apk add --no-cache \
    ca-certificates \
    coreutils \
    grep

COPY --from=cloudflared \
    /usr/local/bin/cloudflared \
    /usr/local/bin/cloudflared

COPY tunnel.sh /usr/local/bin/tunnel.sh

RUN chmod +x /usr/local/bin/tunnel.sh

ENTRYPOINT ["/usr/local/bin/tunnel.sh"]