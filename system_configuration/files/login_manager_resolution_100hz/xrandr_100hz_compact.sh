#!/usr/bin/env bash

if which xrandr >/dev/null 2>&1
then
  xrandr --query \
   | sed -E '/^[^ ]/i'$'\n' \
   | sed -E '/ connected/,/^$/!d' \
   | sed -E '/^[^ ]/{s| .*||;:a;N;/\n$/!b a;s| *\n *|;|g;s|[+*]||g;s| +|,|g;s|;| |}' \
   | grep -E '[0-9]{3,}\.' \
   | sed -E 's|,[0-9]{1,2}\.[^,;]+||g ; s|[0-9]+x[0-9]+;||g ; s|,.*||' \
   | while read -r display resolution; do
       xrandr --output "$display" --mode "$resolution"
     done
fi