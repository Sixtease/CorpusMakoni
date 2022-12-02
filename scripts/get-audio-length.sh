#!/bin/bash

for stem in "$@"; do
    echo $stem >&2
    echo -n "$stem,"
    gsutil cat gs://karel-makon-splits/split-meta/$stem.jsonp | tail -n 6  | head -n 1 | grep -o '"to": [0-9.]*' | cut -d ' ' -f 2
done
