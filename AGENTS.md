> 共通の規約は /Users/naoya-nakamoriq/Documents/Github/harness-pluginsv2/AGENTS.md にある。ここには、この repository だけの規則を置く。

# AGENTS.md

このrepositoryはProduct North StarとProduct Strategyの立案・反証を扱うmarketplaceである。marketplaceへ公開するインストール対象はpackage `product-planning`（`./plugins/product-planning`）だけにし、公開入口は `skills/set-product-north-star` と `skills/set-product-strategy` の2つとする。内部skillは置かない。各入口は自身の `SKILL.md`、隣接 `playbook.yml`、`references/`、`scripts/` だけで完結し、工程の順は `playbook.yml` の宣言順で決まり、同じagentがその順に辿る。

`write-doc`と`grill`は同梱しない。

設定fileを置かず、保存先は公開入力 `document_destination` で受け取る。agentが作った本文は検査scriptへ標準入力で渡し、作業directory・検査用file・後片付け工程を置かない。
