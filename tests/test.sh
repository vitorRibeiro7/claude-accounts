#!/usr/bin/env bash
# Tests claude-accounts WITHOUT opening Claude or touching your accounts: runs in a fake HOME.
#   ./tests/test.sh
# shellcheck disable=SC2015,SC2016,SC2088  # A && ok || bad is intended; literal ~ and $ are expected output
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"; [ -n "${SLEEPER:-}" ] && kill "$SLEEPER" 2>/dev/null' EXIT
export HOME="$T/home" CLAUDE_ACCOUNTS_DIR="$T/cfg" CLAUDE_ACCOUNTS_PROC_NAME="claude-ghost-$$"
unset CLAUDE_CONFIG_DIR CLAUDE_ACCOUNTS_LANG CLAUDE_ACCOUNTS_BIN
mkdir -p "$HOME" "$CLAUDE_ACCOUNTS_DIR"
CA="$ROOT/bin/claude-accounts"
failures=0
ok()  { echo "  ok   $1"; }
bad() { echo "  FAIL $1"; failures=$((failures+1)); }
expect() { # description, expected, actual
  [ "$2" = "$3" ] && ok "$1" || bad "$1 (expected '$2', got '$3')"
}
refuses() { # description, command...
  local d="$1"; shift; "$@" >/dev/null 2>&1 && bad "$d (should refuse)" || ok "$d"
}
yes_if() { "$@" && echo yes; }
enc() { printf '%s\n' "${1//[!abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789]/-}"; }   # Claude's projects/ folder for a path

echo "default account"
echo "personal=~/.claude" > "$CLAUDE_ACCOUNTS_DIR/accounts"; echo personal > "$CLAUDE_ACCOUNTS_DIR/active"
expect "_dir of the default account is empty" "" "$("$CA" _dir)"
mkdir -p "$HOME/.claude"
printf '{\n  "numStartups": 3,\n  "oauthAccount": {\n    "accountUuid": "x",\n    "emailAddress": "me@example.com"\n  }\n}\n' > "$HOME/.claude.json"
expect "default email comes from ~/.claude.json" "me@example.com" "$("$CA" list | awk '{print $NF}')"
expect "list shows ~ paths" "~/.claude" "$("$CA" list | awk '{print $3}')"

echo "new"
"$CA" new work >/dev/null
expect "new creates the folder" "yes" "$(yes_if [ -d "$HOME/.claude-work" ])"
expect "new account is not logged in" "1" "$("$CA" list | grep -c ' work .*(not logged in)$')"
refuses "duplicate name" "$CA" new work
refuses "invalid name" "$CA" new "Bad Name"
refuses "reserved name" "$CA" new list
refuses "reserved alias ls" "$CA" new ls
refuses "reserved alias rm" "$CA" new rm
mkdir -p "$HOME/.claude-work/plugins"; echo x > "$HOME/.claude-work/settings.json"
"$CA" new client --share work >/dev/null
expect "--share creates a link" "yes" "$(yes_if [ -L "$HOME/.claude-client/settings.json" ])"
refuses "--share with a missing account" "$CA" new other --share ghost
refuses "unknown option" "$CA" new other --nope

echo "share (existing account)"
"$CA" new loose >/dev/null
mkdir -p "$HOME/.claude-loose/projects/-my-dir" "$HOME/.claude-work/projects"
echo conversation > "$HOME/.claude-loose/projects/-my-dir/a.jsonl"
"$CA" share loose work >/dev/null
expect "projects became a link" "yes" "$(yes_if [ -L "$HOME/.claude-loose/projects" ])"
expect "old conversation merged into the source" "conversation" "$(cat "$HOME/.claude-work/projects/-my-dir/a.jsonl" 2>/dev/null)"
expect "original kept, not deleted" "yes" "$(yes_if [ -d "$HOME/.claude-loose/projects.before-share" ])"
expect "conversation visible through the link" "conversation" "$(cat "$HOME/.claude-loose/projects/-my-dir/a.jsonl" 2>/dev/null)"
"$CA" share loose work >/dev/null
expect "running it twice is safe" "yes" "$(yes_if [ -L "$HOME/.claude-loose/projects" ])"
refuses "share with itself" "$CA" share loose loose
refuses "share a missing account" "$CA" share loose ghost
"$CA" remove loose >/dev/null

