# lxc-bootstrap

One-command setup for a fresh Debian 12 LXC: Claude Code, the `/opt/projects`
picker, `/opt/tools`, skills, and a fresh `jeff` project scaffold.

Everything is fetched from this repo — no flash drive, no extra files.

## Quick start

On the new LXC, as root:

```bash
curl -fsSL https://raw.githubusercontent.com/dabmarketing/lxc-bootstrap/main/install.sh | bash
```

Then:
```bash
source ~/.bashrc
claude        # first run prompts for login
```

The picker will show:
```
   1) jeff ✓ has CLAUDE.md
   2) make new …
   0) skip — launch claude in current dir
```

## What the script does

1. apt: curl, git, build tools, python3, sqlite3, tmux, jq, rsync, vim
2. Sets a placeholder git identity if none exists (override later)
3. Node 20 from NodeSource (skipped if already ≥ 20)
4. `npm i -g @anthropic-ai/claude-code`
5. Fetches and extracts `/opt/tools` (new-project, promote-to-briefs, templates)
6. Installs `claude-pick` + `claude-new` to `/usr/local/bin/`
7. Adds the `alias claude='/usr/local/bin/claude-pick'` line to `/root/.bashrc`
8. Scaffolds a fresh `/opt/projects/jeff` via `new-project jeff`
9. Installs skills: `obra/superpowers` (all) + `vercel-labs/skills` (find-skills)

## Files in this repo

```
install.sh            # the bootstrap script
tools.tar.gz          # /opt/tools — new-project, promote-to-briefs, templates
helpers/claude-pick   # the `claude` alias target — shows project picker
helpers/claude-new    # scaffold a new /opt/projects/<name>
```

## What is NOT set up

- Claude session history, file-history, auto-memory — start fresh
- Per-machine permission allowlist (`settings.local.json`) — re-prompts as you go
- Your real git identity — placeholder is set; override with:
  ```
  git config --global user.email "you@example.com"
  git config --global user.name  "Your Name"
  ```
