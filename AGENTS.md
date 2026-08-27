# AGENTS.md

このrepositoryはProduct North StarとProduct Strategyの立案・反証を扱うmarketplaceである。`write-doc`と`grill`は同梱せず、marketplace名とplugin名で外部依存を解決する。依存versionは固定せず、解決先に必要なskillが存在することを検査する。変更後は`bash scripts/validate.sh`を実行する。
