#!/bin/bash
set -euo pipefail

SRC_DIR="./testku"
DEST_DIR="./test"

for KU in `find $SRC_DIR -type f -name "*.ku"`; do
  FILE="${KU#$SRC_DIR}"
  NAME="${FILE%.ku}"

  MO="$DEST_DIR$NAME.mo"

  SUB_DIR=`dirname $MO`
  mkdir -p "$SUB_DIR"

  echo "Transpiling $KU > $MO"
  kusanagi < "$KU" > "$MO"
done