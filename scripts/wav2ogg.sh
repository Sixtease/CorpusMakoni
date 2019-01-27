#!/bin/bash

if [ -t 2 ]; then
    Q=''
else
    Q='--quiet'
fi

oggenc $Q -q 2 --downmix --resample 24000 -o - -- "$1"
