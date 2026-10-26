🇧🇷 [Leia em português](pt-BR/adicionar-conta.md)

# Adding an account

Scenario: `claude-accounts` is already installed and you want to start using **one more** Claude account (another email, another company, another client).

## Step by step

### 1. Pick a name

Lowercase letters, digits, `-` or `_`. This is what you will type after `ca`: `work`, `client-x`, `freelance`.

Command names (`list`, `ls`, `use`, `new`, `base`, `share`, `remove`, `rm`, `here`, `sessions`, `stop`, `lang`, `statusline`, `prompt`, `doctor`, `help`, `version`) are reserved.

### 2. Create the account

```bash
ca new freelance
```

This creates `~/.claude-freelance` and adds the account to the list. **It is not logged in yet** — that is step 4.

**It starts linked to the base.** If you have set a base (`ca base NAME`, once), the new account gets the same plugins, skills, settings and conversations as the others, with nothing else to do. Only the **login** is separate.

```bash
ca base                              # show which account is the base
ca new freelance                     # linked to the base
ca new freelance --clean             # isolated: nothing from the others (good for another organization)
ca new freelance --share other       # linked to another account instead of the base
```

### 3. Switch to it

```bash
ca stop            # if any Claude sessions are open
ca freelance       # same as: ca use freelance
```

### 4. Log in (the step people get wrong most often)

```bash
claude
```

Inside Claude Code, type `/login` and sign in **with the new account's email**. The browser opens, you authorize, done.

> **Watch out:** if your browser is already signed in to another Anthropic account, it may authorize the wrong account without asking. Use a private window, or sign out in the browser first.

### 5. Check

```bash
ca
# active account: freelance → /home/you/.claude-freelance · you@freelance.example.com
```

If you see the right email, you are done. If you see `(not logged in)`, `/login` did not finish; repeat step 4.

## Conversations missing in the new account? (empty `/resume`)

Each account keeps **its own** conversations. An account created with `--clean` (or before a base existed) starts with an empty history and **cannot see the other accounts' sessions**: you cannot resume, in one account, a conversation started in another.

If you want to continue in any account what you started in another, share them (this also works for an account that already exists and already has conversations):

```bash
ca stop                    # no open session on the account being linked
ca share NEW MAIN          # link NEW's conversations, plugins and settings to MAIN's
```

- Whatever the new account already had is **merged** into the main one; nothing is overwritten, and the original is kept as `<item>.before-share` (delete it once you have checked).
- Running the command again is safe.
- Only the **login** stays separate per account.
- Pick as "main" the account that holds your full history.

## From now on

```bash
ca list            # see all accounts (* = active)
ca work            # switch back whenever you want
claude             # always opens on the active account
```

## Should a new account become my "default" Claude account?

No need. The default account is simply the one using `~/.claude` (the folder that existed before you installed). The others work the same way, just in their own folders. See [how-it-works.md](how-it-works.md).

## Troubleshooting

- **"an account named 'X' already exists"** → pick another name (`ca list` shows the ones in use).
- **"~/.claude-X already exists"** → a folder is left over from an old account. Delete it or pick another name.
- **How many accounts can I have?** As many as you like. Each one is just a folder and a line in the list.
- **On macOS?** See [macos.md](macos.md) for how logins are stored there.
