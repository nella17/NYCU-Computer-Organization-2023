#!/bin/bash
set -eux
make
while true; do
  python3 generate.py > input.txt
  ./Valu_tb
  python3 check.py
done
