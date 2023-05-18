#!/bin/bash
set -eu
if [ ! "$ID" ]; then
  exit
fi

FOLDER="HW3_$ID"
PACK="HW3_$ID.zip"

rm -fr "$FOLDER" || true
mkdir "$FOLDER"
files=(alu.v core_top.v decode.v dmem.v  imem.v reg_file.v)
for file in "${files[@]}"; do
  cp "$file" "$FOLDER"
done
rm "$PACK" || true
zip -r "$PACK" "$FOLDER"
unzip -l "$PACK"
rm -fr "$FOLDER"
