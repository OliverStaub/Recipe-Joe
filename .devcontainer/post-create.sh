#!/usr/bin/env bash
# Runs once after the dev container is built. Idempotent — safe to re-run.
set -euo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_DIR/skills"
SVELTE_SKILLS_DIR="$SKILLS_DIR/svelte"

mkdir -p "$SKILLS_DIR"

# 1. Svelte / SvelteKit Claude skills (spences10/svelte-claude-skills).
# Cloned to ~/.claude/skills/svelte so each subdirectory becomes a discoverable skill.
if [ ! -d "$SVELTE_SKILLS_DIR/.git" ]; then
    echo "Installing Svelte Claude skills..."
    git clone --depth=1 https://github.com/spences10/svelte-claude-skills.git "$SVELTE_SKILLS_DIR"
else
    echo "Svelte Claude skills already present — pulling latest..."
    git -C "$SVELTE_SKILLS_DIR" pull --ff-only || true
fi

# Symlink each individual skill from the cloned repo's .claude/skills/* into ~/.claude/skills
# so Claude Code discovers them as top-level skills (not nested under svelte/).
if [ -d "$SVELTE_SKILLS_DIR/.claude/skills" ]; then
    for skill_path in "$SVELTE_SKILLS_DIR"/.claude/skills/*/; do
        skill_name=$(basename "$skill_path")
        target="$SKILLS_DIR/$skill_name"
        if [ ! -e "$target" ]; then
            ln -s "$skill_path" "$target"
            echo "Linked skill: $skill_name"
        fi
    done
fi

# 2. Claude Code plugins.
# These require the official marketplace to be registered. We attempt to install
# each one and continue on failure (e.g. if the user is not yet authenticated).
PLUGINS=(
    "frontend-design@claude-plugins-official"
    "code-simplifier@claude-plugins-official"
    "feature-dev@claude-plugins-official"
    "claude-code-setup@claude-plugins-official"
    "supabase@claude-plugins-official"
    "vercel@claude-plugins-official"
    "claude-md-management@claude-plugins-official"
    "code-simplifier@claude-plugins-official"
)

if command -v claude >/dev/null 2>&1; then
    for plugin in "${PLUGINS[@]}"; do
        echo "Installing Claude plugin: $plugin"
        claude plugin install "$plugin" || echo "  (skipped — may need 'claude login' or marketplace add first)"
    done
else
    echo "claude CLI not found — skipping plugin install"
fi

# 3. Wire up project-level git hooks (formatting on commit).
if [ -d .githooks ]; then
    git config core.hooksPath .githooks
    chmod +x .githooks/* 2>/dev/null || true
    echo "Configured git core.hooksPath -> .githooks"
fi

# 4. Ensure pnpm store and node_modules are owned by `node`, then install deps.
# The named volumes start root-owned on first mount.
sudo chown -R node:node /home/node/.cache/pnpm-store /workspace/node_modules 2>/dev/null || true
pnpm config set store-dir /home/node/.cache/pnpm-store
if [ -f package.json ]; then
    echo "Installing project dependencies (pnpm install)..."
    pnpm install --frozen-lockfile 2>/dev/null || pnpm install
fi

echo "post-create.sh complete."
