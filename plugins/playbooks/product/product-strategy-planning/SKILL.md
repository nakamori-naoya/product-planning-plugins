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
printf '%s\n' "$CFG_FILE"
```

**このコマンドは説明例ではない。必ず実行する。** 解決済みYAMLが空なら先へ進まない。設定ファイルを直接読んで代用しない。

本文中の `${...}` は解決済みYAMLのプロパティである。使用時に `yq -er` で読み、欠落または `null` なら停止する。
<!-- END shared:skill-entry/config-load -->

`${.instructions.execution.directive}`と`${.instructions.interaction.directive}`に従い、`${.playbook.steps}`を上から実行する。自分のpackageのskillへは`--scope=${.resolution.scope_root}`と`${.playbook.contract}`と前工程の成果物を渡す。外部packageは`playbook:`の工程でだけ呼び、`§2`の手順に従う。

一時ファイルは解決済みYAMLと同じdirectory（`$(dirname "$CFG_FILE")`）へ置く。

## 2. 外部playbookの呼び方

`playbook:`の工程（`settle-strategy`と`document`）は、相手の公開契約だけを使って呼ぶ。相手のskill名、工程id、references、config、保存モード名、scriptの引数は使わない。**呼び方は2段だけである。**

### 第1段 — こちらが解決する

相手の`CONTRACT.md`が定める入力schemaで入力YAMLを書く。`contract`・`version`・`output_to`は必ず入れ、`output_to`は自分が用意する絶対pathにする。そのうえで相手の`prepare.sh`を通す。

```bash
DEP_CFG=$(bash "${.deps.<論理名>.root}/scripts/prepare.sh" "$(pwd)" \
  --input="<入力YAMLの絶対path>" \
  --scope="${.resolution.scope_root}" \
  --bindings="${.resolution.bindings_lock}") || exit 2
```

標準出力に返る絶対pathが、相手の解決済みYAMLである。空なら工程を実行せず停止する。

### 第2段 — 入口のSKILL.mdへ渡して実行させる

`${.deps.<論理名>.entry}`が相手の入口SKILL.mdである。**第1段で得た`$DEP_CFG`を`CFG_FILE`として渡し**、そのSKILL.mdに従って実行する。入口は相手の契約が選ぶので、相手の公開skill名を知る必要はない。

**相手に`prepare.sh`を再実行させない。** 解決は第1段で終わっている。二度解決すると、こちらが渡した`--input`と、入口playbookが決めた`--scope`・束縛lockが捨てられ、後始末の持ち主も分からなくなる。

相手のrootから他のpath（`scripts/`のそれ以外、`skills/`、`references/`、`config/`）を組み立てない。相手の実行設定の後始末は相手が自分で行う。完了したら`output_to`の絶対pathに書かれた出力YAMLを読む。**相手の内部の記録やログは読まない。**

### settle-strategy（`grill`）

入力に`topic`、`context`（`purpose`・`audience`・`boundary`）、`questions`（`{id, question, recommendation}`。推奨は必ず添える）、既に分かっている材料の`grounding`（North Starと現在地の成果物）、`output_to`を渡す。最重要課題、全体を止める弱い環、手が届く近い目標、制約への態度、トレードオフ、やらないこと、資源集中は、ここで一度に一問だけ確かめる。題材固有の観点は`context`で渡し、相手に持ち込ませない。

第1段は `bash "${.deps.grill.root}/scripts/prepare.sh"`、第2段は `${.deps.grill.entry}` のSKILL.mdである。

出力は`decisions`と`open_questions`の2つだけである。「根拠づけられた入力」は相手の出力ではないので、次の`ground-strategy`工程がこちらの側で束ねる。

```bash
python3 "${PLUGIN_ROOT}/scripts/ground.py" --config "$CFG_FILE" \
  --dialogue-output "<output_toのpath>" \
  --request "<依頼のpath>" --reference "<参照資料のpath>" \
  --output "<束ねた入力の書き込み先>"
