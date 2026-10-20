🇺🇸 [Read in English](../reinstall-from-scratch.md)

# Reinstalar do zero

Guia para quando a máquina foi formatada, o WSL foi recriado, você trocou de computador ou algo quebrou e é preciso montar tudo de novo. Foi escrito para ser seguido **sem lembrar de nada**.

Dica: mantenha, fora de qualquer repositório, uma anotação sua com os nomes das contas, o e-mail de cada uma, o que compartilha com o quê e os programas que chamam `claude-auto`. É o que mais se esquece.

---

## 0. O que se perde e o que não se perde

| Item | Onde fica | Reinstalando |
|---|---|---|
| Os scripts (`ca`, wrapper, `claude-auto`) | o repositório `claude-accounts` | volta com o `install.sh` |
| A lista de contas, a ativa e a base | `~/.config/claude-accounts/` | **perde**: recrie (passo 5) |
| O **login** de cada conta | dentro da pasta de cada conta (no macOS, no Keychain) | **perde**: refaça `/login` em cada uma |
| Configurações, plugins, skills, conversas, memória | pasta de cada conta (`~/.claude`, `~/.claude-NOME`) | **perde, se não tiver backup** |
| O bloco de PATH/alias | `~/.zshrc` / `~/.bashrc` / `~/.bash_profile` | volta com o `install.sh` |

O que dói de verdade perder **não é o login** (é só entrar de novo) e sim o conteúdo das pastas: `settings.json`, `plugins/`, `skills/`, `CLAUDE.md`, `rules/`, a memória e o histórico em `projects/`. Isso **não está no git**. Veja o passo 1.

---

## 1. Antes de qualquer desastre: o backup

Faça periodicamente (ou antes de formatar/reinstalar o WSL):

```bash
# uma cópia de TODAS as pastas de conta, sem os arquivos de login
tar czf ~/claude-accounts-backup-$(date +%F).tgz \
  --exclude='.credentials.json' \
  -C ~ .claude $(cd ~ && ls -d .claude-* 2>/dev/null) \
  .config/claude-accounts
```

- `--exclude='.credentials.json'` deixa os tokens de login **fora** do backup. Guarde o arquivo num lugar seu (outro disco, nuvem pessoal) e não em repositório. O backup sem login é só uma pasta de configurações; o login se refaz.
- `~/.claude.json` (na home) guarda o login da **conta padrão**. Também fica de fora de propósito.
- Para o WSL: o jeito mais simples de ter um backup completo é `wsl --export <distro> arquivo.tar` no PowerShell do Windows (guarda tudo, inclusive logins; trate o arquivo como segredo).

Restaurar:

```bash
tar xzf claude-accounts-backup-AAAA-MM-DD.tgz -C ~
```

---

## 2. Instalar o Claude Code

Siga a instalação oficial do Claude Code para o seu sistema. Confirme:

```bash
claude --version
command -v claude        # anote o caminho; o install.sh o encontra sozinho
```

Também precisam existir `bash` e `curl` (ou `git`, se for clonar). Python **não** é necessário; se houver `jq`, ele é usado para ler o e-mail das contas.

> **Não faça login ainda.** O `/login` deve ser feito *depois* de as contas existirem (passo 6); senão o login cai na pasta padrão e você precisa descobrir de qual conta ele é.

---

## 3. Instalar o `claude-accounts`

Em uma linha:

```bash
curl -fsSL https://raw.githubusercontent.com/vitorRibeiro7/claude-accounts/main/install.sh | bash
```

Ou clonando o repositório:

```bash
git clone https://github.com/vitorRibeiro7/claude-accounts ~/claude-accounts
cd ~/claude-accounts
./install.sh
```

Opções úteis: `--name NOME` (nomeia a conta padrão sem perguntar) e `--lang pt-BR` (mensagens em português). Exemplo: `./install.sh --name pessoal --lang pt-BR`.

O instalador:
1. encontra o `claude` de verdade e grava o caminho em `~/.config/claude-accounts/config`;
2. copia os scripts para `~/.local/share/claude-accounts/bin/`;
3. pergunta **o nome da conta padrão** (a que usa a pasta `~/.claude`), se ainda não houver contas;
4. adiciona o bloco `# >>> claude-accounts >>>` (PATH e alias `ca`) ao `~/.zshrc`, `~/.bashrc` e/ou `~/.bash_profile`, com backup `*.bak-claude-accounts`.

É seguro rodar de novo. Para desinstalar (mantém contas e logins): `./install.sh --uninstall`.

Abra um terminal **novo** (ou `source ~/.zshrc`) e confirme:

```bash
command -v claude      # deve ser .../claude-accounts/bin/claude  (o wrapper), e NÃO o claude de verdade
ca list                # deve mostrar a conta padrão
ca doctor              # confere binário real, PATH, conta ativa e login
```

Se `command -v claude` mostra o binário real, o PATH não pegou: veja "Problemas" abaixo.

---

## 4. Vindo do `claude-contas`

Se a máquina já tinha o `claude-contas` (a versão anterior, só em português), o instalador migra sozinho:

- copia `contas`, `ativa` e `base` de `~/.config/claude-contas/` para `accounts`, `active` e `base` em `~/.config/claude-accounts/` (a pasta antiga fica intacta);
- remove o bloco antigo `# >>> claude-contas >>>` dos arquivos do shell e põe o novo;
- deixa as mensagens em português (`ca lang pt-BR`).

