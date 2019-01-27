#!/bin/bash

if [ -t 2 ]; then
    Q=''
else
    Q='--silent'
fi

flac $Q --decode -o - -- "$1" | lame $Q -h -m m --resample 24 -b 40 - -
