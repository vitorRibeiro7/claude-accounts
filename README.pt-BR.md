<div align="center">

# claude-accounts

**Troque entre várias contas do Claude Code (pessoal, trabalho, cliente) com um comando.**<br>
Sem ficar fazendo logout/login. Plugins, skills e configurações compartilhados. Logins separados.

[![CI](https://github.com/vitorRibeiro7/claude-accounts/actions/workflows/ci.yml/badge.svg)](https://github.com/vitorRibeiro7/claude-accounts/actions/workflows/ci.yml)
![Plataformas](https://img.shields.io/badge/plataforma-macOS%20%7C%20Linux%20%7C%20WSL-blue)
![Shell](https://img.shields.io/badge/bash-3.2%2B-4EAA25)
[![Licença: MIT](https://img.shields.io/badge/licen%C3%A7a-MIT-yellow.svg)](LICENSE)

🇺🇸 [Read in English](README.md)

</div>

```console
$ ca list
* pessoal              ~/.claude                          voce@gmail.com
  trabalho (base)      ~/.claude-trabalho                 voce@empresa.com
  cliente-x            ~/.claude-cliente-x                voce@cliente-x.com

$ ca trabalho      # troca
conta ativa: trabalho → /home/voce/.claude-trabalho · voce@empresa.com

$ claude           # o Claude Code abre na conta do trabalho
```

## Por quê

O Claude Code guarda um login por pasta de configuração. Se você tem uma assinatura pessoal *e* uma do trabalho, trocar significa `/logout`, `/login`, navegador, de novo e de novo, e seus plugins, skills e histórico de conversas não vêm junto.

O `claude-accounts` dá a cada conta a sua pasta e troca entre elas definindo o [`CLAUDE_CONFIG_DIR`](https://docs.claude.com/en/docs/claude-code/settings) por você:

- ⚡ **Um comando para trocar**: `ca trabalho`, depois `claude`. Só isso.
- 🔐 **Logins separados**: cada conta guarda as próprias credenciais; nada é copiado nem compartilhado.
- 🧩 **Configuração compartilhada**: instale um plugin ou skill uma vez e tenha em todas as contas (opcional, por conta).
- 💬 **Retome conversas entre contas**: histórico compartilhado, então o `/resume` funciona em qualquer conta.
- 🛡️ **Seguro por padrão**: recusa trocar com sessão aberta, nunca apaga pasta sem perguntar e guarda backup de tudo que religa.
- 🪶 **Pequeno e sem dependências**: três scripts bash. Sem Node, sem Python, sem daemon. Funciona com o bash 3.2 de fábrica do macOS.

## Instalar

Precisa do [Claude Code](https://docs.claude.com/en/docs/claude-code) já instalado.

```bash
curl -fsSL https://raw.githubusercontent.com/vitorRibeiro7/claude-accounts/main/install.sh | bash -s -- --lang pt-BR
```

<details>
<summary>Ou clone (recomendado se quiser ler o código antes)</summary>

```bash
git clone https://github.com/vitorRibeiro7/claude-accounts ~/claude-accounts
cd ~/claude-accounts
./install.sh --lang pt-BR      # opção: --name pessoal
```
</details>

O instalador pergunta que nome dar à conta que você **já** usa (ex.: `pessoal`) e adiciona um pequeno bloco marcado no seu `~/.zshrc` / `~/.bashrc` / `~/.bash_profile`. Abra um terminal novo e confira:

```bash
ca doctor
```

As mensagens ficam em português com `--lang pt-BR` (ou depois, com `ca lang pt-BR`). Os comandos são sempre em inglês.

> **Vindo do `claude-contas`?** O instalador importa suas contas, a ativa e a base sozinho, e remove o bloco antigo do `.zshrc`. Veja [docs/pt-BR/reinstalar-do-zero.md](docs/pt-BR/reinstalar-do-zero.md).

## Começo rápido: adicionar uma segunda conta

```bash
ca new trabalho    # 1. cria (já ligada à configuração compartilhada)
ca trabalho        # 2. troca para ela
claude             # 3. abre o Claude Code; rode /login com o e-mail do trabalho
ca                 # 4. confira: mostra o e-mail do trabalho
```

Volte quando quiser com `ca pessoal`. Guia completo: [docs/pt-BR/adicionar-conta.md](docs/pt-BR/adicionar-conta.md).

> **Dica:** se o navegador já estiver logado em outra conta da Anthropic, o `/login` pode autorizar essa conta sem avisar. Use uma janela anônima.

## Comandos

| Comando | O que faz |
|---|---|
| `ca` | mostra a conta ativa e o e-mail |
| `ca list` | todas as contas; `*` marca a ativa |
| `ca NOME` / `ca use NOME` | troca para NOME (recusa se houver sessão aberta) |
| `ca new NOME [--clean \| --share OUTRA]` | cria conta: ligada à base por padrão, isolada com `--clean` |
| `ca base [NOME]` | mostra / troca a **base**: a conta que guarda plugins, skills e configurações compartilhados |
| `ca share NOME OUTRA` | liga conversas/plugins/configurações de uma conta existente aos de OUTRA |
| `ca remove NOME [--delete-dir]` | tira da lista (a pasta só é apagada com `--delete-dir`) |
| `ca sessions` | sessões do Claude abertas e suas contas |
| `ca stop` | encerra todas as sessões (pede confirmação) |
| `ca lang [en\|pt-BR]` | idioma das mensagens |
| `ca doctor` | confere a instalação |
| `claude` | Claude Code na conta ativa |
| `claude-auto` | igual, mas continua a última conversa do diretório se houver; ótimo para IDEs e presets de terminal |

## Configuração compartilhada, logins separados

Escolha uma conta como **base** e toda conta nova se liga a ela:

```bash
ca base pessoal              # uma vez só
ca new trabalho              # trabalho passa a ver plugins, skills, configurações e histórico da pessoal
ca new cliente-x --clean     # ...ou deixe um cliente totalmente isolado
```

O que é compartilhado: `settings.json`, `plugins/`, `skills/`, `projects/` (conversas), `file-history/`, `history.jsonl`.
O que **nunca** é compartilhado: o login. Detalhes e armadilhas: [docs/pt-BR/configuracao-compartilhada.md](docs/pt-BR/configuracao-compartilhada.md).

## Como funciona

```
você digita:  claude
   → o wrapper (primeiro no PATH) pergunta ao `ca` a pasta da conta ativa
   → exporta CLAUDE_CONFIG_DIR=~/.claude-trabalho
   → executa o claude de verdade
```

O estado é texto puro em `~/.config/claude-accounts/`. A conta padrão (`~/.claude`) tem tratamento especial porque o login dela fica fora da pasta. Explicação completa com diagramas: [docs/pt-BR/como-funciona.md](docs/pt-BR/como-funciona.md).

## Documentação

- [Adicionar conta](docs/pt-BR/adicionar-conta.md) · [Remover conta](docs/pt-BR/remover-conta.md)
- [Configuração compartilhada entre contas](docs/pt-BR/configuracao-compartilhada.md)
- [Separar o login da conta padrão](docs/pt-BR/conta-padrao-separada.md)
- [Notas de macOS](docs/pt-BR/macos.md)
- [Reinstalar do zero](docs/pt-BR/reinstalar-do-zero.md)
- [Integração com o Maestri](docs/pt-BR/maestri.md) (presets com `claude-auto`, anéis de uso por conta)
- [Como funciona](docs/pt-BR/como-funciona.md)

## Perguntas frequentes

**Isso é permitido?** A ferramenta só automatiza o `CLAUDE_CONFIG_DIR`, uma configuração oficial do Claude Code. Use com contas que são legitimamente suas (ex.: pessoal e a da empresa) e siga os [termos da Anthropic](https://www.anthropic.com/legal/consumer-terms). **Não** é para alternar contas e driblar limites de uso.

**Ela lê ou mexe nas minhas credenciais?** Não. Nunca abre arquivos de token. Só lê o e-mail que aparece no `.claude.json` para mostrar na tela.

**Uma IDE / ferramenta abre o Claude na conta errada.** Provavelmente ela não lê o rc do shell e chama o `claude` real. Aponte para o `claude-auto` (caminho completo: `~/.local/share/claude-accounts/bin/claude-auto`) e rode `ca doctor`.

**fish / nushell?** O instalador ainda não configura. Adicione `~/.local/share/claude-accounts/bin` ao `PATH` e um alias `ca` para `claude-accounts`. PRs são bem-vindos.

**O Claude Code atualizou e algo quebrou?** Rode `ca doctor`; rodar o `install.sh` de novo atualiza o caminho do binário real.

## Desinstalar

```bash
curl -fsSL https://raw.githubusercontent.com/vitorRibeiro7/claude-accounts/main/install.sh | bash -s -- --uninstall
# ou, de um clone:  ./install.sh --uninstall
```

Remove o bloco do PATH e os scripts; suas contas e logins ficam intactos.

## Contribuir

Issues e PRs são bem-vindos; veja [CONTRIBUTING.md](CONTRIBUTING.md). Os testes rodam num `HOME` falso e nunca mexem nas suas contas:

```bash
./tests/test.sh
```

## Licença

[MIT](LICENSE)
