# 3x-ui on Railway â€” one port (no TCP Proxy)

[ÙØ§Ø±Ø³ÛŒ](./README.md) | English

This repo runs [3x-ui](https://github.com/mhsanaei/3x-ui) behind an nginx reverse
proxy so both the web panel and your VLESS/WebSocket inbound are reachable through
a **single fixed port (3000)** â€” the same idea as the RVG setup.

## Why

By default 3x-ui runs the panel on one port and each inbound on another. A Railway
Public Domain points at only **one** internal port, so you'd get either the panel
or the inbound â€” not both. nginx puts both behind one port.

## Deploy

### 1. Create a repo
Create a new GitHub repo (public or private) and put these files at the root:
- `Dockerfile`
- `nginx.conf.template`
- `start.sh`

### 2. In Railway
1. **New Project â†’ Deploy from GitHub repo**, pick the repo.
2. Railway auto-detects the `Dockerfile` and builds.
3. When the deploy finishes, go to **Settings â†’ Networking â†’ Generate Domain**.
   The image declares **`EXPOSE 3000`**, so the port is preset to **3000**
   (nginx listens there). One domain is enough.

### Ports (predetermined)

| Port | Used by | Exposure |
|---|---|---|
| **3000** | nginx (panel + inbound + sub) | **public** â€” what `Generate Domain` targets (`EXPOSE 3000`) |
| 2053 | 3x-ui panel | internal only |
| 2096 | subscription server | internal only |
| 8080 | VLESS/WebSocket inbound | internal only |

### 3. First login
Your panel URL:
```
https://yourdomain.up.railway.app/managepanel/
```
Default 3x-ui credentials are `admin` / `admin` â€” change them immediately in
**Settings**.

### 4. Create an inbound
Create an inbound with exactly these values:

| Field | Value |
|---|---|
| Protocol | VLESS |
| Listen Port | **8080** (must not change â€” nginx points here) |
| Listen IP | empty or `0.0.0.0` |
| Network | ws |
| Security | none |
| Path | any, e.g. `/cdn` |

âš ï¸ If you want a different inbound port, change `127.0.0.1:8080` in
`nginx.conf.template` to match, then push/redeploy.

### 5. Client link
```
vless://UUID@yourdomain.up.railway.app:443?encryption=none&security=tls&sni=yourdomain.up.railway.app&fp=chrome&type=ws&host=yourdomain.up.railway.app&path=%2Fcdn#MyConfig
```

### Quick test
Open in a browser:
```
https://yourdomain.up.railway.app/cdn
```
You should see **"Bad Request"** (the request reached Xray). The panel should also
answer:
```
https://yourdomain.up.railway.app/managepanel/
```

## Notes

- All inbound(s) must use the same internal port **8080**. Multiple inbounds with
  different paths on that port are fine (they differ only by WebSocket path).
- The panel DB/settings (`/etc/x-ui`) live on the container's ephemeral
  filesystem. To keep users/inbounds across redeploys, attach a **Volume** at
  `/etc/x-ui`.

---

## Multi-node: connect panels together (no panel change)

3x-ui has built-in multi-node support: the central panel manages each **node**
using an **API token** created on that node. In this architecture the panel is
served at `/managepanel/`, so the node's **Base path** is always `/managepanel/`.
**No panel or config change is required.**

The central panel calls a node at:
```
https://<node-domain>/managepanel/panel/api/...
```

### Step 1 â€” on the NODE: create an API key
Open the node panel: `https://<node-domain>/managepanel/`
Then **Settings â†’ API Tokens â†’ Create**, scope = `admin`.
**Copy the token immediately** (shown only once).

### Step 2 â€” on the CENTRAL panel: add the node
**Nodes â†’ Add node** with these exact values:

| Field | Value |
|---|---|
| Name | anything, e.g. `de-fra-1` |
| Scheme | `https` |
| Address | the node's domain, e.g. `node-xxx.up.railway.app` (no `https://`) |
| Port | `443` |
| Base path | `/managepanel/` |
| API token | the token from Step 1 |
| TLS verify | `verify` |
| Inbound sync | `all` or `selected` |

Click **Test/Add**. When the node shows **online**, the central panel reports its
version/CPU/RAM/uptime/traffic and pushes inbound/client edits to it.

### Notes
- Attach a **Volume** at `/etc/x-ui` on **every node**, otherwise a redeploy wipes
  the token/users and the link breaks.
- Every node needs a **Generate Domain** so the central panel can reach it.
- Persian guide: [README.md](./README.md)
