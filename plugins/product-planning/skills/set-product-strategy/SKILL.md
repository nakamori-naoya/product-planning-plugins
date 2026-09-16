---
name: set-product-strategy
description: 完成済みのProduct North Starを入力として検査し、現在地と制約を整理し、grillでトレードオフと資源集中を確かめ、Rumelt型Product Strategyを独立反証して資料にする。「北極星を変えずにプロダクト戦略を立てて」「このNorth Starへの行き方を資料にして」と言われたときに使う。
---

# set-product-strategy

既存のProduct North Starを変えずに、現在地から北極星へ近づくための時限的な選択を、診断・基本方針・一貫した行動の三つが不可分に結び付いたProduct Strategy資料に固める。読み終えた利用者は、いまどの課題へ資源を寄せ、何をしないか、どの状態に到達したら次の障害が見えるかを決められる。有効なNorth Star資料が無ければ始めない。

## 入力

- `product_north_star_path`: 完成済みProduct North Star資料の絶対path。必須。
- `user_input`: 現在地、制約、判断についての依頼と発言。
- `referenced_artifacts`: 明示された参照資料の絶対path配列。任意。
- `document_destination`: 新規作成なら `{output_directory: <既存の書き込み可能な絶対directory>, name: <.md名>}`、更新なら `{update_target: <既存Markdownの絶対path>}` のどちらか一方だけを持つobject。片側の欠落、両方式の混在、未知キー、未確定の保存先は受け取らず、利用者へ確認して止まる。

同じagentが、同じdirectoryの [`playbook.yml`](playbook.yml) を読み、その `steps` の宣言順を実行順の正本にする。`agent_work: invoking_agent` の工程はこのagentが同じ文脈で意味判断し、`script:` は決定論的な構造検査、`playbook:` は依存先の公開playbookの呼び出しである。工程間で値を運ぶためのfileは作らない。

## 判断基準

[`references/context-guidance.md`](references/context-guidance.md)、[`references/strategy-guidance.md`](references/strategy-guidance.md)、[`references/critique-guidance.md`](references/critique-guidance.md) を全文読み、必要に応じて [`references/product-context.md`](references/product-context.md)、[`references/product-strategy.md`](references/product-strategy.md)、[`references/critique.md`](references/critique.md)、[`references/product-north-star.md`](references/product-north-star.md) で判断の詳細を確かめ、次で判定する。

- **North Starは不変か。** 入力のNorth Starを更新・置換しない。異論が出たら、成果物へ書き戻さず再策定が必要な理由として報告する。
- **現在地は証拠の状態で分かれているか。** 事実（出典と観測時点）、仮説（反証方法）、未確認事項（確認先）、制約、能力、機会を混同しない。課題候補は、現状が生む問題とNorth Starへ進む際の障壁の両方から洗い出し、症状と原因候補を分ける。
- **資料から分かることか、戦略上の選択か。** 最重要課題、全体を止める弱い環、手が届く近い目標、制約への態度、トレードオフ、やらないこと、資源集中のうち、North Starと現在地だけでは決まらないものだけを `grill` へ渡す。
- **三つの節は不可分か。** 診断は状況の列挙ではなく最重要課題への圧縮、基本方針はその課題への進み方と捨てる選択、一貫した行動は前の行動が次を可能にする鎖と最初の到達状態である。一つを外しても説明が変わらない寄せ集めは戦略ではない。
- **反証の文脈は作成時と別か。** 作成時の会話を持たない別の評価文脈で行えるなら、そこで行った反証を独立評価と呼ぶ。同じagentが同じ文脈で行う反証は、証拠と決定を保持したまま作成者から反証者へ視点を切り替える批評passであり、独立評価とは呼ばず、その制約（同一文脈で行った反証であること）を反証fileの `## 制約・根拠・鮮度` と報告に明記する。`要修正` の条件（`critique-guidance.md`）に一つでも当たれば `合格` にせず、`合格` は正しさの保証ではなく提示根拠に対する整合性の判定である。
- **保存先は依頼で示されたか。** `document_destination` をそのまま使い、既定の置き場を補わない。

## 手順

