#!/usr/bin/env bash
# Boots Atlan Doorway on this Mac. Run from inside this folder: ./run-local.sh
set -euo pipefail
cd "$(dirname "$0")"

# The SAME pnpm the Dockerfile pins. A different version writing pnpm-lock.yaml
# is what produced ERR_PNPM_LOCKFILE_CONFIG_MISMATCH on Render once already —
# a mismatch that only surfaces on a deploy whose layer cache misses.
PNPM_VERSION=10.33.3

# ---------------------------------------------------------------- Docker path

if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    echo "Docker found — building and starting via docker compose (recommended)."
    docker compose up -d --build
    echo
    echo "Atlan Doorway is coming up at http://localhost:3001"
    echo "  Watch it:      docker compose logs -f app"
    echo "  Sign in with:  ADMIN_EMAIL / ADMIN_PASSWORD from .env"
    echo "  Then open:     http://localhost:3001/skill-health"
    exit 0
  fi
  echo "Docker is installed but not running."
  echo "Starting Docker Desktop and re-running this script is the easiest path — it needs"
  echo "no Node, no pnpm and no Postgres on your machine."
  echo
  echo "Continuing from source instead..."
  echo
fi

# ------------------------------------------------------------ from-source path

echo "Running from source with a local Postgres."

if ! command -v node >/dev/null 2>&1; then
  echo "Node is required. Install Node 22 ('brew install node@22') and re-run."; exit 1
fi

# The supported range is NOT "22 or newer". `isolated-vm` is a native addon
# (pulled in by @utcp/code-mode and deliberately built — see the pnpm
# onlyBuiltDependencies list) and it compiles against V8's C++ API, which
# changes between majors. On Node 26 it fails with a wall of
# "no member named 'GetIsolate' in 'v8::Object'" after several minutes of
# compiling. Checking here turns that into one line, before the wait.
ENGINE_RANGE="$(node -p "require('./package.json').engines?.node ?? ''" 2>/dev/null || echo '')"
WANT_MIN="$(printf '%s' "$ENGINE_RANGE" | sed -nE 's/.*>=([0-9]+).*/\1/p')"
WANT_MAX="$(printf '%s' "$ENGINE_RANGE" | sed -nE 's/.*<([0-9]+).*/\1/p')"
WANT_MIN="${WANT_MIN:-22}"
WANT_MAX="${WANT_MAX:-23}"
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"

if [ "$NODE_MAJOR" -lt "$WANT_MIN" ] || [ "$NODE_MAJOR" -ge "$WANT_MAX" ]; then
  # Try to rescue the run with a Homebrew node@22 that is installed but not on PATH.
  RESCUE=""
  if command -v brew >/dev/null 2>&1; then
    CANDIDATE="$(brew --prefix "node@$WANT_MIN" 2>/dev/null || true)"
    if [ -n "$CANDIDATE" ] && [ -x "$CANDIDATE/bin/node" ]; then RESCUE="$CANDIDATE/bin"; fi
  fi
  if [ -n "$RESCUE" ]; then
    export PATH="$RESCUE:$PATH"
    hash -r
    NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
    echo "Node $WANT_MIN found at $RESCUE — using it for this run (your default node is untouched)."
  fi
fi

if [ "$NODE_MAJOR" -lt "$WANT_MIN" ] || [ "$NODE_MAJOR" -ge "$WANT_MAX" ]; then
  echo
  echo "Node $(node -v) is not supported by this build — it needs Node $WANT_MIN.x ($ENGINE_RANGE)."
  echo "A native dependency (isolated-vm) compiles against V8 and will not build on newer majors."
  echo
  echo "Two ways forward:"
  echo "  1. Start Docker Desktop and re-run this script. It needs no Node at all — simplest."
  echo "  2. Install Node $WANT_MIN and re-run; this script will pick it up automatically:"
  echo "       brew install node@$WANT_MIN"
  echo "     A previous failed install may have left a half-built addon, so also:"
  echo "       rm -rf node_modules"
  exit 1
fi

# pnpm, three ways — because corepack ships with some Node builds and not others,
# and a global install needs write access this script should not assume it has.
# `PNPM` ends up holding a command, not necessarily a binary name.
PNPM=""
if command -v pnpm >/dev/null 2>&1 && [ "$(pnpm --version 2>/dev/null || echo none)" = "$PNPM_VERSION" ]; then
  echo "pnpm $PNPM_VERSION already on PATH."
  PNPM="pnpm"
