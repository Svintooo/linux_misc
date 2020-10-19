#!/bin/bash

script=$(basename $0)

printf "Are you sure you want to $script [y/n] "
read RESPONSE
if [ "$RESPONSE" = "Y" ]
then
        /sbin/$script
else
        echo "response not Y"
fi
