#!/usr/bin/env bash
set -e  # Exit on error

# Pack/unpack deb files.
# Author: Svintoo
# Date: 2020-09-11


#
# Variables
#

usage="\
USAGE: $(basename $0) [-f|--force] FILE [DIR]
       $(basename $0) [-f|--force] DIR [FILE]
       $(basename $0) -h|--help

Pack/unpack deb files.\
"

err=false

force=false
deb_file=""
deb_dir=""


#
# Parse Args
#

declare -a args=()

while [ "$#" -ne 0 ]; do
  arg="$1"; shift
  case "$arg" in
    (-h|--help)   echo "$usage"; exit 0                   ;;
    (-f|--force)  force=true                              ;;
    (-*)          err=true; echo >&2 "Unknown arg: $arg"  ;;
    (--)          args+=( "$@" ); break                   ;;
    (*)           args+=( "$arg" )                        ;;
  esac
done

[[ "$err" == "true" ]] && exit 1

set -- "${args[@]}"
unset args

# Set variables
[[ -n "$1" && -f "$1" ]] && { target="file"; deb_file="$(realpath "$1")"; }
[[ -n "$1" && -d "$1" ]] && { target="dir";  deb_dir="$(realpath "$1")"; }

if [[ -n "$deb_dir" || -n "$deb_file" ]]; then
  [[ -n "$deb_dir" && -z "$deb_file" ]] && deb_file="$deb_dir".deb
  deb_name="${deb_file%.deb}"  # "asdf.deb" -> "asdf"
  [[ -n "$deb_file" && -z "$deb_dir" ]] && deb_dir="$deb_name"
fi


#
# Error Checks
#

type -P ar  >/dev/null || { err=true; echo >&2 "Command not found: ar";  }
type -P tar >/dev/null || { err=true; echo >&2 "Command not found: tar"; }

(( 1 <= $# && $# <= 2 )) || { err=true; echo >&2 "Wrong number of arguments."; echo -e "\n$usage"; }

if [[ "$target" == "file" ]]; then
  [[ ! -f "$deb_file" ]]  &&  { err=true; echo >&2 "Not found: $deb_file"; }
  [[   -f "$deb_dir"  ]]  &&  { err=true; echo >&2 "Extraction dir name occupied by file: $deb_dir"; }
  [[   -d "$deb_dir"  &&
     "$force" != true ]]  &&  { err=true; echo >&2 "Extraction dir already exists: $deb_dir"; }
elif [[ "$target" == "dir" ]]; then
  [[ ! -d "$deb_dir"  ]]  &&  { err=true; echo >&2 "Not found: $deb_dir"; }
  [[   -d "$deb_file" ]]  &&  { err=true; echo >&2 "Package file name occupied by dir: $deb_file/"; }
  [[   -f "$deb_file" &&
     "$force" != true ]]  &&  { err=true; echo >&2 "Package file already exists: $deb_file"; }
fi

[[ "$err" == true ]] && exit 2


#
# Code
#

function unpack() {
  local file="$1"
  local dir="$2"

  [[ -d "$dir" ]] && rm -rf -- "$dir"
  mkdir "$dir"
  cd "$dir"
  ar x "$file"
  cd - >/dev/null

  mkdir "$dir"/control
  tar xf "$dir"/control.tar.*z -C "$dir"/control/
  rm -f -- "$dir"/control.tar.*z

  mkdir "$dir"/data
  tar xf "$dir"/data.tar.*z -C "$dir"/data/
  rm -f -- "$dir"/data.tar.*z
}

function repack() {
  local dir="$1"
  local file="$2"

  cd "$dir"/control/
  tar cvJf "$dir"/control.tar.xz * >/dev/null
  cd - >/dev/null
  rm -rf -- "$dir"/control/

  cd "$dir"/data/
  tar cvJf "$dir"/data.tar.xz * >/dev/null
  cd - >/dev/null
  rm -rf -- "$dir"/data/

  cd "$dir"
  ar rcs "$file" debian-binary control.tar.xz data.tar.xz  # Order is important
  cd - >/dev/null
}

case "$target" in
  ("file")
    unpack "$deb_file" "$deb_dir"
    ;;
  ("dir")
    repack "$deb_dir" "$deb_file_new"
    ;;
  (*)
    echo >&2 "FATAL ERROR: This should never happen."
    exit 255
    ;;
esac
