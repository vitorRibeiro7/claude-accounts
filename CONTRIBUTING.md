# Contributing

Thanks for helping! The whole tool is a few small bash scripts, so changes are easy to review.

1. **Run the tests** — they use a fake `HOME` and never touch your real accounts:
   ```bash
   ./tests/test.sh
   ```
2. **Stay portable.** Scripts must run on Linux, WSL and macOS with the stock **bash 3.2**:
   no `sed -i`, no `mapfile`, no `${var,,}`, no GNU-only flags. CI runs the suite on
   `ubuntu-latest` and `macos-latest` (bash 3.2) plus `shellcheck`.
3. **Messages are bilingual.** User-facing text goes through `t "english" "português"` /
   `say` / `die` in `bin/claude-accounts`. If you don't speak Portuguese, write the English
   one and leave the Portuguese for review.
4. **Docs** live in `docs/` (English) and `docs/pt-BR/` (Portuguese). Update both when behavior changes.
5. Use [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:` …).
