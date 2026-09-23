FROM alpine:3.19

RUN apk add --no-cache \
    curl \
    bash \
    ca-certificates \
    socat \
    tzdata \
    sqlite \
    nginx \
    gettext \
    && ln -sf /usr/share/zoneinfo/Asia/Tehran /etc/localtime

# Ø¯Ø§Ù†Ù„ÙˆØ¯ Ùˆ Ù†ØµØ¨ 3x-ui â€” Ø¨Ø§ ØªÙ„Ø§Ø´ Ù…Ø¬Ø¯Ø¯ Ùˆ fail-on-error ØªØ§ Ø¨ÛŒÙ„Ø¯ Ù¾Ø§ÛŒØ¯Ø§Ø± Ø¨Ù…Ø§Ù†Ø¯
RUN set -eux; \
    curl -fSL --retry 8 --retry-delay 5 --retry-all-errors --connect-timeout 30 \
        -A "3x-ui-railway" \
        "https://github.com/mhsanaei/3x-ui/releases/download/v3.8.5/x-ui-linux-amd64.tar.gz" \
        -o /tmp/x-ui.tar.gz; \
    tar -xzf /tmp/x-ui.tar.gz -C /usr/local/; \
    rm -f /tmp/x-ui.tar.gz; \
    chmod +x /usr/local/x-ui/x-ui

RUN mkdir -p /etc/x-ui /var/log/x-ui

# Ù…Ø³ÛŒØ± Volume Ø¨Ø±Ø§ÛŒ Ù…Ø§Ù†Ø¯Ú¯Ø§Ø±ÛŒ Ø¯ÛŒØªØ§Ø¨ÛŒØ³ Ùˆ ØªÙ†Ø¸ÛŒÙ…Ø§Øª Ù¾Ù†Ù„ (Ù¾ÛŒØ´â€ŒÙØ±Ø¶ 3x-ui: /etc/x-ui)
VOLUME ["/etc/x-ui"]

COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Ù¾ÙˆØ±Øª Ø«Ø§Ø¨Øª (Ù¾ÛŒØ´â€ŒØªØ¹ÛŒÛŒÙ†â€ŒØ´Ø¯Ù‡) Ú©Ù‡ nginx Ø±ÙˆÛŒ Ø¢Ù† Ú¯ÙˆØ´ Ù…ÛŒâ€ŒØ¯Ù‡Ø¯.
# Railway Ø§Ø² Ù‡Ù…ÛŒÙ† EXPOSE Ù¾ÙˆØ±Øª Ù¾ÛŒØ´â€ŒÙØ±Ø¶ Ø¯Ø§Ù…Ù†Ù‡ Ø±Ø§ Ø¨Ø±Ù…ÛŒâ€ŒØ¯Ø§Ø±Ø¯.
# 2053 (Ù¾Ù†Ù„)ØŒ 2096 (Ø³Ø§Ø¨) Ùˆ 8080 (Ø§ÛŒÙ†Ø¨Ø§Ù†Ø¯) ÙÙ‚Ø· Ø¯Ø§Ø®Ù„ÛŒâ€ŒØ§Ù†Ø¯ Ùˆ Ù†ÛŒØ§Ø²ÛŒ Ø¨Ù‡ EXPOSE Ù†Ø¯Ø§Ø±Ù†Ø¯.
EXPOSE 3000

CMD ["/start.sh"]
