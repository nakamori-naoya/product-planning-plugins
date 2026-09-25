---
name: set-product-strategy
description: 完成済みのProduct North Starを入力として検査し、現在地と制約を整理し、grillでトレードオフと資源集中を確かめ、Rumelt型Product Strategyを反証して資料にする。「北極星を変えずにプロダクト戦略を立てて」「このNorth Starへの行き方を資料にして」と言われたときに使う。
---

# set-product-strategy

既存のProduct North Starを変えずに、現在地から北極星へ近づくための時限的な選択を、診断・基本方針・一貫した行動の三つが不可分に結び付いたProduct Strategy資料に固める。読み終えた利用者は、いまどの課題へ資源を寄せ、何をしないか、どの状態に到達したら次の障害が見えるかを決められる。有効なNorth Star資料が無ければ始めない。

## 入力

- `product_north_star_path`: 完成済みProduct North Star資料の絶対path。必須。
- `user_input`: 現在地、制約、判断についての依頼と発言。
- `references`: 追加で従う資料の絶対path配列。任意。手順の最初に読む。プロジェクト固有の規約や文脈は、対象repositoryのAGENTS.md / CLAUDE.mdとこの入力で渡される。
- `document_destination`: 新規作成なら `{output_directory: <既存の書き込み可能な絶対directory>, name: <.md名>}`、更新なら `{update_target: <既存Markdownの絶対path>}` のどちらか一方だけを持つobject。片側の欠落、両方式の混在、未知キー、未確定の保存先は受け取らない。

同じagentが、同じdirectoryの [`playbook.yml`](playbook.yml) を読み、その `steps` の宣言順を実行順の正式な定義にする。`agent_work: invoking_agent` の工程はこのagentが同じ文脈で意味判断し、`script:` は決定論的な構造検査、`playbook:` は依存先の公開playbookの呼び出しである。戦略本文と反証はインメモリで保持し、検査scriptへは標準入力で渡す。工程間で値を運ぶためのfileや作業directoryは作らない。

## 判断基準

[`references/context-guidance.md`](references/context-guidance.md)、[`references/strategy-guidance.md`](references/strategy-guidance.md)、[`references/critique-guidance.md`](references/critique-guidance.md) を全文読み、必要に応じて [`references/product-context.md`](references/product-context.md)、[`references/product-strategy.md`](references/product-strategy.md)、[`references/critique.md`](references/critique.md)、[`references/product-north-star.md`](references/product-north-star.md) で判断の詳細を確かめ、次で判定する。

- **North Starは不変か。** 入力のNorth Starを更新・置換しない。異論が出たら、成果物へ書き戻さず再策定が必要な理由として報告する。
- **現在地は証拠の状態で分かれているか。** 事実（出典と観測時点）、仮説（反証方法）、未確認事項（確認先）、制約、能力、機会を混同しない。資料が無い部分は、その時点の根拠から最も筋の良い仮説を立てて仮説と分かる形で書く。課題候補は、現状が生む問題とNorth Starへ進む際の障壁の両方から洗い出し、症状と原因候補を分ける。
- **資料から分かることか、戦略上の選択か。** 最重要課題、全体を止める弱い環、手が届く近い目標、制約への態度、トレードオフ、やらないこと、資源集中のうち、North Starと現在地だけでは決まらないものだけを `grill` の候補にする。
- **成果を左右する問いか。** 候補のうち、回答によって最重要課題・基本方針・捨てる選択・最初の到達状態が別物になるものを先に並べて `questions` に渡す。表現や粒度しか変わらない論点、資料を見てから確かめれば足りる論点は渡さず、推奨を仮置きした未決にする。問う数の上限と対話の作法は `grill` の公開契約に従い、上限で問われなかった問いは推奨付きの `open_questions` として返る。問わなかった論点と `grill` の `open_questions` は、推奨を仮置きした本文と反証の `## 制約・根拠・鮮度`、報告の未決に仮説であること・根拠・採らなかった解釈を添えて載せる。
- **三つの節は不可分か。** 診断は状況の列挙ではなく最重要課題への圧縮、基本方針はその課題への進み方と捨てる選択、一貫した行動は前の行動が次を可能にする鎖と最初の到達状態である。一つを外しても説明が変わらない寄せ集めは戦略ではない。
- **反証の視点を切り替えたか。** 反証は、同じagentが同じ文脈で、証拠と決定を保持したまま作成者から反証者へ視点を切り替えて行う批評passである。独立評価とは呼ばず、その制約（同一文脈で行った反証であること）を反証fileの `## 制約・根拠・鮮度` と報告に明記する。`要修正` の条件（`critique-guidance.md`）に一つでも当たれば `合格` にせず、`合格` は正しさの保証ではなく提示根拠に対する整合性の判定である。
- **保存先は依頼で示されたか。** `document_destination` をそのまま使い、既定の置き場を補わない。