echo "share creates what the source lacks (so later items are shared too)"
"$CA" new bare --clean >/dev/null
"$CA" new kid --share bare >/dev/null
expect "every item is linked although the source was empty" "6" \
  "$(for i in projects settings.json plugins skills file-history history.jsonl; do [ -L "$HOME/.claude-kid/$i" ] && echo y; done | grep -c y)"
expect "the source got a valid empty settings.json" "{}" "$(cat "$HOME/.claude-bare/settings.json")"
expect "...and an empty history.jsonl" "yes" "$(yes_if [ -f "$HOME/.claude-bare/history.jsonl" ] && [ ! -s "$HOME/.claude-bare/history.jsonl" ])"
touch "$HOME/.claude-bare/skills/later.md"
expect "something the source gains later shows up in the linked account" "yes" "$(yes_if [ -e "$HOME/.claude-kid/skills/later.md" ])"
"$CA" new owner --clean >/dev/null; echo mine > "$HOME/.claude-owner/settings.json"
mkdir -p "$HOME/.claude-owner/skills"; echo s > "$HOME/.claude-owner/skills/x.md"
"$CA" new blank --clean >/dev/null
"$CA" share owner blank >/dev/null
expect "an account's own file seeds a source that lacks it" "mine" "$(cat "$HOME/.claude-blank/settings.json")"
expect "...and so do its folders" "s" "$(cat "$HOME/.claude-blank/skills/x.md")"
expect "the original is still kept as a backup" "mine" "$(cat "$HOME/.claude-owner/settings.json.before-share")"
for a in kid bare owner blank; do "$CA" remove "$a" >/dev/null; done

echo "base"
expect "no base set" "0" "$("$CA" base | grep -c '^base:')"
echo y | "$CA" base work >/dev/null
expect "base is saved" "work" "$(cat "$CLAUDE_ACCOUNTS_DIR/base")"
refuses "missing base" "$CA" base ghost
"$CA" new inherits >/dev/null
expect "new account is linked to the base" "yes" "$(yes_if [ -L "$HOME/.claude-inherits/settings.json" ])"
"$CA" new isolated --clean >/dev/null
expect "--clean is isolated" "" "$(yes_if [ -L "$HOME/.claude-isolated/settings.json" ])"
expect "list marks the base" "1" "$("$CA" list | grep -c '(base)')"
"$CA" personal >/dev/null
refuses "won't remove the base" "$CA" remove work
"$CA" remove inherits >/dev/null; "$CA" remove isolated >/dev/null
echo personal > "$CLAUDE_ACCOUNTS_DIR/base"

echo "switch"
"$CA" work >/dev/null
expect "switch saves the active account" "work" "$(cat "$CLAUDE_ACCOUNTS_DIR/active")"
expect "_dir of a named account" "$HOME/.claude-work" "$("$CA" _dir)"
"$CA" use personal >/dev/null
expect "ca use NAME also switches" "personal" "$(cat "$CLAUDE_ACCOUNTS_DIR/active")"
refuses "switch to a missing account" "$CA" ghost
refuses "names are literal, not regex" "$CA" 'w.*'
"$CA" work >/dev/null

echo "stale active account (hand-edited state)"
echo fantasma > "$CLAUDE_ACCOUNTS_DIR/active"
refuses "an active account missing from the list is an error, not a silent fallback" "$CA" _dir
expect "...the error names it" "1" "$("$CA" 2>&1 | grep -c "'fantasma' is not in the list")"
expect "...ca list points it out and marks no account as active" "1 0" "$("$CA" list | grep -c fantasma) $("$CA" list | grep -c '^\*')"
expect "...and ca NAME fixes it" "work" "$("$CA" work >/dev/null && cat "$CLAUDE_ACCOUNTS_DIR/active")"

