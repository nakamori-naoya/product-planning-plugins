---
name: map-product-context
description: プロダクトの現在地を、出典と時点のある事実、仮説、未確認事項、制約、能力、機会へ分け、現状が生む問題とNorth Starへ進む際の障壁を課題候補として証拠台帳にする。「現状を整理して」「課題を洗い出して」「戦略の前提を棚卸しして」と言われたときに使う。
---

# map-product-context

このentryは配布形式を中立化する薄い入口である。次を実行してplugin rootを検証し、root直下の正本`SKILL.md`を全文読んで、その手順に従う。

```bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-/absolute/path/to/this/plugin}"
bash "${PLUGIN_ROOT}/scripts/prepare.sh" --root-only >/dev/null || exit 2
cat "${PLUGIN_ROOT}/SKILL.md"
```