## 手順

1. **North Starを検査する（`validate-north-star`）。** `python3 scripts/validate-north-star.py --config playbook.yml --north-star <product_north_star_path>` を実行する。入力は同じdirectoryの `playbook.yml`（`contract.north_star_sections` / `forbidden_north_star_sections`）とNorth Star資料、出力は `product_north_star_path` と `product_north_star_sha256` を持つ標準出力のJSON、終了codeは `0` = 有効、`2` = 必須節の欠落や戦略の節の混入（診断は標準エラー）。`2` なら止まる。
2. **現在地を読む（`map-context`）。** 現在地を事実・仮説・未確認事項と制約・能力・機会へ分け、課題候補を洗い出して同じ文脈に保持する。最重要課題はまだ選ばない。
3. **戦略上の選択を確かめる（`settle-strategy`）。** `grill` の公開契約の入力object（`contract: grill/grill`、`version: 1`、`topic`、`context` の `purpose` / `audience` / `boundary`、判断基準で選び成果を左右する順に並べた `questions`（推奨付き。無ければ `[]`）、North Star・現在地の資料と入力の `references`。保存も求められた場合だけ `output_to`）を公開Skill `grill:grill` へ直接渡し、対話は `grill` の公開契約に従って同じ会話で進める。返ったobjectの `status` が `completed` なら `decisions` と `open_questions` を使い、`failed` なら `reason` を報告して止まる。契約IDや版の不一致、`rationale` の無い決定、`open` / `withdrawn` 以外の状態、配列の欠落や `null` は不正な結果として止まる。空配列は合法である。2回目の `grill` は、利用者が求めた場合か、決定なしでは戦略を完成できない場合だけ行う。
4. **戦略を作る（`form-strategy`）。** `## 診断` `## 基本方針` `## 一貫した行動` だけを最上位の節に持つ本文をインメモリで作る。節は見出しの最初の半角`:`より前の名前で見つかる（write-docの公開契約の「検査が読む目印」）ので、`:`の後ろに節の結論を書いてよい。節内は意味のある `###` 小見出しと本文で因果を読めるようにし、選ぶことと選ばないこと、行動間の因果は本文を補う図でも示してよい。問わなかった論点と `open_questions` は推奨を仮置きし、該当箇所に仮説と分かる形で書く。推奨が無い未決は、agentが根拠から自分の仮説を置き、仮説として明示する。置けない（判断者の決定が要る）ものだけhard stop。
5. **反証する（`critique`）。** 入力戦略を編集せず、反証者の視点で主張・根拠・反証・重大度・修正要求を対応づけ、`## 判定`（`合格` か `要修正` だけ）、`## 診断への反証` `## 基本方針への反証` `## 一貫した行動への反証` `## 鎖構造と近い目標への反証` `## 制約・根拠・鮮度` `## 修正要求` を持つ反証本文をインメモリで作る。同一文脈で行った反証ならその制約を、仮置きした推奨があればその一覧を `## 制約・根拠・鮮度` に書く。
6. **構造を検査する（`verify`）。** `{"strategy": <戦略本文>, "critique": <反証本文>}` のJSON objectを標準入力で `python3 scripts/verify.py --config playbook.yml --north-star <product_north_star_path> --north-star-sha256 <sha256>` へ渡す。入力は標準入力のJSON（`strategy` と `critique` のちょうど2 key、値は空でない文字列）、同じdirectoryの `playbook.yml`（`contract.strategy_sections` / `critique_verdicts`）、Product North Star資料のpathとsha256。出力は `verdict` と `product_north_star_path` を持つ標準出力のJSON、終了codeは `0` = 構造が契約に合う（`合格` と `要修正` のどちらも値として返る）、`2` = 標準入力が空か不正JSON、keyの過不足、North Starの同一性が崩れた、戦略の節構造が違う、判定欄が無いか許容語彙外（診断は標準エラー）。`2` なら止まる。渡し方の例:

   ```bash
   jq -n --arg strategy "$STRATEGY" --arg critique "$CRITIQUE" '{strategy: $strategy, critique: $critique}' \
     | python3 scripts/verify.py --config playbook.yml --north-star "$NORTH_STAR" --north-star-sha256 "$SHA256"
   ```