echo "remove"
refuses "won't remove the active account" "$CA" remove work
"$CA" personal >/dev/null
refuses "won't delete a folder others link to" bash -c "echo y | '$CA' remove work --delete-dir"
"$CA" remove client >/dev/null
expect "remove keeps the folder" "yes" "$(yes_if [ -d "$HOME/.claude-client" ])"
echo y | "$CA" remove work --delete-dir >/dev/null
expect "--delete-dir deletes" "" "$(yes_if [ -e "$HOME/.claude-work" ])"
refuses "won't delete the default account" bash -c "echo y | '$CA' remove personal --delete-dir"

echo "move the base (real files move)"
"$CA" new alpha --clean >/dev/null; "$CA" new gamma --clean >/dev/null
mkdir -p "$HOME/.claude-alpha/projects/-d"
echo conv > "$HOME/.claude-alpha/projects/-d/x.jsonl"; echo cfg > "$HOME/.claude-alpha/settings.json"
"$CA" new beta --share alpha >/dev/null
echo alpha > "$CLAUDE_ACCOUNTS_DIR/base"
echo n | "$CA" base gamma >/dev/null 2>&1
expect "cancelling changes nothing" "yes" "$(yes_if [ -d "$HOME/.claude-alpha/projects" ] && [ ! -L "$HOME/.claude-alpha/projects" ])"
echo y | "$CA" base gamma >/dev/null
expect "real file moved to the new base" "cfg" "$(cat "$HOME/.claude-gamma/settings.json" 2>/dev/null)"
expect "it is not a link in the new base" "" "$(yes_if [ -L "$HOME/.claude-gamma/settings.json" ])"
expect "the old base now points to the new one" "$HOME/.claude-gamma/settings.json" "$(readlink "$HOME/.claude-alpha/settings.json")"
expect "accounts pointing to the old base were relinked" "$HOME/.claude-gamma/settings.json" "$(readlink "$HOME/.claude-beta/settings.json")"
expect "conversation still readable via the old base" "conv" "$(cat "$HOME/.claude-alpha/projects/-d/x.jsonl" 2>/dev/null)"
expect "conversation readable via the relinked account" "conv" "$(cat "$HOME/.claude-beta/projects/-d/x.jsonl" 2>/dev/null)"
expect "base saved" "gamma" "$(cat "$CLAUDE_ACCOUNTS_DIR/base")"
echo y | "$CA" base alpha >/dev/null
expect "moving it back works too" "cfg" "$(cat "$HOME/.claude-alpha/settings.json" 2>/dev/null)"

echo "sessions (portable registry, no /proc needed)"
sleep 60 & SLEEPER=$!
mkdir -p "$CLAUDE_ACCOUNTS_DIR/sessions"
printf '%s\n%s\n%s\n' "$HOME/.claude-beta" "$HOME/proj" "$(ps -o lstart= -p "$SLEEPER")" > "$CLAUDE_ACCOUNTS_DIR/sessions/$SLEEPER"
expect "sessions lists the registered session" "1" "$("$CA" sessions | grep -c "PID $SLEEPER")"
expect "sessions shows its account and folder" "yes" "$("$CA" sessions | grep -q '.claude-beta *~/proj' && echo yes)"
refuses "won't switch with an open session" "$CA" gamma
refuses "won't share an account with an open session" "$CA" share beta gamma
echo n | "$CA" stop >/dev/null 2>&1
expect "stop asks before killing" "yes" "$(yes_if kill -0 "$SLEEPER" 2>/dev/null)"
echo y | "$CA" stop >/dev/null
expect "stop terminates it" "" "$(yes_if kill -0 "$SLEEPER" 2>/dev/null)"
wait "$SLEEPER" 2>/dev/null; SLEEPER=""
printf '%s\n%s\n%s\n' "$HOME/.claude-beta" "$HOME" "Thu Jan  1 00:00:00 1970" > "$CLAUDE_ACCOUNTS_DIR/sessions/1"
"$CA" gamma >/dev/null
expect "a stale entry (PID reused) does not block and is cleaned" "no" "$([ -e "$CLAUDE_ACCOUNTS_DIR/sessions/1" ] && echo yes || echo no)"
"$CA" alpha >/dev/null

