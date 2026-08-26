---
name: challenge-strategy
description: Product North Star、現在地、Product Strategyを反証し、Rumeltの戦略カーネル、根拠の鮮度、制約、選択、行動の整合性を合格または要修正で判定する。「この戦略を厳しくレビューして」「悪い戦略になっていないか反証して」「実行前に独立評価して」と言われたときに使う。
---

# challenge-strategy（戦略を反証する）

**このskillは戦略を編集しない。** 欠陥を隠す修正文を混ぜず、反証、判定、修正要求を独立した成果物として返す。

## 0. プラグイン root を決める

<!-- BEGIN shared:skill-entry/root-block -->
```bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-/absolute/path/to/this/plugin}"
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

`${.product_context}` `${.product_north_star}` `${.product_strategy}`を読み、[反証契約](references/critique.md)と`${.instructions.critique.directive}`に従う。

## 2. 独立した文脈で反証する

可能なら作成時の会話を持たない別の評価文脈で行う。同じ文脈で行った場合は「独立評価」と呼ばず、その制約を明記する。入力文書を編集せず、各主張を根拠まで辿る。

診断について、現状が生む問題とNorth Starへ進む際の障壁を見落としていないか、症状を原因と誤認していないか、最重要課題を選べているか、反対の説明がより妥当でないかを問う。基本方針について、課題へ効く選択か、制約を扱うか、何を捨てたかを問う。一貫した行動について、それぞれが診断した課題へ働きかけ、前の行動が次を可能にし、得た学びが前段を強くするかを問う。全体を止める弱い環を外していないか、一つの行動を外しても説明が変わらない寄せ集めでないか、まず到達する状態が手の届く範囲にあり、到達後に次の障害が見えるかも確かめる。

## 3. 判定する

重大な欠陥が一つでもあれば`要修正`にする。文章の洗練度で`合格`にしない。`合格`は正しさの保証ではなく、提示された根拠に対して戦略カーネルが実行可能な整合性を持つという判定である。

## 4. 検査して保存する

`## 判定`には`合格`か`要修正`だけを書く。続けて`## 診断への反証` `## 基本方針への反証` `## 一貫した行動への反証` `## 鎖構造と近い目標への反証` `## 制約・根拠・鮮度` `## 修正要求`を持たせる。

```bash
python3 "${PLUGIN_ROOT}/scripts/artifact.py" write --config "$CFG_FILE" \
  --topic <題材> --body-file <本文ファイル>
```

## 5. 報告する

保存先、判定、重大指摘、修正後に再評価すべき条件を報告する。`要修正`なら戦略を検証済みにしない。
