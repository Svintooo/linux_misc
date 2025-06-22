#!/usr/bin/env bash
set +H -Eeuo pipefail
CDPATH=""

# Constans
readonly SCRIPT_DIR="$(dirname "$(readlink -e "${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}")")"
readonly BIN_DIR_USER="$HOME/.local/bin"
readonly BIN_DIR_SCRIPTS="$(readlink -e -- "${SCRIPT_DIR}/../bin")"
[[ -d "$BIN_DIR_SCRIPTS" ]] || { echo >&2 "Scripts bin folder not found"; exit 1; }

# create bin/
mkdir -p "$BIN_DIR_USER"

# symlink scripts bin/ to users bin/.import-bin
{
  # Find the common base path that is shared between $BIN_DIR_SCRIPTS and $BIN_DIR_USER
  # Ex: /this/is/some/path /this/is/another/path => /this/is
  commonpath="$(
    paste <(sed -E 's,(.)/,\1\n/,g' <<<"$BIN_DIR_SCRIPTS") \
          <(sed -E 's,(.)/,\1\n/,g' <<<"$BIN_DIR_USER"  ) \
          | while read -r a b; do
              [[ "$a" == "$b" ]] && printf "$a" || break
            done
  )"
  if [[ -n "$commonpath" ]]; then
    # Create symlink using a relative path (ex: ../src/repo/bin)
    backpath="$( sed -E 's,[^/]+,..,g' <<<"${BIN_DIR_USER#$commonpath/}" )"
    ln --symbolic --force --no-dereference "${backpath}/${BIN_DIR_SCRIPTS#$commonpath/}" "${BIN_DIR_USER}/.import-bin"
  else
    # Create symlink using an absolute path
    ln --symbolic --force --no-dereference "${BIN_DIR_SCRIPTS}" "${BIN_DIR_USER}/.import-bin"
  fi
}

# symlink all files under bin/.repo-bin/* to bin/
(
  cd "$BIN_DIR_USER"
  for bin in .import-bin/*; do
    [[ -x "$bin" ]] || continue  # Skip non-executable files
    #ln --symbolic --no-dereference --force "$bin" . >/dev/null 2>&1
    ln --symbolic --no-dereference "$bin" . >/dev/null 2>&1 || true  # Will not overwrite existing files
  done
)

# Create python venv
python3 -I -m venv "$BIN_DIR_USER"/.venv

# Inside venv, install yaml
"$BIN_DIR_USER"/.venv/bin/python3 -I -m pip install \
                                              PyYaml \
                                              idna \
                                              --upgrade \
                                              --quiet \
                                              --disable-pip-version-check