echo "wrapper"
fake="$T/fakebin"; mkdir -p "$fake"
cat > "$fake/claude" <<'FAKE'
#!/usr/bin/env bash
# FAKE_FAIL_CONTINUE: refuse --continue like Claude Code does when the last conversation is a background session
if [ "${1:-}" = --continue ] && [ -n "${FAKE_FAIL_CONTINUE:-}" ]; then echo "moved to a background session" >&2; exit 1; fi
# `claude agents --json`: each fake account lists the background sessions in its fake-agents.json
if [ "${1:-}" = agents ]; then cat "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/fake-agents.json" 2>/dev/null || echo '[]'; exit 0; fi
echo "dir=${CLAUDE_CONFIG_DIR:-unset} args=$*"
FAKE
chmod +x "$fake/claude"
echo "CLAUDE_REAL=$fake/claude" > "$CLAUDE_ACCOUNTS_DIR/config"
expect "claude runs on the active account" "dir=$HOME/.claude-alpha args=-p hi" "$("$ROOT/bin/claude" -p hi)"
expect "an explicit CLAUDE_CONFIG_DIR wins" "dir=/x args=" "$(CLAUDE_CONFIG_DIR=/x "$ROOT/bin/claude")"
"$CA" personal >/dev/null
expect "default account leaves CLAUDE_CONFIG_DIR unset" "dir=unset args=" "$("$ROOT/bin/claude")"
expect "the wrapper registers its session" "yes" "$(for f in "$CLAUDE_ACCOUNTS_DIR"/sessions/*; do [ -e "$f" ] && echo yes && break; done)"
echo "CLAUDE_REAL=/nowhere" > "$CLAUDE_ACCOUNTS_DIR/config"
expect "finds the real claude in PATH if CLAUDE_REAL is stale" "dir=unset args=" "$(PATH="$fake:$PATH" "$ROOT/bin/claude")"
echo "CLAUDE_REAL=$fake/claude" > "$CLAUDE_ACCOUNTS_DIR/config"
mkdir -p "$T/repo" "$HOME/.claude/projects/$(enc "$T/repo")"
expect "claude-auto starts fresh without history" "dir=unset args=" "$(cd "$T" && "$ROOT/bin/claude-auto")"
touch "$HOME/.claude/projects/$(enc "$T/repo")/s.jsonl"
expect "claude-auto continues when there is history" "dir=unset args=--continue" "$(cd "$T/repo" && "$ROOT/bin/claude-auto")"
odd="$T/my_app v2"; mkdir -p "$odd" "$HOME/.claude/projects/$(enc "$odd")"; touch "$HOME/.claude/projects/$(enc "$odd")/s.jsonl"
expect "claude-auto encodes _ and spaces like Claude Code does" "dir=unset args=--continue" "$(cd "$odd" && "$ROOT/bin/claude-auto")"
agents() { # account dir, short id, session id → that account lists one background session
  printf '[\n  {\n    "id": "%s",\n    "cwd": "%s",\n    "kind": "background",\n    "sessionId": "%s",\n    "state": "done"\n  },\n  {\n    "pid": 1,\n    "kind": "interactive",\n    "sessionId": "other"\n  }\n]\n' "$2" "$T/repo" "$3" > "$1/fake-agents.json"
}
hist="$HOME/.claude/projects/$(enc "$T/repo")"
touch "$hist/old.jsonl"; sleep 1; touch "$hist/s.jsonl"            # s = the last conversation here
agents "$HOME/.claude" bg12 s
expect "claude-auto reattaches when the last conversation is a background session" "dir=unset args=attach bg12" \
  "$(cd "$T/repo" && "$ROOT/bin/claude-auto" 2>/dev/null)"
agents "$HOME/.claude" bg12 old
expect "a background session of an OLDER conversation doesn't hijack --continue" "dir=unset args=--continue" \
  "$(cd "$T/repo" && "$ROOT/bin/claude-auto" 2>/dev/null)"
