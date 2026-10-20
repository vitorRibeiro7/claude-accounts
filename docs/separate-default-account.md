🇧🇷 [Leia em português](pt-BR/conta-padrao-separada.md)

# Moving the login out of the default account (without logging in again)

> **macOS:** this procedure moves `.credentials.json`, but on macOS Claude Code stores the token in the login Keychain instead. It does not apply as-is there — just run `/login` again in the new account. See [macos.md](macos.md).

## The problem

`~/.claude` is Claude Code's **default** account: it is what opens when no variable is set, and what most tools and updates assume. If you started with a single account you probably logged in there, and it quietly became "the account for everything".

Once you add more accounts this gets confusing: the default account is now just some work account with a specific email, but it is still "the first one". It is hard to tell which one is the main account, and anything that uses the default (a usage meter, a program that calls `claude` directly) shows that account.

The clean fix: **keep the default account for personal use (or empty), and put every work login in a named folder**.

## Move the default account's login to a named account

No new `/login` needed. Example: moving the current default login to an account called `work`.

**0. Close everything on the default account**

```bash
ca sessions         # no session should be on ".claude"
ca stop             # if there are any
```

**1. Create the folder and move the login**

```bash
umask 077
mkdir -p ~/.claude-work
cp -p ~/.claude.json ~/.claude-work/.claude.json                        # account data (email, plan)
mv    ~/.claude/.credentials.json ~/.claude-work/.credentials.json      # the token
```

- The token is **moved**, not copied. Two copies of the same login token invalidate each other when one of them refreshes.
- `~/.claude.json` also stays in the default account for now; step 3 removes the login from it.

**2. Test BEFORE cleaning the default account**

```bash
CLAUDE_CONFIG_DIR=~/.claude-work claude
# inside it: /status (or /usage) → should show the right email and plan
```

If something is wrong, undo:

```bash
mv ~/.claude-work/.credentials.json ~/.claude/.credentials.json
```

**3. Remove the login from the default account**

With `jq`:

```bash
jq 'del(.oauthAccount)' ~/.claude.json > ~/.claude.json.tmp \
  && chmod 600 ~/.claude.json.tmp && mv ~/.claude.json.tmp ~/.claude.json
```

Or with `python3`:

```bash
python3 - <<'PY'
import json, os, tempfile
p = os.path.expanduser('~/.claude.json')
d = json.load(open(p))
d.pop('oauthAccount', None)
fd, t = tempfile.mkstemp(dir=os.path.dirname(p)); os.fchmod(fd, 0o600)
with os.fdopen(fd, 'w') as f: json.dump(d, f)
os.replace(t, p)
PY
```

The default account is now logged out. To use it as your personal account: `ca DEFAULT-NAME`, `claude`, `/login` with your personal email.

**4. Register the accounts in `ca`**

Edit `~/.config/claude-accounts/accounts` (one account per line, `name=folder`). The default account gets a new name and the moved account is added under its own:

```
personal=~/.claude
work=~/.claude-work
```

If the active account was the old name of the default one, set it again: `ca personal`.

**5. Link the new account to the shared config**

```bash
ca share work BASE      # BASE = the account holding the config (see shared-config.md)
ca list                 # check the emails
```

**6. If you use Maestri**, the default account's usage meter needs a new name and the moved account gets its own: see [maestri.md](maestri.md).

## Afterwards

- `ca list` shows each account with the right email.
- Anything that uses the default account (meters, programs) now shows the **personal** account, predictably.
- No work login depends on being "the first account".

> The default account stays **not logged in** until you sign in to it. That is expected: `ca list` shows `(not logged in)` for it.
