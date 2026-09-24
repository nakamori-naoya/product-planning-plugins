> 作業を始める前に、workspace規約入口 `/Users/naoya-nakamoriq/Documents/Github/harness-pluginsv2/AGENTS.md` を読み、そこから指定される共通規約とこのrepository固有の規則を適用する。

# AGENTS.md

このrepositoryはProduct North StarとProduct Strategyの立案・反証を扱うmarketplaceである。marketplaceへ公開するインストール対象はpackage `product-planning`（`./plugins/product-planning`）だけにし、公開入口は `skills/set-product-north-star` と `skills/set-product-strategy` の2つとする。内部skillは置かない。各入口は自身の `SKILL.md`、隣接 `playbook.yml`、`references/`、`scripts/` だけで完結し、工程順は `playbook.yml` の宣言順が正式な定義であり、同じagentが辿る。

`write-doc`と`grill`は同梱せず、別repositoryにはそのrepositoryが公開するpackageだけで依存する。**外部packageは `playbook.yml` の `requires` に `{plugin, marketplace}` で宣言し、`playbook:` の工程でだけ呼ぶ。`skill:`や`script:`で指さない。** 呼び出しは相手の公開契約が定める入力と返却値だけを使い、内部skill名・工程id・references・config・保存モード名・非公開path・scriptの引数・終了コードを前提にしない。`requires` に自marketplaceの要素を置かない。

`SKILL.md`、`references/`、`playbook.yml` に実行基盤の配管（`${.`マクロ、同期block、環境変数によるroot解決、設定解決scriptの実行指示、`prepare.sh` / `resolve.sh` の対）を書かない。設定fileを置かず、保存先は公開入力 `document_destination` で受け取る。agentが作った本文は検査scriptへ標準入力で渡し、作業directory・検査用file・後片付け工程を置かない。

変更後は `bash scripts/validate.sh` と `bash /Users/naoya-nakamoriq/Documents/Github/harness-pluginsv2/scripts/validate.sh /Users/naoya-nakamoriq/Documents/Github/harness-pluginsv2/product-planning-plugins` を実行する。

## 検査スクリプトは、意味が一意に決まることだけを判定する

このrepositoryの検査スクリプト（validate、lint、verify、checkなど、名前を問わない）が判定してよいのは、ファイルや見出しの有無、識別子や版の一致、宣言と配置の対応、禁止された書き方の有無のように、入力と基準資料から意味が決定論的に一意に決まることだけである。読んで解釈しないと決まらないことや、件数や語の出現のような品質の代わりの指標は判定せず、エージェントが読んで評価する（意味評価）。判定が一意に決まることを宣言できない検査は作らず、詳しい条件は `/Users/naoya-nakamoriq/Documents/Github/harness-pluginsv2/.agents/rules/deterministic-validation.md` に従う。
