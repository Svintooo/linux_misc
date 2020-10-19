function editor() {
  if [ -n "$VISUAL" ]; then
    "$VISUAL" "$@"
  elif [ -n "$EDITOR" ]; then
    "$EDITOR" "$@"
  elif type -P nano >/dev/null; then
    nano "$@"
  elif type -P vim >/dev/null; then
    vim "$@"
  else
    vi "$@"
  fi
}