elif command -v corepack >/dev/null 2>&1; then
  echo "Activating pnpm $PNPM_VERSION via corepack..."
  corepack enable >/dev/null 2>&1 || true
  if corepack prepare "pnpm@$PNPM_VERSION" --activate >/dev/null 2>&1; then
    PNPM="pnpm"
  fi
fi
if [ -z "$PNPM" ]; then
  if command -v npx >/dev/null 2>&1; then
    echo "Using pnpm $PNPM_VERSION through npx (no global install needed)."
    echo "The first command will pause for a moment while npx fetches it."
    PNPM="npx -y pnpm@$PNPM_VERSION"
  else
    echo "Could not get pnpm $PNPM_VERSION. Install it with:  npm install -g pnpm@$PNPM_VERSION"
    exit 1
  fi
fi

# Postgres 17 on 127.0.0.1:5432.
if ! command -v pg_isready >/dev/null 2>&1 || ! pg_isready -h 127.0.0.1 -p 5432 >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "Starting Postgres via Homebrew (first run installs it — this can take a few minutes)..."
    brew install postgresql@17 >/dev/null 2>&1 || true
    brew services start postgresql@17 >/dev/null 2>&1 || true
    export PATH="$(brew --prefix)/opt/postgresql@17/bin:$PATH"
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      pg_isready -h 127.0.0.1 -p 5432 >/dev/null 2>&1 && break
      sleep 2
    done
  fi
fi
if ! pg_isready -h 127.0.0.1 -p 5432 >/dev/null 2>&1; then
  echo
  echo "No Postgres reachable on 127.0.0.1:5432."
  echo "Either start Docker Desktop and re-run this script (simplest), or install"
  echo "Postgres 17 (Postgres.app, or 'brew install postgresql@17 && brew services start postgresql@17')."
  exit 1
fi

createuser -h 127.0.0.1 -s doorway 2>/dev/null || true
psql -h 127.0.0.1 -U "$(whoami)" -d postgres -tAc "ALTER ROLE doorway WITH PASSWORD 'doorway'" >/dev/null 2>&1 || true
createdb -h 127.0.0.1 -O doorway doorway 2>/dev/null || true

echo "Installing dependencies (first run takes a minute or two)..."
# --frozen-lockfile, deliberately: a local run must never silently rewrite
# pnpm-lock.yaml, because the next thing that reads it is a Render build.
INSTALL_LOG="$(mktemp)"
if ! $PNPM install --frozen-lockfile 2>&1 | tee "$INSTALL_LOG"; then
  echo
  # An install can fail for several unrelated reasons and they need different
  # answers. Read what actually happened rather than blaming the lockfile for
  # all of them — the first version of this script did, and sent a native
  # compile failure off down completely the wrong path.
  if grep -qE 'ERR_PNPM_OUTDATED_LOCKFILE|ERR_PNPM_LOCKFILE_CONFIG_MISMATCH|frozen-lockfile' "$INSTALL_LOG"; then
    echo "pnpm refused the lockfile — package.json and pnpm-lock.yaml disagree."
    echo "Fix that on purpose rather than here:  $PNPM install --no-frozen-lockfile"
    echo "...then commit the updated pnpm-lock.yaml, so local and Render install the same tree."
  elif grep -qE 'gyp ERR|node-gyp|make: \*\*\*|prebuild-install' "$INSTALL_LOG"; then
    echo "A native addon failed to compile. You are on $(node -v); this build needs Node $WANT_MIN.x."
    echo "Start Docker Desktop and re-run (no Node needed), or:"
    echo "    brew install node@$WANT_MIN && rm -rf node_modules && ./run-local.sh"
    echo "Xcode command line tools are also required for native builds:  xcode-select --install"
  else
    echo "pnpm install failed — the reason is in the output above."
    echo "Full log kept at: $INSTALL_LOG"
  fi
  exit 1
fi
rm -f "$INSTALL_LOG"

echo "Building..."
$PNPM -r run build

echo
echo "Starting Atlan Doorway on http://localhost:3001"
echo "  Sign in with ADMIN_EMAIL / ADMIN_PASSWORD from .env"
echo "  Skill Health:   http://localhost:3001/skill-health"
echo "  Connect Claude: http://localhost:3001/skill-health/connect"
echo "  Scoring method: http://localhost:3001/method"
echo
STATIC_DIR="$(pwd)/apps/web/dist" $PNPM --filter @atlan-doorway/server start
