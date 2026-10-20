🇺🇸 [Read in English](../macos.md)

# macOS

O `claude-accounts` funciona no macOS do mesmo jeito que no Linux/WSL. Esta página reúne o que é diferente.

## Instalação

```bash
curl -fsSL https://raw.githubusercontent.com/vitorRibeiro7/claude-accounts/main/install.sh | bash
```

- **zsh** (o shell padrão do macOS): o bloco `# >>> claude-accounts >>>` vai para o `~/.zshrc`, que é criado se não existir.
- **bash**: vai para o `~/.bash_profile` (é ele que o Terminal do macOS lê), também criado se faltar.
- Funciona com o **bash 3.2** que vem de fábrica no macOS; não precisa instalar um bash novo.
- **Não precisa de python.** Se houver `jq` (`brew install jq`), ele é usado para ler o e-mail das contas; sem ele, o `sed` resolve.

Abra um terminal novo e confira com `ca doctor`.

## Login: fica no Keychain, não na pasta

No macOS o Claude Code guarda o token de login no **Keychain**, e não em `<pasta da conta>/.credentials.json` como no Linux. Na prática:

- **Cada conta faz o próprio `/login`.** Crie a conta (`ca new NOME`), troque para ela (`ca NOME`), abra o `claude` e rode `/login`.
- O procedimento de "mover o login sem logar de novo" de [conta-padrao-separada.md](conta-padrao-separada.md) **não vale como está**: não há `.credentials.json` para mover. No macOS, rode `/login` de novo na conta nova (e, se quiser, deslogue a padrão com `/logout` nela).
- Os backups que excluem `.credentials.json` ([reinstalar-do-zero.md](reinstalar-do-zero.md)) continuam corretos; o token simplesmente não está ali.

Cada `CLAUDE_CONFIG_DIR` tem o seu login: o Claude Code separa as entradas do Keychain por pasta de configuração. Sendo honesto: isso depende de como o Claude Code faz esse armazenamento, que é dele e pode mudar entre versões. Se duas contas parecerem compartilhar o mesmo login (o `ca list` mostra o mesmo e-mail, ou um `/login` numa conta troca o da outra), [abra uma issue](https://github.com/vitorRibeiro7/claude-accounts/issues) com a versão do Claude Code (`claude --version`).

## Sessões

`ca sessions` e `ca stop` funcionam no macOS: o wrapper registra cada sessão que abre em `~/.config/claude-accounts/sessions/<pid>`, com a conta e o diretório.

Sessões abertas **sem passar pelo wrapper** (por uma IDE ou ferramenta que chama o `claude` real direto) ainda são encontradas pelo nome do processo, mas o macOS não tem `/proc` para dizer de qual conta são. Elas aparecem como conta `(desconhecida)`, e o `ca share` recusa enquanto houver uma aberta, por cautela. Feche-as (ou `ca stop`) e tente de novo.

## Ferramentas e IDEs

Apps abertos pelo Finder/Dock não leem o `~/.zshrc`, então não enxergam o wrapper e abrem o `claude` real **na conta padrão**. Configure o comando do Claude neles para:

```
~/.local/share/claude-accounts/bin/claude-auto
```

Ele usa a conta ativa, continua a conversa do diretório se houver, e registra a sessão (então ela aparece certinha no `ca sessions`). Veja também [maestri.md](maestri.md).