rm -f -- "$HOME/.claude/fake-agents.json"; agents "$HOME/.claude-gamma" bg34 s
expect "when --continue refuses, it reattaches with the account that owns the session" "dir=$HOME/.claude-gamma args=attach bg34" \
  "$(cd "$T/repo" && FAKE_FAIL_CONTINUE=1 "$ROOT/bin/claude-auto" 2>/dev/null)"
rm -f -- "$HOME/.claude-gamma/fake-agents.json"
refuses "...and never starts a new session on its own" bash -c "cd '$T/repo' && FAKE_FAIL_CONTINUE=1 '$ROOT/bin/claude-auto' 2>/dev/null | grep -q 'args=\$'"
expect "...it tells you how to resume instead" "1" "$(cd "$T/repo" && FAKE_FAIL_CONTINUE=1 "$ROOT/bin/claude-auto" 2>&1 >/dev/null | grep -c 'claude --resume s')"
refuses "a failure that isn't at startup is passed through" bash -c "cd '$T/repo' && FAKE_FAIL_CONTINUE=1 CLAUDE_AUTO_GRACE=0 '$ROOT/bin/claude-auto'"

echo "language"
expect "English by default" "(not logged in)" "$("$CA" list | grep ' gamma ' | sed 's/.*(not/(not/')"
"$CA" lang pt-BR >/dev/null
expect "pt-BR messages" "(sem login)" "$("$CA" list | grep ' gamma ' | sed 's/.*(sem/(sem/')"
expect "env var overrides" "en" "$(CLAUDE_ACCOUNTS_LANG=en "$CA" lang)"
"$CA" lang en >/dev/null
refuses "unknown language" "$CA" lang xx

echo "per-folder accounts (.claude-account) and CLAUDE_ACCOUNT"
"$CA" personal >/dev/null
P="$T/projects/acme"; mkdir -p "$P/src/deep"
(cd "$P" && "$CA" here gamma >/dev/null)
expect "ca here writes the pin" "gamma" "$(cat "$P/.claude-account")"
expect "the pin applies in that folder" "$HOME/.claude-gamma" "$(cd "$P" && "$CA" _dir)"
expect "...and in its subfolders" "$HOME/.claude-gamma" "$(cd "$P/src/deep" && "$CA" _dir)"
expect "outside it the global account applies" "" "$(cd "$T" && "$CA" _dir)"
expect "ca shows where the account comes from" "1" "$(cd "$P/src" && "$CA" | grep -c 'from ~*.*acme/.claude-account')"
expect "ca list marks the account used here" "1" "$(cd "$P" && "$CA" list | grep -c '^> gamma')"
expect "the wrapper follows the pin" "dir=$HOME/.claude-gamma args=" "$(cd "$P/src" && "$ROOT/bin/claude")"
expect "claude-auto follows the pin" "dir=$HOME/.claude-gamma args=" "$(cd "$P/src" && "$ROOT/bin/claude-auto")"
mkdir -p "$HOME/.claude-gamma/projects/$(enc "$P/src")" && touch "$HOME/.claude-gamma/projects/$(enc "$P/src")/s.jsonl"
expect "claude-auto continues using the pinned account's history" "dir=$HOME/.claude-gamma args=--continue" "$(cd "$P/src" && "$ROOT/bin/claude-auto")"
expect "claude-auto follows CLAUDE_ACCOUNT" "dir=$HOME/.claude-alpha" "$(cd "$P/src" && CLAUDE_ACCOUNT=alpha "$ROOT/bin/claude-auto" | cut -d' ' -f1)"
expect "CLAUDE_ACCOUNT beats the pin" "$HOME/.claude-alpha" "$(cd "$P" && CLAUDE_ACCOUNT=alpha "$CA" _dir)"
expect "CLAUDE_CONFIG_DIR beats everything" "dir=/x args=" "$(cd "$P" && CLAUDE_ACCOUNT=alpha CLAUDE_CONFIG_DIR=/x "$ROOT/bin/claude")"
expect "prompt prints the account here" "gamma" "$(cd "$P" && "$CA" prompt)"
refuses "ca here with a missing account" bash -c "cd '$P' && '$CA' here ghost"
echo ghost > "$P/src/.claude-account"
refuses "a pin to a missing account fails loudly" bash -c "cd '$P/src' && '$CA' _dir"
refuses "...and the wrapper won't open Claude" bash -c "cd '$P/src' && '$ROOT/bin/claude'"
refuses "...nor claude-auto" bash -c "cd '$P/src' && '$ROOT/bin/claude-auto'"
expect "prompt stays silent on errors" "" "$(cd "$P/src" && "$CA" prompt 2>&1)"
refuses "CLAUDE_ACCOUNT with a missing account fails" env CLAUDE_ACCOUNT=ghost "$CA" _dir
(cd "$P/src" && "$CA" here --unset >/dev/null)
expect "ca here --unset removes the pin" "" "$(yes_if [ -e "$P/src/.claude-account" ])"
refuses "--unset without a pin" bash -c "cd '$P/src' && '$CA' here --unset"
expect "switching globally inside a pinned folder says the pin wins" "1" "$(cd "$P" && "$CA" alpha | grep -c "'gamma' applies here")"
"$CA" personal >/dev/null

