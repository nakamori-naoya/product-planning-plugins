---
name: set-product-strategy
description: 完成済みのProduct North Starを入力として検査し、現在地と制約を整理し、grillでトレードオフと資源集中を確かめ、Rumelt型Product Strategyを独立反証して資料にする。「北極星を変えずにプロダクト戦略を立てて」「このNorth Starへの行き方を資料にして」と言われたときに使う。
---

# set-product-strategy

**有効なProduct North Star成果物が無ければ開始しない。** 入力されたNorth Starを更新・置換せず、異論は再策定の必要性として報告する。

## 1. 実行契約を受け取る

このSKILLを実行する同じagentが、同じdirectoryの`playbook.yml`と本文から参照する資料を全文読み、利用者の入力と明示された資料を保持した一つの文脈で最後まで判断する。YAMLの`steps`は工程順・`needs`・`provides`の正本であり、宣言順に辿る。`agent_work: invoking_agent`は別skillや架空runtimeを呼ぶ印ではなく、このagentが同じ文脈で意味判断する工程である。`script:`は決定論的な構造検査、`playbook:`は依存先の公開Skill呼び出しだけを表す。必要な入力や結果が無ければ推測せず停止する。

公開入力`document_destination`は、新規作成なら`{output_directory: <既存の書き込み可能な絶対directory>, name: <.md名>}`、更新なら`{update_target: <既存Markdownの絶対path>}`のどちらか一方だけを持つobjectとする。片側の必須値欠落、両方式の混在、未知キー、未確定の保存先は受け取らず、利用者へ確認して停止する。旧`output_target`を互換aliasとして解釈しない。

`${.instructions.execution.directive}`と`${.instructions.interaction.directive}`に従い、`${.playbook.steps}`の認知責務を同じagentが上から実行し、決定論的toolの結果だけを工程間で受け渡す。外部packageは`playbook:`の工程でだけ呼び、`§2`の手順に従う。

## 2. grillで戦略上の選択を確かめる

`settle-strategy`工程では、`grill`の公開契約だけを使う。相手のskill名、工程id、references、config、保存モード名、非公開pathは使わない。

`grill`の公開契約が定める入力objectを公開Skill `grill:grill`へ直接渡す。依存先の`prepare.sh`、`resolve.sh`、解決済みYAMLは使わない。完了したら公開Skillが直接返す結果objectを読む。永続記録も必要な場合だけ利用者が明示した`output_to`を追加し、相手の内部の記録やログは読まない。

### settle-strategy（`grill`）

入力objectには`contract: grill/grill`、`version: 1`、`topic`、`context`（`purpose`・`audience`・`boundary`）、`questions`（`{id, question, recommendation}`。推奨は必ず添える）、既に分かっている材料の`grounding`（North Starと現在地）を渡す。保存も求める場合だけ`output_to`を追加する。最重要課題、全体を止める弱い環、手が届く近い目標、制約への態度、トレードオフ、やらないこと、資源集中は、ここで一度に一問だけ確かめる。題材固有の観点は`context`で渡し、相手に持ち込ませない。初期質問が無い場合の`questions: []`も合法であり、対話や最終一覧への明示合意を省略する意味にはしない。

入力を公開Skill `grill:grill`へ直接渡し、その公開入口に従って実行する。

直接返されたobjectの`status`を確認し、`completed`なら`decisions`と`open_questions`を使う。`failed`なら`reason`を報告して停止する。現在地、課題候補、対話結果は同じagentの文脈に保持し、値運搬だけの`ground-strategy`ファイルは作らない。

契約を満たさない出力（契約IDや版の不一致、`status`が`completed`でない、`rationale`の無い決定、`open`/`withdrawn`以外の状態）では停止する。`decisions`と`open_questions`はキーが存在する配列でなければならず、欠落、`null`、別の型を空配列へ補正しない。契約どおりの空配列は合法として受け入れる。

### document（`write-doc`）

契約ID `write-doc/write-doc` の公開playbookへ入力objectを直接渡す。`material`は検証済み戦略本文と反証を`{kind: text, content: <完成本文と反証>}`にしたobject配列、`document_type`は`strategy`とする。North Starは変更しない参照資料として渡す。追加で従わせる資料がある場合だけ、こちらが所有する読み取り可能な絶対pathを`references`へ渡す。

`document`工程はYAMLの`needs`で届いた公開`document_destination`を検査する。新規作成では利用者が明示した`output_directory`と`.md`で終わる`name`をそのまま組にし、既存資料を更新する場合はその2つを渡さず、利用者が明示した既存Markdownの絶対pathを`update_target`へそのまま渡す。保存先が未確定なら利用者へ確認し、推測で補わない。

入力YAML、解決済みYAML、依存先の`prepare.sh`、結果受取用ファイルは使わない。公開playbookが直接返した`status`が`completed`なら同じobjectの`path`を最終資料として次へ渡す。`failed`なら`reason`を報告して停止する。1回の呼び出しで作る資料は1本だけである。

## 3. North Starを固定して戦略を作る

先頭の検査工程でNorth Starの必須節とハッシュ値を確かめる。[現在地を読む規律](references/context-guidance.md)を全文読み、`map-context`で現在地を事実・仮説・未確認事項と制約・能力・機会へ分け、現状が生む問題とNorth Starへ進む際の障壁を課題候補として同じ文脈に保持する。そのうえで`settle-strategy`で戦略上の選択を確かめる。

[Product Strategyの判断規律](references/strategy-guidance.md)を全文読み、`form-strategy`で診断・基本方針・一貫した行動の三つを不可分の核として作る。一貫した行動では、前の行動が次を可能にする因果と、まず到達する状態を本文の流れとして示す。North Starへの異論は成果物へ書き戻さず、再策定が必要な理由として残す。

`form-strategy`でsystem temporary directory内にrun専用`work_directory`を一つ作り、候補本文と反証用fileはその内側へ置く。

## 4. 独立反証して資料にする

[戦略反証の規律](references/critique-guidance.md)を全文読み、`critique`では同じagentが入力、対話の決定、現在地、North Starを保持したまま、作成者の視点から反証者の視点へ明示的に切り替え、主張・根拠・反証・重大度・修正要求を対応づける。「別の文脈」は証拠や決定を捨てることでも別agentへ委譲することでもなく、同じ文脈内の独立した批評passを意味する。

`verify`はNorth Starのハッシュ、戦略の節構造、判定欄の存在・型・許容語彙だけを機械検査し、`合格`と`要修正`をどちらも値として保持する。続く`decide-after-critique`で同じagentが反証根拠を読み、`要修正`なら`form-strategy`へ戻して修正し、再度`critique`と`verify`を行う。意味判定をscriptへ代理させず、`合格`と判断した戦略だけを`document`工程へ渡す。

最終資料の保存成功を確認した同じagentだけが、公開`playbook.yml`、`work_directory`、論理名つき絶対pathを`cleanup.py`へ直接渡す。`${.playbook.contract.cleanup}`で削除候補にしたrun専用directory内の戦略・反証fileだけを後片付けする。入力したNorth Starと最終資料、run専用directoryの外、symlink、追跡済みファイルは削除しない。

最終資料の保存先、現在地の要約、反証結果と判定、主要な選択、未決、方針を見直す条件を報告する。資料が保存されるまで完了にしない。
