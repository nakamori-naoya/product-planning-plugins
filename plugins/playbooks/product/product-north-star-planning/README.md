# product-north-star-planning

顧客理解、価値仮説、参照資料から価値判断を対話で確かめ、Product North Star資料を1本完成させるplaybook pluginです。現在の制約から診断、基本方針、一貫した行動、資源配分、期限つき施策は作りません。

## 必要なplugin

`grill@grill`、`product-north-star@product-planning`、`write-doc@write-doc`、`intermediate-cleanup@product-planning`。versionは固定せず、解決先のmanifest identityと必要なskillまたはplaybookを検査する。

## 入力と出力

入力は顧客理解、価値仮説、根拠となる資料です。中間成果物は`product/north-star/<topic>.md`へ保存し、対象、望む状態、約束する価値、プロダクトの役割、判断原則、やらないこと、根拠と仮説、見直し条件、未決を持ちます。

境界検査を通った内容だけを`north-star`型として`write-doc`へ渡し、Markdown資料を保存します。テンプレートと記載例は`content-types`が所有し、playbookは型名と検査済み素材だけを渡します。保存後は作業用のNorth Star成果物だけを削除し、最終資料を保持します。後片付けまで完了しなければ完了扱いにしません。

`grill`の決定ログは`product-north-star-planning`のscopeで分離します。必須節の欠落・空欄、戦略の節の混入、既存成果物への黙った上書きがあれば停止します。

## 設定

`<repo>/.harness-plugins/product-north-star-planning.config.yml`、personal設定、同梱既定の順で最上位の完全な1ファイルを選びます。`steps`を上書きする場合も、grill→north-star→verify→write-doc→中間生成物の後片付けという責務契約は維持します。
