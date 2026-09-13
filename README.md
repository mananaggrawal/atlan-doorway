<p align="center">
  <img src="docs/hero-light.svg" alt="Atlan Doorway: git-backed skills, tools and context for AI agents" width="100%">
</p>

**Atlan Doorway is a git-backed control plane for AI-agent skills, tools,
context, permissions and identity. Self-hosted and MCP-native.**

One place where your company's AI skills, tool manuals and knowledge live —
centrally managed, reviewed and access-controlled, and usable from **any AI
agent** that speaks MCP.

---

## Quick start

Three ways in, fastest first. All three end at the same place: your own
instance, your own git repository, your team signing in.

### 1. Deploy to Render (one click)

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/mananaggrawal/atlan-doorway)

The blueprint in [`render.yaml`](render.yaml) provisions the web service and a
Postgres database, and generates `JWT_SECRET` and `SECRETS_ENC_KEY` for you.
Set `ADMIN_EMAIL` and `ADMIN_PASSWORD` when prompted and you are live.

### 2. Docker Compose

You need Docker with Compose, and an **empty git repository** on any host to
hold your knowledge base — the app seeds it from a starter template on first
run.

```sh
git clone https://github.com/mananaggrawal/atlan-doorway.git
cd atlan-doorway
cp .env.example .env
```

Fill the four required values in `.env`:

```sh
ADMIN_EMAIL=you@example.com     # the deployment owner, always an admin
ADMIN_PASSWORD=pick-something   # only used when password login is on
JWT_SECRET=…                    # node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
SECRETS_ENC_KEY=…               # same command, run it again
```

Then:

```sh
docker compose up -d
```

Open **http://localhost:3001** and sign in. For a public deployment set
`DOMAIN=doorway.your-domain.com` and start with `--profile https` — Caddy
handles Let's Encrypt certificates and the HTTP→HTTPS redirect.

### 3. From source

Needs **Node 22.x** (the range is `>=22.13 <23` — not "22 or newer"; the
`isolated-vm` native addon will not compile on Node 23+), pnpm 10, git ≥ 2.41
and Postgres 17.

```sh
./run-local.sh
```

That script checks your Node version, finds or fetches the right pnpm,
installs, starts the bundled Postgres and boots the app. See
[GETTING-STARTED.md](GETTING-STARTED.md) for the full walkthrough.

---

## Sign in with your organisation's Google account

Doorway speaks standard OIDC, so Google Workspace sign-in is configuration,
not code. Create an OAuth client in the Google Cloud console with the
redirect URI `https://your-host/api/auth/oidc/callback`, then set:

```sh
OIDC_ISSUER_URL=https://accounts.google.com
OIDC_CLIENT_ID=…apps.googleusercontent.com
OIDC_CLIENT_SECRET=…
OIDC_PROVIDER_LABEL=Sign in with Google
ALLOWED_EMAIL_DOMAINS=your-company.com
LOGIN_PASSWORD=false            # optional: SSO only, no passwords
```

Anyone at `your-company.com` can now sign in with their work Google account
and is provisioned on first login; an admin assigns them roles from
**Roles & Members**. `ALLOWED_EMAIL_DOMAINS` is not optional against Google —
Google will authenticate anyone on earth, so the domain list is the boundary
that keeps your deployment yours.

The same block works for Entra, Okta, Auth0 or Keycloak; only the issuer URL
changes.

---

## What it does

**Skills and tools as reviewable files.** Every skill, tool manual and
permission is a file in a git repository you own. The audit trail is the
storage layer: who changed what, when, who approved it, and how to undo it.

**Bidirectional, not a gateway.** MCP gateways only let people consume. In
Doorway anyone can propose a change; on protected branches it reaches the
owners of the files it touches and ships only once they approve. Agents
propose too — one that hits a broken skill mid-task can suggest the fix, and
a person decides whether it lands.

**Per-file access control.** An agent can only do what the person running it
can do, resolved per file, and it never holds the credentials it uses.
Secrets live in an encrypted vault and are injected at call time.

**Any MCP client.** Claude Code, Claude Desktop, Codex, Cursor, Cline and
ChatGPT all connect over MCP with OAuth 2.1, each seeing only what its user's
role allows.

**Context that does not flood the window.** Agents look skills up rather than
loading them all: `list_skills` and `search` narrow the field, `get_skill`
returns one skill at call time.

---

## Documentation

- **[GETTING-STARTED.md](GETTING-STARTED.md)** — first run, first skill, connecting an agent
- **[Configuration](docs/configuration.md)** — every environment variable, SSO, backups, health
- **[Skills in Cowork and claude.ai](docs/claude-cowork.md)**
- **[Git sync](docs/git-sync.md)**
- **[Troubleshooting](docs/troubleshooting.md)**
- **[Upgrading](UPGRADING.md)**

## Repository layout

| Path | What it is |
| --- | --- |
| `packages/shared` | `@atlan-doorway/platform-shared`: shared types + pure domain utilities |
| `packages/core-backend` | `@atlan-doorway/platform-core-backend`: the core backend (ships `migrations/` + `kb-template/`) |
| `packages/core-frontend` | `@atlan-doorway/platform-core-frontend`: the core UI, published as raw TS/TSX source |
| `packages/doorway-mcp` | `@atlan-doorway/doorway-mcp`: the MCP server and CLI |
| `packages/mcp-core` | `@atlan-doorway/platform-mcp-core`: shared MCP plumbing |
| `apps/server` | standalone core backend shell |
| `apps/web` | standalone core SPA shell (Vite) |

## FAQ

<details>
<summary><b>How does an agent know what is in the knowledge base?</b></summary>

Every MCP session starts with instructions: a fixed platform header that says
what Doorway is and to search the knowledge base before answering from memory,
followed by `mcp-description.md` from the root of your repository, where an
admin describes what the knowledge base holds and when to consult it.
</details>

<details>
<summary><b>How is the catalogue versioned?</b></summary>

By git: every save is a commit, so history, blame and revert work as they do
for code, and changes to protected branches ship as reviewable change requests.
</details>

<details>
<summary><b>What governance do we get?</b></summary>

Per-file access control, review-gated change requests, and a git audit trail
of who changed what and who approved it.
</details>

License: [Apache-2.0](LICENSE)
