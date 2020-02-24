#!/bin/bash

locale="en_SE.UTF-8 UTF-8"

declare -a files=(/etc/locale.gen /etc/locale.gen.pacnew)

for file in "${files[@]}"; do
  # Skip file if not exist, of if already contains $locale
  [[ ! -f "$file" ]] && continue
  grep -q "$locale" "$file" && continue

  # Add missing Line Feed to end of file
  file_end_char="$(tail -c 1 "$file" | od -An -vc | tail -c 3)"
  [[ "$file_end_char" != '\n' ]] && echo >> "$file"

  # Add locale to file
  {
    echo
    echo "###"
    echo "#"
    echo "# Locale added by en_se-locale"
    echo "#$locale"
  } >> "$file"
done
