#!/bin/bash

#
# Variables
#

locale_name="en_SE"
locale_name_utf8="en_SE.UTF-8"
locale_gen_string="en_SE.UTF-8 UTF-8"

# Symlink to the first found locale in this list
declare -a locale_sources=(
  en_XX@POSIX
  en_DK
)

declare -a locale_gen_files=(
  "etc/locale.gen"
  "etc/locale.gen.pacnew"
)

declare -a compose_strings=(
  "en_US.UTF-8/Compose:		$locale_name_utf8"
  "en_US.UTF-8/Compose		$locale_name_utf8"
)

declare -a locale_strings=(
  "en_US.UTF-8/XLC_LOCALE:			$locale_name_utf8"
  "en_US.UTF-8/XLC_LOCALE			$locale_name_utf8"
)

locales_path="usr/share/i18n/locales"
compose_dir_file="usr/share/X11/locale/compose.dir"
locale_dir_file="usr/share/X11/locale/locale.dir"



#
# Helper Functions
#

function search_file() {
  local file="$1"
  local search="$2"

  # Error if file doesn't exist
  [[ ! -f "$file" ]] && return 1

  # Return search success/failure
  grep -qF "$search" "$file"
  return "$?"
}

function modify_file(){
  local file="$1"
  local insert="$2"

  # Skip file if not exist
  [[ ! -f "$file" ]] && return 1

  # Add missing Line Feed to end of file
  file_end_char="$(tail -c 1 "$file" | od -An -vc | tail -c 3)"
  [[ "$file_end_char" != '\n' ]] && echo >> "$file"

  # Add locale to file
  echo "$insert" >> "$file"
}



#
# Functions
#

function install() {
  # Check that symlink name is not already used
  locale_file="${locales_path}/${locale_name}"
  if [[ -e "$locale_file" && ! -L "$locale_file" ]]; then
    echo >&2 "[$BASH_SOURCE] ERROR: Can not create symlink. A file already exists with the same name: '$locale_file'"
    return 1
  fi

  # Add locale
  for locale_src in "${locale_sources[@]}"; do
    if [[ -f "${locales_path}/${locale_src}" ]]; then
      ln -sf "$locale_src" "${locales_path}/${locale_name}"
      break
    fi
  done

  # Modify locale.gen
  for file in "${locale_gen_files[@]}"; do
    search_file "$file" "$locale_gen_string" \
      || modify_file "$file" "$locale_gen_string"
  done

  # Modify compose.dir
  for compose_string in "${compose_strings[@]}"; do
    search_file "$compose_dir_file" "$compose_string" \
      || modify_file "$compose_dir_file" "$compose_string"
  done

  # Modify locale.dir
  for locale_string in "${locale_strings[@]}"; do
    search_file "$locale_dir_file" "$locale_string" \
      || modify_file "$locale_dir_file" "$locale_string"
  done

  # Generate locale (if locale is uncommented)
  if grep -q "^$locale_gen_string" "${locale_gen_files[0]}"; then
    usr/bin/locale-gen
  fi
}

function upgrade() {
  install
}

function remove() {
  # Unregister locale
  usr/bin/localedef --delete-from-archive "$locale_name_utf8"

  # Remove locale (if symlink exists)
  locale_file="${locales_path}/${locale_name}"
  if [[ -L "$locale_file" ]]; then
    rm -f "$locale_file"
  fi

  # Modify locale.gen
  for file in "${locale_gen_files[@]}"; do
    locale_gen_regex="$( sed -r 's,/,\\/,g;s,\.,\\.,g' <<<"$locale_gen_string" )"
    search_file "$file" "$locale_gen_string" \
      && sed -Ei "/^#?$locale_gen_regex/d" "$file"
  done

  # Modify compose.dir
  for compose_string in "${compose_strings[@]}"; do
    compose_regex="$( sed -r 's,/,\\/,g;s,\.,\\.,g' <<<"$compose_string" )"
    search_file "$compose_dir_file" "$compose_string" \
      && sed -Ei "/$compose_regex/d" "$compose_dir_file"
  done

  # Modify locale.dir
  for locale_string in "${locale_strings[@]}"; do
    locale_regex="$( sed -r 's,/,\\/,g;s,\.,\\.,g' <<<"$locale_string" )"
    search_file "$locale_dir_file" "$locale_string" \
      && sed -Ei "/$locale_regex/d" "$locale_dir_file"
  done
}



#
# Code
#

case "$1" in
  (install)  install  ;;
  (upgrade)  upgrade  ;;
  (remove)   remove   ;;
  (*)        echo >&2 "[$BASH_SOURCE] ERROR: Unknown command '$1'"
esac

