#!/usr/bin/env bash
# ケースが共有する準備。空の作業場所へ、お題の依頼と依頼者の記憶、ケースが名指しした前の段の資料、
# skill が読む別 package のファイルを置く。各ケースの scaffold.sh が、お題のディレクトリと前の段の資料の名前を渡して呼ぶ。
# 別 package（write-doc、grill）は隔離環境に入らないので、兄弟 checkout の最新のファイルを写す。
# 兄弟 checkout や前の段の資料が無ければ、写しで代用せずに止まる。
set -euo pipefail

[ $# -ge 1 ] || { echo "使い方: bash scaffold.sh <お題のディレクトリ> [前の段の資料の名前 ...]" >&2; exit 2; }
TOPIC_DIR=$(cd "$1" && pwd)
shift
EVALS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY=$(cd "$EVALS_DIR/.." && pwd)
WORKSPACE=$(cd "$(dirname "$REPOSITORY")" && pwd)
WRITE_DOC="$WORKSPACE/write-doc-plugins/plugins/write-doc/skills/write-doc"
GRILL="$WORKSPACE/grill-plugins/plugins/grill/skills/grill"

for skill in "$WRITE_DOC" "$GRILL"; do
  [ -f "$skill/SKILL.md" ] || { echo "兄弟 checkout の skill が無い: $skill" >&2; exit 2; }
done

mkdir -p harness out grill-log
cp -R "$TOPIC_DIR/materials/input" input
cp "$TOPIC_DIR/materials/依頼者の記憶.md" 依頼者の記憶.md
for name in "$@"; do
  [ -f "$TOPIC_DIR/materials/upstream/$name" ] || { echo "前の段の資料が無い: $TOPIC_DIR/materials/upstream/$name" >&2; exit 2; }
  mkdir -p upstream
  cp "$TOPIC_DIR/materials/upstream/$name" "upstream/$name"
done
cp -R "$WRITE_DOC" harness/write-doc
cp -R "$GRILL" harness/grill
