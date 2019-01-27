#!/bin/bash

ls_cmd="${1:-gsutil ls gs://karel-makon-splits/splits/}"; shift
rm_cmd="${1:-gsutil -m rm}"; shift

while read stem; do
    torm=$(
        $ls_cmd$stem/*/ | while read url; do
            bn=`basename "$url"`
            if grep -q "$bn" split-meta/"$stem".jsonp; then :
            else
                echo -n " $url"
            fi
        done
    )
    $rm_cmd$torm
done
