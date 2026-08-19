#!/bin/bash
# install.sh — Install claude-code-orchestra into ~/.claude/
#
# Copies scripts, agent definitions, and memory files to the user's
# Claude Code config directory. Updates ~/.claude/settings.json with
# the required Bash permissions. Does not overwrite existing files
# without confirmation.

set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
AGENTS_DIR="$CLAUDE_DIR/agents"
SKILLS_DIR="$CLAUDE_DIR/skills"
MEMORY_DIR=""  # detected below
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

BOLD=$(tput bold 2>/dev/null || echo "")
RESET=$(tput sgr0 2>/dev/null || echo "")
GREEN=$(tput setaf 2 2>/dev/null || echo "")
YELLOW=$(tput setaf 3 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")

info()    { echo "${BOLD}==>${RESET} $*"; }
success() { echo "${GREEN}✓${RESET} $*"; }
warn()    { echo "${YELLOW}!${RESET} $*"; }
error()   { echo "${RED}✗${RESET} $*" >&2; }

# ── Preflight ─────────────────────────────────────────────────────────
info "claude-code-orchestra installer"
echo ""

if [ ! -d "$CLAUDE_DIR" ]; then
  error "~/.claude not found. Install Claude Code first: https://claude.com/claude-code"
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  error "claude CLI not found in PATH. Install Claude Code first."
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  warn "codex CLI not found. Install with:"
  echo "  brew install --cask codex"
  echo "  # or"
  echo "  npm install -g @openai/codex"
  echo ""
  read -p "Continue without codex? (y/N) " -n 1 -r
  echo ""
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    error "Aborted."
    exit 1
  fi
fi

if ! command -v jq >/dev/null 2>&1; then
  error "jq is required for settings.json merging. Install with: brew install jq"
  exit 1
fi

# ── Detect memory directory ──────────────────────────────────────────
# Memory lives at ~/.claude/projects/<encoded-home>/memory/
# The encoded home is the home path with slashes replaced by dashes.
ENCODED_HOME=$(echo "$HOME" | sed 's|/|-|g')
MEMORY_DIR="$CLAUDE_DIR/projects/${ENCODED_HOME}/memory"

if [ ! -d "$MEMORY_DIR" ]; then
  info "Creating memory directory at $MEMORY_DIR"
  mkdir -p "$MEMORY_DIR"
fi

# ── Install scripts ───────────────────────────────────────────────────
info "Installing scripts to $SCRIPTS_DIR"
mkdir -p "$SCRIPTS_DIR"

for script in "$REPO_DIR"/scripts/*; do
  [ -f "$script" ] || continue   # skips scripts/archive/ — retired, not installed
  name=$(basename "$script")
  target="$SCRIPTS_DIR/$name"

  # agents.env is config the user is expected to edit — seed it, never clobber it
  if [ "$name" = "agents.env" ]; then
    if [ -f "$target" ]; then
      if cmp -s "$script" "$target"; then
        info "Kept existing $name"
      else
        warn "Kept your $name — upstream defaults changed, diff against $script"
      fi
    else
      cp "$script" "$target"
      success "Installed $name"
    fi
    continue
  fi

  if [ -f "$target" ] && ! cmp -s "$script" "$target"; then
    warn "$name already exists and differs. Overwrite? (y/N)"
    read -r -n 1 reply
    echo ""
    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
      warn "Skipped $name"
      continue
    fi
  fi
  cp "$script" "$target"
  chmod +x "$target"
  success "Installed $name"
done

# ── Install agent definitions ─────────────────────────────────────────
info "Installing agent definitions to $AGENTS_DIR"
mkdir -p "$AGENTS_DIR"

for agent in "$REPO_DIR"/agents/*.md; do
  name=$(basename "$agent")
  target="$AGENTS_DIR/$name"
  if [ -f "$target" ] && ! cmp -s "$agent" "$target"; then
    warn "$name already exists and differs. Overwrite? (y/N)"
    read -r -n 1 reply
    echo ""
    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
      warn "Skipped $name"
      continue
    fi
  fi
  cp "$agent" "$target"
  success "Installed agent: $name"
done

# ── Install skills ────────────────────────────────────────────────────
info "Installing skills to $SKILLS_DIR"
mkdir -p "$SKILLS_DIR"

for skill_dir in "$REPO_DIR"/skills/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename "$skill_dir")
  target="$SKILLS_DIR/$skill_name"

  if [ -d "$target" ]; then
    # Compare SKILL.md if both exist
    if [ -f "$target/SKILL.md" ] && [ -f "$skill_dir/SKILL.md" ] && ! cmp -s "$skill_dir/SKILL.md" "$target/SKILL.md"; then
      warn "Skill $skill_name already exists and differs. Overwrite? (y/N)"
      read -r -n 1 reply
      echo ""
      if [[ ! "$reply" =~ ^[Yy]$ ]]; then
        warn "Skipped skill: $skill_name"
        continue
      fi
    fi
  fi

  mkdir -p "$target"
  cp -R "$skill_dir"/* "$target"/
  success "Installed skill: $skill_name"
done

# ── Install memory files ──────────────────────────────────────────────
info "Installing memory (behavioral rules) to $MEMORY_DIR"

MEMORY_INDEX="$MEMORY_DIR/MEMORY.md"
EXISTING_INDEX_LINES=""
if [ -f "$MEMORY_INDEX" ]; then
  EXISTING_INDEX_LINES=$(cat "$MEMORY_INDEX")
fi

for mem in "$REPO_DIR"/memory/*.md; do
  name=$(basename "$mem")
  if [ "$name" = "MEMORY.md" ]; then continue; fi

  target="$MEMORY_DIR/$name"
  if [ -f "$target" ] && ! cmp -s "$mem" "$target"; then
    warn "$name already exists and differs. Overwrite? (y/N)"
    read -r -n 1 reply
    echo ""
    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
      warn "Skipped $name"
      continue
    fi
  fi
  cp "$mem" "$target"
  success "Installed memory: $name"
done

# Merge MEMORY.md index
info "Merging MEMORY.md index"
TMP_INDEX=$(mktemp)
{
  if [ -n "$EXISTING_INDEX_LINES" ]; then
    echo "$EXISTING_INDEX_LINES"
  fi
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if ! echo "$EXISTING_INDEX_LINES" | grep -qF "$line"; then
      echo "$line"
    fi
  done < "$REPO_DIR/memory/MEMORY.md"
} > "$TMP_INDEX"
mv "$TMP_INDEX" "$MEMORY_INDEX"
success "Updated MEMORY.md"

# ── Update settings.json ──────────────────────────────────────────────
info "Updating $SETTINGS_FILE"

REQUIRED_PERMS=(
  "Bash(codex exec *)"
  "Bash(~/.claude/scripts/parallel-review*)"
  "Bash(~/.claude/scripts/full-audit*)"
)

if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{"permissions":{"allow":[]}}' > "$SETTINGS_FILE"
fi

for perm in "${REQUIRED_PERMS[@]}"; do
  if jq -e --arg p "$perm" '.permissions.allow | index($p)' "$SETTINGS_FILE" >/dev/null 2>&1; then
    continue
  fi
  TMP=$(mktemp)
  jq --arg p "$perm" '.permissions.allow = ((.permissions.allow // []) + [$p])' "$SETTINGS_FILE" > "$TMP"
  mv "$TMP" "$SETTINGS_FILE"
  success "Added permission: $perm"
done

# ── Install Codex plugin (if not already) ────────────────────────────
info "Checking Codex plugin"
if claude plugin list 2>/dev/null | grep -q "codex@openai-codex"; then
  success "Codex plugin already installed"
else
  warn "Codex plugin not installed. Install now? (Y/n)"
  read -r -n 1 reply
  echo ""
  if [[ ! "$reply" =~ ^[Nn]$ ]]; then
    claude plugin marketplace add openai/codex-plugin-cc && \
      claude plugin install codex@openai-codex --scope user && \
      success "Codex plugin installed" || \
      warn "Codex plugin install failed — run manually: claude plugin marketplace add openai/codex-plugin-cc && claude plugin install codex@openai-codex --scope user"
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────
echo ""
success "Installation complete."
echo ""
echo "Next steps:"
echo "  1. Restart any running Claude Code sessions to pick up the new plugin and permissions"
echo "  2. Run ${BOLD}claude${RESET} in any git repo to start using the setup"
echo "  3. The Codex review gate can be enabled per-repo with: ${BOLD}/codex:setup --enable-review-gate${RESET}"
echo ""
echo "Scripts installed:"
ls -1 "$SCRIPTS_DIR" | sed 's/^/  /'
echo ""
echo "Agents installed:"
ls -1 "$AGENTS_DIR" | sed 's/^/  /'
echo ""
echo "Skills installed:"
ls -1 "$SKILLS_DIR" | sed 's/^/  /'
echo ""
