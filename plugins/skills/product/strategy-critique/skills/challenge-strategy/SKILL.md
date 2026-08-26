---
name: challenge-strategy
description: Product North Star、現在地、Product Strategyを反証し、Rumeltの戦略カーネル、根拠の鮮度、制約、選択、行動の整合性を合格または要修正で判定する。「この戦略を厳しくレビューして」「悪い戦略になっていないか反証して」「実行前に独立評価して」と言われたときに使う。
---

# challenge-strategy

このentryは配布形式を中立化する薄い入口である。次を実行してplugin rootを検証し、root直下の正本`SKILL.md`を全文読んで、その手順に従う。

```bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-/absolute/path/to/this/plugin}"
bash "${PLUGIN_ROOT}/scripts/prepare.sh" --root-only >/dev/null || exit 2
cat "${PLUGIN_ROOT}/SKILL.md"
```
