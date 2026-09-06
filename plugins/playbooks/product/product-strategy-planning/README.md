# product-strategy-planning

完成済みのProduct North Starと現在地を受け取り、現状が生む問題とNorth Starへ進む際の障壁を洗い出し、戦略上の選択を対話で確かめ、Rumeltの診断、基本方針、一貫した行動だけで因果を説明するProduct Strategyを独立反証し、資料を1本完成させるplaybook pluginです。

## 必要なplugin

同じpackage内の`product-context`、`product-strategy`、`strategy-critique`と、外部の`grill@grill`、`write-doc@write-doc`に依存する。外部packageへは公開playbookでだけ依存し、`playbook:`の工程として呼ぶ。相手の内部skill名、工程id、references、config、保存モード名、scriptの引数には依存しない。versionは固定せず、解決先のmanifest identityと自己宣言した契約を検査する。

差し替えたい利用者は`~/.config/harness-plugins/dependencies.yml`などで契約ID（`grill/grill`、`write-doc/write-doc`）に別の実体を束縛する。playbookの`requires`は変えない。

## 入力と出力

入力には必須節を持つ既存のProduct North Star成果物が必要です。無い場合や不正な場合は、現在地の整理へ進まず停止します。

中間成果物は`product/context/<topic>.md`、`product/strategy/<topic>.md`、`product/strategy-critique/<topic>.md`へ保存します。入力North Starはハッシュ値で追跡し、工程中の更新・置換を拒否します。North Starへの異論は再策定の必要性として報告します。

反証と最終検査を通った内容だけを`strategy`型として`write-doc`の公開playbookへ渡し、Markdown資料を保存します。型の実現方法は`write-doc`側に委ね、こちらは型名と検証済み素材と保存先だけを渡します。保存後は`scripts/cleanup.py`が、この playbook が所有する現在地、戦略候補、批評、検証用の中間成果物だけを削除し、入力したNorth Starと最終戦略資料を保持します。後片付けまで完了しなければ完了扱いにしません。

`grill`は`playbook:`の工程として呼び、決定と未決を受け取ります。「根拠づけられた入力」は`scripts/ground.py`がこちら側で束ねます。設定は`product-strategy-planning`のscopeで分離します。反証結果が`要修正`なら検証済みStrategyを返しません。

## 設定

`<repo>/.harness-plugins/product-strategy-planning.config.yml`、personal設定、同梱既定の順で最上位の完全な1ファイルを選びます。`steps`を上書きする場合も、North Star検査→context→grill→根拠づけ→strategy→critique→verify→write-doc→自分の中間生成物の後片付けという責務契約は維持します。
