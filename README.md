# x-ui on Railway — one port, multi-node (central panel + nodes)

[فارسی](./README.fa.md) | English

Runs the [3x-ui](https://github.com/mhsanaei/3x-ui) panel (v3.8.5) behind an nginx
reverse proxy on a **single Railway port**, so both the panel and your
VLESS/WebSocket inbound are reachable through the one HTTPS domain Railway gives
you.

On top of that, this package lets you link **several deployments of this repo**:
one **central panel** manages the others as **nodes**. This uses 3x-ui's built-in
multi-node feature — **the panel itself is not modified in any way**.

## Files

| File | Role |
| ---- | ---- |
| `Dockerfile` | Builds the image (3x-ui + nginx + helper). |
| `nginx.conf.template` | Single-port routing (`/managepanel/`, `/sub/`, `/`). |
| `start.sh` | Starts the panel and nginx; nginx listens on Railway's `$PORT`. |
| `node-link.sh` | Mints a node API token and prints the values to paste into the central panel. |

---

## 1. Deploy

1. Create a repo from these files (or deploy this repo directly).
2. Railway → **New Project → Deploy from GitHub repo**. Railway detects the
   `Dockerfile` and builds.
3. **Settings → Networking → Generate Domain** for the service. A panel with no
   public domain can't be reached by a central panel, so do this for **every**
   service you intend to use as a node.
4. *(Recommended)* Add a **Volume** mounted at `/etc/x-ui`, otherwise users,
   inbounds, settings and tokens are wiped on every redeploy.

### First login

```
https://<your-domain>.up.railway.app/managepanel/
```

Default `admin` / `admin` — change it in **Settings → Panel**.

### Inbound

Create a **VLESS** inbound with **Listen Port `8080`** (nginx forwards the
catch-all `location /` there), Network **ws**, Security **none**, any path
(e.g. `/cdn`).

```
vless://<UUID>@<your-domain>.up.railway.app:443?encryption=none&security=tls&sni=<your-domain>.up.railway.app&fp=chrome&type=ws&host=<your-domain>.up.railway.app&path=%2Fcdn#MyConfig
```

---

## 2. Multi-node (connect the panels)

```
                  ┌───────────────────────────────┐
   Clients ─────► │  Central panel (master)        │
                  │  https://central.up.railway.app │
                  │  /managepanel/                 │
                  └──────────────┬────────────────┘
                                 │ HTTPS + API token
              ┌──────────────────┼──────────────────┐
              ▼                  ▼                  ▼
       ┌────────────┐     ┌────────────┐     ┌────────────┐
       │  Node A    │     │  Node B    │     │  Node C    │
       │  inbound   │     │  inbound   │     │  inbound   │
       └────────────┘     └────────────┘     └────────────┘
        inbound VLESS/WS on 8080 behind the single public port
```

The central panel **pulls** from each node by calling the node's panel API at:

```
<scheme>://<address>:<port><basePath>panel/api/...
```

Since this wrapper serves the panel (and its `/panel/api/...`) under
`/managepanel/`, a node is always described like this:

| Add-node field | Value for a Railway node |
| -------------- | ------------------------ |
| **Name** | anything, e.g. `de-fra-1` |
| **Scheme** | `https` |
| **Address** | the node's Railway domain, e.g. `node-xxx.up.railway.app` (**no** `https://`) |
| **Port** | `443` |
| **Base path** | `/managepanel/` |
| **API token** | a token created **on the node** (see Step A) |
| **TLS verify** | `verify` |
| **Inbound sync** | `all` (or `selected`) |

### Step A — on the NODE: create the API key

Open the node's panel at `https://<node-domain>/managepanel/`, then either:

- **UI:** *Settings → API Tokens → create* (scope `admin`, or `node-sync`).
  **Copy it immediately** — it is shown only once.
- **Helper:** in the service shell run `bash /node-link.sh`. It mints a token and
  prints a paste-ready block:

  ```
  Scheme:    https
  Address:   node-xxx.up.railway.app
  Port:      443
  Base path: /managepanel/
  API token: <the token>
  ```

  (Values are also saved to `/etc/x-ui/node-connection.txt`.)

### Step B — on the CENTRAL panel: paste the token + address

Open the central panel → **Nodes → Add node**, fill the table above, and click
**Test / Add**. Once the node shows **online**, the central panel reports its
version, CPU/RAM, uptime and traffic, and pushes inbound/client edits to it.

> A node can itself manage further nodes; the central panel shows those as
> read-only *transitive* sub-nodes.

### Optional: mutual TLS instead of a token

Set the node's **TLS verify** to `mtls` (both sides `https`), copy the central
panel's node CA (Nodes → *Get CA*) into the node's *trusted CA* setting, and
restart the node.

---

## 3. Environment variables

| Variable | Default | Purpose |
| -------- | ------- | ------- |
| `PORT` | `3000` | Public port nginx listens on. Set by Railway automatically. |
| `NODE_PUBLIC_ADDRESS` | `$RAILWAY_PUBLIC_DOMAIN` | Address printed by `node-link.sh`. |
| `NODE_TOKEN_NAME` | `central` | Token name minted by `node-link.sh`. |

Railway target port: nginx listens on `$PORT`, so the generated domain reaches it
directly. If `PORT` isn't injected, set the service target port to `3000`.

---

## 4. What changed vs. the original wrapper

Only what is needed for reachability + node linking. **The panel is untouched.**

- `start.sh` — nginx now binds Railway's `$PORT` (`${PORT:-3000}`) instead of a
  hard-coded 3000, so the public domain always reaches it.
- `Dockerfile` — also copies `node-link.sh` into the image.
- `node-link.sh` — new, optional helper.

Everything else (`nginx.conf.template` routes, panel settings, inbound on 8080)
is unchanged.

---

## 5. Troubleshooting

- **Node offline** → check: node has a public domain; Address has no scheme;
  Port `443`; Base path `/managepanel/`; token copied in full. Opening
  `https://<node-domain>/managepanel/` in a browser must show the login page.
- **"speaks HTTP, not HTTPS"** → set that node's Scheme to `http`.
- **Token broke after redeploy** → no `/etc/x-ui` volume, so the node DB (and its
  token) was reset. Mount the volume, or mint a new token.