echo "pins stay out of git"
R="$T/repo-git"; mkdir -p "$R/sub"; git -C "$R" init -q
printf 'node_modules\n' > "$R/.gitignore"
(cd "$R" && "$CA" here gamma >/dev/null)
expect "ca here adds the pin to .git/info/exclude" "1" "$(grep -cxF .claude-account "$R/.git/info/exclude")"
expect "git does not see the pin" "?? .gitignore" "$(git -C "$R" status --porcelain)"
expect "the shared .gitignore is untouched" "node_modules" "$(cat "$R/.gitignore")"
(cd "$R" && "$CA" here alpha >/dev/null)
expect "pinning again does not duplicate the line" "1" "$(grep -cxF .claude-account "$R/.git/info/exclude")"
(cd "$R/sub" && "$CA" here alpha >/dev/null)
expect "a pin in a subfolder is ignored too" "" "$(git -C "$R" status --porcelain | grep claude-account)"
rm -f -- "$R/sub/.claude-account"
R2="$T/repo-tracked"; mkdir -p "$R2"; git -C "$R2" init -q; echo gamma > "$R2/.claude-account"
git -C "$R2" add .claude-account
expect "warns when the pin is already committed" "1" "$(cd "$R2" && "$CA" here gamma | grep -c 'git rm --cached')"

echo "status line"
echo '{"oauthAccount":{"emailAddress":"g@example.com"}}' > "$HOME/.claude-gamma/.claude.json"
sl="$(echo '{"model":{}}' | CLAUDE_CONFIG_DIR="$HOME/.claude-gamma" "$CA" statusline | sed 's/\x1b\[[0-9;]*m//g')"
expect "statusline shows the session's account and email" "● gamma · g@example.com" "$sl"
sl="$(echo '{}' | CLAUDECODE=1 "$CA" statusline | sed 's/\x1b\[[0-9;]*m//g')"
expect "statusline inside Claude without CLAUDE_CONFIG_DIR is the default account" "● personal · me@example.com" "$sl"
sl="$(cd "$P" && CLAUDECODE='' "$CA" statusline </dev/null | sed 's/\x1b\[[0-9;]*m//g')"
expect "statusline in a plain terminal shows the account in effect here" "● gamma · g@example.com" "$sl"
SG="$HOME/.claude-gamma/settings.json"; rm -f -- "$SG"
(cd "$P" && "$CA" statusline --install >/dev/null)
expect "--install writes the statusLine" "1" "$(grep -c '"command": ".*claude-accounts statusline"' "$SG")"
refuses "--install twice is refused" bash -c "cd '$P' && '$CA' statusline --install"
echo '{}' > "$SG"; (cd "$P" && "$CA" statusline --install >/dev/null)
expect "--install on an empty object" "1" "$(grep -c statusLine "$SG")"
nojq="$T/nojq"; mkdir -p "$nojq"; printf '#!/bin/sh\nexit 1\n' > "$nojq/jq"; chmod +x "$nojq/jq"   # jq that fails → no-jq path
for json in '{\n  "model": "opus",\n  "env": { "A": "1" }\n}' '{"model":"opus","env":{"A":"1"}}'; do
  printf '%b\n' "$json" > "$SG"
  (cd "$P" && PATH="$nojq:$PATH" "$CA" statusline --install >/dev/null)
  expect "--install without jq adds the statusLine" "1" "$(grep -c '"statusLine"' "$SG")"
  expect "...keeps the other settings" "1" "$(grep -c '"model": *"opus"' "$SG")"
  expect "...keeps a backup" "yes" "$(yes_if [ -f "$SG.before-statusline" ])"
  if command -v python3 >/dev/null 2>&1; then
    expect "...and the JSON stays valid" "ok" "$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print("ok" if d["statusLine"]["type"]=="command" and d["model"]=="opus" else "bad")' "$SG" 2>&1)"
  fi
