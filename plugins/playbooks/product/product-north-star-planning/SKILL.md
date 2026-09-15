---
name: set-product-north-star
description: 顧客理解、価値仮説、参照資料から、grillで受益者、望む未来、価値、判断原則、非目標、見直し条件を確かめ、戦略や行動計画を混ぜずProduct North Star資料を完成させる。「プロダクトの北極星を対話で作って」「戦略とは分けて目指す方向を資料にして」と言われたときに使う。
---

# set-product-north-star

**入力をそのまま整形しない。** 観測できる根拠・仮説・未決を分け、価値判断はgrillで一問ずつ確かめる。現在の制約から戦略や行動計画は作らない。

## 1. 実行契約を受け取る

このSKILLを実行する同じagentが、同じdirectoryの`playbook.yml`と本文から参照する資料を全文読み、利用者の入力と明示された資料を保持した一つの文脈で最後まで判断する。YAMLの`steps`は工程順・`needs`・`provides`の正本であり、宣言順に辿る。`agent_work: invoking_agent`は別skillや架空runtimeを呼ぶ印ではなく、このagentが同じ文脈で意味判断する工程である。`script:`は決定論的な構造検査、`playbook:`は依存先の公開Skill呼び出しだけを表す。必要な入力や結果が無ければ推測せず停止する。

公開入力`document_destination`は、新規作成なら`{output_directory: <既存の書き込み可能な絶対directory>, name: <.md名>}`、更新なら`{update_target: <既存Markdownの絶対path>}`のどちらか一方だけを持つobjectとする。片側の必須値欠落、両方式の混在、未知キー、未確定の保存先は受け取らず、利用者へ確認して停止する。旧`output_target`を互換aliasとして解釈しない。

`${.instructions.execution.directive}`と`${.instructions.interaction.directive}`に従い、`${.playbook.steps}`の認知責務を同じagentが上から実行し、決定論的toolの結果だけを工程間で受け渡す。外部packageは`playbook:`の工程でだけ呼び、`§2`の手順に従う。

## 2. grillで価値判断を確かめる

`settle-north-star`工程では、`grill`の公開契約だけを使う。相手のskill名、工程id、references、config、保存モード名、非公開pathは使わない。

`grill`の公開契約が定める入力objectを公開Skill `grill:grill`へ直接渡す。依存先の`prepare.sh`、`resolve.sh`、解決済みYAMLは使わない。完了したら公開Skillが直接返す結果objectを読む。永続記録も必要な場合だけ利用者が明示した`output_to`を追加し、相手の内部の記録やログは読まない。

### settle-north-star（`grill`）

入力objectには`contract: grill/grill`、`version: 1`、`topic`、`context`（`purpose`・`audience`・`boundary`）、`questions`（`{id, question, recommendation}`。推奨は必ず添える）、既に分かっている材料の`grounding`を渡す。保存も求める場合だけ`output_to`を追加する。受益者、望む未来、約束する価値、プロダクトの役割、判断原則、非目標、見直し条件は、ここで一度に一問だけ確かめる。題材固有の観点は`context`で渡し、相手に持ち込ませない。初期質問が無い場合の`questions: []`も合法であり、対話や最終一覧への明示合意を省略する意味にはしない。

入力を公開Skill `grill:grill`へ直接渡し、その公開入口に従って実行する。

直接返されたobjectの`status`を確認し、`completed`なら`decisions`と`open_questions`を使う。`failed`なら`reason`を報告して停止する。「根拠づけられた入力」は相手の出力ではない。`ground-north-star`工程で同じagentが対話結果、依頼、参照資料を一つの文脈に保ったまま、根拠・仮説・決定・未決へ区別する。値運搬だけのファイルは作らない。

契約を満たさない出力（契約IDや版の不一致、`status`が`completed`でない、`rationale`の無い決定、`open`/`withdrawn`以外の状態）では停止する。`decisions`と`open_questions`はキーが存在する配列でなければならず、欠落、`null`、別の型を空配列へ補正しない。契約どおりの空配列は合法として受け入れる。

### document（`write-doc`）

契約ID `write-doc/write-doc` の公開playbookへ入力objectを直接渡す。`material`は同じagentが作って検査した最終本文を`{kind: text, content: <完成本文>}`にした1要素の配列、`document_type`は`north-star`とする。追加で従わせる資料がある場合だけ、こちらが所有する読み取り可能な絶対pathを`references`へ渡す。

`document`工程はYAMLの`needs`で届いた公開`document_destination`を検査する。新規作成では利用者が明示した`output_directory`と`.md`で終わる`name`をそのまま組にし、既存資料を更新する場合はその2つを渡さず、利用者が明示した既存Markdownの絶対pathを`update_target`へそのまま渡す。保存先が未確定なら利用者へ確認し、推測で補わない。

入力YAML、解決済みYAML、依存先の`prepare.sh`、結果受取用ファイルは使わない。公開playbookが直接返した`status`が`completed`なら同じobjectの`path`を最終資料として次へ渡す。`failed`なら`reason`を報告して停止する。1回の呼び出しで作る資料は1本だけである。

## 3. 境界を検証して資料にする

[Product North Starの判断規律](references/judgment-guidance.md)を全文読む。`ground-north-star`では同資料の「根拠を分ける」を適用し、`define-north-star`では「North Starを構成する」と境界例を適用する。節名を埋めるだけでなく、対象、望む状態、価値、固有の役割、判断原則、非目標、根拠、見直し条件の関係を本文から読めるようにする。

`define-north-star`でsystem temporary directory内にrun専用`work_directory`を一つ作り、本文と同じ内容をその内側の検査用fileへ書く。`verify`で必須節、空欄、節の順序、戦略カーネルや行動計画の混入を検査する。検査済みの本文だけを`document`工程へ直接渡す。

最終資料の保存成功を確認した同じagentだけが、公開`playbook.yml`、`work_directory`、論理名つき絶対pathを`cleanup.py`へ直接渡す。`${.playbook.contract.cleanup}`で削除候補にした、run専用directory内の検査用一時ファイルだけを後片付けする。保持対象、run専用directoryの外、symlink、追跡済みファイルは削除しない。

最終資料の保存先、North Starの一文、重要な判断原則と非目標、根拠・仮説・未決、見直し条件を報告する。資料が保存されるまで完了にしない。Product Strategyは作らない。
