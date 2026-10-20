🇺🇸 [Read in English](../per-project-accounts.md)

# Contas por projeto

Pare de trocar de conta. Diga a cada projeto a conta dele, e o `claude` escolhe sozinho.

```bash
cd ~/trabalho/api
ca here trabalho    # grava .claude-account
claude              # abre na "trabalho", aqui e em todas as subpastas

cd ~/pessoal/blog
claude              # abre na sua conta global, como sempre
```

Como a conta é escolhida **a cada vez que o Claude abre**, dá para ter uma sessão pessoal num terminal e uma do trabalho em outro **ao mesmo tempo**. O `ca NOME` global continua valendo como padrão.

## Qual conta vale

Ao rodar `claude` (ou `claude-auto`), vale a primeira que bater:

| # | Origem | Alcance | Como definir |
|---|---|---|---|
| 1 | `CLAUDE_CONFIG_DIR` | aquele comando | `CLAUDE_CONFIG_DIR=~/.claude-trabalho claude` |
| 2 | `CLAUDE_ACCOUNT` | aquele comando ou terminal | `CLAUDE_ACCOUNT=trabalho claude` · `export CLAUDE_ACCOUNT=trabalho` |
| 3 | `.claude-account` na pasta ou em alguma pasta acima | aquele projeto | `ca here trabalho` |
| 4 | conta global | todo o resto | `ca trabalho` |

O `ca` sempre mostra qual está valendo e por quê:

```console
$ ca
conta aqui: trabalho (via ~/trabalho/api/.claude-account) → /home/voce/.claude-trabalho · voce@empresa.com

$ ca list
* pessoal              ~/.claude                          voce@gmail.com
> trabalho             ~/.claude-trabalho                 voce@empresa.com
> = usada aqui (via ~/trabalho/api/.claude-account) · * = global
```

## Comandos

```bash
ca here trabalho    # fixa esta pasta (e subpastas) na conta "trabalho"
ca here             # mostra a conta que vale aqui
ca here --unset     # tira a fixação desta pasta
```

O arquivo pode ficar em qualquer nível: um `~/trabalho/.claude-account` faz todos os repositórios dentro de `~/trabalho` usarem a conta do trabalho.

## Segurança

- **Apontar para uma conta que não existe é erro**, não volta para a global em silêncio: o `claude` se recusa a abrir em vez de abrir na conta errada. Corrija com `ca list` ou `ca here --unset`.
- O arquivo só escolhe entre as **suas** contas. Não cria conta nem aponta para pastas arbitrárias.
- **Nunca vai para o repositório.** A fixação é configuração pessoal, não do projeto. Dentro de um repositório git, o `ca here` adiciona o arquivo ao `.git/info/exclude`, a lista de ignorados local do git, que não é versionada. O `.gitignore` do time fica intacto e ninguém vê nada no `git status`. Se o arquivo já tiver sido commitado por engano, o `ca here` avisa e mostra o `git rm --cached` para corrigir.

## A conta no prompt do terminal

O `ca prompt` imprime só o nome da conta que vale na pasta atual (e nada, se der erro). Exemplos para starship, powerlevel10k e PS1 em [status-line.md](status-line.md).
