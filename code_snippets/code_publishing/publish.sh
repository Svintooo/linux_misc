#!/bin/bash
set -e  # Exit on error

if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
  echo "Bash version 4 or later required"
  exit 1
  # Bash 4.0 required for associative arrays (declare -A)
  # Bash 3.1 required for the `+=' assignment operator
  # Bash 2.0 required for the existence of BASH_VERSINFO
  # Bash 1.14.7 required for the `read' option: `-p'
  # SOURCE: https://tiswww.case.edu/php/chet/bash/NEWS
fi

#NOTE: Script stops here if 'which' returns an error
BIN_SSH="$(which ssh)"
BIN_RSYNC="$(which rsync)"

MODE="development"
DRY_RUN=
CWD="$(pwd)"  # Set Current Working Directory

while [ $# -ne 0 ]; do
  case "$1" in
    (-d|--dry-run) DRY_RUN=true ;;
    (*)            MODE="$1" ;;
  esac
  shift
done

declare -A CONFIG=(
  [development,server]=dev.server.tld
  [development,location]="/some/path/"
  [development,user]=root

  [testing,server]=localhost
  [testing,location]="/tmp/publish test"
  [testing,user]="$USER"

  [production,server]=live.server.tld
  [production,location]="/some/path/"
  [production,user]=root
)

declare -a EXCLUDE=(
  ".git/"
  ".gitignore"
  "bin/"
)

declare -a INCLUDE=()

if [[ -z "${CONFIG[$MODE,server]}" ]]; then
  echo "Mode not found"
  exit 1
fi

[[ "$DRY_RUN" ]] && echo "DRY RUN"
echo "You're about to sync your current branch (${CWD}/) with '${CONFIG[$MODE,user]}@${CONFIG[$MODE,server]}':'${CONFIG[$MODE,location]}', this will remove all local changes."
read -p "Are you sure you want to continue? [no] " answer
[[ "$answer" != "yes" ]] && exit


cmd_mkdir="${BIN_SSH} '${CONFIG[$MODE,user]}@${CONFIG[$MODE,server]}' -- \"mkdir -p '${CONFIG[$MODE,location]}'\""

                  cmd_rsync="${BIN_RSYNC} -Rcvrh --progress --delete --force"
[ "$EXCLUDE" ] && cmd_rsync+="$( printf " --exclude='%s'" "${EXCLUDE[@]}" )"
                  cmd_rsync+=" '$CWD/./'"
[ "$INCLUDE" ] && cmd_rsync+="$( printf " '$CWD/./%s'" "${INCLUDE[@]}" )"
                  cmd_rsync+=" '${CONFIG[$MODE,user]}@${CONFIG[$MODE,server]}':\"'${CONFIG[$MODE,location]}'\""

if [[ "$DRY_RUN" ]]; then
  cmd_rsync+=" --dry-run"
  echo
  echo "$cmd_rsync"
  echo
  bash -c "$cmd_rsync"
  exit
fi

bash -c "$cmd_mkdir"
bash -c "$cmd_rsync"

exit
