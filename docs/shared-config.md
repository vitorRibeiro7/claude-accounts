🇧🇷 [Leia em português](pt-BR/configuracao-compartilhada.md)

# One config, many logins

The goal: **install a plugin or skill, or change a setting, once and have it in every account**. Only the **login** is separate per account.

## How claude-accounts does it

Pick one account as the **base** (the one that holds the real config). The others point to it with symlinks:

```
~/.claude-base/settings.json    ← the real file
~/.claude-other/settings.json   → link to the one above
```

Shared items: `settings.json`, `plugins`, `skills`, `projects` (conversations), `file-history`, `history.jsonl`. **Not** shared: the login (`.credentials.json` and each folder's own `.claude.json`).

```bash
ca base NAME             # set the BASE (once)
ca new NEW               # every new account starts linked to the base
ca new NEW --clean       # ... or isolated, if you want nothing shared
ca stop                  # (only for an account that ALREADY exists) no open session on it
ca share OTHER BASE      # link an existing account to the BASE
```

In practice:
- install a plugin in any account → it shows up in the others;
- resume a conversation in any account → all of them see it (`/resume`);
- change the theme, model or permissions → applies to all of them.

When an existing account is shared, what it already had is merged into the base (folders) or kept as `<item>.before-share` (files). Items the base does not have yet are created there first (empty, or from the account's own copy), so the link exists from day one. Nothing is deleted.

## Which account should be the base?

Any of them. Once linked, the accounts are equivalent; the only difference is **where the real files live**.

- If you use the same skills and plugins for personal and work projects, the **default** account (`~/.claude`) is a natural base: one setup that is "yours", and the work accounts just point to it.
- If the default account is personal and you do not want that mixed in, pick another account as the base.

**Moving the base later** moves the real files to the new account and relinks all the others, without losing anything:

```bash
ca stop             # moving the base touches everything shared: no open sessions
ca base NEW-BASE    # asks for confirmation
ca list             # check: the new base is marked (base)
```

Old paths keep working, because the old base's folder now holds links to the new one. If the same item exists "for real" in both accounts, the command **refuses** before touching anything and tells you which item to merge by hand.

## What is NOT shared (and leaks if you do not know)

These items live in each account's folder and do **not** go through the links:

| Item | Effect |
|---|---|
| `agents/`, `commands/`, `hooks/`, `CLAUDE.md` | apply only to the account that owns the folder |
| **`~/.claude/rules/`** | **applies to EVERY account**, even when another config folder is in use |

The last one is the trap: rules placed in `~/.claude/rules/` (the default account's folder) are read by every account. If you install a large rules pack there, **every** account loads it, which grows the context and the latency, and there is no way to enable it for just one account.

Recommendations:
- Keep `~/.claude/rules/` **empty** (or only with rules you want everywhere).
- A large pack (rules, agents, commands) that only one project needs: install it **in the project**, under `<project>/.claude/`, not in the user folder.
- To disable a pack you already installed without losing it: `mv` its folders somewhere else and note how to bring them back.

## Different plans, same config

Since there is a single `settings.json`, values like `model` apply to **every** account, including those on a smaller plan. If an account on a cheaper plan errors out on a model its plan does not include:

1. Check `model` in the shared `settings.json`.
2. Test that account with a minimal call:
   ```bash
   CLAUDE_CONFIG_DIR=~/.claude-NAME claude -p "reply with just: ok" --no-session-persistence
   ```
3. If the error is about the model, set `model` to one every plan accepts, or use `/model` inside that account's session.

(In testing, `model: "opus"` worked on a Pro plan. This depends on the plan and may change; test yours.)
