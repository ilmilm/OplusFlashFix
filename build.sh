#!/bin/sh
# 打包成可刷入的模块 zip
set -e
cd "$(dirname "$0")"
OUT="${1:-dist/OplusFlashFix.zip}"
mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"
zip -r "$OUT" module.prop config.sh service.sh post-fs-data.sh uninstall.sh capctl README.md
echo "built: $OUT"
