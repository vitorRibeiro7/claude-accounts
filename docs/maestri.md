🇧🇷 [Leia em português](pt-BR/maestri.md)

# Maestri (and similar tools)

Maestri has two things that use Claude and that **break silently** when the active account changes: the **terminals/agents** and the **usage meters**. Each needs a different fix.

The examples below assume Maestri on Windows calling Claude inside WSL. The same reasoning applies to any program that launches `claude` on its own.

## 1. Terminals, agents and presets → `claude-auto`

In every preset (agent, terminal, "Claude Code"…), set the command to:

```
claude-auto
```

It opens Claude **on the active account** (`ca`) and **continues the directory's conversation** if there is one, or starts a new one. This matters because Maestri opens each agent in a fresh folder (`.maestri/roles/<id>`), and `claude --continue` fails in a folder that never had a session.

To move everything to another account at once: close the sessions (`ca stop`), `ca NAME`, open them again.

> If the command is not found, Maestri probably does not see your shell's PATH. Use the full path: `~/.local/share/claude-accounts/bin/claude-auto`.

## 2. Usage meters → one provider per account, calling the real binary

Maestri shows each account's plan usage. It reads it from JSON files, one per account:

```
C:\Users\<you>\.maestri\usage\providers\<id>.json
```

Maestri writes an `AGENTS.md` in that folder describing the format, and **rereads the folder every 15 seconds**.

### What goes wrong

The built-in provider (`claude.json`) runs `claude`. With `claude-accounts` installed, that command is the **wrapper**, which opens the **active account**. Result: the "Claude" meter shows whoever is active, not the account its name says. Another common failure: a provider pointing to a folder that was renamed, which then reads an empty folder.

### The fix

Each provider calls the **real binary** (bypassing the wrapper) with its account's folder set explicitly:

- **Named account:** `CLAUDE_CONFIG_DIR="$HOME/.claude-NAME"`
- **Default account (`~/.claude`):** `unset CLAUDE_CONFIG_DIR` (its login lives in `~/.claude.json`, outside the folder; see [how-it-works.md](how-it-works.md))

The real binary comes from `~/.config/claude-accounts/config` (`CLAUDE_REAL`), written by `install.sh`, so the provider keeps working if Claude Code moves.

### Create a provider for a new account

There is a ready-made template at [`examples/maestri-usage-provider.json`](../examples/maestri-usage-provider.json) with three placeholders:

| Placeholder | Meaning |
|---|---|
| `__ID__` | lowercase id, same as the file name |
| `__NAME__` | label shown on the meter |
| `__DIR__` | the account's folder, relative to `$HOME` |

Example for the account `work` (folder `.claude-work`):

```bash
PROV=/mnt/c/Users/YOUR-WINDOWS-USER/.maestri/usage/providers
sed -e 's/__ID__/work/g' -e 's/__NAME__/Work/g' -e 's/__DIR__/.claude-work/g' \
    examples/maestri-usage-provider.json > "$PROV/claude-work.json"
```

The `id` accepts only **lowercase letters, digits and hyphens**, and must match the file name (without `.json`).

Within 15 seconds the meter shows up under *Settings → Agents → Usage*; if the file has an error, the exact message appears there.

> Not on WSL? If Maestri runs on the same OS as Claude Code, drop the `wsl -e` hop: use `"executable": "/bin/bash"` and `"args": ["-lc", "<command>"]`. Check Maestri's `AGENTS.md` for the exact format.

### Fix the built-in provider (default account)

Edit `claude.json` so the command ends like this (default account, no variable):

```
. "$HOME/.config/claude-accounts/config"; unset CLAUDE_CONFIG_DIR; exec "$CLAUDE_REAL" -p --input-format stream-json --output-format stream-json --verbose --no-session-persistence
```

with the `source` using `"executable": "wsl"` and `"args": ["-e", "bash", "-lc", "<the command above>"]`, as in the template.

Editing the built-in provider marks it **Modified**; *Restore Default* brings back the original (and the meter goes back to following the active account).

### Test without opening Maestri

Run the provider's command the way Maestri does (minimal environment):

```bash
REQ='{"type":"control_request","request_id":"u","request":{"subtype":"get_usage","skip_behaviors":true}}'
printf '%s\n' "$REQ" | env -i HOME="$HOME" PATH=/usr/bin:/bin timeout 40 bash -lc '<provider command>' \
  | grep '"request_id":"u"'
```

You should get back JSON with `subscription_type` (the plan) and `rate_limits`. If each provider returns a **different** plan/percentage, the meters are correctly separated.

## Caveats

- **Do not keep backups inside the `providers` folder**: Maestri loads everything in it. Keep copies elsewhere.
- **Account not logged in** (`ca list` shows `(not logged in)`): its meter stays empty or in error until you log in.
- **Renamed an account's folder?** Update its provider (and `~/.config/claude-accounts/accounts`, and any alias).
- **Meter refreshes are short Claude processes.** While one runs (a few seconds, every few minutes), `ca NAME` sees it as an open session and refuses; just try again. On macOS these processes bypass the wrapper and show as `(unknown)` in `ca sessions` (see [how-it-works.md](how-it-works.md#sessions)).
