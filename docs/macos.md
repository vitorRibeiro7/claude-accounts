🇧🇷 [Leia em português](pt-BR/macos.md)

# macOS notes

`claude-accounts` works on macOS the same way it does on Linux and WSL. This page covers the differences.

## Installing

```bash
curl -fsSL https://raw.githubusercontent.com/vitorRibeiro7/claude-accounts/main/install.sh | bash
```

- **zsh** (the default shell): the block goes into `~/.zshrc`, which is created if it does not exist.
- **bash**: the block goes into `~/.bash_profile` (macOS opens login shells, which read that file rather than `~/.bashrc`).
- Any of `~/.zshrc`, `~/.bashrc` and `~/.bash_profile` that already exist also get the block (each with a `.bak-claude-accounts` backup).

Open a new terminal and run `ca doctor`.

## Requirements

| Needed | Notes |
|---|---|
| bash | the stock `/bin/bash` 3.2 is enough; no Homebrew bash needed |
| Claude Code | installed and in PATH before you run the installer |
| `jq` | optional; used to read account emails, with a `sed` fallback |
| python3 | **not** needed |

## Logins live in the Keychain

On macOS, Claude Code stores the OAuth token in the **login Keychain** rather than in `<config dir>/.credentials.json`. Two consequences:

**1. Moving a login between folders does not work as documented.** The procedure in [separate-default-account.md](separate-default-account.md) moves `.credentials.json`, which does not exist on macOS. Instead, create the account and log in again:

```bash
ca new work
ca work
claude              # then /login with that account's email
```

To log the default account out afterwards, run `/logout` inside a session on it.

**2. Each account still gets its own login.** Every `CLAUDE_CONFIG_DIR` gets a separate login. This relies on Claude Code storing credentials per config folder, which is Claude Code's behavior, not something `claude-accounts` controls. If two accounts ever appear to share a login (`ca list` shows the same email for both, or logging in to one logs out the other), please [open an issue](https://github.com/vitorRibeiro7/claude-accounts/issues) with your Claude Code version (`claude --version`).

Also note that deleting an account folder (`ca remove NAME --delete-dir`) may leave its token in the Keychain. Run `/logout` in that account first if you want it gone.

## Sessions

There is no `/proc` on macOS, so `ca sessions` and `ca stop` rely on the registry the wrapper keeps in `~/.config/claude-accounts/sessions/`. Every session opened through `claude` or `claude-auto` is listed with its account and directory.

Sessions opened by tools that **bypass the wrapper** (they run the real binary directly) are still found by process name, but their account shows as `(unknown)`. `ca share` treats an unknown session conservatively: it refuses, because the session might be on the account being linked. Close it (or `ca stop`) and try again.

## IDEs and other tools

GUI apps launched from the Dock or Finder usually do not read `~/.zshrc`, so they do not see the wrapper and open the real `claude` on the default account. Point them to `claude-auto` by full path:

```
~/.local/share/claude-accounts/bin/claude-auto
```

It opens the active account and continues the directory's conversation if there is one. It also registers the session, so it shows up correctly in `ca sessions`. See [maestri.md](maestri.md) for a worked example.
