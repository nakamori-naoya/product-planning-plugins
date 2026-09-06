# product-north-star-planning

顧客理解、価値仮説、参照資料から価値判断を対話で確かめ、Product North Star資料を1本完成させるplaybook pluginです。現在の制約から診断、基本方針、一貫した行動、資源配分、期限つき施策は作りません。

## 必要なplugin

同じpackage内の`product-north-star`と、外部の`grill@grill`、`write-doc@write-doc`に依存する。外部packageへは公開playbookでだけ依存し、`playbook:`の工程として呼ぶ。相手の内部skill名、工程id、references、config、保存モード名、scriptの引数には依存しない。versionは固定せず、解決先のmanifest identityと自己宣言した契約を検査する。

差し替えたい利用者は`~/.config/harness-plugins/dependencies.yml`などで契約ID（`grill/grill`、`write-doc/write-doc`）に別の実体を束縛する。playbookの`requires`は変えない。

## 入力と出力

入力は顧客理解、価値仮説、根拠となる資料です。中間成果物は`product/north-star/<topic>.md`へ保存し、対象、望む状態、約束する価値、プロダクトの役割、判断原則、やらないこと、根拠と仮説、見直し条件、未決を持ちます。

境界検査を通った内容だけを`north-star`型として`write-doc`の公開playbookへ渡し、Markdown資料を保存します。型の実現方法は`write-doc`側に委ね、こちらは型名と検査済み素材と保存先だけを渡します。保存後は`scripts/cleanup.py`が、この playbook が所有する作業用成果物だけを削除し、最終資料を保持します。後片付けまで完了しなければ完了扱いにしません。

`grill`は`playbook:`の工程として呼び、決定と未決を受け取ります。「根拠づけられた入力」は`scripts/ground.py`がこちら側で束ねます。設定は`product-north-star-planning`のscopeで分離します。必須節の欠落・空欄、戦略の節の混入、既存成果物への黙った上書きがあれば停止します。

## 設定

`<repo>/.harness-plugins/product-north-star-planning.config.yml`、personal設定、同梱既定の順で最上位の完全な1ファイルを選びます。`steps`を上書きする場合も、grill→根拠づけ→north-star→verify→write-doc→自分の中間生成物の後片付けという責務契約は維持します。
