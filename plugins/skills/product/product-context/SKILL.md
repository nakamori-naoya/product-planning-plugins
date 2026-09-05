---
name: map-product-context
description: プロダクトの現在地を、出典と時点のある事実、仮説、未確認事項、制約、能力、機会へ分け、現状が生む問題とNorth Starへ進む際の障壁を課題候補として証拠台帳にする。「現状を整理して」「課題を洗い出して」「戦略の前提を棚卸しして」と言われたときに使う。
---

# map-product-context（いま立っている場所を知る）

**このskillは戦略を決めない。** 現在地を都合よく説明せず、後から反証できる証拠台帳へする。

## 0. プラグイン root を決める

<!-- BEGIN shared:skill-entry/root-block -->
```bash
BUNDLE_ROOT="${CLAUDE_PLUGIN_ROOT:-/absolute/path/to/this/plugin}"
if [ -d "${BUNDLE_ROOT}/skills/product/product-context" ]; then
  PLUGIN_ROOT="${BUNDLE_ROOT}/skills/product/product-context"
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
printf '%s\n' "$CFG_FILE"
```

**このコマンドは説明例ではない。必ず実行する。** 解決済みYAMLが空なら先へ進まない。設定ファイルを直接読んで代用しない。

本文中の `${...}` は解決済みYAMLのプロパティである。使用時に `yq -er` で読み、欠落または `null` なら停止する。
<!-- END shared:skill-entry/config-load -->

`${.product_context}`を必ず読み、`${.instructions.mapping.directive}`に従う。

## 2. 入力を証拠の状態へ分ける

利用者の発言、明示された資料、観測データだけから始める。事実には出典と観測時点を付ける。解釈は仮説へ分け、反証方法を添える。未確認事項には確認先または確認方法を添える。

顧客と利用、市場と競争、組織能力と資源、制度と技術、時間を確認する。制約は選べる経路を狭める条件、能力は現に使えるもの、機会は未確定の可能性として書く。

## 3. 課題候補を洗い出す

現状が顧客や事業にもたらしている問題と、明示された目標やNorth Starへ進む際に乗り越える必要がある障壁を分ける。症状と原因候補を区別し、根拠となる事実・仮説・未確認事項を結び付ける。

課題候補は洗い出すが、最重要課題の選択、基本方針、一貫した行動は書かない。資料から見つけられることを利用者へ質問せず、不明なものを事実に昇格させない。

## 4. 検査して保存する

`## 対象と観測時点` `## 事実` `## 仮説` `## 未確認事項` `## 制約` `## 能力` `## 機会` `## 課題`を持つMarkdownを作る。事実の各箇条書きは`出典：`と`観測時点：`を含める。課題には「現状が生む問題」と「目標へ進む際の障壁」の両方を明記する。

```bash
python3 "${PLUGIN_ROOT}/scripts/artifact.py" write --config "$CFG_FILE" \
  --topic <題材> --body-file <本文ファイル>
```

既存成果物は黙って上書きしない。意図した更新だけ`--force`を使う。

## 5. 報告する

保存先、主要な制約と能力、洗い出した課題候補、戦略判断に効く未確認事項、鮮度を再確認すべき事実を報告する。診断へは進まない。

## 実行設定の寿命

prepareが返した絶対pathを実行記録へ保持する。別shellではそのpathを`CFG_FILE`へ明示して読み、shell変数の継承を前提にしない。完了時と失敗停止時のどちらも、最後の設定利用後に`python3 "${PLUGIN_ROOT}/scripts/run-config.py" cleanup --config "$CFG_FILE"`を実行する。他runの設定やdirectoryを削除しない。