```

契約を満たさない出力（契約IDや版の不一致、`status`が`completed`でない、`rationale`の無い決定、`open`/`withdrawn`以外の状態）では束ねずに停止する。

### document（`write-doc`）

入力の必須は`contract: write-doc/write-doc`、`version: 1`、`material`（**絶対pathの配列**。検証済み戦略・North Star・現在地・反証結果を素材として束ねたもの。1つ以上、それぞれ通常ファイル）、`output_to`である。任意で`document_type`（`${.playbook.document_type}`）、`output_format`（`${.playbook.output_format}`）、追加指示の`references`（こちらが書いた文書だけ）を渡す。保存先は、新規作成なら`name`、既存資料の差し替えなら`update_target`を渡す。この2つは**排他**で、両方を渡しても、どちらも渡さなくても止まる。`output_directory`は任意で、渡すなら`name`も要る。

**依頼に無い保存先を推測して渡さない。** `output_directory`を渡さない新規作成では、利用者が作業repositoryの設定で決めた保存先へ保存される。未知のキーを渡すと止まる。型の実現方法、テンプレート、記載例は相手に委ね、こちらは型名と検証済み素材だけを渡す。

第1段は `bash "${.deps.write-doc.root}/scripts/prepare.sh"`、第2段は `${.deps.write-doc.entry}` のSKILL.mdである。

出力YAMLは`status`（`completed` | `failed`）、`path`、`document_type`、`output_format`（失敗時は`reason`）を持つ。1回の呼び出しで作る資料は1本だけである。`status: completed`と`path`を確かめてから、次へ進む。

## 3. North Starを固定して戦略を作る

先頭の検査工程でNorth Starの必須節とハッシュ値を確かめる。現在地を事実・仮説・未確認事項と制約・能力・機会へ分け、現状が生む問題とNorth Starへ進む際の障壁を課題候補として洗い出す。そのうえで`settle-strategy`で戦略上の選択を確かめ、`ground-strategy`でNorth Star、現在地、課題候補、決定と未決を根拠づけられた入力へ束ねる。

Product StrategyをRumeltの診断・基本方針・一貫した行動の三つだけで保存する。一貫した行動では、前の行動が次を可能にする因果と、まず到達する状態を本文の流れとして示す。North Starへの異論は成果物へ書き戻さず、再策定が必要な理由として残す。

## 4. 独立反証して資料にする

可能なら作成時と別の文脈で反証する。同じ文脈なら制約を明記する。最終検査でNorth Starのハッシュ値と判定を再確認し、`要修正`なら停止する。`合格`の検証済み戦略だけを`document`工程へ渡す。

最終資料の保存を確認したら、`scripts/cleanup.py`へ`--config "$CFG_FILE"`と`--artifact <論理名>=<絶対path>`を渡し、`${.playbook.contract.cleanup}`で削除候補にした現在地、戦略候補、批評、検証用成果物だけを後片付けする。入力したNorth Starと最終資料、repositoryの外、追跡済みファイルは削除しない。後片付けを外部packageへ委ねない。

最終資料、現在地、反証結果の保存先、判定、主要な選択、未決、方針を見直す条件を報告する。資料が保存されるまで完了にしない。

## 実行設定の寿命

prepareが返した絶対pathを実行記録へ保持する。別shellではそのpathを`CFG_FILE`へ明示して読み、shell変数の継承を前提にしない。完了時と失敗停止時のどちらも、最後の設定利用後に`python3 "${PLUGIN_ROOT}/scripts/run-config.py" cleanup --config "$CFG_FILE"`を実行する。他runの設定やdirectoryを削除しない。**外部packageの実行設定には触れない。**

条件付き工程を含め、各工程を呼ぶ直前に`yq -o=json '.' "$CFG_FILE" | python3 "${PLUGIN_ROOT}/scripts/resolve-dependency.py" --check-steps <工程id>`を実行する。失敗時は工程を実行せず停止する。
