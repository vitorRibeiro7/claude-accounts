# bash completion for claude-accounts / ca (sourced by the block install.sh adds to your rc file)
# shellcheck disable=SC2207  # compgen output is word-split on purpose (bash 3.2 has no mapfile)
_claude_accounts() {
  local cur="${COMP_WORDS[COMP_CWORD]}" accounts
  local cmds="list use new base share remove here sessions stop lang statusline prompt doctor version help"
  accounts="$(claude-accounts _names 2>/dev/null)"
  COMPREPLY=()
  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=($(compgen -W "$cmds $accounts" -- "$cur")); return
  fi
  case "${COMP_WORDS[1]}:$COMP_CWORD" in
    use:2|base:2|share:2|share:3|here:2|remove:2|new:4) COMPREPLY=($(compgen -W "$accounts" -- "$cur")) ;;
    remove:3)     COMPREPLY=($(compgen -W "--delete-dir" -- "$cur")) ;;
    new:3)        COMPREPLY=($(compgen -W "--clean --share" -- "$cur")) ;;
    lang:2)       COMPREPLY=($(compgen -W "en pt-BR" -- "$cur")) ;;
    statusline:2) COMPREPLY=($(compgen -W "--install" -- "$cur")) ;;
  esac
  case "${COMP_WORDS[1]}:$COMP_CWORD" in here:2) COMPREPLY+=($(compgen -W "--unset" -- "$cur")) ;; esac
}
complete -F _claude_accounts claude-accounts ca
