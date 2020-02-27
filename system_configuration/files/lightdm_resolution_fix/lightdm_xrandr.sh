#!/usr/bin/env bash
# Tries to change the resolution of the login manager to
# a resolution that has a refresh rate of 100Hz or more.

# DEBUG Settings
DEBUG=false
DEBUG_FILE=/tmp/xrandr.result.log

# DEBUG: logging
if [[ "$DEBUG" == "true" ]]; then
  :> "$DEBUG_FILE"  # Create empty file
  xrandr >> "$DEBUG_FILE" --listactivemonitors
  echo   >> "$DEBUG_FILE"
  xrandr >> "$DEBUG_FILE"
  echo   >> "$DEBUG_FILE"
fi

# List all active monitors
mapfile -t monitors < <(
  xrandr --listactivemonitors | grep -Ev '^Monitors:' | awk '{print $(NF)}'
)

# Loop over monitors
for monitor in "${monitors[@]}"; do
  # Gets current and preferred  resolution from the following output:
  #DP-2 connected 2560x1440+0+0 (normal left inverted right x axis y axis)
  #   3840x2160     60.00*+  50.00    30.00    25.00
  #   2560x1440    143.63
  #   1920x2160    143.84
  #   1920x1080    143.56
  resolution_current="$(
    # Find current resolution
    # Above example output becomes: 3840x2160
    xrandr \
    | sed -En "/^${monitor}/,/^\S/"'{ /\*/s/^\s*(\S+).*/\1/p }' \
    | head -n1
  )"
  resolution_preferred="$(
    # Find biggest resolution which supports refresh rate 100 Hz and above
    # Above example output becomes: 2560x1440
    xrandr \
    | sed -En "/^${monitor}/,/^\S/"'{ /^\s+(\S+)\s+[1-9][0-9]{2}.*/s//\1/p }' \
    | head -n1
  )"

  # DEBUG: logging
  if [[ "$DEBUG" == "true" ]]; then
    echo "  resolution_current: $resolution_current"   >> "$DEBUG_FILE"
    echo "resolution_preferred: $resolution_preferred" >> "$DEBUG_FILE"
  fi

  # Do nothing if a preferred resolution is not found
  [[ -n "$resolution_preferred" ]] || exit

  # Do nothing if current resolution is smaller than then preferred one
  [[ "$resolution_current" > "$resolution_preferred" ]] || exit

  # Change resolution
  xrandr --output "$monitor" --mode "$resolution_preferred"
done

exit
