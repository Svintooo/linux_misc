#!/bin/bash
# Ser till så USB-minnet blir read/write


bootmnt="/run/archiso/bootmnt"

if ! grep -q "${bootmnt}" /proc/mounts; then
  echo "!!!!! BOOT MOUNT NOT FOUND !!!!!"
else
  grep "${bootmnt}" /proc/mounts  # PRINT
  bootdev="$(mount | grep "${bootmnt}") | awk '{ print $1 }'"
  mount -o remount,rw "${bootdev}" "${bootmnt}"
  grep "${bootmnt}" /proc/mounts  # PRINT
fi

