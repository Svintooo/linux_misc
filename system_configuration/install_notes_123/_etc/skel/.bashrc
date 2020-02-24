#
# ~/.bashrc
#

## If not running interactively, don't do anything
[[ $- != *i* ]] && return


## PS1
[[ -f ~/.bash_ps1 ]] && source ~/.bash_ps1


## enable dircolors
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  LS_COLOR_OPTION="--color=auto"
fi


## Aliases
alias sudo='sudo '  # This makes aliases work when using sudo :)

if ! type -P exa >/dev/null ; then
  alias ls='ls -CFNv $LS_COLOR_OPTION --group-directories-first --time-style=long-iso'
  alias ll='ls -l'
  alias la='ls -lA'
  alias l.='ls -la'
else
  alias exa='exa --sort=Name --group-directories-first --time-style=long-iso'
  alias ls='exa'
  alias ll='exa -g -h -l'
  alias lt='ll --tree'
  alias lg='ll --git'
  alias la='ll -a'
  alias lat='la --tree'
  alias l.='ll -a -a --links --inode --blocks --git'
  alias l.t='ll -a    --links --inode --blocks --git --tree'  # Two '-a' and a '--tree' can't run together
  alias l.e='ll -a -a --links --inode --blocks --git --extended'
fi

alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"
alias zgrep="zgrep --color=auto"

alias mv='mv -i'
alias rm='rm -i'
alias cp='cp -i'

type -P vim >/dev/null && alias viless="$( "$(type -P ls)" -1 /usr/share/vim/vim[0123456789]*/macros/less.sh | sort | tail -n 1 )"


## Help functions
type -P date >/dev/null && function date(){ local DATE="$(type -P date)"; [[ "$?" != "0" ]] && exit $?;  if [ "$#" -eq "0" ]; then "$DATE" +'%F %T %:z'; else "$DATE" "$@"; fi; }
type -P ip >/dev/null && function ip(){ local IP="$(type -P ip)"; [[ "$?" != "0" ]] && exit $?;  if [ "$#" -eq "0" ]; then "$IP" -c -br addr; else "$IP" -c "$@"; fi; }
type -P findmnt >/dev/null && function findmnt(){ local FINDMNT="$(type -P findmnt)"; [[ "$?" != "0" ]] && exit $?;  if [ "$#" -eq "0" ]; then "$FINDMNT" -t nocgroup,nocgroup2,noproc,noautofs,nobinfmt_misc,noefivarfs,nosecurityfs,nopstore,nobpf,nodebugfs,noconfigfs,nohugetlbfs,nodevpts,nomqueue; else "$FINDMNT" "$@"; fi; }


type -P aura >/dev/null && function aura(){
  local AURA="$(type -P aura)"

  if   [[ "$1" == "-A" ]];                   then sudo "$AURA" -a --hotedit "$@"
  elif [[ "$1" == "-S" ]];                   then sudo "$AURA" --needed "$@"
  elif [[ "$1" == "-Ss" || "$1" == "-As" ]]; then      "$AURA" "$@"
  else                                            sudo "$AURA" "$@"
  fi
}


type -P yay >/dev/null && function yay(){
  local YAY="$(type -P yay)"

  # Indexed arrays
  declare -a args=( "$@" )
  declare -a search_terms

  # Associative arrays
  declare -A flags_count

  # Booleans
  local file_list_filter=true

  # Other
  local _IFS_orig="${IFS}"
  grep -E -q '^Color\s*(#.*)?$' /etc/pacman.conf && local color="--color=always"  # Make sure pacman keeps colored output, if necessary
  local escsec='(([@A-Z\[\\^_]|\])[0-9:;<=>?]*[-!"#$%&()*,./'"'"']*([@A-Z\[\\^_`a-z{|}~]|\]))'  # Escape sequense REGEXP pattern

  # Parse/modify arguments
  local i
  for (( i=0 ; i<${#args[@]} ; i++ )); do
    local arg="${args[$i]}"

    if [[ "$arg" == "--no-file-filter" ]]; then
      unset "args[$i]"
      file_list_filter=false
      continue
    fi

    [[ ! "$arg" =~ ^-  ]] && search_terms+=("$arg") && continue  # $arg is a search term
    [[   "$arg" =~ ^-- ]] && continue                            # $arg is a double dash (--) flag

    arg="${arg:1}"  # Remove the dash (-)

    local j
    for (( j=0 ; j<"${#arg}" ; j++ )); do
      local c="${arg:$j:1}"
      [ -z "${flags_count[$c]+x}" ] && flags_count[$c]=0
      ((flags_count[$c]+=1))
    done
  done
  declare -a args=( "${args[@]}" )

  #for i in "${!flags_count[@]}"; do echo "DEBUG [$i]=\"${flags_count[$i]}\""; done  #DEBUG

  if [[ "${#flags_count[@]}" == 1 ]] && [[ "${flags_count[S]}" == 1 ]]; then
    # yay -S <asdf>
    "$YAY" --needed "${args[@]}"
  elif [[ "${flags_count[S]}" == 1 ]] && [[ "${flags_count[s]}" -ge 2 ]]; then  # -ge: greater OR equal
    # yay -Sss <asdf>
    ## Only display search results for which name includes the search term(s)
    IFS='|'  # ${search_terms[*]} becomes "a|b|c" instead of "a b c", which is needed in the REGEXP
    "$YAY" "$color" "${args[@]}" | \
        grep --color=always -E -A 1 '^[^[:space:]]+('"${search_terms[*]}"')' | \
        grep -E -v "^${escsec}*--${escsec}*$"
    IFS="${_IFS_orig}"
  elif [[ "${flags_count[l]}" == 1 ]] && [[ "$file_list_filter" == "true" ]] && [[ "${flags_count[Q]}" == 1 || "${flags_count[F]}" == 1 ]]; then
    # yay -Ql <asdf>, yay -Fl <asdf>
    ## Filter out files I'm not interested in 
    #https://stackoverflow.com/questions/1444406/how-can-i-delete-duplicate-lines-in-a-file-in-unix#answer-1444433
    # sed script explanation:
    #"If you're not at the last line, read in another line. Now look at what you"
    #"have and if it ISN'T stuff followed by a newline and then the same stuff"
    #"again, print out the stuff. Now delete the stuff (up to the newline)."
    "$YAY" "$color" "${args[@]}" | \
      sed -r '$!N; /(usr\/share\/man\/).*\n.*\1/!   {s|(usr/share/man/)[^\n]*|\1 . . .|   ;P}; D' | \
      sed -r '$!N; /(usr\/share\/locale\/).*\n.*\1/!{s|(usr/share/locale/)[^\n]*|\1 . . .|;P}; D' | \
      sed -r '$!N; /(usr\/share\/icons\/).*\n.*\1/! {s|(usr/share/icons/)[^\n]*|\1 . . .| ;P}; D' | \
      sed -r '$!N; /(usr\/share\/doc\/).*\n.*\1/!   {s|(usr/share/doc/)[^\n]*|\1 . . .|   ;P}; D'
  else
    "$YAY" "${args[@]}"
  fi
}
