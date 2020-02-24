#
# ~/.bashrc_svintoo
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Set bash history size to "unlimited" and to not store duplicate commands
export HISTSIZE=-1
export HISTFILESIZE=-1
export HISTCONTROL=ignoreboth

# ls
if ! type -P exa >/dev/null ; then
  alias ls='ls -CFNv $LS_COLOR_OPTION --group-directories-first --time-style=long-iso'
  alias ll='ls -l'
  alias la='ls -lA'
  alias l.='ls -la'
else
  alias exa='exa --group --header --sort=Name --group-directories-first --time-style=long-iso'
  alias ls='exa'
  alias ll='exa -l'
  alias lt='ll --tree'
  alias lg='ll --git'
  alias la='ll -a'
  alias lat='la --tree'
  alias l.='ll -a -a --links --inode --blocks --git'
  alias l.t='ll -a    --links --inode --blocks --git --tree'  # '-a'x2 and '--tree' can't run together
  alias l.e='ll -a -a --links --inode --blocks --git --extended'
fi

# Ask before overwrite/delete
alias mv='mv -i'                          # confirm before overwriting something
alias cp="cp -i"                          # confirm before overwriting something
alias rm="rm -i"                          # confirm before deleting something

# grep
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"
alias zgrep="zgrep --color=auto"

# Run aliases with sudo
alias sudo='sudo '

# viless (vim pager)
# See also: pacman -Si vimpager
type -P vim >/dev/null && alias viless="/usr/share/vim/vim[0123456789]*/macros/less.sh"

