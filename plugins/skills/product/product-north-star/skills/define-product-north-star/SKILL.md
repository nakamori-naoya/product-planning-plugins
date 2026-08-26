---
name: define-product-north-star
description: プロダクトが誰にどんな価値ある未来を実現し、どんな選択をしないかを長期の判断基準として文書化する。「プロダクトの北極星を作って」「目指す方向を定めて」「機能やKPIより上位の価値を言語化して」と言われたときに使う。
---

# define-product-north-star

このentryは配布形式を中立化する薄い入口である。次を実行してplugin rootを検証し、root直下の正本`SKILL.md`を全文読んで、その手順に従う。

```bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-/absolute/path/to/this/plugin}"
bash "${PLUGIN_ROOT}/scripts/prepare.sh" --root-only >/dev/null || exit 2
cat "${PLUGIN_ROOT}/SKILL.md"
```
