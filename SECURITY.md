# Security policy

`claude-accounts` never reads, copies or transmits credentials: it only sets `CLAUDE_CONFIG_DIR`
and reads the account email from `.claude.json` for display.

If you find a way it could leak a login, mix up accounts, or delete data it shouldn't, please
**do not open a public issue**. Report it privately through
[GitHub Security Advisories](https://github.com/vitorRibeiro7/claude-accounts/security/advisories/new).
You'll get a reply within a few days.
