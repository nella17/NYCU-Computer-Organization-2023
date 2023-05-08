#!/bin/bash
set -eu
if [ ! "$ID" ]; then
  exit
fi

FOLDER="TEST_$ID"
PACK="TEST_$ID.zip"

rm -fr "$FOLDER" || true
mkdir "$FOLDER"
files=(*.v *.cpp Makefile)
for file in "${files[@]}"; do
  cp "$file" "$FOLDER"
done
rm "$PACK" || true
zip -r "$PACK" "$FOLDER"
unzip -l "$PACK"
rm -fr "$FOLDER"
