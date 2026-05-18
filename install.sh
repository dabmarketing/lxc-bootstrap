#!/usr/bin/env bash
# install.sh — bootstrap a fresh Debian 12 LXC into Ben's dev sandbox setup.
#
# Usage (one-liner from a fresh root shell):
#
#   curl -fsSL https://raw.githubusercontent.com/dabmarketing/lxc-bootstrap/main/install.sh \
#     | bash -s -- /mnt/usb/lxc-bootstrap-usb
#
# Or download and run:
#
#   curl -fsSL https://raw.githubusercontent.com/dabmarketing/lxc-bootstrap/main/install.sh -o /tmp/install.sh
#   bash /tmp/install.sh /mnt/usb/lxc-bootstrap-usb
#
# The bundle path must contain: tools.tar.gz, projects-local.tar.gz, memory.tar.gz.
# Defaults to /mnt/usb/lxc-bootstrap-usb if no arg is given.

set -euo pipefail

BUNDLE_DIR="${1:-/mnt/usb/lxc-bootstrap-usb}"
REPO_RAW="https://raw.githubusercontent.com/dabmarketing/lxc-bootstrap/main"

LOG()  { printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
WARN() { printf '\033[1;33m! %s\033[0m\n' "$*"; }
FAIL() { printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || FAIL "must run as root"

# --- 0. Validate bundle -------------------------------------------------
LOG "Looking for bundle at $BUNDLE_DIR"
for f in tools.tar.gz projects-local.tar.gz memory.tar.gz; do
  [ -f "$BUNDLE_DIR/$f" ] || FAIL "missing $BUNDLE_DIR/$f — mount your USB and pass its path"
done

# --- 1. apt deps --------------------------------------------------------
LOG "Installing apt packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
  curl ca-certificates gnupg git \
  build-essential python3 python3-pip python3-venv \
  sqlite3 tmux jq rsync less vim

# --- 2. Node 20 (NodeSource) -------------------------------------------
if ! command -v node >/dev/null || [ "$(node -v | cut -dv -f2 | cut -d. -f1)" -lt 20 ]; then
  LOG "Installing Node.js 20 from NodeSource"
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y -qq nodejs
else
  LOG "Node $(node -v) already present"
fi

# --- 3. Claude Code -----------------------------------------------------
if ! command -v claude >/dev/null; then
  LOG "Installing @anthropic-ai/claude-code globally"
  npm install -g @anthropic-ai/claude-code
else
  LOG "claude already installed at $(command -v claude)"
fi

# --- 4. Restore /opt/tools ---------------------------------------------
if [ ! -d /opt/tools ]; then
  LOG "Restoring /opt/tools"
  mkdir -p /opt
  tar -xzf "$BUNDLE_DIR/tools.tar.gz" -C /opt
else
  WARN "/opt/tools already exists — leaving it alone"
fi

# --- 5. Install picker helpers -----------------------------------------
LOG "Installing claude-pick and claude-new"
# When run via curl|bash, helpers/ isn't local — fetch from the repo.
if [ -d "$(dirname "$0")/helpers" ] && [ -f "$(dirname "$0")/helpers/claude-pick" ]; then
  SRC="$(dirname "$0")/helpers"
  install -m 0755 "$SRC/claude-pick" /usr/local/bin/claude-pick
  install -m 0755 "$SRC/claude-new"  /usr/local/bin/claude-new
else
  curl -fsSL "$REPO_RAW/helpers/claude-pick" -o /usr/local/bin/claude-pick
  curl -fsSL "$REPO_RAW/helpers/claude-new"  -o /usr/local/bin/claude-new
  chmod +x /usr/local/bin/claude-pick /usr/local/bin/claude-new
fi

# --- 6. Bashrc alias ---------------------------------------------------
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

# --- 7. Restore projects ------------------------------------------------
LOG "Restoring projects to /opt/projects"
mkdir -p /opt/projects
tar -xzf "$BUNDLE_DIR/projects-local.tar.gz" -C /opt/projects --skip-old-files

# --- 8. Restore Claude memory dirs -------------------------------------
LOG "Restoring auto-memory directories"
mkdir -p /root/.claude/projects
tmpdir=$(mktemp -d)
tar -xzf "$BUNDLE_DIR/memory.tar.gz" -C "$tmpdir"
for parent in "$tmpdir"/memory-stage/*; do
  [ -d "$parent" ] || continue
  name=$(basename "$parent")
  mkdir -p "/root/.claude/projects/$name"
  cp -rn "$parent/memory" "/root/.claude/projects/$name/" 2>/dev/null || true
done
rm -rf "$tmpdir"

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

Notes:
  • settings.local.json is per-machine; permissions re-prompt fresh.
  • Add more projects later with: claude-new <name>
────────────────────────────────────────────────────────
EOF
