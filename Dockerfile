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

# دانلود و نصب 3x-ui — با تلاش مجدد و fail-on-error تا بیلد پایدار بماند
RUN set -eux; \
    curl -fSL --retry 8 --retry-delay 5 --retry-all-errors --connect-timeout 30 \
        -A "3x-ui-railway" \
        "https://github.com/mhsanaei/3x-ui/releases/download/v3.8.5/x-ui-linux-amd64.tar.gz" \
        -o /tmp/x-ui.tar.gz; \
    tar -xzf /tmp/x-ui.tar.gz -C /usr/local/; \
    rm -f /tmp/x-ui.tar.gz; \
    chmod +x /usr/local/x-ui/x-ui

RUN mkdir -p /etc/x-ui /var/log/x-ui

COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /start.sh
RUN chmod +x /start.sh

# پورت ثابت (پیش‌تعیین‌شده) که nginx روی آن گوش می‌دهد.
# Railway از همین EXPOSE پورت پیش‌فرض دامنه را برمی‌دارد.
# 2053 (پنل)، 2096 (ساب) و 8080 (اینباند) فقط داخلی‌اند و نیازی به EXPOSE ندارند.
EXPOSE 3000

CMD ["/start.sh"]
