🇺🇸 [Read in English](../status-line.md)

# Status line e prompt do terminal

Saiba sempre em qual conta você vai gastar.

## Dentro do Claude Code

```bash
ca statusline --install
```

Isso adiciona uma `statusLine` nas configurações da conta que vale aqui. Reinicie o Claude Code e a barra de baixo mostra:

```
● trabalho · voce@empresa.com
```

- A conta é lida da própria sessão (`CLAUDE_CONFIG_DIR`), então cada janela mostra **a sua** conta, mesmo com várias abertas.
- Se as contas compartilham uma base, o `settings.json` é um só e um `--install` vale para todas.
- Já tem uma status line? O `--install` não sobrescreve. Chame o comando a partir do seu script:
  ```bash
  #!/usr/bin/env bash
  input="$(cat)"
  echo "$(echo "$input" | ~/.local/share/claude-accounts/bin/claude-accounts statusline) | $(outra-coisa)"
  ```
- Configuração manual, no `settings.json`:
  ```json
  "statusLine": { "type": "command", "command": "~/.local/share/claude-accounts/bin/claude-accounts statusline" }
  ```

## No prompt do terminal

O `ca prompt` imprime a conta que vale na pasta atual (fixada na pasta, `CLAUDE_ACCOUNT` ou global). Não imprime nada se der erro, então não quebra o seu prompt.

**starship** (`~/.config/starship.toml`):

```toml
[custom.claude]
command = "claude-accounts prompt"
when = "command -v claude-accounts"
format = "[✻ $output]($style) "
style = "bold cyan"
```

**powerlevel10k** (`~/.p10k.zsh`): adicione `claude_account` em `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS` e depois:

```zsh
function prompt_claude_account() {
  local a; a="$(claude-accounts prompt)"
  [[ -n $a ]] && p10k segment -f 81 -t "✻ $a"
}
```

**zsh / bash puro:**

```bash
# zsh
setopt PROMPT_SUBST; PROMPT='%F{cyan}$(claude-accounts prompt)%f '"$PROMPT"
# bash
PS1='\[\e[36m\]$(claude-accounts prompt)\[\e[0m\] '"$PS1"
```
