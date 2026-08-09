#!/bin/sh
set -eu

BASE_URL="${SPARK_INSTALL_BASE_URL:-https://raw.githubusercontent.com/alexandermakuch/sparkscripts/main}"
BIN_DIR="${SPARK_BIN_DIR:-$HOME/.local/bin}"
LIB_DIR="${SPARK_LIB_DIR:-$HOME/.local/lib/unsloth-spark-launchers}"
mkdir -p "$BIN_DIR" "$LIB_DIR"

fetch() { curl -fsSL "$BASE_URL/$1" -o "$2"; }
fetch lib/common.sh "$LIB_DIR/common.sh"
for command in sparkcode sparkpi sparkcodex; do
  fetch "$command" "$BIN_DIR/$command"
  chmod 755 "$BIN_DIR/$command"
done
chmod 644 "$LIB_DIR/common.sh"
printf 'Installed sparkcode, sparkpi, and sparkcodex in %s\n' "$BIN_DIR"
printf 'Set SPARK_ADDR and optionally SPARK_API_KEY (or UNSLOTH_API_KEY), then run one.\n'