As pastas das contas e os logins não mudam. O que muda são os comandos, agora em inglês: `ca lista` → `ca list`, `ca nova` → `ca new`, `ca compartilhar` → `ca share`, `ca remover` → `ca remove`, `ca sessoes` → `ca sessions`, `ca parar` → `ca stop`; e as opções `--limpa` → `--clean`, `--compartilhar` → `--share`, `--apagar-pasta` → `--delete-dir`. Se você tem providers do Maestri ou atalhos apontando para `~/.local/share/claude-contas/bin` ou `~/.config/claude-contas/config`, atualize os caminhos para `claude-accounts`. Depois de conferir, pode apagar `~/.local/share/claude-contas` e `~/.config/claude-contas`.

Os backups `*.antes-de-compartilhar` criados pela versão antiga continuam onde estão; os novos se chamam `*.before-share`.

---

## 5. Recriar as outras contas

Uma vez por conta, **com os mesmos nomes de antes**:

```bash
ca base NOME-1                  # opcional: a conta que guarda plugins/skills/config
ca new NOME-2                   # já nasce ligada à base
ca new NOME-3 --clean           # ou isolada
```

- Sem base definida (ou com `--clean`), a conta nasce limpa e isolada. Para ligar a uma conta específica: `ca new NOME --share OUTRA`.
- Se você **restaurou um backup** (passo 1), as pastas `~/.claude-NOME` já existem e `ca new` recusa ("já existe"). Nesse caso é só registrar a conta na lista:
  ```bash
  echo 'NOME-1=~/.claude-NOME-1' >> ~/.config/claude-accounts/accounts
  ```
  (Uma linha por conta. A padrão é `NOME=~/.claude`.)

---

## 6. Fazer o login em cada conta

Para **cada** conta, uma por vez:

```bash
ca stop             # se houver sessão do Claude aberta
ca NOME
claude
# dentro do Claude:  /login   → entre com o e-mail DAQUELA conta
# saia do Claude (/exit)
ca                  # confira: o e-mail mostrado tem de ser o esperado
```

Cuidado com o navegador: se ele já estiver logado em outra conta da Anthropic, o `/login` pode autorizar a conta errada sem avisar. Use janela anônima ou saia da conta no navegador entre um login e outro.

Se uma conta mostrar `(sem login)` no `ca list`, o login dela não terminou; repita.

---

## 7. Escolher a conta principal

```bash
ca NOME             # a que o `claude` deve abrir por padrão
ca                  # confira
```

Depois disso `claude` abre sempre nessa conta, e a troca é só `ca OUTRA`.

---

## 8. Conferir que tudo funciona

```bash
ca doctor            # instalação ok?
ca list              # todas as contas, com e-mail, ativa marcada
ca sessions          # nenhuma sessão aberta
```

E um teste real: `ca NOME` → `claude` → use `/status` e confira o e-mail.

---

## 9. Ligar as contas à configuração compartilhada

Se você usa uma conta como base e alguma conta já existente ainda não aponta para ela, ligue (uma vez por conta):

```bash
ca stop
ca share OUTRA BASE
```

Se restaurou o backup (passo 1), os links já vêm nele, mas confira com `ls -l ~/.claude-NOME`. Lembre-se de que `~/.claude/rules/` vale para **todas** as contas; veja [configuracao-compartilhada.md](configuracao-compartilhada.md) antes de reinstalar qualquer pacote de regras ali.

---

## 10. Ferramentas que abrem o Claude sozinhas (IDE, etc.)

Programas que não leem o `~/.zshrc` não enxergam o wrapper e abrem o `claude` real, **na conta padrão**, sem avisar. Para esses, configure o comando para:

```
claude-auto
```

(ou o caminho completo: `~/.local/share/claude-accounts/bin/claude-auto`). Ele usa a conta ativa e **continua a conversa do diretório** se existir. Anote **em que programas você fez isso**, porque é a parte mais fácil de esquecer.

**Maestri:** além dos presets, ele tem um provider de uso por conta (os anéis). Refaça-os conforme [maestri.md](maestri.md); o modelo está em `examples/maestri-usage-provider.json`.

---

## Problemas

Primeiro passo para qualquer problema: `ca doctor`.

**`ca: command not found`** → terminal antigo. Abra um novo ou `source ~/.zshrc`. Se persistir, confira se o bloco `# >>> claude-accounts >>>` está no arquivo do seu shell (`~/.zshrc`, `~/.bashrc` ou, no macOS com bash, `~/.bash_profile`).

**`command -v claude` mostra o binário real** → o diretório do wrapper não está na frente do PATH. Veja `echo $PATH`: `~/.local/share/claude-accounts/bin` deve aparecer **antes** de onde está o Claude. Se o arquivo do shell define o PATH depois do bloco, mova o bloco para o fim do arquivo.

**`claude-accounts: real 'claude' not found`** → o Claude Code não está instalado ou mudou de lugar e não está no PATH. Instale/conserte e rode o `install.sh` de novo; ele regrava o caminho. (Se o Claude só mudou de lugar mas continua no PATH, o wrapper o encontra sozinho.)

**`ca NOME` diz que há sessões abertas** → proposital. `ca sessions` mostra quais; `ca stop` encerra.

**A conta aparece sem login mesmo depois do `/login`** → o login foi feito com outra conta ativa. `ca` mostra qual estava ativa; refaça o passo 6 com a conta certa.

**Conta padrão "deslogada" depois de mexer em variáveis** → para a conta padrão a variável `CLAUDE_CONFIG_DIR` **não pode** estar definida (veja [como-funciona.md](como-funciona.md)). Rode `echo $CLAUDE_CONFIG_DIR`: se não estiver vazia no terminal, algo no seu shell a está definindo.

**Mudou de WSL para outro WSL/máquina** → os caminhos mudam; refaça do passo 2. No macOS, veja também [macos.md](macos.md).
