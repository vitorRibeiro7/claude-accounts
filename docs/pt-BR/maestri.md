🇺🇸 [Read in English](../maestri.md)

# Maestri (e programas parecidos)

Este guia existe porque o Maestri tem duas coisas que usam o Claude e que **quebram em silêncio** quando a conta ativa muda: os **terminais/agentes** e os **anéis de uso**. A solução é diferente para cada um.

Os exemplos são do Maestri no Windows chamando o Claude do WSL. O mesmo raciocínio serve para outros programas que abrem o `claude` por conta própria (e para o Maestri em outros sistemas, trocando a forma de chamar o shell).

## 1. Terminais, agentes e presets → `claude-auto`

Em todo preset (agente, terminal, "Claude Code"…), troque o comando por:

```
claude-auto
```

Ele abre o Claude **na conta ativa** (`ca`) e **continua a conversa do diretório** se existir, ou começa uma nova. Isso é necessário porque o Maestri abre cada agente numa pasta nova (`.maestri/roles/<id>`), e `claude --continue` falha em pasta que nunca teve sessão.

Para trocar tudo de conta de uma vez: feche as sessões (`ca stop`), `ca NOME`, abra de novo.

> Se o comando não for encontrado, o Maestri provavelmente não vê o PATH do WSL. Use o caminho completo: `~/.local/share/claude-accounts/bin/claude-auto`.

## 2. Anéis de uso → um provider por conta, chamando o binário real

O Maestri mostra o consumo do plano de cada conta. (No terminal, `ca usage` mostra os mesmos números de todas as contas de uma vez.) Ele guarda isso em arquivos JSON (um por conta):

```
C:\Users\<você>\.maestri\usage\providers\<id>.json
```

O próprio Maestri escreve um `AGENTS.md` nessa pasta explicando o formato. Ele **relê a pasta a cada 15 segundos**.

### O que dá errado

O provider que vem de fábrica (`claude.json`) roda o comando `claude`. Com o `claude-accounts` instalado, esse comando é o **wrapper**, que abre a **conta ativa**. Resultado: o anel "Claude" passa a mostrar o uso de quem estiver ativo, e não da conta que o nome diz. Outra falha comum: um provider apontando para uma pasta que foi renomeada, que passa a ler uma pasta vazia.

### A correção

Cada provider chama o **binário real** (sem o wrapper), com a pasta da conta dele definida explicitamente:

- **Conta nomeada:** `CLAUDE_CONFIG_DIR="$HOME/.claude-NOME"`
- **Conta padrão (`~/.claude`):** `unset CLAUDE_CONFIG_DIR` (o login dela mora em `~/.claude.json`, fora da pasta; veja [como-funciona.md](como-funciona.md))

O binário real vem de `~/.config/claude-accounts/config` (`CLAUDE_REAL`), gravado pelo `install.sh`; assim o provider não quebra se o Claude mudar de lugar.

### Criar o provider de uma conta nova

Há um modelo pronto em [`examples/maestri-usage-provider.json`](../../examples/maestri-usage-provider.json), com `__ID__` (minúsculo, igual ao nome do arquivo), `__NAME__` (o que aparece no anel) e `__DIR__` (a pasta da conta) para trocar. Exemplo para a conta `trabalho` (pasta `.claude-trabalho`), rodado na raiz do repositório:

```bash
PROV=/mnt/c/Users/SEU-USUARIO-WINDOWS/.maestri/usage/providers
sed -e 's/__ID__/trabalho/g' -e 's/__NAME__/Trabalho/g' -e 's/__DIR__/.claude-trabalho/g' \
    examples/maestri-usage-provider.json > "$PROV/claude-trabalho.json"
```

O `id` só aceita **minúsculas, números e hífen** e tem de ser igual ao nome do arquivo (sem `.json`).

Em até 15 segundos o anel aparece em *Settings → Agents → Usage*; se houver erro no arquivo, ali aparece a mensagem exata.

### Corrigir o provider de fábrica (conta padrão)

Edite `claude.json` para o comando terminar assim (a conta padrão, sem a variável):

```
. "$HOME/.config/claude-accounts/config"; unset CLAUDE_CONFIG_DIR; exec "$CLAUDE_REAL" -p --input-format stream-json --output-format stream-json --verbose --no-session-persistence
```

e a fonte (`source`) usando `"executable": "wsl"` e `"args": ["-e", "bash", "-lc", "<o comando acima>"]`, como no modelo.

Editar o de fábrica marca-o como **Modified**; *Restore Default* volta ao original (e o anel volta a seguir a conta ativa).

### Testar sem abrir o Maestri

Rode o comando do provider como o Maestri roda (ambiente mínimo):

```bash
REQ='{"type":"control_request","request_id":"u","request":{"subtype":"get_usage","skip_behaviors":true}}'
printf '%s\n' "$REQ" | env -i HOME="$HOME" PATH=/usr/bin:/bin timeout 40 bash -lc '<comando do provider>' \
  | grep '"request_id":"u"'
```

Deve voltar um JSON com `subscription_type` (o plano) e `rate_limits`. Se cada provider devolver um plano/percentual **diferente**, os anéis estão separados corretamente.

## Cuidados

- **Não deixe backups dentro da pasta `providers`**: o Maestri carrega o que está lá. Guarde cópias fora.
- **Conta sem login** (`ca list` mostra `(sem login)`): o anel dela fica com erro ou vazio até você fazer o login.
- **Renomeou a pasta de uma conta?** Atualize o provider dela (e `~/.config/claude-accounts/accounts`, e o alias, se houver).
- **As atualizações dos anéis são processos curtos do Claude.** Enquanto um roda (alguns segundos, de tempos em tempos), `ca NOME` conta ele como sessão aberta no aviso, e `ca share` / `ca base` recusam até ele terminar; é só tentar de novo. No macOS esses processos não passam pelo wrapper e aparecem como `(desconhecida)` no `ca sessions` (veja [como-funciona.md](como-funciona.md#sessões)).
- **Veio do `claude-contas`?** Providers antigos leem `~/.config/claude-contas/config`. Troque para `~/.config/claude-accounts/config`.
