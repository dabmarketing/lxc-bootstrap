# lxc-bootstrap

One-command setup for a fresh Debian 12 LXC: Claude Code, the `/opt/projects` picker,
`/opt/tools`, skills, auto-memory, and the local project tree.

## Quick start

On the new LXC, as root:

```bash
# 1. Mount the flash drive with the data tarballs (tools.tar.gz, projects-local.tar.gz, memory.tar.gz)
mkdir -p /mnt/usb && mount /dev/sdX1 /mnt/usb

# 2. Run the one-liner
curl -fsSL https://raw.githubusercontent.com/dabmarketing/lxc-bootstrap/main/install.sh \
  | bash -s -- /mnt/usb/lxc-bootstrap-usb

# 3. Log in
source ~/.bashrc
claude        # first run prompts for login
```

## What's in this repo (public)

```
install.sh            # the bootstrap script
helpers/claude-pick   # the `claude` alias target — shows project picker
helpers/claude-new    # scaffold a new /opt/projects/<name>
README.md
```

## What lives on the USB (private — never push here)

```
lxc-bootstrap-usb/
├── tools.tar.gz          # /opt/tools (new-project, promote-to-briefs, templates)
├── projects-local.tar.gz # jeff (the only project bundled)
└── memory.tar.gz         # ~/.claude/projects/*/memory/ — auto-memory
```

These contain personal/business context (trading thresholds, family names, health data)
and must not be committed.

## What the script does

1. apt: curl, git, build tools, python3, sqlite3, tmux, jq, rsync, vim
2. Node 20 from NodeSource (skipped if already ≥ 20)
3. `npm i -g @anthropic-ai/claude-code`
4. Extracts `/opt/tools` from `tools.tar.gz`
5. Installs `claude-pick` + `claude-new` to `/usr/local/bin/` (from local helpers/ if present, else fetched from this repo)
6. Adds `alias claude='/usr/local/bin/claude-pick'` to `/root/.bashrc`
7. Extracts the `jeff` project to `/opt/projects/`
8. Restores `~/.claude/projects/*/memory/` from `memory.tar.gz`
9. Installs skills: `obra/superpowers` (all) + `vercel-labs/skills` (find-skills)

## What is NOT restored

- `settings.local.json` — per-machine permission allowlist; re-prompts fresh
- Claude session history, file-history — intentional clean slate
- Any project other than `jeff` (add new ones with `claude-new <name>`)

## Refreshing the USB bundle

From the source LXC:

```bash
cd /root/lxc-bootstrap-usb
tar -czf tools.tar.gz -C /opt tools
tar -czf projects-local.tar.gz -C /opt/projects jeff
# memory tarball: stage ~/.claude/projects/*/memory dirs under memory-stage/ then tar -czf
```

Then copy `lxc-bootstrap-usb/` back onto the flash drive.
