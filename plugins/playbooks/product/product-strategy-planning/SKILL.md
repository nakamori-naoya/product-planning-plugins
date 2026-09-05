---
name: set-product-strategy
description: 完成済みのProduct North Starを入力として検査し、現在地と制約を整理し、grillでトレードオフと資源集中を確かめ、Rumelt型Product Strategyを独立反証して資料にする。「北極星を変えずにプロダクト戦略を立てて」「このNorth Starへの行き方を資料にして」と言われたときに使う。
---

# set-product-strategy

**有効なProduct North Star成果物が無ければ開始しない。** 入力されたNorth Starを更新・置換せず、異論は再策定の必要性として報告する。

## 0. プラグイン root を決める

<!-- BEGIN shared:skill-entry/root-block -->
```bash
BUNDLE_ROOT="${CLAUDE_PLUGIN_ROOT:-/absolute/path/to/this/plugin}"
if [ -d "${BUNDLE_ROOT}/playbooks/product/product-strategy-planning" ]; then
  PLUGIN_ROOT="${BUNDLE_ROOT}/playbooks/product/product-strategy-planning"
else
  PLUGIN_ROOT="${BUNDLE_ROOT}"
fi
```

`PLUGIN_ROOT`は配布物rootの絶対パスである。単一skill pluginではこの`SKILL.md`があるdirectory、複数skill pluginでは`skills/<skill>/`の2つ上に当たる。Claude Codeでは`${CLAUDE_PLUGIN_ROOT}`が自動展開される。
<!-- END shared:skill-entry/root-block -->

## 1. 工程を解決する

<!-- BEGIN shared:skill-entry/config-load -->
```bash
CFG_FILE=$(bash "${PLUGIN_ROOT}/scripts/prepare.sh" "$(pwd)") || exit 2
trap 'rm -f "$CFG_FILE"' EXIT
```

**このコマンドは説明例ではない。必ず実行する。** 解決済みYAMLが空なら先へ進まない。設定ファイルを直接読んで代用しない。

本文中の `${...}` は解決済みYAMLのプロパティである。使用時に `yq -er` で読み、欠落または `null` なら停止する。
<!-- END shared:skill-entry/config-load -->

`${.instructions.execution.directive}`と`${.instructions.interaction.directive}`に従い、`${.playbook.steps}`を上から実行する。各skillへ`--scope=${.resolution.scope_root}`を渡し、`${.playbook.contract}`と前工程の成果物を渡す。

## 2. North Starを固定して戦略を作る

先頭の検査工程でNorth Starの必須節とハッシュ値を確かめる。現在地を事実・仮説・未確認事項と制約・能力・機会へ分け、現状が生む問題とNorth Starへ進む際の障壁を課題候補として洗い出す。そのうえでgrillにより、最重要課題、全体を止める弱い環、手が届く近い目標、制約への態度、トレードオフ、やらないこと、資源集中を一度に一問だけ確かめる。

Product StrategyをRumeltの診断・基本方針・一貫した行動の三つだけで保存する。一貫した行動では、前の行動が次を可能にする因果と、まず到達する状態を本文の流れとして示す。North Starへの異論は成果物へ書き戻さず、再策定が必要な理由として残す。

## 3. 独立反証して資料にする

可能なら作成時と別の文脈で反証する。同じ文脈なら制約を明記する。最終検査でNorth Starのハッシュ値と判定を再確認し、`要修正`なら停止する。`合格`の検証済み戦略だけを`write-doc`へ渡し、`${.playbook.document_type}`と`${.playbook.output_format}`を指定して資料を保存する。最終資料の存在を確認してから、`${.playbook.contract.cleanup}`で削除候補にした現在地、戦略候補、批評、検証用成果物だけを後片付けし、入力したNorth Starと最終資料は残す。

最終資料、現在地、反証結果の保存先、判定、主要な選択、未決、方針を見直す条件を報告する。資料が保存されるまで完了にしない。
