# product-strategy-planning

完成済みのProduct North Starと現在地を受け取り、現状が生む問題とNorth Starへ進む際の障壁を洗い出し、戦略上の選択を対話で確かめ、Rumeltの診断、基本方針、一貫した行動だけで因果を説明するProduct Strategyを独立反証し、資料を1本完成させるplaybook pluginです。

## 必要なplugin

`product-context@product-planning`、`grill@grill`、`product-strategy@product-planning`、`strategy-critique@product-planning`、`write-doc@write-doc`、`write-doc-cleanup@write-doc`。versionは固定せず、解決先のmanifest identityと必要なskillまたはplaybookを検査する。

## 入力と出力

入力には必須節を持つ既存のProduct North Star成果物が必要です。無い場合や不正な場合は、現在地の整理へ進まず停止します。

中間成果物は`product/context/<topic>.md`、`product/strategy/<topic>.md`、`product/strategy-critique/<topic>.md`へ保存します。入力North Starはハッシュ値で追跡し、工程中の更新・置換を拒否します。North Starへの異論は再策定の必要性として報告します。

反証と最終検査を通った内容だけを`strategy`型として`write-doc`へ渡し、Markdown資料を保存します。テンプレートと記載例は`content-types`が所有し、playbookは型名と検証済み素材だけを渡します。保存後は現在地、戦略候補、批評、検証用の中間成果物だけを削除し、入力したNorth Starと最終戦略資料を保持します。後片付けまで完了しなければ完了扱いにしません。

`grill`の決定ログは`product-strategy-planning`のscopeで分離します。反証結果が`要修正`なら検証済みStrategyを返しません。

## 設定

`<repo>/.harness-plugins/product-strategy-planning.config.yml`、personal設定、同梱既定の順で最上位の完全な1ファイルを選びます。`steps`を上書きする場合も、North Star検査→context→grill→strategy→critique→verify→write-doc→中間生成物の後片付けという責務契約は維持します。
