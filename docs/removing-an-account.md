🇧🇷 [Leia em português](pt-BR/remover-conta.md)

# Removing an account

Scenario: you no longer use one of your accounts and want it out of the way.

## Remove it from the list only (safe, the default)

```bash
ca remove freelance
```

The account disappears from `ca list`, but the `~/.claude-freelance` folder **stays on disk** with its login and history. To undo, add the line back to `~/.config/claude-accounts/accounts`:

```
freelance=~/.claude-freelance
```

## Remove it from the list and delete the folder

```bash
ca remove freelance --delete-dir
```

Asks for confirmation, deletes `~/.claude-freelance` (the login and history of **that** account only) and removes it from the list. Symlinks inside the folder are deleted, never what they point to.

## What is blocked

| Action | Why | What to do |
|---|---|---|
| Removing the **active** account | you would be left on an account that no longer exists | switch first: `ca other-account` |
| Removing the **base** | the other accounts link to it | move the base first: `ca base OTHER` |
| Deleting the **default** account's folder (`~/.claude`) | never deleted from here | removing it from the list is allowed |
| Deleting a folder that another account **shares items from** | the other account would silently break | remove or recreate the other account first |

`--delete-dir` also refuses any folder that is not a `~/.claude-*` folder.

## Before deleting: the login

Deleting the folder removes the local login, but **the session stays valid on Anthropic's side** until you end it. If the account belonged to a company you have left, go to *claude.ai → Settings* and sign out of that device.

On macOS Claude Code keeps the token in the login Keychain rather than in the folder, so deleting the folder may leave it there; see [macos.md](macos.md).

## Afterwards

```bash
ca list      # check
```
