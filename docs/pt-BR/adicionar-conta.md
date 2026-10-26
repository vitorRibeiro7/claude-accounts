🇺🇸 [Read in English](../adding-an-account.md)

# Adicionar uma conta

Cenário: você já tem o `claude-accounts` instalado e vai começar a usar **mais uma** conta do Claude (outro e-mail, outra empresa, outro cliente).

## Passo a passo

### 1. Escolha um nome

Minúsculas, números, `-` ou `_`. É o nome que você vai digitar no `ca`: `trabalho`, `cliente-x`, `freela`. Nomes de comandos (`list`, `ls`, `use`, `new`, `base`, `share`, `remove`, `rm`, `here`, `sessions`, `stop`, `lang`, `statusline`, `prompt`, `doctor`, `help`, `version`) são reservados.

### 2. Crie a conta

```bash
ca new freela
```

Isso cria a pasta `~/.claude-freela` e registra a conta na lista. **Ainda não tem login** — isso é o passo 4.

**Já nasce ligada à BASE.** Se você definiu uma base (`ca base NOME`, uma vez só), a conta nova já vem com os mesmos plugins, skills, configurações e conversas das outras, sem você digitar nada. Só o **login** fica separado.

```bash
ca base                        # mostra qual é a base
ca new freela                  # nasce ligada à base
ca new freela --clean          # nasce isolada: nada das outras (bom para conta de outra organização)
ca new freela --share pessoal  # liga a outra conta, em vez da base
```

### 3. Troque para ela

```bash
ca stop           # se houver sessões do Claude abertas
ca freela         # ou: ca use freela
```

### 4. Faça o login (a parte que mais dá dúvida)

```bash
claude
```

Dentro do Claude Code, digite `/login` e entre **com o e-mail da conta nova**. O navegador abre, você autoriza, e pronto.

> **Cuidado:** se o navegador já estiver logado em outra conta da Anthropic, ele pode autorizar a conta errada sem avisar. Use uma janela anônima ou saia da conta no navegador antes.

### 5. Confira

```bash
ca
# conta ativa: freela → /home/voce/.claude-freela · voce@exemplo.com
```

Se aparecer o e-mail certo, está pronto. Se aparecer `(sem login)`, o `/login` não terminou; repita o passo 4.

> As mensagens aparecem em inglês por padrão. Para vê-las em português, como nos exemplos deste guia: `ca lang pt-BR`.

## Conversas não aparecem na conta nova? (`/resume` vazio)

Cada conta guarda as **próprias** conversas. Uma conta criada com `--clean` (ou antes de existir uma base) nasce com o histórico vazio e **não enxerga as sessões das outras**: não dá para retomar, numa conta, uma conversa começada em outra.

Se você quer continuar em qualquer conta o que começou em outra, compartilhe (serve também para uma conta que já existe e já tem conversas):

```bash
ca stop                         # sem sessão aberta na conta que vai ser ligada
ca share NOVA PRINCIPAL         # liga as conversas, plugins e configurações da NOVA aos da PRINCIPAL
```

- O que a conta nova já tinha é **mesclado** na principal, nada é sobrescrito, e o original fica guardado como `<item>.before-share` (apague depois que conferir).
- É seguro repetir o comando.
- Só o **login** continua separado por conta.
- Escolha como "principal" a conta onde está o seu histórico completo.

## Daqui para frente

```bash
ca list           # veja todas
ca trabalho       # volte para outra quando quiser
claude            # sempre abre na conta ativa
```

## E se eu quiser que uma conta nova seja a minha "padrão" do Claude?

Não precisa. A conta padrão é só a que usa a pasta `~/.claude` (a que existia antes de instalar). As demais funcionam igual, só em pastas próprias. Veja [como-funciona.md](como-funciona.md).

## Dúvidas

- **"já existe uma conta chamada X"** → escolha outro nome (`ca list` mostra os usados).
- **"~/.claude-X já existe"** → sobrou uma pasta de uma conta antiga. Apague-a ou escolha outro nome.
- **Posso ter quantas contas quiser?** Sim. Cada uma é só uma pasta e uma linha na lista.
- **No macOS** o login fica no Keychain, não na pasta; veja [macos.md](macos.md).
