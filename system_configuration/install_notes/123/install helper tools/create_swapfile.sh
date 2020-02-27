#!/bin/bash


if df -h | grep -q -P '^/dev/.* /$'; then
  root="/"
elif df -h | grep -q -P '^/dev/.* /mnt$'; then
  root="/mnt/"
else
  echo "ERROR"
  exit 1
fi

swapfile="${root}"swapfile

fallocate -l 1G $swapfile
chmod 600 $swapfile
mkswap -L swap $swapfile

echo
echo $swapfile
echo "/swapfile none swap defaults 0 0"
