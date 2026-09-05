---
name: set-product-north-star
description: 顧客理解、価値仮説、参照資料から、grillで受益者、望む未来、価値、判断原則、非目標、見直し条件を確かめ、戦略や行動計画を混ぜずProduct North Star資料を完成させる。「プロダクトの北極星を対話で作って」「戦略とは分けて目指す方向を資料にして」と言われたときに使う。
---

# set-product-north-star

**入力をそのまま整形しない。** 観測できる根拠・仮説・未決を分け、価値判断はgrillで一問ずつ確かめる。現在の制約から戦略や行動計画は作らない。

## 0. プラグイン root を決める

<!-- BEGIN shared:skill-entry/root-block -->
```bash
BUNDLE_ROOT="${CLAUDE_PLUGIN_ROOT:-/absolute/path/to/this/plugin}"
if [ -d "${BUNDLE_ROOT}/playbooks/product/product-north-star-planning" ]; then
  PLUGIN_ROOT="${BUNDLE_ROOT}/playbooks/product/product-north-star-planning"
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

## 2. 対話で価値判断を確かめる

grillを必ず実行し、受益者、望む未来、約束する価値、プロダクトの役割、判断原則、非目標、見直し条件を一度に一問だけ確かめる。資料から判明することを聞かず、決定と未決を分ける。

## 3. 境界を検証して資料にする

North Star成果物を保存した後、検査工程で必須節、空欄、節の順序、戦略カーネルや行動計画の混入を検査する。検査済み成果物だけを`write-doc`へ渡し、`${.playbook.document_type}`と`${.playbook.output_format}`を指定して資料を保存する。最終資料の存在を確認してから、`${.playbook.contract.cleanup}`で削除候補にした作業用成果物だけを後片付けし、保持対象は残す。

最終資料の保存先、North Starの一文、重要な判断原則と非目標、根拠・仮説・未決、見直し条件を報告する。資料が保存されるまで完了にしない。Product Strategyは作らない。
