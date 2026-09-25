#!/usr/bin/env bash
# product-planning repository の検査。意味が一意に決まることだけを判定する。
# package の構造（manifest の一致、公開入口、配置、禁止参照形）は harness-tools の validate-plugin-repository.py が判定する。
# North Star や戦略の中身、反証の妥当性は判定しない。資料と SKILL.md は読んで評価する。
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TOOLS="$ROOT/../harness-tools/tools"
[ -d "$TOOLS" ] || { echo "[error] 兄弟 checkout harness-tools が無い: $TOOLS" >&2; exit 2; }
status=0
python3 "$TOOLS/validate-plugin-repository.py" "$ROOT" || status=1
python3 "$TOOLS/test-hardening.py" --repository "$ROOT" >/dev/null 2>&1 && echo "PASS: test-hardening --repository" || { echo "FAIL: test-hardening --repository"; status=1; }
[ "$status" -eq 0 ] && echo "Validation: passed" || echo "Validation: failed"
exit "$status"
