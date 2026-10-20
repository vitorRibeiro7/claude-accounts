🇺🇸 [Read in English](../separate-default-account.md)

# Separar o login da conta padrão (sem logar de novo)

> **macOS:** o procedimento abaixo **não vale como está**. No macOS o Claude Code guarda o token no Keychain, não em `~/.claude/.credentials.json`, então não há arquivo de token para mover. Lá, crie a conta nova (`ca new trabalho`), troque para ela e rode `/login` de novo. Veja [macos.md](macos.md).

## O problema

A pasta `~/.claude` é a conta **padrão** do Claude Code: é a que abre quando nenhuma variável está definida, e é a que a maioria das ferramentas e das atualizações assume. Quem começa com uma conta só costuma logar nela, e ela vira, sem querer, a "conta de tudo".

Depois que você adiciona outras contas, isso confunde: a conta padrão vira uma conta de trabalho qualquer, com um e-mail específico, mas continua sendo a "primeira". Fica difícil dizer qual é a principal, e qualquer coisa que use o padrão (um anel de uso, um programa que chama `claude` direto) mostra aquela conta.

A solução limpa: **a conta padrão fica para o seu uso pessoal (ou vazia), e cada login de trabalho vive numa pasta com nome**.

## Mover o login da padrão para uma conta nomeada (Linux/WSL)

Sem precisar de novo `/login`. Exemplo movendo o login atual da padrão para uma conta chamada `trabalho`:

**0. Feche tudo na conta padrão**

```bash
ca sessions         # nenhuma sessão deve estar em ".claude"
ca stop             # se houver
```

**1. Crie a pasta e leve o login**

```bash
umask 077
mkdir -p ~/.claude-trabalho
cp -p ~/.claude.json ~/.claude-trabalho/.claude.json          # dados da conta (e-mail, plano)
mv    ~/.claude/.credentials.json ~/.claude-trabalho/.credentials.json   # o token
```

- O token é **movido**, não copiado. Duas cópias do mesmo token de login se invalidam entre si quando uma delas renova.
- O `~/.claude.json` fica também na padrão por enquanto; o passo 3 tira o login dele.

**2. Teste ANTES de limpar a padrão**

```bash
CLAUDE_CONFIG_DIR=~/.claude-trabalho claude
# dentro dele: /status (ou /usage) → deve mostrar o e-mail e o plano certos
```

Se algo estiver errado, desfaça:
```bash
mv ~/.claude-trabalho/.credentials.json ~/.claude/.credentials.json
```

**3. Tire o login da padrão**

Com `jq`:

```bash
umask 077
jq 'del(.oauthAccount)' ~/.claude.json > ~/.claude.json.tmp && mv ~/.claude.json.tmp ~/.claude.json
```

Ou, se preferir, com `python3` (precisa estar instalado; o `claude-accounts` em si não usa python):

```bash
python3 - <<'PY'
import json, os, tempfile
p = os.path.expanduser('~/.claude.json')
d = json.load(open(p))
d.pop('oauthAccount', None)
fd, t = tempfile.mkstemp(dir=os.path.dirname(p)); os.fchmod(fd, 0o600)
with os.fdopen(fd, 'w') as f: json.dump(d, f)
os.replace(t, p)
PY
```

A padrão fica deslogada. Para usá-la como pessoal: `ca NOME-DA-PADRAO`, `claude`, `/login` com o e-mail pessoal.

**4. Registre as contas no `ca`**

Edite `~/.config/claude-accounts/accounts` (uma conta por linha, `nome=pasta`). A padrão ganha um nome novo e a conta movida entra com o dela:

```
pessoal=~/.claude
trabalho=~/.claude-trabalho
```

Se você renomeou a conta que estava ativa ou era a base, atualize também `~/.config/claude-accounts/active` e `~/.config/claude-accounts/base` (cada um tem só o nome da conta).

**5. Ligue a conta nova à configuração compartilhada**

```bash
ca share trabalho BASE      # BASE = a conta que guarda a configuração (veja configuracao-compartilhada.md)
ca list                     # confira os e-mails
```

**6. Se você usa o Maestri**, o anel de uso da conta padrão precisa mudar de nome e a conta movida ganha o seu: veja [maestri.md](maestri.md).

## Depois disso

- `ca list` mostra cada conta com o e-mail certo.
- O que usa a conta padrão (anel, programas) passa a mostrar a conta **pessoal**, previsível.
- Nenhum login de trabalho depende de ser "a primeira conta".

> A padrão como conta pessoal fica **sem login** até você entrar nela. Isso é normal: o `ca list` mostra `(sem login)` para ela (com `ca lang pt-BR`; em inglês, `(not logged in)`).
