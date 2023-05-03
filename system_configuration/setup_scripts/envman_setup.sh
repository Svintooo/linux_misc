#!/usr/bin/env bash

#
# This script setups a management system for configuring
# environment variables.
#
# SETUP
# 1. Run this script.
#
# 2. Source the correct helper script in your shellrc file.
#    POSIX: $HOME/.config/env/loadrc.sh
#    Bash:  $HOME/.config/env/loadrc.sh
#    Zsh:   $HOME/.config/env/loadrc.zsh
#    Csh:   $HOME/.config/env/loadrc.csh
#    Tcsh:  $HOME/.config/env/loadrc.csh
#
# 3. Add a .env file in $HOME/.config/env/ for each
#    environment variable you want.
#    Example: echo "vim" > $HOME/.config/env/EDITOR.env
#
# Note: PATH.env is treated as special.
#       Each whitespace separated string will be
#       prepended to the global PATH variable.
#       ALSO: Variables are expanded. So usage of $HOME
#       is possible.
#
# REMOVE
#   Just delete the folder: $HOME/.config/env/

mkdir -p "$HOME/.config/env"

cat > "$HOME/.config/env/loadrc.csh" <<'EOF'
if ( -f "$HOME/.config/env/PATH.env" ) then
  foreach p (`cat "$HOME/.config/env/PATH.env"`)
    set p = `eval "echo $p"`  # Ex: $HOME => /home/user
    set path = ($p $path)
  end
endif
foreach x ("$HOME"/.config/env/*.env)
  set e = `basename "$x" | sed 's/[.]env$//'`
  echo "$e" | grep --quiet '[^_A-Za-z0-9]' && continue
  if ( "$e" == "PATH" ) then
    continue
  endif
  set v = "`cat $x`"
  eval "setenv $e "'"'"$v"'"'
end
unset e x p v
EOF

cat > "$HOME/.config/env/loadrc.sh" <<'EOF'
if [ -f "$HOME/.config/env/PATH.env" ]; then
  for p in `cat "$HOME/.config/env/PATH.env"`; do
    p="`eval "echo $p"`"  # Ex: $HOME => /home/user
    export PATH="$p:$PATH"
  done
fi
for x in "$HOME"/.config/env/*.env; do
  e="`basename "$x" | sed 's/[.]env$//'`"
  echo "$e" | grep --quiet '[^_A-Za-z0-9]' && continue
  if [ "$e" = "PATH" ]; then
    continue
  fi
  v="`cat $x`"
  eval "export $e=\"$v\""
done
unset e x p v
EOF

ln -sf "loadrc.sh" "$HOME/.config/env/loadrc.zsh"
