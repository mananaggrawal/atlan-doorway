# Getting started with Atlan Doorway

From nothing to "my team's agents are using our skills" in about twenty
minutes. Four stages: get it running, point it at a git repo, let your team
in, connect an agent.

---

## 0. What you need before you start

- **An empty git repository** on any host (GitHub, GitLab, Bitbucket, Azure
  DevOps, self-hosted). This becomes your knowledge base — every skill, tool
  manual and permission file lives in it, and you own it. Doorway seeds it
  from a starter template on first run.
- **A git credential for that repo** with read *and* write access. On GitHub,
  a fine-grained personal access token with **Contents: read & write** scoped
  to that one repository is enough.
- Somewhere to run it: Render, any Docker host, or your laptop.

Have both ready before the first sign-in — the setup screen asks for them and
tests them against the real host before it saves.

---

## 1. Get it running

### The laptop path (fastest for a first look)

```sh
git clone https://github.com/mananaggrawal/atlan-doorway.git
cd atlan-doorway
cp .env.example .env
```

Fill four values in `.env`:

```sh
ADMIN_EMAIL=you@example.com
ADMIN_PASSWORD=pick-something
JWT_SECRET=…
SECRETS_ENC_KEY=…
```

Generate the two secrets (run it twice, one result each):

```sh
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

Then either:

```sh
docker compose up -d          # needs Docker, no Node at all
```

or, from source:

```sh
./run-local.sh
```

Open **http://localhost:3001**.

> **The Node version is the whole story if you run from source.** This repo
> needs **Node 22.x exactly** — `engines` says `>=22.13 <23`, and it means it.
> `isolated-vm` is a native addon compiled against V8's C++ API, which changes
> between majors; on Node 23+ it fails after several minutes of compiling with
> `no member named 'GetIsolate' in 'v8::Object'`. If that happens:
> `brew install node@22` (it is keg-only, which is fine — `run-local.sh` finds
> it via `brew --prefix node@22`), then `rm -rf node_modules` to clear the
> half-built addon, then run the script again. Or use Docker, which needs no
> Node on your machine at all.

### The server path

Use the Render button in the [README](README.md#1-deploy-to-render-one-click),
or bring up Docker Compose on a VPS with `DOMAIN` set and the `https` profile:

```sh
DOMAIN=doorway.your-company.com docker compose --profile https up -d
```

Caddy handles Let's Encrypt certificates and the HTTP→HTTPS redirect. You need
a DNS A record pointing at the box and ports 80 and 443 open — port 80 is not
optional, the certificate challenge uses it.

Behind a proxy you already run (Coolify, Traefik, nginx), skip the profile and
set `PUBLIC_BACKEND_URL`, `PUBLIC_FRONTEND_URL` and `TRUST_PROXY` instead —
two things terminating TLS for one app is one too many.

---

## 2. First sign-in: the setup screen

Sign in with `ADMIN_EMAIL` / `ADMIN_PASSWORD`. The app asks for three things
and tests each one before saving:

1. **Knowledge-base repo** — the https clone URL of that empty repository.
2. **Git credential** — the token from stage 0.
3. **Branch model** — which branch is the default, and which are protected.
   Changes to a protected branch can only land through an approved change
   request. For an empty repo the default `main` is fine.

Because the repo is empty, Doorway initialises it from the bundled template and
writes a `roles.yaml` whose first Admin is you. You are now in the workspace.

---

## 3. Let your team in with their work Google account

This is configuration, not code. In the Google Cloud console: **APIs &
Services → Credentials → Create OAuth client ID → Web application**, with

```
Authorised redirect URI:  https://<your-host>/api/auth/oidc/callback
```

Then set, in `.env` or your host's environment:

```sh
OIDC_ISSUER_URL=https://accounts.google.com
OIDC_CLIENT_ID=…apps.googleusercontent.com
OIDC_CLIENT_SECRET=GOCSPX-…
OIDC_PROVIDER_LABEL=Sign in with Google
ALLOWED_EMAIL_DOMAINS=your-company.com
LOGIN_PASSWORD=false
```

Restart. The login screen now shows a Google button; anyone at
`your-company.com` signs in with their work account and is provisioned on
first login. You assign roles from **Roles & Members**.

**`ALLOWED_EMAIL_DOMAINS` is load-bearing.** Google authenticates every Google
account in existence, so the domain list — not the issuer — is what keeps your
deployment yours. Set it before you expose the app publicly.

`LOGIN_PASSWORD=false` turns off password sign-in entirely once SSO works, so
there is no shared admin password sitting in your environment. Do it *after*
you have confirmed a Google sign-in succeeds, not before.

The same six lines work for Entra, Okta, Auth0 or Keycloak — only the issuer
URL changes.

---

## 4. Make your first skill

In the app: **Skills & Tools → new plugin → new skill**. A skill is a folder
with a `SKILL.md` in it. The frontmatter matters more than people expect:

```md
---
name: quarterly-report
description: Use when someone asks for the quarterly revenue report, a QBR deck, or "the numbers for last quarter".
---

Pull the figures from the Finance workspace, not from memory…
```

The `description` is the only thing an agent sees when deciding whether to load
the skill. Write it as *when to use this*, in the words someone would actually
say — not as a summary of what the skill contains. A description that describes
the contents rather than the trigger is the single most common reason a skill
sits unused.

Put an `access.md` next to it to control who can read and who can change it.
Access follows folders, so the structure of the repository *is* the permission
model.

---

## 5. Connect an agent

**Connect** in the app menu shows the exact snippet for each client. The shape
of it:

```sh
# Claude Code
claude mcp add --transport http doorway https://your-host/api/mcp
```

Complete the OAuth sign-in in the browser when prompted. The agent then sees
only what that person's role allows — the same catalogue, filtered per user.

Ask it something normal ("what's our approval process for discounts?") and it
will search the knowledge base rather than answer from memory. Ask it to do
something a skill covers and it will load that skill at call time.

Local instances work with Claude Code over `http://localhost:3001/api/mcp`.
The Claude desktop app's Connectors generally want public HTTPS, so a desktop
demo needs a real deployment or a tunnel.

---

## 6. The loop that makes it worth running

1. Someone proposes a change to a skill — a teammate in the UI, or an agent
   that hit a broken instruction mid-task.
2. On a protected branch it becomes a change request, routed to the owners of
   the files it touches.
3. An owner reviews the exact diff and approves.
4. Every agent in the company picks it up on its next call.

Nothing here is a database row you cannot inspect. It is all commits in your
repository, so `git log`, `git blame` and `git revert` work exactly as they do
for code.

---

## Where to go next

- **[Configuration](docs/configuration.md)** — every environment variable, SSO, backups, health checks
- **[Git sync](docs/git-sync.md)** — how the repository and the app stay in step
- **[Skills in Cowork and claude.ai](docs/claude-cowork.md)**
- **[Troubleshooting](docs/troubleshooting.md)** — the failures you are most likely to hit
- **[Upgrading](UPGRADING.md)** — upgrades and what to back up
