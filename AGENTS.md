> 共通の規約は /Users/naoya-nakamoriq/Documents/Github/harness-pluginsv2/AGENTS.md にある。ここには、この repository だけの規則を置く。

# product-planning

この repository は、Product North Star と Product Strategy の立案と反証を扱う。インストール対象は package `product-planning`（`./plugins/product-planning`）だけで、公開入口は `skills/set-product-north-star` と `skills/set-product-strategy` の二つである。内部 skill は置かず、各入口は自分の `SKILL.md` と `references/` だけで完結する。

利用者に問うときは `grill` を、資料を保存するときは `write-doc` を呼び、どちらも同梱しない。設定ファイルは置かず、保存先は依頼で受け取る。
