---
name: define-product-north-star
description: プロダクトが誰にどんな価値ある未来を実現し、どんな選択をしないかを長期の判断基準として文書化する。「プロダクトの北極星を作って」「目指す方向を定めて」「機能やKPIより上位の価値を言語化して」と言われたときに使う。
---

# define-product-north-star（価値ある未来を指し示す）

**北極星は現在の機能、ロードマップ、売上目標、単一KPIではない。** 戦略が変わっても判断を同じ方向へ揃える、価値ある未来を定める。

## 0. プラグイン root を決める

<!-- BEGIN shared:skill-entry/root-block -->
```bash
BUNDLE_ROOT="${CLAUDE_PLUGIN_ROOT:-/absolute/path/to/this/plugin}"
if [ -d "${BUNDLE_ROOT}/skills/product/product-north-star" ]; then
  PLUGIN_ROOT="${BUNDLE_ROOT}/skills/product/product-north-star"
else
  PLUGIN_ROOT="${BUNDLE_ROOT}"
fi
```

`PLUGIN_ROOT`は配布物rootの絶対パスである。単一skill pluginではこの`SKILL.md`があるdirectory、複数skill pluginでは`skills/<skill>/`の2つ上に当たる。Claude Codeでは`${CLAUDE_PLUGIN_ROOT}`が自動展開される。
<!-- END shared:skill-entry/root-block -->

## 1. 置き場と規律を解決する

<!-- BEGIN shared:skill-entry/config-load -->
```bash
CFG_FILE=$(bash "${PLUGIN_ROOT}/scripts/prepare.sh" "$(pwd)") || exit 2
trap 'rm -f "$CFG_FILE"' EXIT
```

**このコマンドは説明例ではない。必ず実行する。** 解決済みYAMLが空なら先へ進まない。設定ファイルを直接読んで代用しない。

本文中の `${...}` は解決済みYAMLのプロパティである。使用時に `yq -er` で読み、欠落または `null` なら停止する。
<!-- END shared:skill-entry/config-load -->

`${.product_north_star}`を必ず読み、`${.instructions.direction.directive}`に従う。

## 2. 価値ある未来を定める

入力された顧客理解、現在地、信念から、対象、望む状態、約束する価値、プロダクト固有の役割をつなげる。現行技術や機能を目的へ昇格させない。根拠と仮説を分け、反証されたら見直す条件を置く。

判断原則は、実際の二択で答えが分かれるように書く。「顧客中心」のように何も捨てない標語では足りない。魅力的でも選ばない領域を`やらないこと`へ書く。

North Star Metricを置く場合は価値提供の補助信号と明記し、北極星と同一視しない。

## 3. 戦略へ越境しない

現在の障害の診断、基本方針、期限つきの行動は書かない。それらはNorth Starへ至る経路であり、Product Strategyの責務である。

## 4. 検査して保存する

`## 対象` `## 望む状態` `## 約束する価値` `## プロダクトの役割` `## 判断原則` `## やらないこと` `## 根拠と仮説` `## 見直し条件` `## 未決`を持つMarkdownを作る。

節内はラベル付き箇条書きへ分解せず、意味のある小見出しと本文で構成する。対象の損なわれた価値から望む状態へ至る関係や、プロダクトが担う範囲と担わない範囲は、文章だけでは比較しにくい場合に外部の図でも示す。

```bash
python3 "${PLUGIN_ROOT}/scripts/artifact.py" write --config "$CFG_FILE" \
  --topic <題材> --body-file <本文ファイル>
```

## 5. 報告する

保存先、北極星の一文、もっとも重要な判断原則と非目標、残った仮説と見直し条件を報告する。戦略は作らない。
