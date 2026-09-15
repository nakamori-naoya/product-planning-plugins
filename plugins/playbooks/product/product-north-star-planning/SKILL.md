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
printf '%s\n' "$CFG_FILE"
```

**このコマンドは説明例ではない。必ず実行する。** 解決済みYAMLが空なら先へ進まない。設定ファイルを直接読んで代用しない。

本文中の `${...}` は解決済みYAMLのプロパティである。使用時に `yq -er` で読み、欠落または `null` なら停止する。
<!-- END shared:skill-entry/config-load -->

`${.instructions.execution.directive}`と`${.instructions.interaction.directive}`に従い、`${.playbook.steps}`を上から実行する。自分のpackageのskillへは`--scope=${.resolution.scope_root}`と`${.playbook.contract}`と前工程の成果物を渡す。外部packageは`playbook:`の工程でだけ呼び、`§2`の手順に従う。

一時ファイルは解決済みYAMLと同じdirectory（`$(dirname "$CFG_FILE")`）へ置く。

## 2. grillで価値判断を確かめる

`settle-north-star`工程では、`grill`の公開契約だけを使う。相手のskill名、工程id、references、config、保存モード名、非公開pathは使わない。

`grill`の公開契約が定める入力object、または同じ内容を書いた入力YAMLの絶対pathを`${.deps.grill.entry}`へ直接渡す。依存先の`prepare.sh`、`resolve.sh`、解決済みYAMLは使わない。完了したら、入力で指定した`output_to`の絶対pathに書かれた出力YAMLを読む。相手の内部の記録やログは読まない。

### settle-north-star（`grill`）

入力に`topic`、`context`（`purpose`・`audience`・`boundary`）、`questions`（`{id, question, recommendation}`。推奨は必ず添える）、既に分かっている材料の`grounding`、`output_to`を渡す。受益者、望む未来、約束する価値、プロダクトの役割、判断原則、非目標、見直し条件は、ここで一度に一問だけ確かめる。題材固有の観点は`context`で渡し、相手に持ち込ませない。

入力を`${.deps.grill.entry}`へ直接渡し、その公開入口に従って実行する。

出力は`decisions`と`open_questions`の2つだけである。「根拠づけられた入力」は相手の出力ではないので、次の`ground-north-star`工程がこちらの側で束ねる。

```bash
python3 "${PLUGIN_ROOT}/scripts/ground.py" --config "$CFG_FILE" \
  --dialogue-output "<output_toのpath>" \
  --request "<依頼のpath>" --reference "<参照資料のpath>" \
  --output "<束ねた入力の書き込み先>"
```

契約を満たさない出力（契約IDや版の不一致、`status`が`completed`でない、`rationale`の無い決定、`open`/`withdrawn`以外の状態）では束ねずに停止する。

### document（`write-doc`）

契約ID `write-doc/write-doc` の公開playbookへ入力objectを直接渡す。`material`は検査済みNorth Starの絶対pathを`{kind: file, path: <絶対path>}`にした1要素の配列、`document_type`は`north-star`とする。追加で従わせる資料がある場合だけ、こちらが所有する読み取り可能な絶対pathを`references`へ渡す。

新規作成では、利用者が明示した`output_directory`と`.md`で終わる`name`を必ず組にする。既存資料を更新する場合は、その2つを渡さず、利用者が明示した既存Markdownの絶対pathを`update_target`へ渡す。保存先が未確定なら利用者へ確認し、推測で補わない。

入力YAML、解決済みYAML、依存先の`prepare.sh`、結果受取用ファイルは使わない。公開playbookが直接返した`status`が`completed`なら`path`を`product_north_star_document_path`として次へ渡す。`failed`なら`reason`を報告して停止する。1回の呼び出しで作る資料は1本だけである。

## 3. 境界を検証して資料にする

North Star成果物を保存した後、検査工程で必須節、空欄、節の順序、戦略カーネルや行動計画の混入を検査する。検査済み成果物だけを`document`工程へ渡す。

最終資料の保存を確認したら、`scripts/cleanup.py`へ`--config "$CFG_FILE"`と`--artifact <論理名>=<絶対path>`を渡し、`${.playbook.contract.cleanup}`で削除候補にした自分の作業用成果物だけを後片付けする。保持対象・repositoryの外・追跡済みファイルは削除しない。後片付けを外部packageへ委ねない。

最終資料の保存先、North Starの一文、重要な判断原則と非目標、根拠・仮説・未決、見直し条件を報告する。資料が保存されるまで完了にしない。Product Strategyは作らない。

## 実行設定の寿命

prepareが返した絶対pathを実行記録へ保持する。別shellではそのpathを`CFG_FILE`へ明示して読み、shell変数の継承を前提にしない。完了時と失敗停止時のどちらも、最後の設定利用後に`python3 "${PLUGIN_ROOT}/scripts/run-config.py" cleanup --config "$CFG_FILE"`を実行する。他runの設定やdirectoryを削除しない。**外部packageの実行設定には触れない。**

条件付き工程を含め、各工程を呼ぶ直前に`yq -o=json '.' "$CFG_FILE" | python3 "${PLUGIN_ROOT}/scripts/resolve-dependency.py" --check-steps <工程id>`を実行する。失敗時は工程を実行せず停止する。
