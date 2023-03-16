#!/bin/bash
set -eux
make
while python3 generate.py > input.txt && ./Valu_tb; do true; done
