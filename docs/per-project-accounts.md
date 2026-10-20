🇧🇷 [Leia em português](pt-BR/contas-por-projeto.md)

# Per-project accounts

Stop switching. Tell each project which account it belongs to, and `claude` picks it by itself.

```bash
cd ~/work/api
ca here work        # writes .claude-account
claude              # opens on "work" — here and in every subfolder

cd ~/personal/blog
claude              # opens on your global account, as usual
```

Because the account is chosen **per launch**, you can have a personal session in one terminal and a work session in another **at the same time**. The global `ca NAME` keeps working as the fallback.

## Which account wins

When you run `claude` (or `claude-auto`), the first match wins:

| # | Source | Scope | Set with |
|---|---|---|---|
| 1 | `CLAUDE_CONFIG_DIR` | that command | `CLAUDE_CONFIG_DIR=~/.claude-work claude` |
| 2 | `CLAUDE_ACCOUNT` | that command or terminal | `CLAUDE_ACCOUNT=work claude` · `export CLAUDE_ACCOUNT=work` |
| 3 | `.claude-account` in the folder or any parent | that project | `ca here work` |
| 4 | global account | everything else | `ca work` |

`ca` always tells you which one is in effect and why:

```console
$ ca
account here: work (from ~/work/api/.claude-account) → /home/you/.claude-work · you@company.com

$ ca list
* personal             ~/.claude                          you@gmail.com
> work                 ~/.claude-work                     you@company.com
> = used here (from ~/work/api/.claude-account) · * = global
```

## Commands

```bash
ca here work        # pin this folder (and subfolders) to "work"
ca here             # show the account in effect here
ca here --unset     # remove this folder's pin
```

A pin can live anywhere: put one in `~/work/.claude-account` and every repo under `~/work` uses the work account.

## Safety

- **A pin to an account that doesn't exist is an error**, not a silent fallback: `claude` refuses to open instead of starting on the wrong account. Fix it with `ca list` or `ca here --unset`.
- A pin only selects among **your** accounts. It can't create accounts or point to arbitrary folders.
- The file is personal, so keep it out of git. `ca here` reminds you when you're in a repo that doesn't ignore it:
  ```bash
  mkdir -p ~/.config/git && echo .claude-account >> ~/.config/git/ignore
  ```

## Show the account in your prompt

`ca prompt` prints just the account name in effect for the current folder, and prints nothing if there's an error. See [status-line.md](status-line.md) for starship, powerlevel10k and plain PS1 snippets.
