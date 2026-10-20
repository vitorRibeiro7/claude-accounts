🇺🇸 [Read in English](../shared-config.md)

# Uma configuração, vários logins

O objetivo: **instalar um plugin, uma skill ou mudar uma configuração uma vez e ter isso em todas as contas**. Só o **login** é separado por conta.

## Como o sistema já faz isso

Escolha uma conta como **base** (a que guarda a configuração de verdade). As outras apontam para ela por links simbólicos:

```
~/.claude-base/settings.json   ← arquivo de verdade
~/.claude-outra/settings.json  → link para o de cima
```

Itens compartilhados: `settings.json`, `plugins`, `skills`, `projects` (conversas), `file-history`, `history.jsonl`. O que **não** é compartilhado: o login (`.credentials.json` e o `.claude.json` de cada pasta; no macOS, o token fica no Keychain — veja [macos.md](macos.md)).

```bash
ca base NOME                      # define a BASE (uma vez só)
ca new NOVA                       # toda conta nova já nasce ligada à base
ca new NOVA --clean               # ... ou isolada, se não quiser nada compartilhado
ca stop                           # (só para conta que JÁ existe) sem sessão aberta nela
ca share OUTRA BASE               # liga uma conta que já existe à BASE
```

Resultado prático:
- instalou um plugin em qualquer conta → aparece nas outras;
- retomou uma conversa em qualquer conta → todas enxergam (`/resume`);
- mudou o tema, o modelo, as permissões → vale para todas.

## Qual conta deve ser a base?

Qualquer uma. Depois de ligadas, as contas são equivalentes: o que muda é só **onde os arquivos de verdade moram**.

- Se você usa as mesmas skills e plugins em projetos pessoais e de trabalho, faz sentido a base ser a conta **padrão** (`~/.claude`): fica uma coisa só, "a sua", e as contas de trabalho apenas apontam para ela.
- Se a conta padrão for de uso pessoal e você não quer isso misturado, escolha outra conta como base.

**Trocar a base depois** leva os arquivos de verdade para a conta nova e religa todas as outras, sem perder nada:

```bash
ca stop                 # a troca mexe em tudo que é compartilhado: nenhuma sessão aberta
ca base NOVA-BASE       # pede confirmação
ca list                 # confira: a nova base aparece marcada com (base)
```

Os caminhos antigos continuam funcionando, porque a pasta da base antiga passa a ter links para a nova. Se o mesmo item existir "de verdade" nas duas contas, o comando **recusa** antes de mexer em qualquer coisa e diz qual item juntar à mão.

## O que NÃO é compartilhado (e vaza se você não souber)

Estes itens vivem na pasta de cada conta e **não** passam pelos links:

| Item | Efeito |
|---|---|
| `agents/`, `commands/`, `hooks/`, `CLAUDE.md` | valem só para a conta dona da pasta |
| **`~/.claude/rules/`** | **vale para TODAS as contas**, mesmo quando você abre outra pasta de config |

O último é a armadilha: regras colocadas em `~/.claude/rules/` (a pasta da conta padrão) são lidas por qualquer conta. Se você instalar um pacote grande de regras ali, **todas** as contas passam a carregá-lo, aumentam o contexto e a latência, e não há como ligar só numa conta.

Recomendações:
- Deixe `~/.claude/rules/` **vazia** (ou só com regras que você quer em tudo).
- Pacote grande (de regras, agentes, comandos) que só serve para um projeto: instale **no projeto**, em `<projeto>/.claude/`, não na pasta de usuário.
- Para tirar um pacote já instalado sem perder: mova as pastas para uma pasta de guardados (`mv`), e anote como voltar.

Quer mudar a lista do que é compartilhado? Edite a variável `SHAREABLE` em `bin/claude-accounts` (veja [como-funciona.md](como-funciona.md)).

## Planos diferentes na mesma configuração

Como o `settings.json` é um só, valores como `model` valem para **todas** as contas, inclusive as de plano menor. Se uma conta de plano mais barato der erro ao usar um modelo que o plano dela não inclui:

1. Confira o `model` no `settings.json` compartilhado.
2. Teste a conta de plano menor com uma chamada mínima:
   ```bash
   CLAUDE_CONFIG_DIR=~/.claude-NOME claude -p "responda apenas: ok" --no-session-persistence
   ```
3. Se o erro for de modelo, troque o `model` para um que todos os planos aceitem, ou use `/model` dentro da sessão daquela conta.

O que cada plano aceita depende da Anthropic e pode mudar; teste na sua.
