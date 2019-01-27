#!/bin/bash

BINDIR=`dirname $0`

CHUNKDIR="$1";
shift;

SOURCEDIR="${1:-/media/sixtease/VERBATIM HD/Makon}"

: ${TEMPDIR:=temp}

if which split-audio.pl > /dev/null; then : ; else
    echo split-audio.pl not in path
    exit 1
fi

mkdir -p "$CHUNKDIR/mp3"
mkdir -p "$CHUNKDIR/ogg"
mkdir -p "$CHUNKDIR/wav"
mkdir -p "$CHUNKDIR/flac"
mkdir -p "$TEMPDIR"

convert() {
    format="$1"; shift
    stem="$1"  ; shift
    find "$CHUNKDIR/$format/" -name "$stem--*.$format" | while read audiofile; do
        basename=`basename "$audiofile" | sed "s/\.$format$//"`
        "$format"2mp3.sh "$audiofile" > "$CHUNKDIR/mp3/$basename.mp3" >> log.out 2>> log.err
        echo -n .
        "$format"2ogg.sh "$audiofile" > "$CHUNKDIR/ogg/$basename.ogg" >> log.out 2>> log.err
        echo -n ,
    done
    echo -n ' '
}

while read stem; do
    echo -n "$stem "
    if mkdir "$TEMPDIR/$stem" 2> /dev/null; then
        if find "$CHUNKDIR/ogg" | grep -q "/$stem--"; then
            echo already split
            continue
        elif find "$CHUNKDIR/flac" | grep -q "/$stem--"; then
            echo -n 'found flac chunks, convert '
            convert flac "$stem"
        elif find "$CHUNKDIR/wav" | grep -q "/$stem--"; then
            echo -n 'found wav chunks, convert '
            convert wav "$stem"
        elif [ -e "$SOURCEDIR/flac/$stem.flac" ]; then
            echo -n 'found flac, splitting ... '
            split-audio.pl \
                --output-file-naming=intervals \
                --output-format=flac \
                --splitdir=/home/sixtease/Documents/Kama/meta/splits \
                --chunkdir="$CHUNKDIR/flac" \
                "$SOURCEDIR/flac/$stem.flac" >> log.out 2>> log.split.err
            echo -n 'converting '
            convert flac "$stem"
        elif [ -e "$SOURCEDIR/mp3/$stem.mp3" ]; then
            echo -n 'found mp3, splitting ... '
            split-audio.pl \
                --output-file-naming=intervals \
                --splitdir=/home/sixtease/Documents/Kama/meta/splits \
                --chunkdir="$CHUNKDIR/wav" \
                "$SOURCEDIR/mp3/$stem.mp3" >> log.out 2>> log.split.err
            echo -n 'converting '
            convert wav "$stem"
        fi
        echo done
    else
        echo taken by another process
    fi
done
