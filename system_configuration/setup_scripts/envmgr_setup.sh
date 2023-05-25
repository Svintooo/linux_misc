#!/usr/bin/env bash

###############################################################################
#     INFO
###############################################################################
#
# This script setups a management system for configuring
# environment variables.
#
# HOW TO SETUP
# 1. Run this script.
#    It will create and populate the path: $HOME/.config/env/
#
# 2. Edit your shellrc file so it sources one of the helper scripts.
#    POSIX: $HOME/.config/env/load.sh
#    Bash:  $HOME/.config/env/load.sh
#    Zsh:   $HOME/.config/env/load.zsh
#    Csh:   $HOME/.config/env/load.csh
#    Tcsh:  $HOME/.config/env/load.csh
#
# 3. Add a *.env file in $HOME/.config/env/ for each
#    environment variable you want, and make them executable.
#    Example: cat <<EOF >$HOME/.config/env/EDITOR.env
#             #!/usr/bin/env bash
#             echo "vim"
#             EOF
#    Example: cat <<EOF >$HOME/.config/env/GIT_PAGER.env
#             #!/usr/bin/env python3
#             print("less -FRX --mouse")
#             EOF
#
# HOW TO REMOVE
#   Delete the folder: $HOME/.config/env/
#   Delete $HOME/.local/bin/pathmgr


###############################################################################
#     GENERAL SETUP
###############################################################################

# Create directories
mkdir -p "$HOME/.config/env"
mkdir -p "$HOME/.local/bin"

# Create PATH.env
cat > "$HOME/.config/env/PATH.env.template" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail  # Crash if any undeclared variables are used (+ more)

PATH="$HOME/.local/bin:$PATH"
PATH="$HOME/bin:$PATH"

### NO TOUCHY UNDER THIS LINE ###

# Remove duplicate and nonexistant paths
declare _PATH="" path=""
while [[ "$PATH" == *:* ]]; do
  path="${PATH%%:*}"  # Ex: "aa:bb:cc" => "aa"
  PATH="${PATH#*:}"   # Ex: "aa:bb:cc" => "bb:cc"
  [[ ":$PATH:" == *":$path:"* ]] && continue  # Check if duplicate
  [[ ! -d "$path" ]] && continue              # Check if directory exists
  _PATH="$_PATH:$path"
done
PATH="${_PATH}:${PATH}"
PATH="${PATH#:}"  # Remove ':' at the beginning of string

# Print
echo "$PATH"
EOF

if [[ ! -e "$HOME/.config/env/PATH.env" ]]; then
  cp "$HOME/.config/env/PATH.env.template" "$HOME/.config/env/PATH.env"
  chmod a+x "$HOME/.config/env/PATH.env"
fi

# Create env manager
cat > "$HOME/.local/bin/envmgr" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s extglob

readonly work_dir="$HOME/.config/env"
readonly command="$1"
readonly env_name="${2-}"
readonly env_value="${3-}"

if [[ "$env_name" == "PATH" ]]; then
  echo >&2 "[envmgr] Use pathmgr for editing PATH"
  exit 1
elif [[ ! -d "$work_dir" ]]; then
  echo >&2 "[envmgr] Directory not found: $work_dir"
  exit 1
fi

function usage() {
  echo "USAGE: envmgr add NAME VALUE"
  echo "       envmgr remove NAME"
  echo "       envmgr list"
  echo "       envmgr version"
}

function env_add() {
  readonly name="$1"
  readonly value="$2"
  cat > "${work_dir}/${env_name}.env" <<END
#!/usr/bin/env bash
echo "$env_value"
END
  chmod a+x "${work_dir}/${env_name}.env"
}