# date: default to iso8601
type -P date >/dev/null && function date(){
  local DATE="$(type -P date)" ; local ec="$?" ; ((ec != 0)) && exit "$ec"
  (( $# > 0 )) && "$DATE" "$@" || "$DATE" +'%F %T %:z'
}

# findmnt: defaults to filter out some file systems
type -P findmnt >/dev/null && function findmnt(){
  local FINDMNT="$(type -P findmnt)" ; local ec="$?" ; ((ec != 0)) && exit "$ec"
  local filter="nocgroup,nocgroup2,noproc,noautofs,nobinfmt_misc,noefivarfs,nosecurityfs,nopstore,nodebugfs,noconfigfs,nohugetlbfs,nodevpts,nomqueue"
  (( $# > 0 )) && "$FINDMNT" "$@" || "$FINDMNT" -t "$filter"
}

# iproute2: Change default behaviour
# # Color if interactive shell
# # Set default command: list addresses
# # When compact output (-brief): do alignment correction on the output
type -P ip >/dev/null && function ip(){
  local IP="$(type -P ip)" ; local ec="$?" ; ((ec != 0)) && exit "$ec"

  local color="-color"
  local brief="-brief"

  # Remove colors if not interactive shell
  [ ! -t 1 ] && color=""

  # Remove color and brief is not supported
  # https://git.kernel.org/pub/scm/network/iproute2/iproute2.git/commit/?id=5d295bb8e1af491bc3de1d2506cbb2bd6bbd9da1
  local version="$("$IP" -Version)"
  version="${version##*ss}"  # "iproute2-ss200127" -> "200127"
  if (( "$version" < 150831 )); then
    color=""
    brief=""
  fi

  if (( $# == 0 )); then
    # No args: run a default command + output alignment fix
    "$IP" $color $brief addr | sed -E 's/^([^ ]+[ ]*) /\1░/' | column -t -s '░' -o ' '
  elif for arg in "${@}"; do [[ "$arg" == -br* ]] && break; false; done; then
    # Args contain -brief: output alignment fix
    "$IP" $color "$@"        | sed -E 's/^([^ ]+[ ]*) /\1░/' | column -t -s '░' -o ' '
  else
    # Args exists: Just add -color arg
    "$IP" $color "$@"
  fi
}

# trunc2term: truncate stdout to terminal width
function trunc2term() {
  cut -c 1-"$( tput cols </dev/tty )"
}

# YAML JSON Converter
# pacman -S python-yaml --needed
function yaml2json(){
  #ruby -r json -r yaml -e "puts JSON.pretty_generate(YAML.safe_load(ARGF.read,[],[],true));" "$@"
  python -Ibbs -c 'import sys,fileinput,yaml,json;print(json.dumps(yaml.safe_load("".join(fileinput.input())), indent = 2))' "$@"
}

# IDNA Punycode Converters
# pacman -S python-idna --needed
function punydecode(){
  #ruby -r 'simpleidn' -e "puts SimpleIDN.to_unicode(ARGV.any? ? ARGV.join(" ") : $stdin.read);"
  python -Ibbs -c 'import sys,idna;print(idna.encode(" ".join(sys.argv[1:]) if len(sys.argv) > 1 else sys.stdin.read().strip()).decode())' "$@"
}
function punyencode(){
  #ruby -r 'simpleidn' -e "puts SimpleIDN.to_ascii(ARGV.any? ? ARGV.join(" ") : $stdin.read);"
  python -Ibbs -c 'import sys,idna;print(idna.decode(" ".join(sys.argv[1:]) if len(sys.argv) > 1 else sys.stdin.read().strip()).decode())' "$@"
}

# Display not only changed rows, but also what characters on each row that has changed.
function cdiff() {
  diff -u "$@" \
  | sed -E -e '1,2d' -e '/^[-+@]/!d' \
  | diff-so-fancy
}

# 
function csv_strip(){
  local file=()
  local sep=","
  local i
  for ((i=1;i<=$#;i++)); do
    if [[ "${!i}" =~ ^.$ && ! "${!i}" =~ ^[\'\"]$ ]]; then
      sep="${!i}"
    elif [[ -f "${!i}" ]]; then
      file=("${!i}")
    else
      echo 1>&2 "Invalid arg: ${!i}"
      return 1
    fi
  done
  ruby -r csv -e "CSV.parse(ARGF.read,col_sep:'${sep}'){|o| puts o.collect{|s|s.strip}.to_csv(col_sep:'${sep}')}" "${file[@]}"
}

type -P yay >/dev/null && function yay(){
  local PACMAN="$(type -P pacman)"
  local YAY="$(type -P yay)"
  local GREP="$(type -P grep)"
  local SED="$(type -P sed)"
  local LS="$(type -P ls)"

  # Indexed arrays
  declare -a args=( "$@" )
  declare -a search_terms

  # Associative arrays
  declare -A flags_count

  # Booleans
  local file_list_filter=true

  # Other
  local _IFS_orig="${IFS}"
  # Make sure pacman keeps colored output, if necessary
  "$GREP" -E -q '^Color\s*(#.*)?$' /etc/pacman.conf && local color="--color=always"
  # Escape sequense REGEXP pattern
  local escsec='(@A-Z\[\\^_]|\])[0-9:;<=>?]*[-!"#$%&()*,./'"'"']*([@A-Z\[\\^_`a-z{|}~]|\]))'

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

    arg="${arg#-}"  # Remove the first character, if it's a dash (-)

    local j
    for (( j=0 ; j<"${#arg}" ; j++ )); do
      local c="${arg:$j:1}"
      [ -z "${flags_count[$c]+x}" ] && flags_count[$c]=0
      ((flags_count[$c]+=1))
    done
  done
  declare -a args=( "${args[@]}" )

  #for i in "${!flags_count[@]}"; do echo "DEBUG [$i]=\"${flags_count[$i]}\""; done  #DEBUG

  if [[ "${flags_count[S]}" == 1 ]] && [[ "${#flags_count[@]}" == 1 || "${#flags_count[@]}" == 2 && "${flags_count[y]}" == 1 ]]; then
    # yay -S <asdf>
    # yay -Sy <asdf>
    "$YAY" --needed "${args[@]}"
  elif [[ "${flags_count[S]}" == 1 ]] && [[ "${flags_count[s]}" -ge 2 ]]; then  # -ge: greater OR equal
    # yay -Sss <asdf>
    ## Only display search results for which name includes the search term(s)
    IFS='|'  # ${search_terms[*]} becomes "a|b|c" instead of "a b c", which is needed in the REGEXP
    "$YAY" "$color" "${args[@]}" | \
        "$GREP" --color=always -E -A 1 '^[^[:space:]]+('"${search_terms[*]}"')' | \
        "$GREP" -E -v "^${escsec}*--${escsec}*$"
    IFS="${_IFS_orig}"
  elif [[ "${flags_count[l]}" == 1 ]] && [[ "${flags_count[Q]}" == 1 || "${flags_count[F]}" == 1 ]]; then
    # yay -Ql <asdf>, yay -Fl <asdf>
    ## Filter out files I'm not interested in 
    #https://stackoverflow.com/questions/1444406/how-can-i-delete-duplicate-lines-in-a-file-in-unix#answer-1444433
    # sed script explanation:
    #  If you're not at the last line, read in another line. Now look at what you
    #  have and if it ISN'T stuff followed by a newline and then the same stuff
    #  again, print out the stuff. Now delete the stuff (up to the newline).
    if [[ "$file_list_filter" == "false" ]]; then
      "$PACMAN" "${args[@]}" 2>/dev/null
    else
      (
        set -o pipefail
        "$PACMAN" "$color" "${args[@]}" | \
          "$SED" -r '$!N; /(usr\/share\/man\/).*\n.*\1/!   {s|(usr/share/man/)[^\n]*|\1 . . .|   ;P}; D' | \
          "$SED" -r '$!N; /(usr\/share\/locale\/).*\n.*\1/!{s|(usr/share/locale/)[^\n]*|\1 . . .|;P}; D' | \
          "$SED" -r '$!N; /(usr\/share\/icons\/).*\n.*\1/! {s|(usr/share/icons/)[^\n]*|\1 . . .| ;P}; D' | \
          "$SED" -r '$!N; /(usr\/share\/doc\/).*\n.*\1/!   {s|(usr/share/doc/)[^\n]*|\1 . . .|   ;P}; D'
      ) 2>/dev/null
    fi
    [ "$?" -eq 0 ] && return 0
    [[ "${flags_count[Q]}" == 1 ]] && echo >&2 "error: package '${search_terms[0]}' was not found" && return 1

    ## The package wasn't in any repository. Let's check in AUR instead
    [[ "${#search_terms[@]}" != 1 ]] && echo >&2 'error: Only the files of one package can be listed' && return 2

    (
      local tmpdir="$(/usr/bin/mktemp -d)"                                   ;[ "$?" -ne 0 ] && return 3
      trap 'rm -rf "$tmpdir"; trap - RETURN INT EXIT' RETURN INT EXIT

      cd "$tmpdir"                                                         ;[ "$?" -ne 0 ] && return 4
      "$YAY" -G "${search_terms[0]}" >/dev/null 2>&1                       ;[ "$?" -ne 0 ] && return 5

      echo >&2 "Package '${search_terms[0]}' wasn't found in any repository,  but was found in AUR."
      echo >&2 -n "Do you wan't to compile the package an print its list of files? [y/n]: "
      local answer; read answer                                    ;[[ "$answer" != "y" ]] && return 6

      cd *                                                                 ;[ "$?" -ne 0 ] && return 7
      makepkg --syncdeps --rmdeps --noarchive --noconfirm >/dev/null       ;[ "$?" -ne 0 ] && return 8
      cd pkg/*                                                             ;[ "$?" -ne 0 ] && return 9

      if [ "$color" ]; then
        local pkgname="$(echo -e '\e[38;5;231m''\e[1m'"${search_terms[0]}"'\e[0m')"  # White and bold
      else
        local pkgname="${search_terms[0]}"
      fi

      if [[ "$file_list_filter" == "false" ]]; then
        find . -type d -exec echo {}/ \; -or -print | sed -r -e 's|^\./?||' -e '/^$/d' -e "s/^/${pkgname} /" | sort
      else
        find . -type d -exec echo {}/ \; -or -print | sed -r -e 's|^\./?||' -e '/^$/d' -e "s/^/${pkgname} /" | sort | \
          "$SED" -r '$!N; /(usr\/share\/man\/).*\n.*\1/!   {s|(usr/share/man/)[^\n]*|\1 . . .|   ;P}; D' | \
          "$SED" -r '$!N; /(usr\/share\/locale\/).*\n.*\1/!{s|(usr/share/locale/)[^\n]*|\1 . . .|;P}; D' | \
          "$SED" -r '$!N; /(usr\/share\/icons\/).*\n.*\1/! {s|(usr/share/icons/)[^\n]*|\1 . . .| ;P}; D' | \
          "$SED" -r '$!N; /(usr\/share\/doc\/).*\n.*\1/!   {s|(usr/share/doc/)[^\n]*|\1 . . .|   ;P}; D'
      fi
    )
  else
    "$YAY" "${args[@]}"
  fi
}
