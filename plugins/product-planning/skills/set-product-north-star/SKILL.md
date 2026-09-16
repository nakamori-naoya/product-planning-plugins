---
name: set-product-north-star
description: 顧客理解、価値仮説、参照資料から、grillで受益者、望む未来、価値、判断原則、非目標、見直し条件を確かめ、戦略や行動計画を混ぜずProduct North Star資料を完成させる。「プロダクトの北極星を対話で作って」「戦略とは分けて目指す方向を資料にして」と言われたときに使う。
---

# set-product-north-star

プロダクトが誰にどんな価値ある未来を実現するかを、長期の意思決定基準として1本のProduct North Star資料に固める。読み終えた利用者は、機能やロードマップの是非を判断するときに戻れる基準と、その基準を疑い直す条件を持つ。現在の障害への基本方針、資源配分、期限つき行動はProduct Strategyの責務であり、ここでは作らない。

## 入力

- `user_input`: 顧客理解、価値仮説、現在地についての依頼と発言。
- `referenced_artifacts`: 明示された参照資料の絶対path配列。任意。
- `document_destination`: 新規作成なら `{output_directory: <既存の書き込み可能な絶対directory>, name: <.md名>}`、更新なら `{update_target: <既存Markdownの絶対path>}` のどちらか一方だけを持つobject。片側の欠落、両方式の混在、未知キー、未確定の保存先は受け取らず、利用者へ確認して止まる。

同じagentが、同じdirectoryの [`playbook.yml`](playbook.yml) を読み、その `steps` の宣言順を実行順の正本にする。`agent_work: invoking_agent` の工程はこのagentが同じ文脈で意味判断し、`script:` は決定論的な構造検査、`playbook:` は依存先の公開playbookの呼び出しである。工程間で値を運ぶためのfileは作らない。

## 判断基準

[`references/judgment-guidance.md`](references/judgment-guidance.md) と [`references/product-north-star.md`](references/product-north-star.md) を全文読み、次で判定する。

- **資料から分かることか、利用者の価値判断か。** 資料や既知の事実から分かることは問わず、根拠付きの前提として示す。受益者、望む未来、約束する価値、プロダクトの役割、判断原則、非目標、見直し条件のうち入力だけでは決まらないものだけを `grill` へ渡す。
- **事実・仮説・未確認・決定・未決を分けているか。** 事実は出典と観測時点を持ち、仮説は反証方法を、未確認事項は確認先を添える。資料が無い部分をもっともらしい事実で補わない。
- **North Starか、戦略か。** 誰のどんな仕事の状態を変え、プロダクトが何を担い、どの近道を選ばないかまでを書く。順位、指標、手段（「業界No.1」「MAUを100万に」「AI機能を搭載」）は価値ある未来ではない。診断、基本方針、一貫した行動、資源配分、行動計画、ロードマップ、期限つき施策が現れたら、それはStrategyへ送る。
- **判断原則は二択を分けるか。** 実際の場面で選択を分ける少数の原則だけを置き、何も捨てない標語は置かない。
- **保存先は依頼で示されたか。** `document_destination` をそのまま使い、既定の置き場を補わない。

## 手順

1. **価値判断を確かめる（`settle-north-star`）。** `grill` の公開契約の入力object（`contract: grill/grill`、`version: 1`、`topic`、`context` の `purpose` / `audience` / `boundary`、`questions`（推奨付き。無ければ `[]`）、既知の材料の `grounding`。保存も求められた場合だけ `output_to`）を公開Skill `grill:grill` へ直接渡し、一問ずつの対話を同じ会話で進める。返ったobjectの `status` が `completed` なら `decisions` と `open_questions` を使い、`failed` なら `reason` を報告して止まる。契約IDや版の不一致、`rationale` の無い決定、`open` / `withdrawn` 以外の状態、配列の欠落や `null` は不正な結果として止まる。空配列は合法である。
2. **根拠を分ける（`ground-north-star`）。** 依頼、参照資料、対話の決定と未決を一つの文脈で読み、根拠・仮説・決定・未決へ区別する。
3. **North Starを構成する（`define-north-star`）。** `## 対象` `## 望む状態` `## 約束する価値` `## プロダクトの役割` `## 判断原則` `## やらないこと` `## 根拠と仮説` `## 見直し条件` `## 未決` の節を持つ本文を作る。節内はラベル付き箇条書きへ分解せず、意味のある小見出しと本文で関係を読めるようにする。system temporary directory内にrun専用の `work_directory` を作り、本文と同じ内容を検査用fileへ書く。
4. **境界を検査する（`verify`）。** `python3 scripts/verify.py --config playbook.yml --north-star <検査用fileの絶対path>` を実行する。入力は同じdirectoryの `playbook.yml`（`contract.north_star_sections` / `forbidden_sections`）と検査対象、出力は標準出力のJSON、終了codeは `0` = 合格、`2` = 必須節の欠落・空欄・戦略の節の混入（診断は標準エラー）。`2` なら本文を直して再検査し、通るまで保存へ進まない。
5. **保存する（`document`）。** 公開Skill `write-doc:write-doc` へ、`material: [{kind: text, content: <検査済み本文>}]`、`document_type: north-star`、`document_destination` から組んだ新規（`output_directory` + `name`）または更新（`update_target`）の保存先、追加で従わせる資料があるときだけ `references` を直接渡す。返ったobjectの `status` が `completed` なら `path` を最終資料、`failed` なら `reason` を報告して止まる。
6. **後片付けする（`cleanup`）。** 最終資料の保存を確認した後だけ、`python3 scripts/cleanup.py --config playbook.yml --work-dir <work_directory> --artifact candidate_product_north_star_path=<検査用file> --artifact product_north_star_document_path=<最終資料>` を実行する。`contract.cleanup.delete_after_document` にある論理名のfileだけをrun専用directory内で削除し、保持対象、directory外、symlink、追跡済みfileは削除しない。終了codeは `0` = 削除した、`2` = 契約を満たさず何も削除していない（診断は標準エラー）。`2` なら残ったfileのpathを報告する。

## 停止条件

- `document_destination` が契約の形でない、または保存先が未確定。利用者へ確認して止まる。
- `grill` が `failed`、または契約に合わない結果を返した。理由を報告して止まる。
- `verify.py` が `2` を返し続ける。戦略の節や空欄を直せない理由を報告して止まる。
- `write-doc` が `failed` を返した。`reason` を報告し、資料が保存されたことにしない。

## 出力

最終資料の絶対path、North Starの一文、重要な判断原則と非目標、根拠・仮説・未決、見直し条件を報告する。資料が保存されるまで完了にしない。