case "$command" in
      (add) [[ -z "$env_name" || -z "$env_value" ]] && usage >&2 && exit 1
            env_add "$env_name" "$env_value" ;;
   (remove) [[ -z "$env_name" ]] && usage >&2 && exit 1
            rm -f -- "${work_dir}/${env_name}.env" ;;
     (list) CDPATH='' /usr/bin/env ls -1 "${work_dir}"/*.env \
            | while read -r file; do
                declare name="$( basename "$file" | sed -E 's/\.env$//' )"
                declare value="$( "$file" )"
                value="${value//\"/\\\"}"  # " => \"
                echo "$name=\"$value\""
              done ;;
  (version) echo 'envmgr v0.0.1 (aaaaaabbbbbbccccccddddddeeeeeeffffff0124) 2023-05-25T13:41:00+02:00' ;;

  (help|-help|--help|-h|-\?) usage ;;
                         (*) usage >&2 && exit 1 ;;
esac
EOF
chmod a+x "$HOME/.local/bin/envmgr"

# Create path manager
cat > "$HOME/.local/bin/pathmgr" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s extglob

# This script is UGLY. It was written and tested in under 1 hour.

# This script is basically mimicing pathman:
# https://github.com/therootcompany/pathman

readonly path_env="$HOME/.config/env/PATH.env"
readonly command="$1"
readonly path="${2-}"
declare  path_regex

if [[ -! -f "$path_env" ]]; then
  echo >&2 "[$(basename $0)] File not found: $path_env"
  exit 1
fi

case "$command" in
     (list) sed --regexp-extended '/TOUCHY/,$d;/^PATH/!d;s,^PATH="|"$,,g;s,:?\$PATH:?,,' "$path_env" ;;
      (add) [[ -z "$path" ]] && echo >&2 "USAGE: $0 add NEW_PATH" && exit 1
            sed --in-place --regexp-extended '/^$/{ N ; /TOUCHY/!{p;d} ; s,^,PATH="'"$path"':$PATH"\n,g }' "$path_env" ;;
   (remove) [[ -z "$path" ]] && echo >&2 "USAGE: $0 remove NEW_PATH" && exit 1
            path_regex="$path"
            path_regex="${path_regex//$/\\$}"  ;  # $ => \$
            path_regex="${path_regex//\//\\/}" ;  # / => \/
            path_regex="${path_regex//./\\.}"  ;  # . => \.
            sed --in-place --regexp-extended '/^PATH="'"${path}"':/d' "$path_env" ;;
  (version) echo 'pathmgr v0.0.4 (aaaaaabbbbbbccccccddddddeeeeeeffffff0123) 2023-05-25T12:30:00+02:00' ;;
        (*) echo "USAGE: $0 add|remove|list|version"
            exit 1 ;;
esac
EOF
chmod a+x "$HOME/.local/bin/pathmgr"

# Hijack pathman
#if [[ ! -e "$HOME/.local/bin/pathman" ]]; then
#  ln -s pathmgr "$HOME/.local/bin/pathman"
#fi


###############################################################################
#     SHELL SPECIFICS
###############################################################################

# csh and tsch
cat > "$HOME/.config/env/load.csh" <<'EOF'
# SCRIPT INTENT:
#   foreach x ("$HOME"/.config/env/*.env)
#     set e = "` basename "$x" | sed 's/[.]env$//' `"
#     set v = "` $x `"
#     eval "setenv $e $v"
#   end
#
# FEATURES THAT MAKES THIS SCRIPT COMPLICATED:
# - Retry *.env files multiple times.
#   This solves the problem where one environment variable is
#   dependent on another environment variable. A *.env file just
#   need to explicitly fail if required varibles are not available
#   yet.

set env_files = ""  # List of files, separated by ':'

foreach env_file ("$HOME"/.config/env/*.env)
  # Ignore files with illegal variable names
  basename "$env_file" | sed 's/[.]env$//' | grep --quiet '[^_A-Za-z0-9]' && continue

  # Ignore files that are not executable
  [ ! -f "$env_file" -a ! -x "$env_file" ] && continue

  # Add file to list
  set env_files = "$env_files":"$env_file"
end
set env_files = "` echo '$env_files' | sed 's/^://' `"

# Calculate max numbers of loops before script will stop
set env_files_count="` echo :'$env_files' | grep -Fo ':' | wc -l `"
@ loop_max = ( $env_files_count * 4 )  # Magic number

# Add environment variables
foreach _ (`seq 1 $loop_max`)
  [ "$env_files" == "" ] && break

  set env_file  = "` echo '$env_files' | sed -E 's/:.*"'$'"//' `"
  set env_files = "` echo '$env_files' | sed -E 's/^[^:]+:?//' `"
 
  set env_name  = "` basename '$env_file' | sed 's/[.]env"'$'"//' `"
  set env_value = "` sh -c '$env_file 2>/dev/null' `"  # Execute *.env file

  if ( $? != 0 ) then  # If execution of *.env failed
    set env_files = "$env_files":"$env_file"  # Try *.env file again later
    set env_files = "` echo '$env_files' | sed 's/^://' `"
  else
    eval "setenv $env_name '$env_value'"
  endif
end

[ -n "$env_files" ] && sh -c "echo >&2 'Error loading the following environment variable files: $env_files'"

unset env_files env_file env_name env_value
unset env_files_count loop_max
EOF

# Bash and POSIX Shell
cat > "$HOME/.config/env/load.sh" <<'EOF'
# SCRIPT INTENT:
#   for x in "$HOME"/.config/env/*.env; do
#     e="$( basename "$x" | sed 's/[.]env$//' )"
#     declare $e="$( $x )"
#     export $e
#   done
#
# FEATURES THAT MAKES THIS SCRIPT COMPLICATED:
# - Retry *.env files multiple times.
#   This solves the problem where one environment variable is
#   dependent on another environment variable. A *.env file just
#   need to explicitly fail if required varibles are not available
#   yet.

env_files=""  # List of files, separated by ':'

for env_file in "$HOME"/.config/env/*.env; do
  # Ignore files with illegal variable names
  basename "$env_file" | sed 's/[.]env$//' | grep --quiet '[^_A-Za-z0-9]' && continue

  # Ignore files that are not executable
  [ ! -x "$env_file" ] && continue

  # Add file to list
  env_files="$env_files:$env_file"
done
env_files="$( echo "$env_files" | sed 's/^://' )"

# Calculate max numbers of loops before script will stop
env_files_count="$( echo ":$env_files" | grep -Fo ':' | wc -l )"
loop_max="$(( env_files_count * 4 ))"  # Magic number

# Add environment variables
for _ in $(seq 1 $loop_max); do
  [ "$env_files" == "" ] && break

  env_file="$(  echo "$env_files" | sed -E 's/:.*$//'     )"
  env_files="$( echo "$env_files" | sed -E 's/^[^:]+:?//' )"

  env_name="$( basename "$env_file" | sed 's/[.]env$//' )"
  env_value="$( "$env_file" 2> /dev/null )"  # Execute *.env file

  if [ $? != 0 ]; then  # If execution of *.env failed
    env_files="$env_files:$env_file"  # Try *.env file again later
    env_files="$( echo "$env_files" | sed 's/^://' )"
  else
    declare $env_name="$env_value"
    export $env_name
  fi
done

[ -n "$env_files" ] && echo >&2 "Error loading the following environment variable files: $env_files"

unset env_files env_file env_name env_value
unset env_files_count loop_max
EOF

# zsh
ln -sf "load.sh" "$HOME/.config/env/load.zsh"

