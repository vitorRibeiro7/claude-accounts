# zsh completion for claude-accounts / ca (sourced by the block install.sh adds to your rc file)
_claude_accounts() {
  local -a cmds accounts
  cmds=(
    'list:all accounts' 'use:switch the global account' 'new:create an account'
    'base:show / move the base account' 'share:link an account to another one'
    'remove:drop an account from the list' 'here:pin this folder to an account'
    'sessions:open Claude sessions' 'stop:terminate all sessions' 'usage:plan usage of every account'
    'lang:UI language'
    'statusline:account in the Claude Code status line' 'prompt:account name for your prompt'
    'doctor:check the installation' 'version:show the version' 'help:show help'
  )
  accounts=(${(f)"$(claude-accounts _names 2>/dev/null)"})
  if (( CURRENT == 2 )); then
    _describe -t accounts 'account' accounts
    _describe -t commands 'command' cmds
    return
  fi
  case "${words[2]}:$CURRENT" in
    use:3|base:3|share:3|share:4|remove:3|new:5) _describe -t accounts 'account' accounts ;;
    here:3)       _describe -t accounts 'account' accounts; compadd -- --unset ;;
    remove:4)     compadd -- --delete-dir ;;
    new:4)        compadd -- --clean --share ;;
    lang:3)       compadd -- en pt-BR ;;
    statusline:3) compadd -- --install ;;
    usage:*)      _describe -t accounts 'account' accounts ;;
  esac
}
(( $+functions[compdef] )) && compdef _claude_accounts claude-accounts ca
