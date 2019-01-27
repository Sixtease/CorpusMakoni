#!/bin/bash

if [ -t 2 ]; then
    Q=''
else
    Q='--quiet'
fi

lame $Q -h -m m --resample 24 -b 40 "$1" -
