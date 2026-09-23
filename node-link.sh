#!/bin/bash
# ---------------------------------------------------------------------------
# node-link.sh
#
# Prints the values you paste into the CENTRAL panel's
# "Nodes -> Add node" dialog so this deployment can be managed as a node, and
# (re)mints the API token the central panel will authenticate with.
#
# Run it on THIS deployment (the node):
#   Railway : open the service shell, or  railway run bash /node-link.sh
#   Docker  : docker exec -it <container> bash /node-link.sh
#
# Env overrides:
#   NODE_PUBLIC_ADDRESS  public host of this node (default: $RAILWAY_PUBLIC_DOMAIN)
#   NODE_SCHEME          http|https                      (default: https)
#   NODE_PORT            public port                     (default: 443)
#   NODE_TOKEN_NAME      API token name to mint/rotate   (default: central)
#   XUI_WEB_BASE_PATH    panel base path                 (default: /managepanel/)
# ---------------------------------------------------------------------------
set -e
cd /usr/local/x-ui

TOKEN_NAME="${NODE_TOKEN_NAME:-central}"

# Mint (or rotate) the node API token. The CLI prints one line: "apiToken: <48 chars>".
# Note: pass -getApiToken as a bare flag (do NOT write "-getApiToken true"),
# otherwise "true" becomes a positional arg and later flags are dropped.
TOKEN_RAW="$(./x-ui setting -getApiToken -tokenName "$TOKEN_NAME" 2>/dev/null \
             | awk -F': ' '/^apiToken:/ {print $2}' | tail -n1)"

SCHEME="${NODE_SCHEME:-https}"
ADDR="${NODE_PUBLIC_ADDRESS:-${RAILWAY_PUBLIC_DOMAIN:-<your-node-domain>}}"
PORT="${NODE_PORT:-443}"
BASEPATH="${XUI_WEB_BASE_PATH:-/managepanel/}"

cat <<EOF

===================== NODE CONNECTION INFO =====================
| Field         | Value
| ------------- | -------------------------------------------
| Name          | $(hostname)
| Scheme        | $SCHEME
| Address       | $ADDR
| Port          | $PORT
| Base path     | $BASEPATH
| API token     | $TOKEN_RAW
| TLS verify    | verify
| Inbound sync  | all
================================================================

Paste these into the CENTRAL panel -> Nodes -> Add node.
EOF

# Persist for reference (0600). Lives on the /etc/x-ui volume if one is mounted.
umask 077
{
  echo "name=$(hostname)"
  echo "scheme=$SCHEME"
  echo "address=$ADDR"
  echo "port=$PORT"
  echo "basePath=$BASEPATH"
  echo "apiToken=$TOKEN_RAW"
  echo "created=$(date -u +%FT%TZ)"
} > /etc/x-ui/node-connection.txt
touch /etc/x-ui/.node-token-created

echo "Saved to /etc/x-ui/node-connection.txt"
