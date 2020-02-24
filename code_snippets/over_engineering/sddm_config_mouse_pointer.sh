# Code for setting the mouse pointer used in sddm
# Is made to handle all situations possible
# - File not existing
# - \n missing at end of file
# - The config section existing or not
# - and more

# Adds the following to the config file:
[Theme]
CursorTheme=KDE_Classic

# This is a perfect example of over engineering from my part.
# I spend at least 5 hour writing this code, only to conclude
# that it's a mess to understand and to maintain.

# I have archived it here, because I spent too much time on
# it for just throwing it away.

# Author: Svintoo
# Date: 2020-02-24

(
  # Init
  set -e
  FILE="/etc/sddm.conf.d/kde_settings.conf"
  SECTION="Theme"
  KEY="CursorTheme"
  VALUE="KDE_Classic"
  # Create file if necessary
  [[ ! -f "$FILE" ]] && sudo touch "$FILE"
  # If file not empty
  if test -s "$FILE"; then
    # Add newline at end of file, if missing
    test "$(sudo tail -c 1 "$FILE" | wc -l)" -eq 0 && sudo tee -a <<<"" >/dev/null "$FILE"
    # Add newline at end of file, if [SECTION] is missing
    ! sudo grep -q -E "^\[${SECTION}\]" "$FILE" && sudo tee -a <<<"" >/dev/null "$FILE"
  fi
  # Add [SECTION], if missing
  ! sudo grep -q -E "^\[${SECTION}\]" "$FILE" && sudo tee -a <<<"[${SECTION}]" >/dev/null "$FILE"
  # Add KEY, if missing
  if ! sed -E "$FILE" -e "/^\[${SECTION}\]/,/^\[/"'!d' | grep -q -E "^${KEY}\s*="; then
    # Add KEY to beginning of section
    #sed -i -E "$FILE" -e "/^\[${SECTION}\]/a${KEY}="
    # Add KEY to end of section
    sed -i -E "$FILE" -e "/^\[${SECTION}\]/,/^\[/"'{H;$!d}' -e 'x;/./{s,^\n,,;'"s,^(\[[^\[]+\])((\n*[^\n\[][^\n]*)*)(\n+)?,\1\2\n${KEY}=\4,"';p;$Q;z};x'
  fi
  # Set value of KEY
  sed -i -E "$FILE" -e "/^\[${SECTION}\]/,/^\[/{ /^(${KEY}\s*=\s*).*/s,,\1${VALUE}, }"
)
