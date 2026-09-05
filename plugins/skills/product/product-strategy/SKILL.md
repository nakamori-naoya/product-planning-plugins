---
name: form-product-strategy
description: Product North Starと現在地の証拠台帳を受け取り、現状が生む問題と目標へ進む際の障壁から最重要課題を選び、基本方針と相互に補強する行動をRumeltの戦略カーネルで文書化する。「プロダクト戦略を作って」「制約を踏まえてNorth Starへの行き方を決めて」と言われたときに使う。
---

# form-product-strategy（現在地から北極星への経路を選ぶ）

**戦略は願望、目標値、標語、要望一覧ではない。** 診断、基本方針、一貫した行動の三つが互いを支える選択にする。

## 0. プラグイン root を決める

<!-- BEGIN shared:skill-entry/root-block -->
```bash
BUNDLE_ROOT="${CLAUDE_PLUGIN_ROOT:-/absolute/path/to/this/plugin}"
if [ -d "${BUNDLE_ROOT}/skills/product/product-strategy" ]; then
  PLUGIN_ROOT="${BUNDLE_ROOT}/skills/product/product-strategy"
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

`${.product_context}` `${.product_north_star}` `${.product_strategy}`を必ず読み、`${.instructions.strategy.directive}`に従う。

## 2. North Starと現在地を受け取る

任意の作成元による有効なNorth Star文書と現在地の証拠台帳を受け取る。出典と時点のない主張は事実として使わず、仮説または未確認事項へ戻す。入力がない場合は、このskill内で最低限の同等情報と課題候補を整理してから進む。

## 3. Rumeltの戦略カーネルを作る

診断では状況を並べず、現状が生む問題とNorth Starへ進む際の障壁を洗い出し、症状と原因を分け、前進を妨げる最重要課題を一つの焦点へ圧縮する。現在地、制約、能力、機会、未検証仮説を根拠として接続する。

基本方針では、その課題への全体的な進み方を決める。活かす能力、受け入れる・回避する・変える制約、選ぶこと、やらないこと、方針変更条件を明示する。

一貫した行動では、近い期間に集中する少数の行動について、何を変えるか、なぜ次の行動を可能にするか、どの状態なら前進したと分かるかを書く。全体を止める弱い環へ最初の行動を集中させ、前の成果が次を可能にし、利用者価値から得た学習が前の行動を強くする鎖にする。North Starは、現在の能力で手が届き、次の障害を明らかにする最初の到達状態へ翻訳する。

## 4. 検査して保存する

`## 診断` `## 基本方針` `## 一貫した行動`だけを最上位の節に持つMarkdownを作る。North Starとの接続、根拠、不確実性、弱い環は診断へ、集中と非選択、見直し条件は基本方針へ、行動の鎖と最初の到達状態は一貫した行動へ含める。節内はラベル付き箇条書きで分解せず、意味のある`###`小見出しと本文で読み進められるようにする。選ぶことと選ばないこと、行動間の因果は、本文を補う図でも示す。記入欄の網羅より、三つの節を通した因果を優先する。

```bash
python3 "${PLUGIN_ROOT}/scripts/artifact.py" write --config "$CFG_FILE" \
  --topic <題材> --body-file <本文ファイル>
```

## 5. 報告する

保存先、最重要課題と弱い環、基本方針、行動のつながり、最初の到達状態、やらないこと、方針を見直す条件を報告する。
