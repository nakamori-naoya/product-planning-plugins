#!/usr/bin/env bash
# お題の依頼と依頼者の記憶、前の段の資料、別 package のファイルを、共通の準備で作業場所へ置く。
set -euo pipefail
CASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec bash "$CASE_DIR/../../scaffold.sh" "$CASE_DIR/.." problem-hypothesis.md
