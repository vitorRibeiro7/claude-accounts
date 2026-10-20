# Changelog

All notable changes are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/)
and the project uses [Semantic Versioning](https://semver.org/).

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

[1.0.0]: https://github.com/vitorRibeiro7/claude-accounts/releases/tag/v1.0.0