done
echo '[1]' > "$SG"
refuses "--install refuses a file that isn't a JSON object" bash -c "cd '$P' && '$CA' statusline --install"
rm -f -- "$SG" "$SG.before-statusline"
echo '{}' > "$HOME/.claude-alpha/settings.json"
rm -f -- "$SG"; ln -s "$HOME/.claude-alpha/settings.json" "$SG"
(cd "$P" && "$CA" statusline --install >/dev/null)
expect "--install keeps a shared settings.json a link" "yes" "$(yes_if [ -L "$SG" ])"
expect "...and writes through it" "1" "$(grep -c statusLine "$HOME/.claude-alpha/settings.json")"
echo ghost > "$P/src/.claude-account"
refuses "--install under a pin to a missing account fails before touching anything" bash -c "cd '$P/src' && '$CA' statusline --install"
expect "...with the pin error, and no settings.json path" "1 0" \
  "$(cd "$P/src" && "$CA" statusline --install 2>&1 | grep -c "names 'ghost'") $(cd "$P/src" && "$CA" statusline --install 2>&1 | grep -c 'settings.json')"
rm -f -- "$P/src/.claude-account" "$P/.claude-account"

echo "shell completion"
if bash -c ". '$ROOT/completions/claude-accounts.bash'"; then ok "bash completion loads"; else bad "bash completion loads"; fi
comp() { # words... → completions for the last word
  PATH="$ROOT/bin:$PATH" bash -c ". '$ROOT/completions/claude-accounts.bash'; COMP_WORDS=($*); COMP_CWORD=\$((\${#COMP_WORDS[@]}-1)); _claude_accounts; echo \"\${COMPREPLY[*]}\""
}
expect "completes commands and accounts" "gamma" "$(comp ca ga)"
expect "completes subcommands" "statusline stop" "$(comp ca st | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ $//')"
expect "completes account names after use" "alpha" "$(comp ca use al)"
expect "completes flags of new" "--clean" "$(comp ca new x --c)"
if command -v zsh >/dev/null 2>&1; then
  if zsh -n "$ROOT/completions/claude-accounts.zsh"; then ok "zsh completion parses"; else bad "zsh completion parses"; fi
fi

echo "install / uninstall (fake HOME, fake claude)"
IH="$T/ihome"; mkdir -p "$IH"
inst() { HOME="$IH" SHELL=/bin/zsh CLAUDE_ACCOUNTS_DIR="$IH/.config/claude-accounts" PATH="$fake:$PATH" LANG=C LC_ALL='' bash "$ROOT/install.sh" "$@" </dev/null; }
old="$T/oldwrap"; mkdir -p "$old"
printf '#!/usr/bin/env bash\nCFG="${CLAUDE_CONTAS_DIR:-x}"\n' > "$old/claude"; chmod +x "$old/claude"
inst --name personal >/dev/null 2>&1
expect "install skips wrappers when looking for the real claude" "CLAUDE_REAL=$fake/claude" \
  "$(HOME="$IH" PATH="$old:$fake:$PATH" CLAUDE_ACCOUNTS_DIR="$IH/c2" bash "$ROOT/install.sh" --name x </dev/null >/dev/null 2>&1; cat "$IH/c2/config")"
