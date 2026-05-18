#!/usr/bin/env bash
# install.sh — bootstrap a fresh Debian 12 LXC into Ben's dev sandbox setup.
#
# One-liner from a fresh root shell (no USB, no extra args):
#
#   curl -fsSL https://raw.githubusercontent.com/dabmarketing/lxc-bootstrap/main/install.sh | bash
#
# Everything is fetched from this repo. After it finishes:
#   source ~/.bashrc && claude

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/dabmarketing/lxc-bootstrap/main"

LOG()  { printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
WARN() { printf '\033[1;33m! %s\033[0m\n' "$*"; }
FAIL() { printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || FAIL "must run as root"

# --- 1. apt deps --------------------------------------------------------
LOG "Installing apt packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
  curl ca-certificates gnupg git \
  build-essential python3 python3-pip python3-venv \
  sqlite3 tmux jq rsync less vim

# --- 2. Git identity (needed for new-project's initial commit) ----------
if ! git config --global user.email >/dev/null 2>&1; then
  LOG "Setting placeholder git identity (override later with git config --global ...)"
  git config --global user.email "root@$(hostname)"
  git config --global user.name "root"
fi

# --- 3. Node 20 (NodeSource) -------------------------------------------
if ! command -v node >/dev/null || [ "$(node -v | cut -dv -f2 | cut -d. -f1)" -lt 20 ]; then
  LOG "Installing Node.js 20 from NodeSource"
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y -qq nodejs
else
  LOG "Node $(node -v) already present"
fi

# --- 4. Claude Code -----------------------------------------------------
if ! command -v claude >/dev/null; then
  LOG "Installing @anthropic-ai/claude-code globally"
  npm install -g @anthropic-ai/claude-code
else
  LOG "claude already installed at $(command -v claude)"
fi

# --- 5. Fetch + extract /opt/tools -------------------------------------
if [ ! -d /opt/tools ]; then
  LOG "Fetching and installing /opt/tools"
  mkdir -p /opt
  curl -fsSL "$REPO_RAW/tools.tar.gz" | tar -xzf - -C /opt
else
  WARN "/opt/tools already exists — leaving it alone"
fi

# --- 6. Install picker helpers -----------------------------------------
LOG "Installing claude-pick and claude-new"
curl -fsSL "$REPO_RAW/helpers/claude-pick" -o /usr/local/bin/claude-pick
curl -fsSL "$REPO_RAW/helpers/claude-new"  -o /usr/local/bin/claude-new
chmod +x /usr/local/bin/claude-pick /usr/local/bin/claude-new

# --- 7. Bashrc alias ---------------------------------------------------
if ! grep -q "claude-pick" /root/.bashrc 2>/dev/null; then
  LOG "Adding claude alias to /root/.bashrc"
  cat >> /root/.bashrc <<'EOF'

# Project picker for Claude Code — type `claude` from anywhere outside /opt/projects/
# to get a numbered menu. Bypass with `command claude` or full path.
alias claude='/usr/local/bin/claude-pick'
EOF
else
  LOG "claude alias already in /root/.bashrc"
fi

# --- 8. Scaffold the jeff project --------------------------------------
if [ ! -d /opt/projects/jeff ]; then
  LOG "Scaffolding /opt/projects/jeff via new-project"
  /opt/tools/bin/new-project jeff
else
  LOG "/opt/projects/jeff already exists"
fi

# --- 9. Install skills via skilladd ------------------------------------
LOG "Installing skills (obra/superpowers + vercel-labs find-skills)"
npx --yes skilladd add obra/superpowers   -g --agent claude-code --skill '*'         -y || \
  WARN "skilladd obra/superpowers failed — re-run manually"
npx --yes skilladd add vercel-labs/skills -g --agent claude-code --skill find-skills -y || \
  WARN "skilladd find-skills failed — re-run manually"

# --- 10. Done ----------------------------------------------------------
cat <<'EOF'

────────────────────────────────────────────────────────
✓ Bootstrap complete.

Next:
  source ~/.bashrc        # pick up the `claude` alias
  claude                  # first run will prompt for login

The picker will show:
   1) jeff
   2) make new …
   0) skip

To use your real git identity:
  git config --global user.email "you@example.com"
  git config --global user.name  "Your Name"
────────────────────────────────────────────────────────
EOF
