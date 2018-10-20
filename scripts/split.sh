#!/bin/bash

BINDIR=`dirname $0`

CHUNKDIR="$1";
shift;

SOURCEDIR="${1:-/media/sixtease/VERBATIM HD/Makon}"

if which split-audio.pl > /dev/null; then : ; else
    echo split-audio.pl not in path
    exit 1
fi

convert() {
    format="$1"; shift
    stem="$1"  ; shift
    for audiofile in "$CHUNKDIR/$stem/$format/"*; do
        basename=`basename "$audiofile" | sed "s/\.$format$//"`
        "$format"2mp3.sh "$audiofile" > "$CHUNKDIR/$stem/mp3/$basename.mp3" 2>> log.err
        echo -n .
        "$format"2ogg.sh "$audiofile" > "$CHUNKDIR/$stem/ogg/$basename.ogg" 2>> log.err
        echo -n ,
    done
    echo -n ' '
}

while read stem; do
    echo -n "$stem "
    if mkdir "$CHUNKDIR/$stem" 2> /dev/null; then
        mkdir "$CHUNKDIR/$stem/ogg"
        mkdir "$CHUNKDIR/$stem/mp3"
        mkdir "$CHUNKDIR/$stem/flac"
        mkdir "$CHUNKDIR/$stem/wav"
        if find "$CHUNKDIR/$stem/ogg" | grep -q "/$stem--"; then
            echo already split
            continue
        elif find "$CHUNKDIR/$stem/flac" | grep -q "/$stem--"; then
            echo -n 'found flac chunks, convert '
            convert flac "$stem"
        elif find "$CHUNKDIR/$stem/wav" | grep -q "/$stem--"; then
            echo -n 'found wav chunks, convert '
            convert wav "$stem"
        elif [ -e "$SOURCEDIR/flac/$stem.flac" ]; then
            echo -n 'found flac, splitting ... '
            split-audio.pl \
                --output-file-naming=intervals \
                --output-format=flac \
                --splitdir=/home/sixtease/Documents/Kama/meta/splits \
                --chunkdir="$CHUNKDIR/$stem/flac" \
                "$SOURCEDIR/flac/$stem.flac" >> log.out 2>> log.split.err
            echo -n 'converting '
            convert flac "$stem"
        elif [ -e "$SOURCEDIR/mp3/$stem.mp3" ]; then
            echo -n 'found mp3, splitting ... '
            split-audio.pl \
                --output-file-naming=intervals \
                --splitdir=/home/sixtease/Documents/Kama/meta/splits \
                --chunkdir="$CHUNKDIR/$stem/wav" \
                "$SOURCEDIR/mp3/$stem.mp3" >> log.out 2>> log.split.err
            echo -n 'converting '
            convert wav "$stem"
        else
            echo 'no source found'
        fi
        echo done
        rm -R "$CHUNKDIR/$stem/flac"
        rm -R "$CHUNKDIR/$stem/wav"
    else
        echo taken by another process
    fi
done
