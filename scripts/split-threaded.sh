#!/bin/bash

BINDIR=`dirname $0`

CHUNKDIR="$1";
shift;

SOURCEDIR=${1:-'/media/sixtease/VERBATIM HD/Makon'}

: ${THREAD_CNT:=`cat /proc/cpuinfo | grep -w processor | wc -l`}

mkdir "$CHUNKDIR/mp3"
mkdir "$CHUNKDIR/ogg"
mkdir "$CHUNKDIR/wav"
mkdir "$CHUNKDIR/flac"

echo splitting flac

find "$SOURCEDIR/flac/" -name '*.flac' | awk -v outfile=flacpart -v thread_cnt="$THREAD_CNT" -f "$BINDIR"/unzip.awk
for partf in flacpart*; do
    split-audio.pl \
        --output-file-naming=intervals \
        --output-format=flac \
        --splitdir=/home/sixtease/Documents/Kama/meta/splits \
        --chunkdir="$CHUNKDIR/flac" \
        $(cat "$partf") &
done
wait

echo splitting mp3

# TODO filter out stems with flac coverage
find "$SOURCEDIR/mp3/" -name '*.mp3' | awk -v outfile=mp3part -v thread_cnt="$THREAD_CNT" -f "$BINDIR"/unzip.awk
for partf in mp3part*; do
    split-audio.pl \
        --output-file-naming=intervals \
        --splitdir=/home/sixtease/Documents/Kama/meta/splits \
        --chunkdir="$CHUNKDIR/wav" \
        $(cat "$partf") &
done
wait

echo encoding flac

find "$CHUNKDIR/flac" -name '*.flac' | awk -v outfile=flacchunkpart -v thread_cnt="$THREAD_CNT" -f "$BINDIR"/unzip.awk
for partf in flacchunkpart*; do
    cat "$partf" | while read flac; do
        stem=`basename "$flac" | sed 's/\.flac$//'`
        flac2mp3.sh "$flac" > "$CHUNKDIR/mp3/$stem.mp3"
        flac2ogg.sh "$flac" > "$CHUNKDIR/ogg/$stem.ogg"
    done &
done
wait

echo encoding wav

find "$CHUNKDIR/wav" -name '*.wav' | awk -v outfile=wavchunkpart -v thread_cnt="$THREAD_CNT" -f "$BINDIR"/unzip.awk
for partf in wavchunkpart*; do
    cat "$partf" | while read wav; do
        stem=`basename "$wav" | sed 's/\.wav$//'`
        if [ -e "$CHUNKDIR/flac/$stem.flac" ]; then continue; fi
        wav2mp3.sh "$wav" > "$CHUNKDIR/mp3/$stem.mp3"
        wav2ogg.sh "$wav" > "$CHUNKDIR/ogg/$stem.ogg"
    done
done
wait