expect "install records the current account" "personal=~/.claude" "$(cat "$IH/.config/claude-accounts/accounts" 2>/dev/null)"
expect "install creates ~/.zshrc with the block" "1" "$(grep -cxF '# >>> claude-accounts >>>' "$IH/.zshrc" 2>/dev/null)"
expect "install copies the scripts" "yes" "$(yes_if [ -x "$IH/.local/share/claude-accounts/bin/claude-accounts" ])"
expect "install copies the completions" "yes" "$(yes_if [ -f "$IH/.local/share/claude-accounts/completions/claude-accounts.zsh" ])"
expect "the rc block loads the completion" "1" "$(grep -c 'completions/claude-accounts.zsh' "$IH/.zshrc")"
inst >/dev/null 2>&1
expect "running install again is idempotent" "1" "$(grep -cxF '# >>> claude-accounts >>>' "$IH/.zshrc")"
printf 'top\n# >>> claude-accounts >>>\nexport PATH="/old:$PATH"\n# <<< claude-accounts <<<\n' > "$IH/.zshrc"
inst >/dev/null 2>&1
expect "an older block is upgraded in place" "1 1 0" "$(grep -cxF '# >>> claude-accounts >>>' "$IH/.zshrc") $(grep -c 'completions/' "$IH/.zshrc") $(grep -c '/old:' "$IH/.zshrc")"
expect "upgrading keeps the rest of the file" "top" "$(head -1 "$IH/.zshrc")"
inst --uninstall >/dev/null 2>&1
expect "uninstall removes the block" "0" "$(grep -cxF '# >>> claude-accounts >>>' "$IH/.zshrc")"
expect "uninstall keeps the accounts" "personal=~/.claude" "$(cat "$IH/.config/claude-accounts/accounts")"
IH2="$T/ihome2"; mkdir -p "$IH2"
refuses "install refuses a reserved name" env HOME="$IH2" SHELL=/bin/zsh CLAUDE_ACCOUNTS_DIR="$IH2/.config/claude-accounts" PATH="$fake:$PATH" LANG=C LC_ALL='' bash "$ROOT/install.sh" --name rm
expect "...and registers no account" "" "$(cat "$IH2/.config/claude-accounts/accounts" 2>/dev/null)"

echo "migration from claude-contas"
MH="$T/mhome"; mkdir -p "$MH/.config/claude-contas"
printf 'pessoal=~/.claude\ntrabalho=~/.claude-trabalho\n' > "$MH/.config/claude-contas/contas"
echo trabalho > "$MH/.config/claude-contas/ativa"; echo pessoal > "$MH/.config/claude-contas/base"
printf 'x\n# >>> claude-contas >>>\nalias ca=claude-conta\n# <<< claude-contas <<<\n' > "$MH/.zshrc"
HOME="$MH" SHELL=/bin/zsh CLAUDE_ACCOUNTS_DIR="$MH/.config/claude-accounts" PATH="$fake:$PATH" bash "$ROOT/install.sh" </dev/null >/dev/null 2>&1
expect "accounts migrated" "2" "$(grep -c = "$MH/.config/claude-accounts/accounts" 2>/dev/null)"
expect "active migrated" "trabalho" "$(cat "$MH/.config/claude-accounts/active" 2>/dev/null)"
expect "base migrated" "pessoal" "$(cat "$MH/.config/claude-accounts/base" 2>/dev/null)"
expect "language set to pt-BR" "pt-BR" "$(cat "$MH/.config/claude-accounts/lang" 2>/dev/null)"
expect "old rc block removed" "0" "$(grep -c claude-contas "$MH/.zshrc")"
expect "new rc block added" "1" "$(grep -cxF '# >>> claude-accounts >>>' "$MH/.zshrc")"
expect "rest of the rc file kept" "x" "$(head -1 "$MH/.zshrc")"

echo
[ "$failures" -eq 0 ] && { echo "all good"; exit 0; } || { echo "$failures failure(s)"; exit 1; }
