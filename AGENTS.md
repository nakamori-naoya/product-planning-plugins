> 作業を始める前に、workspace正本入口 `/Users/naoya-nakamoriq/Documents/Github/harness-pluginsv2/AGENTS.md` を読み、そこから指定される共通規約とこのrepository固有の規則を適用する。

# AGENTS.md

このrepositoryはProduct North StarとProduct Strategyの立案・反証を扱うmarketplaceである。marketplaceへ公開するインストール対象は`product-planning` playbook packageだけにし、個々のplaybookと下段skillを別entryへ公開しない。`write-doc`と`grill`は同梱せず、別repositoryにはそのrepositoryが公開するplaybook packageだけで依存する。**外部packageは`playbook:`の工程でだけ呼ぶ。`skill:`や`script:`で指さない。** 呼び出しは相手の公開契約が定める入力と返却値だけを使い、内部skill名・工程id・references・config・保存モード名・非公開path・scriptの引数・終了コードを前提にしない。後片付けは自分のscriptで、自分が所有する中間成果物だけを削除する。依存versionは固定せず、解決先が自己宣言した契約を検査する。違反は`bash scripts/lint-consumer-contract.py`が落とす。変更後は`bash scripts/validate.sh`を実行する。
