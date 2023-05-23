#!/usr/bin/env bash

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
#    environment variable you want.
#    Example: cat <<EOF >$HOME/.config/env/EDITOR.env
#             #!/usr/bin/env bash
#             echo "vim"
#             EOF
#    Example: cat <<EOF >$HOME/.config/env/GIT_PAGER.env
#             #!/usr/bin/env python3
#             print("less -FRX --mouse")
#             EOF
#    Example: cat <<EOF >$HOME/.config/env/PATH.env
#             #!/usr/bin/env bash
#             [[ -z "$GOPATH" ]] && exit 1
#             PATH="$PATH:$GOPATH/bin"
#             PATH="$HOME/.local/bin:$PATH"
#             echo "$PATH"
#             EOF
#
# HOW TO REMOVE
#   Just delete the folder: $HOME/.config/env/

mkdir -p "$HOME/.config/env"

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
  [ ! -x "$env_file" ] && continue

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
