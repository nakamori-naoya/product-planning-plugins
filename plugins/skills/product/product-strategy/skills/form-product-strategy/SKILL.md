---
name: form-product-strategy
description: Product North Starと現在地の証拠台帳を受け取り、現状が生む問題と目標へ進む際の障壁から最重要課題を選び、基本方針と相互に補強する行動をRumeltの戦略カーネルで文書化する。「プロダクト戦略を作って」「制約を踏まえてNorth Starへの行き方を決めて」と言われたときに使う。
---

# form-product-strategy

このentryは配布形式を中立化する薄い入口である。次を実行してplugin rootを検証し、root直下の正本`SKILL.md`を全文読んで、その手順に従う。

```bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-/absolute/path/to/this/plugin}"
bash "${PLUGIN_ROOT}/scripts/prepare.sh" --root-only >/dev/null || exit 2
cat "${PLUGIN_ROOT}/SKILL.md"
```
