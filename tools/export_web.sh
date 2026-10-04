#!/usr/bin/env bash
# unityroom 向けの Web 書き出し。build/unityroom/index.pck がアップロードするファイル、
# build/web/ は手元のブラウザで動かして確かめるための一式(tools/serve_web.py で配信)。
set -eu
GODOT="${GODOT:-C:/Users/omezi/Documents/Godot_v4.6.2-stable_win64_console.exe}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p logs build/web build/unityroom
"$GODOT" --headless --path . --export-release "Web" build/web/index.html > logs/export_web.log 2>&1
"$GODOT" --headless --path . --export-pack "Web" build/unityroom/index.pck >> logs/export_web.log 2>&1
grep -E "ERROR|SCRIPT ERROR" logs/export_web.log && exit 1
ls -l build/unityroom/index.pck build/web/index.wasm | awk '{print $5, $NF}'
echo "export OK"
