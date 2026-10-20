🇧🇷 [Leia em português](pt-BR/status-line.md)

# Status line & shell prompt

Always know which account you're about to spend.

## Inside Claude Code

```bash
ca statusline --install
```

This adds a `statusLine` to the settings of the account in effect. Restart Claude Code and the bottom bar shows:

```
● work · you@company.com
```

- It reads the account from the session itself (`CLAUDE_CONFIG_DIR`), so every window shows **its own** account, even with several open.
- If your accounts share a base, `settings.json` is shared, so one `--install` covers all of them.
- Already have a status line? `--install` won't overwrite it. Call the command from your own script instead:
  ```bash
  #!/usr/bin/env bash
  input="$(cat)"
  echo "$(echo "$input" | ~/.local/share/claude-accounts/bin/claude-accounts statusline) | $(your-other-thing)"
  ```
- Manual setup, in `settings.json`:
  ```json
  "statusLine": { "type": "command", "command": "~/.local/share/claude-accounts/bin/claude-accounts statusline" }
  ```

## In your shell prompt

`ca prompt` prints the account in effect for the current folder (pin, `CLAUDE_ACCOUNT` or global). It prints nothing on errors, so it can't break your prompt.

**starship** (`~/.config/starship.toml`):

```toml
[custom.claude]
command = "claude-accounts prompt"
when = "command -v claude-accounts"
format = "[✻ $output]($style) "
style = "bold cyan"
```

**powerlevel10k** (`~/.p10k.zsh`): add `claude_account` to `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS`, then:

```zsh
function prompt_claude_account() {
  local a; a="$(claude-accounts prompt)"
  [[ -n $a ]] && p10k segment -f 81 -t "✻ $a"
}
```

**Plain zsh / bash:**

```bash
# zsh
setopt PROMPT_SUBST; PROMPT='%F{cyan}$(claude-accounts prompt)%f '"$PROMPT"
# bash
PS1='\[\e[36m\]$(claude-accounts prompt)\[\e[0m\] '"$PS1"
```
