🇺🇸 [Read in English](../removing-an-account.md)

# Remover uma conta

Cenário: você não vai mais usar uma das contas e quer tirá-la do sistema.

## Só tirar da lista (seguro, é o padrão)

```bash
ca remove freela
```

A conta some do `ca list`, mas a pasta `~/.claude-freela` **continua no disco** com o login e o histórico. Dá para voltar atrás recriando a entrada na lista (`~/.config/claude-accounts/accounts`, uma linha `freela=~/.claude-freela`).

## Tirar da lista e apagar a pasta

```bash
ca remove freela --delete-dir
```

Pede confirmação, apaga `~/.claude-freela` (login e histórico **dessa** conta) e tira da lista.

## O que o sistema impede

- **Remover a conta ativa** → troque antes: `ca outra-conta`.
- **Remover a conta BASE** → defina outra antes: `ca base OUTRA`.
- **Apagar a pasta da conta padrão** (`~/.claude`) → ela não é apagada por aqui. Tirar da lista é permitido.
- **Apagar uma pasta que não seja `~/.claude-*`** → recusado.
- **Apagar a pasta de uma conta cujos itens outra conta compartilha** (ligada com `--share` ou `ca share`) → a outra conta ficaria quebrada. Remova ou recrie a outra primeiro.

## Antes de apagar: o login

Apagar a pasta apaga o login local, mas **a sessão continua válida na Anthropic** até você encerrá-la. Se a conta era de uma empresa e você saiu dela, entre em *claude.ai → Configurações → Segurança* e encerre a sessão do dispositivo.

No macOS o token fica no Keychain, não na pasta; apagar a pasta pode não apagá-lo. Veja [macos.md](macos.md).

## Depois de remover

```bash
ca list       # confira
```
