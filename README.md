<div align="center">

# claude-accounts

**Switch between multiple Claude Code accounts — personal, work, client — with one command.**<br>
No logout/login dance. Plugins, skills and settings shared. Logins kept separate.

[![CI](https://github.com/vitorRibeiro7/claude-accounts/actions/workflows/ci.yml/badge.svg)](https://github.com/vitorRibeiro7/claude-accounts/actions/workflows/ci.yml)
![Platforms](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20WSL-blue)
![Shell](https://img.shields.io/badge/bash-3.2%2B-4EAA25)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)

🇧🇷 [Leia em português](README.pt-BR.md)

</div>

```console
$ ca list
* personal             ~/.claude                          you@gmail.com
  work (base)          ~/.claude-work                     you@company.com
  client-x             ~/.claude-client-x                 you@client-x.com

$ ca work          # switch
active account: work → /home/you/.claude-work · you@company.com

$ claude           # Claude Code opens on the work account
```

<p align="center">
  <img src="assets/demo.gif" alt="claude opens on the personal account inside ~/work; after `ca here work`, it opens on the work account there, while ~/side-project keeps the personal one, side by side" width="100%">
</p>

## Why

Claude Code keeps one login per config folder. If you have a personal subscription *and* a work one, switching means `/logout`, `/login`, browser, repeat — and your plugins, skills and conversation history don't follow you.

`claude-accounts` gives every account its own folder and switches between them by setting [`CLAUDE_CONFIG_DIR`](https://docs.claude.com/en/docs/claude-code/settings) for you:

- ⚡ **One command to switch** — `ca work`, then `claude`. That's it.
- 📁 **Per-project accounts** — `ca here work` once, and `claude` opens on the right account in that repo. Personal and work sessions side by side.
- 👀 **Always know where you are** — account and email in Claude Code's status line and in your shell prompt.
- 📊 **Every account's limits at a glance** — `ca usage` shows the 5-hour and weekly use of all your accounts side by side, with reset times.
- 🔐 **Logins stay separate** — each account keeps its own credentials; nothing is copied or shared.
- 🧩 **Shared setup** — install a plugin or skill once, have it in every account (optional, per account).
- 💬 **Resume across accounts** — shared conversation history, so `/resume` works no matter which account you're on.
- 🛡️ **Safe by default** — never opens Claude on a guessed account, never deletes a folder without asking, keeps a backup of anything it relinks, and won't move shared files while sessions are open.
- 🪶 **Tiny & dependency-free** — three bash scripts. No Node, no Python, no daemon. Works with the stock bash 3.2 on macOS.

## Install

Requires [Claude Code](https://docs.claude.com/en/docs/claude-code) already installed.

```bash
curl -fsSL https://raw.githubusercontent.com/vitorRibeiro7/claude-accounts/main/install.sh | bash
```

<details>
<summary>Or clone it (recommended if you want to read the code first)</summary>

```bash
git clone https://github.com/vitorRibeiro7/claude-accounts ~/claude-accounts
cd ~/claude-accounts
./install.sh            # options: --name personal  --lang pt-BR
```
</details>

The installer asks what to call the account you **already** use (e.g. `personal`), then adds a small marked block to your `~/.zshrc` / `~/.bashrc` / `~/.bash_profile`. Open a new terminal and check:

```bash
ca doctor
```

## Quick start: add a second account

```bash
ca new work        # 1. create it (linked to your shared setup by default)
ca work            # 2. switch to it
claude             # 3. open Claude Code and run /login with your work email
ca                 # 4. check: shows the work email
```

Switch back any time with `ca personal`. Full guide: [docs/adding-an-account.md](docs/adding-an-account.md).

## Per-project accounts

Even better: don't switch at all. Pin a folder once and `claude` picks the account by itself, there and in every subfolder.

```bash
cd ~/work/api && ca here work     # writes .claude-account
claude                            # → work account
cd ~/side-project && claude       # → your global account
CLAUDE_ACCOUNT=personal claude    # one-off override, any folder
```

Sessions on different accounts can run **at the same time** in different terminals. Precedence and safety rules: [docs/per-project-accounts.md](docs/per-project-accounts.md).

## See the account everywhere

```bash
ca statusline --install   # Claude Code's bottom bar: ● work · you@company.com
```

`ca prompt` prints the account for your shell prompt (starship, powerlevel10k, PS1 snippets in [docs/status-line.md](docs/status-line.md)). Tab completion for commands and account names is set up by the installer for zsh and bash.

> **Tip:** if your browser is already signed in to another Anthropic account, `/login` may silently authorize that one. Use a private window.

## See every account's limits

```console
$ ca usage
  ACCOUNT              PLAN     5H  RESETS IN   7D  RESETS IN  MODELS
* personal             max      3%  3h 18m     22%  14h 8m     Fable 34%
  work                 pro     81%  42m        64%  2d 14h
  client-x             team    96%  18m        92%  7h 8m
```

Every logged-in account is asked at once, through Claude Code itself, so it takes about as long as the slowest one (a couple of seconds). Values close to the limit turn yellow, then red. `ca usage work` shows just that account. It only reports: it never switches accounts for you.

## Commands

| Command | What it does |
|---|---|
| `ca` | show the active account and its email |
| `ca list` | all accounts; `*` marks the active one |
| `ca NAME` / `ca use NAME` | switch the global account to NAME (open sessions keep the account they started with) |
| `ca here [NAME \| --unset]` | pin this folder and its subfolders to an account |
| `ca new NAME [--clean \| --share OTHER]` | create an account — linked to the base by default, isolated with `--clean` |
| `ca base [NAME]` | show / move the **base**: the account that holds the shared plugins, skills and settings |
| `ca share NAME OTHER` | link an existing account's conversations/plugins/settings to OTHER's |
| `ca remove NAME [--delete-dir]` | drop it from the list (the folder is only deleted with `--delete-dir`) |
| `ca sessions` | list open Claude sessions and their accounts |
| `ca stop` | terminate all sessions (asks first) |
| `ca usage [NAME…]` | plan usage of every account: 5-hour and weekly limits, reset times, per-model caps |
| `ca statusline [--install]` | account and email in Claude Code's status line |
| `ca prompt` | account name for your shell prompt |
| `ca lang [en\|pt-BR]` | UI language |
| `ca doctor` | check the installation |
| `claude` | Claude Code on the account in effect here |
| `CLAUDE_ACCOUNT=NAME claude` | one command or terminal on another account |
| `claude-auto` | same, but continues this directory's last conversation if there is one — great for IDEs and terminal presets |

## Shared setup, separate logins

Pick one account as the **base** and every new account links to it:

```bash
ca base personal   # once
ca new work        # work now sees personal's plugins, skills, settings and history
ca new client-x --clean   # ...or keep a client fully isolated
```

What's shared: `settings.json`, `plugins/`, `skills/`, `projects/` (conversations), `file-history/`, `history.jsonl`.
What's **never** shared: the login. Details and gotchas: [docs/shared-config.md](docs/shared-config.md).

## How it works

```
you type:  claude
   → wrapper (first in PATH) asks `ca` which account applies here
   → exports CLAUDE_CONFIG_DIR=~/.claude-work
   → execs the real claude
```

State is plain text in `~/.config/claude-accounts/`. The default account (`~/.claude`) is special-cased because its login lives outside the folder. Deep dive with diagrams: [docs/how-it-works.md](docs/how-it-works.md).

## Docs

- [Adding an account](docs/adding-an-account.md) · [Removing an account](docs/removing-an-account.md)
- [Per-project accounts](docs/per-project-accounts.md) · [Status line & shell prompt](docs/status-line.md)
- [Shared config across accounts](docs/shared-config.md)
- [Moving the default account's login to a named account](docs/separate-default-account.md)
- [macOS notes](docs/macos.md)
- [Reinstalling from scratch](docs/reinstall-from-scratch.md)
- [Maestri integration](docs/maestri.md) (presets with `claude-auto`, usage rings per account)
- [How it works](docs/how-it-works.md)

## FAQ

**Is this allowed?** It only automates `CLAUDE_CONFIG_DIR`, an official Claude Code setting. Use it for accounts you legitimately own (e.g. personal and employer-provided) and follow [Anthropic's terms](https://www.anthropic.com/legal/consumer-terms) — it is **not** meant for rotating accounts to get around usage limits.

**Does it read or touch my credentials?** No. It never opens token files. It reads the email shown in `.claude.json` for display, and that's it.

**An IDE / tool opens Claude on the wrong account.** It probably doesn't read your shell rc, so it runs the real `claude`. Point it to `claude-auto` (full path: `~/.local/share/claude-accounts/bin/claude-auto`) and run `ca doctor`.

**fish / nushell?** Not wired up by the installer yet. Add `~/.local/share/claude-accounts/bin` to your `PATH` and alias `ca` to `claude-accounts`. PRs welcome.

**Claude Code updated and something broke?** Run `ca doctor`; re-running `install.sh` refreshes the path to the real binary.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/vitorRibeiro7/claude-accounts/main/install.sh | bash -s -- --uninstall
# or, from a clone:  ./install.sh --uninstall
```

Removes the PATH block and the scripts; your accounts and logins stay untouched.

## Contributing

Issues and PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). The test suite runs in a fake `HOME` and never touches your accounts:

```bash
./tests/test.sh
```

## License

[MIT](LICENSE)
