#!/bin/bash

#getopts "ab" opt
#echo '$?'  : "'$?'"
#echo '$opt': "'$opt'"
#echo '$OPTIND': "'$OPTIND'"

#getopts "ab" opt
#echo '$?'  : "'$?'"
#echo '$opt': "'$opt'"
#echo '$OPTIND': "'$OPTIND'"

#getopts "ab" opt
#echo '$?'  : "'$?'"
#echo '$opt': "'$opt'"
#echo '$OPTIND': "'$OPTIND'"

while getopts "ab" opt; do
  echo '$?'  : "'$?'"
  echo '$opt': "'$opt'"
  echo '$OPTIND': "'$OPTIND'"
  echo "---"
done
