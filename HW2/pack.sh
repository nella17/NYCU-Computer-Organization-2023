#!/bin/bash
set -eu
rm -fr HW2_sample_tb || true
mkdir HW2_sample_tb
files=("Makefile" "decode.v" "decode_tb.v" "input.txt" "readme.txt" "reg_file.txt" "reg_file.v" "top.cpp")
for file in "${files[@]}"; do
  cp "$file" HW2_sample_tb
done
rm HW2_sample_tb.tgz || true
tar cf HW2_sample_tb.tgz HW2_sample_tb
tar tvf HW2_sample_tb.tgz
rm -fr HW2_sample_tb