7. **判定に従う（`decide-after-critique`）。** `要修正` なら反証根拠を読んで手順4へ戻り、修正して再び反証（手順5）と検査（手順6）を行う。修正要求の原因が根拠の不足で、これ以上の資料が今は無いなら、手順4で本文の該当箇所に仮説を明示して要求を未決へ移し、その本文に対して手順5で反証を書き直す。書き直した反証で残る修正要求が無ければ `## 判定` を `合格` と書き、手順6の検査を通す。判定は常に反証本文の `## 判定` として書き、`verify.py` が返す `verdict` で確かめる。著者が判定値だけを書き換えて保存へ進まない。`合格` の戦略だけを保存へ進める。
8. **保存する（`document`）。** 公開Skill `write-doc:write-doc` へ、`material: [{kind: text, content: <検証済み戦略本文と反証>}]`、`document_type: strategy`、`document_destination` から組んだ新規（`output_directory` + `name`）または更新（`update_target`）の保存先、入力の `references` をそのまま `references` に渡す（空なら空配列）。North Starは変更しない参照資料である。返ったobjectの `status` が `completed` なら `path` を最終資料、`failed` なら `reason` を報告して止まる。

## 停止条件

止まるのは次の場合である。理由を報告し、資料が保存されたことにしない。

- `validate-north-star.py` が `2` を返した。North Starが未完成または戦略の節を含む。
- `document_destination` が契約の形でない、または保存先が確認できない。既定の置き場を補わず、利用者へ保存先を確認して止まる。
- `grill` が `failed`、または契約に合わない結果を返した。
- `verify.py` が `2` を返した。同一性の崩れ、節構造、判定欄の問題を直せない。
- `write-doc` が `failed` を返した。
- 推奨が無い未決のうち、判断者の決定が要り仮説を置けないものがある。何の決定が要るかを報告して止まる。

次は止まらず、仮説を明示して進む。

- 現在地の事実が足りない、課題の原因候補や最重要課題の解釈が複数あり得る。その時点の根拠から最も筋の良い仮説を採り、本文に仮説と分かる形で書き、反証の `## 制約・根拠・鮮度` と報告の未決に根拠と採らなかった解釈を残す。確認は資料とともに求める。
- `grill` が `open_questions`（上限で問われなかった論点を含む）を返した。`reason` の推奨を仮置きして本文へ反映し、未決に載せる。
- `要修正` の原因が根拠の不足で、今は資料が無い。本文に仮説を明示して要求を未決へ移し、反証と検査をやり直して `合格` に至る（手順7）。三つの節の不可分性など戦略そのものの欠陥は修正して再反証する。
- North Starへの異論が出た。成果物へ書き戻さず、再策定が必要な理由として報告に残して進む。

## 出力

最終資料の絶対path、現在地の要約、反証結果と判定（同一文脈で行った反証ならその制約を添える）、最重要課題と弱い環、基本方針、行動のつながりと最初の到達状態、やらないこと、未決（仮置きした推奨と、利用者に確かめてほしい論点）、方針を見直す条件を報告する。資料が保存されるまで完了にしない。
