#!/bin/bash

TMP_PATH=.tmp

rm -r "$TMP_PATH"
mkdir -p "$TMP_PATH"

for file in lambda/*.py; do
    FNAME=`basename $file`
    ZIPNAME=${FNAME%.*}
    zip -j "$TMP_PATH/$ZIPNAME.zip" $file > /dev/null
done

echo "{}"
