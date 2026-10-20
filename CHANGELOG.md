# Changelog

All notable changes are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/)
and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed
- `claude-auto` reattaches when the directory's last conversation became a background session
  (`claude attach <id>`, found with `claude agents --json`), instead of dead-ending on
  `--continue`'s "moved to a background session" error. If the session belongs to another account
  that shares `projects/`, it reattaches with that account. It never starts a new session on its
  own: when nothing works, it says how to resume and stops.

### Changed
- `ca here` keeps the pin out of git automatically: inside a repo it adds `.claude-account` to
  `.git/info/exclude` (local, not versioned) instead of printing a tip. It warns if the file was
  already committed.

## [1.1.0] - 2026-10-20

### Added
- **Per-project accounts**: `ca here NAME` writes a `.claude-account` file; `claude` and `claude-auto`
  use it in that folder and every subfolder. `ca here --unset` removes it.
- `CLAUDE_ACCOUNT=NAME` to pick the account for one command or terminal.
- Sessions on different accounts can run at the same time.
- `ca statusline [--install]`: account and email in Claude Code's status line.
- `ca prompt`: account name for shell prompts (starship, powerlevel10k, PS1).
- Tab completion for zsh and bash (commands, account names, flags).
- `ca` and `ca list` show which account applies here and why.

### Changed
- A pin or `CLAUDE_ACCOUNT` naming a missing account makes `claude` refuse to start instead of
  falling back to another account.
- The installer replaces an older rc block, so upgrades pick up new lines.

## [1.0.0] - 2026-10-20

### Added
- `ca` CLI: `list`, `use`, `new` (`--clean`, `--share`), `base`, `share`, `remove` (`--delete-dir`),
  `sessions`, `stop`, `lang`, `doctor`, `version`, `help`.
- `claude` wrapper that runs Claude Code on the active account, and `claude-auto` that continues
  the directory's last conversation when there is one.
- Shared setup through a **base** account (settings, plugins, skills, conversations), logins kept separate.
- macOS support (stock bash 3.2), portable session registry, no Python dependency.
- English and Brazilian Portuguese UI and docs.
- One-line installer with automatic migration from `claude-contas`.
- Test suite in a fake `HOME`, CI on Linux and macOS, shellcheck.

[1.1.0]: https://github.com/vitorRibeiro7/claude-accounts/releases/tag/v1.1.0
[1.0.0]: https://github.com/vitorRibeiro7/claude-accounts/releases/tag/v1.0.0