1. **North Starを検査する（`validate-north-star`）。** `python3 scripts/validate-north-star.py --config playbook.yml --north-star <product_north_star_path>` を実行する。入力は同じdirectoryの `playbook.yml`（`contract.north_star_sections` / `forbidden_north_star_sections`）とNorth Star資料、出力は `product_north_star_path` と `product_north_star_sha256` を持つ標準出力のJSON、終了codeは `0` = 有効、`2` = 必須節の欠落や戦略の節の混入（診断は標準エラー）。`2` なら止まる。
2. **現在地を読む（`map-context`）。** 現在地を事実・仮説・未確認事項と制約・能力・機会へ分け、課題候補を洗い出して同じ文脈に保持する。最重要課題はまだ選ばない。
3. **戦略上の選択を確かめる（`settle-strategy`）。** `grill` の公開契約の入力object（`contract: grill/grill`、`version: 1`、`topic`、`context` の `purpose` / `audience` / `boundary`、`questions`（推奨付き。無ければ `[]`）、North Starと現在地の `grounding`。保存も求められた場合だけ `output_to`）を公開Skill `grill:grill` へ直接渡す。返ったobjectの `status` が `completed` なら `decisions` と `open_questions` を使い、`failed` なら `reason` を報告して止まる。契約IDや版の不一致、`rationale` の無い決定、`open` / `withdrawn` 以外の状態、配列の欠落や `null` は不正な結果として止まる。空配列は合法である。
4. **戦略を作る（`form-strategy`）。** `## 診断` `## 基本方針` `## 一貫した行動` だけを最上位の節に持つ本文を作る。節内は意味のある `###` 小見出しと本文で因果を読めるようにし、選ぶことと選ばないこと、行動間の因果は本文を補う図でも示してよい。system temporary directory内にrun専用の `work_directory` を作り、候補本文をその内側のfileへ書く。
5. **反証する（`critique`）。** 入力戦略を編集せず、反証者の視点で主張・根拠・反証・重大度・修正要求を対応づけ、同一文脈で行った反証ならその制約を `## 制約・根拠・鮮度` に書き、`## 判定`（`合格` か `要修正` だけ）、`## 診断への反証` `## 基本方針への反証` `## 一貫した行動への反証` `## 鎖構造と近い目標への反証` `## 制約・根拠・鮮度` `## 修正要求` を持つ反証fileを `work_directory` 内に書く。
6. **構造を検査する（`verify`）。** `python3 scripts/verify.py --config playbook.yml --north-star <product_north_star_path> --north-star-sha256 <sha256> --strategy <候補本文> --critique <反証file>` を実行する。出力は `verdict` と `strategy_path` を持つ標準出力のJSON、終了codeは `0` = 構造が契約に合う（`合格` と `要修正` のどちらも値として返る）、`2` = North Starの同一性が崩れた、戦略の節構造が違う、判定欄が無いか許容語彙外（診断は標準エラー）。`2` なら止まる。
7. **判定に従う（`decide-after-critique`）。** `要修正` なら反証根拠を読んで手順4へ戻り、修正して再び反証と検査を行う。`合格` と判断した戦略だけを保存へ進める。
8. **保存する（`document`）。** 公開Skill `write-doc:write-doc` へ、`material: [{kind: text, content: <検証済み戦略本文と反証>}]`、`document_type: strategy`、`document_destination` から組んだ新規（`output_directory` + `name`）または更新（`update_target`）の保存先、追加で従わせる資料があるときだけ `references` を直接渡す。North Starは変更しない参照資料である。返ったobjectの `status` が `completed` なら `path` を最終資料、`failed` なら `reason` を報告して止まる。
9. **後片付けする（`cleanup`）。** 最終資料の保存を確認した後だけ、`python3 scripts/cleanup.py --config playbook.yml --work-dir <work_directory> --artifact candidate_strategy_path=<候補本文> --artifact critique_path=<反証file> --artifact product_north_star_path=<North Star> --artifact product_strategy_document_path=<最終資料>` を実行する。`contract.cleanup.delete_after_document` の候補と反証fileだけをrun専用directory内で削除し、North Star、最終資料、directory外、symlink、追跡済みfileは削除しない。終了codeは `0` = 削除した、`2` = 契約を満たさず何も削除していない。`2` なら残ったfileのpathを報告する。

## 停止条件

- `validate-north-star.py` が `2` を返した。North Starが未完成または戦略の節を含むことを報告して止まる。
- `document_destination` が契約の形でない、または保存先が未確定。利用者へ確認して止まる。
- `grill` が `failed`、または契約に合わない結果を返した。理由を報告して止まる。
- `verify.py` が `2` を返した。同一性の崩れ、節構造、判定欄の問題を報告して止まる。
- `要修正` が解消しない。反証の根拠と修正要求を報告し、検証済み戦略を返さない。
- `write-doc` が `failed` を返した。`reason` を報告し、資料が保存されたことにしない。

## 出力

最終資料の絶対path、現在地の要約、反証結果と判定（同一文脈で行った反証ならその制約を添える）、最重要課題と弱い環、基本方針、行動のつながりと最初の到達状態、やらないこと、未決、方針を見直す条件を報告する。資料が保存されるまで完了にしない。
