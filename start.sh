#!/bin/bash
set -e

echo "ðŸš€ Starting X-UI + nginx reverse proxy..."

# nginx Ù‡Ù…ÛŒØ´Ù‡ Ø±ÙˆÛŒ Ù¾ÙˆØ±Øª Ø«Ø§Ø¨Øª 3000 Ú¯ÙˆØ´ Ù…ÛŒâ€ŒØ¯Ù‡Ø¯
export NGINX_PORT=3000

cd /usr/local/x-ui

echo "ðŸ”§ Applying panel settings via x-ui CLI..."
./x-ui setting -port 2053 -webBasePath /managepanel/ || true

echo "ðŸ”§ Building nginx.conf for fixed port: $NGINX_PORT"
envsubst '${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "â–¶ï¸  Starting x-ui in background..."
./x-ui &
X_UI_PID=$!

sleep 2

echo "â–¶ï¸  Starting nginx in foreground on port $NGINX_PORT..."
nginx -t
exec nginx -g "daemon off;"
