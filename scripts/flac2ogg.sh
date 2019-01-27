#!/bin/bash

if [ -t 2 ]; then
    oQ=''
    fQ=''
else
    oQ='--quiet'
    fQ='--silent'
fi

flac $fQ --decode -o - -- "$1" | oggenc $oQ -q 2 --downmix --resample 24000 -
