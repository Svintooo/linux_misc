#!/bin/bash

function asdf(){
  PARAMS=$(getopt --options=a:,q --longoptions=assoc:,qwer --name "$0" -- "$@")
  test 0 -ne $? && exit $?
  declare -a PARAMS="($PARAMS)"
  declare -a ARGS

  while [ "${#PARAMS[@]}" -ne 0 ]; do
    case "${PARAMS[0]}" in
      (-a|--assoc)  ASSOC="${PARAMS[1]}" ; PARAMS=("${PARAMS[@]:1}") ;;
      (-q|--qwer)   QWER=true ;;
      (--)          ;;
      (*)           ARGS+=(${PARAMS[0]}) ;;
    esac
    PARAMS=("${PARAMS[@]:1}")
  done

  echo "ASSOC='$ASSOC'"
  echo " QWER='$QWER'"
  for ARG in "${ARGS[@]}"; do echo $ARG; done
}

asdf "$@"
