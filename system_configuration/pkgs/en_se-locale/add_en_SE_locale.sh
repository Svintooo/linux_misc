#!/bin/bash

#
# Variables
#

locale_gen_string="en_SE.UTF-8 UTF-8"

declare -a locale_gen_files=(
  /etc/locale.gen
  /etc/locale.gen.pacnew
)

declare -a compose_strings=(
  'en_US.UTF-8/Compose:		en_SE.UTF-8'
  'en_US.UTF-8/Compose:		en_SE.utf8'
)

compose_map_file="/usr/share/X11/locale/compose.dir"

header_string="$(
  echo
  echo "###"
  echo "#"
  echo "# Locale added by en_se-locale"
)"



#
# Functions
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
# Code
#

# Modify locale.gen
insertion_string="$(
  echo "$header_string"
  echo "#$locale_gen_string"
)"
for file in "${locale_gen_files[@]}"; do
  search_file "$file" "$locale_gen_string" && continue
  modify_file "$file" "$insertion_string"
done

# Modify Compose
search_file "$compose_map_file" "# Locale added by en_se-locale" \
  || modify_file "$compose_map_file" "$header_string"
for compose_string in "${compose_strings[@]}"; do
  search_file "$compose_map_file" "$compose_string" && continue
  modify_file "$compose_map_file" "$compose_string"
done
