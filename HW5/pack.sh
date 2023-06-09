#!/bin/bash
set -eu
if [ ! "$ID" ]; then
  exit
fi

FOLDER="hw5_$ID"
PACK="hw5_$ID.zip"

rm -fr "$FOLDER" || true
mkdir "$FOLDER"
for file in $(ls ./*.v | grep -v tb); do
  cp "$file" "$FOLDER"
done
rm "$PACK" || true
zip -r "$PACK" "$FOLDER"
unzip -l "$PACK"
rm -fr "$FOLDER"
