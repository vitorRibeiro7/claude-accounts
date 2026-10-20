#!/usr/bin/env bash
# Install claude-accounts on YOUR machine. It ships no accounts: you name the account you
# already use and create the others later with `ca new NAME`.
#
#   ./install.sh                     install (safe to run again)
#   ./install.sh --name personal     name the current account without asking
#   ./install.sh --lang pt-BR        Portuguese messages (default: English)
#   ./install.sh --uninstall         remove PATH/alias; keeps your accounts and logins
#
#   curl -fsSL https://raw.githubusercontent.com/vitorRibeiro7/claude-accounts/main/install.sh | bash
set -euo pipefail

REPO="${CLAUDE_ACCOUNTS_REPO:-https://github.com/vitorRibeiro7/claude-accounts}"
DEST="${CLAUDE_ACCOUNTS_BIN:-$HOME/.local/share/claude-accounts/bin}"
CFG="${CLAUDE_ACCOUNTS_DIR:-$HOME/.config/claude-accounts}"
LEGACY_CFG="$HOME/.config/claude-contas"           # earlier Portuguese-only version
START="# >>> claude-accounts >>>"
END="# <<< claude-accounts <<<"
LEGACY_START="# >>> claude-contas >>>"
LEGACY_END="# <<< claude-contas <<<"
NAME_RE='^[a-z0-9][a-z0-9_-]*$'

name="" lang="" mode="install"
while [ $# -gt 0 ]; do
  case "$1" in
    --uninstall) mode="uninstall" ;;
    --name) name="${2:-}"; shift ;;
    --lang) lang="${2:-}"; shift ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

# Remove the block between two marker lines, keeping the file itself (works on symlinked rc files).
strip_block() {
  [ -f "$1" ] && grep -qxF "$2" "$1" || return 1
  awk -v s="$2" -v e="$3" '$0 == s { skip = 1; next } skip && $0 == e { skip = 0; next } !skip' "$1" > "$1.tmp"
  cat "$1.tmp" > "$1"; rm -f "$1.tmp"
}

# Shell startup files to configure: the ones that exist, plus the right one for the login shell.
rc_files() {
  local f shell_name; shell_name="$(basename "${SHELL:-bash}")"
  for f in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do [ -f "$f" ] && echo "$f"; done
  case "$shell_name" in
    zsh) [ -f "$HOME/.zshrc" ] || echo "$HOME/.zshrc" ;;
    bash)
      if [ "$(uname -s)" = Darwin ]; then [ -f "$HOME/.bash_profile" ] || echo "$HOME/.bash_profile"
      else [ -f "$HOME/.bashrc" ] || echo "$HOME/.bashrc"; fi ;;
  esac
}

ask() { # prompt default → answer (reads the terminal even when piped through curl | bash)
  local a=""
  if [ -t 0 ]; then read -r -p "$1" a
  elif (: < /dev/tty) 2>/dev/null; then read -r -p "$1" a < /dev/tty
  fi
  echo "${a:-$2}"
}

if [ "$mode" = uninstall ]; then
  while IFS= read -r rc; do strip_block "$rc" "$START" "$END" && echo "cleaned $rc"; done < <(rc_files)
  rm -rf "$DEST"
  echo "Done. Your accounts in $CFG and the ~/.claude-* folders were kept."
  exit 0
fi

# 1. source files: this checkout, or a fresh download when run through curl | bash
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)" || HERE="$(pwd)"
if [ ! -f "$HERE/bin/claude-accounts" ]; then
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  echo "downloading $REPO …"
  curl -fsSL "$REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$tmp" --strip-components=1
  HERE="$tmp"
fi

# 2. the real claude (the first one in PATH that is not our wrapper)
real=""
IFS=: read -ra dirs <<< "$PATH"
is_wrapper() { head -c 600 "$1" 2>/dev/null | grep -aqE 'CLAUDE_ACCOUNTS_DIR|CLAUDE_CONTAS_DIR'; }
for d in "${dirs[@]}"; do
  [ "$d" = "$DEST" ] && continue
  [ -x "$d/claude" ] && ! is_wrapper "$d/claude" && { real="$d/claude"; break; }
done
[ -n "$real" ] || { echo "Could not find 'claude' in PATH. Install Claude Code first: https://docs.claude.com/en/docs/claude-code" >&2; exit 1; }
echo "real claude: $real"

# 3. scripts
mkdir -p "$DEST" "$CFG"
cp "$HERE"/bin/* "$DEST"/ && chmod +x "$DEST"/*
printf 'CLAUDE_REAL=%q\n' "$real" > "$CFG/config"
touch "$CFG/accounts"

# 4. coming from claude-contas (the Portuguese-only predecessor)? Bring its accounts along.
if [ -s "$LEGACY_CFG/contas" ] && ! grep -q '^[^#=][^=]*=' "$CFG/accounts"; then
  cp "$LEGACY_CFG/contas" "$CFG/accounts"
  [ -f "$LEGACY_CFG/ativa" ] && cp "$LEGACY_CFG/ativa" "$CFG/active"
  [ -f "$LEGACY_CFG/base" ] && cp "$LEGACY_CFG/base" "$CFG/base"
  [ -n "$lang" ] || lang="pt-BR"
  echo "migrated accounts from $LEGACY_CFG (left untouched)"
fi

# 5. the account the user already has becomes the "default" one (~/.claude), with THEIR name
if ! grep -q '^[^#=][^=]*=' "$CFG/accounts"; then
  if [ -z "$name" ]; then
    echo
    echo "What do you want to call the account you ALREADY use in Claude Code? (e.g. personal, work)"
    name="$(ask "Name [main]: " main)"
  fi
  [[ "$name" =~ $NAME_RE ]] || { echo "Invalid name: use lowercase letters, digits, - or _." >&2; exit 1; }
  echo "$name=~/.claude" >> "$CFG/accounts"
  echo "$name" > "$CFG/active"
fi

# 6. language (English unless asked otherwise)
if [ -z "$lang" ] && [ ! -f "$CFG/lang" ]; then
  case "${LC_ALL:-${LANG:-}}" in pt*) lang="$(ask "Mensagens em português? / Portuguese messages? [Y/n] " y)"
    case "$lang" in n|N|no|nao|não) lang="en" ;; *) lang="pt-BR" ;; esac ;; esac
fi
[ -n "$lang" ] && "$DEST/claude-accounts" lang "$lang" >/dev/null

# 7. PATH + alias in the shell startup files (marked block, with a backup)
block="$START
export PATH=\"$DEST:\$PATH\"
alias ca='claude-accounts'
$END"
while IFS= read -r rc; do
  if [ -f "$rc" ] && grep -qxF "$START" "$rc" && ! grep -qxF "$LEGACY_START" "$rc"; then
    echo "already configured: $rc"; continue
  fi
  [ -f "$rc" ] && cp "$rc" "$rc.bak-claude-accounts"
  strip_block "$rc" "$LEGACY_START" "$LEGACY_END" && echo "removed the old claude-contas block from $rc"
  grep -qxF "$START" "$rc" 2>/dev/null || printf '\n%s\n' "$block" >> "$rc"
  echo "configured $rc (backup: $rc.bak-claude-accounts)"
done < <(rc_files)

existing="$(command -v ca 2>/dev/null || true)"
[ -n "$existing" ] && echo "note: a 'ca' command already exists ($existing); the alias takes precedence in new terminals."

echo
echo "Done. Open a new terminal (or: source ~/.zshrc) and run:  ca list"
echo "Add another account:  ca new NAME     (guide: docs/adding-an-account.md)"
