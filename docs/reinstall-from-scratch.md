🇧🇷 [Leia em português](pt-BR/reinstalar-do-zero.md)

# Reinstalling from scratch

For when the machine was wiped, WSL was recreated, you moved to a new computer, or something broke and you need to set everything up again. It is written to be followed **without remembering anything**.

Tip: keep a short private note (outside any repo) with your account names, which email each one uses, what shares with what, and which programs call `claude-auto`. It makes steps 5–9 trivial.

---

## 0. What you lose and what you keep

| Item | Where it lives | On reinstall |
|---|---|---|
| The scripts (`ca`, wrapper, `claude-auto`) | the [claude-accounts repo](https://github.com/vitorRibeiro7/claude-accounts) | come back with `install.sh` |
| The account list and the active account | `~/.config/claude-accounts/` | **lost**: recreate (step 5) |
| Each account's **login** | inside each account's folder (macOS: the Keychain) | **lost**: `/login` again in each one |
| Settings, plugins, skills, conversations, memory | each account's folder (`~/.claude`, `~/.claude-NAME`) | **lost, unless backed up** |
| The PATH/alias block | `~/.zshrc` / `~/.bashrc` / `~/.bash_profile` | comes back with `install.sh` |

What really hurts to lose **is not the login** (you just sign in again) but the folders' content: `settings.json`, `plugins/`, `skills/`, `CLAUDE.md`, `rules/`, memory and the history in `projects/`. None of that is in git. See step 1.

---

## 1. Before any disaster: the backup

Do this periodically (or before wiping the machine / reinstalling WSL):

```bash
# a copy of ALL account folders, without the login files
tar czf ~/claude-accounts-backup-$(date +%F).tgz \
  --exclude='.credentials.json' --exclude='sessions' \
  -C ~ .claude $(cd ~ && ls -d .claude-* 2>/dev/null) \
  .config/claude-accounts
```

- `--exclude='.credentials.json'` keeps the login tokens **out** of the backup. Store the file somewhere of your own (another disk, personal cloud), never in a repository. Without logins the backup is just configuration; logins are easy to redo.
- `~/.claude.json` (in your home) holds the **default account's** login. It is left out on purpose too.
- WSL: the simplest full backup is `wsl --export <distro> file.tar` from Windows PowerShell (it includes everything, logins too; treat that file as a secret).

Restore:

```bash
tar xzf claude-accounts-backup-YYYY-MM-DD.tgz -C ~
```

---

## 2. Install Claude Code

Follow the official Claude Code install for your system. Check:

```bash
claude --version
command -v claude        # the installer finds this path on its own
```

You also need `bash` and `curl` (or `git`). `jq` is optional (used to read the account email; there is a fallback). `python3` is not required.

> **Do not log in yet.** `/login` should happen *after* the accounts exist (step 6); otherwise the login lands in the default folder and you have to work out which account it was.

---

## 3. Run the installer

One line:

```bash
curl -fsSL https://raw.githubusercontent.com/vitorRibeiro7/claude-accounts/main/install.sh | bash
```

Or from a clone:

```bash
git clone https://github.com/vitorRibeiro7/claude-accounts ~/claude-accounts
cd ~/claude-accounts && ./install.sh
```

Options: `--name NAME` names the default account without asking, `--lang pt-BR` for Portuguese messages.

The installer:
1. finds the real `claude` and writes its path to `~/.config/claude-accounts/config`;
2. copies the scripts to `~/.local/share/claude-accounts/bin/`;
3. asks for **the name of the default account** (the one using `~/.claude`), unless accounts are already registered;
4. adds the `# >>> claude-accounts >>>` block (PATH and the `ca` alias) to your shell startup files, with a `*.bak-claude-accounts` backup.

Coming from the old `claude-contas`? The installer imports its account list (`~/.config/claude-contas/`) and replaces its rc block automatically.

Open a **new** terminal (or `source ~/.zshrc`) and check:

```bash
command -v claude      # must be .../claude-accounts/bin/claude (the wrapper), NOT the real claude
ca doctor              # checks the binary, the PATH and the active account
ca list                # should show the default account
```

If `command -v claude` shows the real binary, PATH did not pick it up: see "Troubleshooting" below.

---

## 4. Restore the backup (optional)

If you have one from step 1, restore it now (`tar xzf … -C ~`). It brings back the account folders, links and `~/.config/claude-accounts`.

---

## 5. Recreate the other accounts

Once per account, **with the same names as before**:

```bash
ca base NAME-1                          # if you use a shared base (see shared-config.md)
ca new NAME-2                           # linked to the base by default
ca new NAME-3 --clean                   # or isolated
```

- If you **restored a backup**, the `~/.claude-NAME` folders already exist and `ca new` refuses ("already exists"). In that case just register the account in the list:
  ```bash
  echo 'NAME-1=~/.claude-NAME-1' >> ~/.config/claude-accounts/accounts
  ```
  (One line per account. The default one is `NAME=~/.claude`.)

---

## 6. Log in to each account

For **each** account, one at a time:

```bash
ca NAME
claude
# inside Claude:  /login   → sign in with THAT account's email
# leave Claude (/exit)
ca                  # check: the email shown must be the expected one
```

Watch the browser: if it is already signed in to another Anthropic account, `/login` may authorize the wrong one without asking. Use a private window, or sign out in the browser between logins.

If an account shows `(not logged in)` in `ca list`, its login did not finish; repeat.

---

## 7. Pick the main account

```bash
ca NAME             # the one `claude` should open by default
ca                  # check
```

From then on `claude` always opens on that account, and switching is just `ca OTHER`.

---

## 8. Check that everything works

```bash
ca doctor            # all checks "ok"
ca list              # every account, with email, active one marked
ca sessions          # no open sessions
```

And a real test: `ca NAME` → `claude` → `/status`, and check the email.

### 8b. Link the accounts to the shared config

If you use one account as the base and the others point to it, redo the links (once per account that is not linked yet):

```bash
ca stop
ca share OTHER BASE
```

If you restored the backup, the links come with it, but check with `ls -l ~/.claude-NAME`. Remember that `~/.claude/rules/` applies to **every** account; read [shared-config.md](shared-config.md) before reinstalling any rules pack there.

---

## 9. Tools that open Claude on their own (IDEs, etc.)

Programs that do not read your shell startup file do not see the wrapper and open the real `claude` **on the default account**, silently. Point them to:

```
claude-auto
```

(or the full path: `~/.local/share/claude-accounts/bin/claude-auto`). It uses the active account and **continues the directory's conversation** if there is one. Write down **which programs you changed**; it is the easiest part to forget.

**Maestri:** besides the presets, it has one usage provider per account (the meters). Recreate them following [maestri.md](maestri.md); the template is `examples/maestri-usage-provider.json`.

---

## Troubleshooting

**`ca: command not found`** → old terminal. Open a new one or `source ~/.zshrc`. If it persists, check that the `# >>> claude-accounts >>>` block is in your startup file.

**`command -v claude` shows the real binary** → the wrapper's folder is not first in PATH. Check `echo $PATH`: `~/.local/share/claude-accounts/bin` must come **before** wherever Claude Code is. If your rc file sets PATH after the block, move the block to the end of the file.

**`claude-accounts: real 'claude' not found`** → Claude Code was reinstalled elsewhere or removed. Install it, then run `install.sh` again; it rewrites the path.

**`ca NAME` mentions open sessions** → they keep the account they started with; the switch applies to new launches. `ca sessions` shows which; `ca stop` closes them if you want everything on the new account.

**The account shows not logged in even after `/login`** → you logged in while another account was active. `ca` shows which one was active; redo step 6 on the right account.

**Default account "logged out" after changing variables** → for the default account `CLAUDE_CONFIG_DIR` **must not** be set (see [how-it-works.md](how-it-works.md)). Run `echo $CLAUDE_CONFIG_DIR`: if it is not empty, something in your shell sets it.

**Moved to another machine or WSL distro** → paths change; start again from step 2.

**Uninstall** → `install.sh --uninstall` removes the PATH/alias block and the scripts; your accounts in `~/.config/claude-accounts` and the `~/.claude-*` folders are kept.
