# Product Planning

Product North Starを定義し、そこからRumelt型Product Strategyを立案・独立反証するClaude Code/Codex両対応marketplaceである。電子チケット題材のHTML作例を`docs/exercises/product-planning`に含む。

## こんなときに使う

**プロダクトの長期的な価値と、現在地からそこへ進む方針を分けて決めたいときに使う。** 機能一覧やロードマップを先に作らず、誰にどんな未来を実現するか、何が現在の障壁か、どこへ資源を集中するかを順番に明確にする。

- チームごとにプロダクトの目的や優先順位が違う
- 目標はあるが、現在地を裏付ける事実と仮説が混ざっている
- North Starはあるが、どの課題へ集中するか決まっていない
- 戦略が願望や施策一覧になっていないか独立して反証したい

## どの機能を使うか

| 今の状況 | 選ぶ機能 |
|---|---|
| 現在地の証拠を事実・仮説・未確認事項へ分けたい | `product-context` |
| 長期の価値ある未来と判断原則だけを定義したい | `product-north-star` |
| 対話で判断を確かめながらNorth Star資料まで完成させたい | `product-north-star-planning` |
| 確定したNorth Starから戦略を組み立てたい | `product-strategy` |
| 対話と資料化を含め、戦略資料まで完成させたい | `product-strategy-planning` |
| 既存戦略を変更せず、弱点を判定したい | `strategy-critique` |

North StarとStrategyは一つの資料へ混ぜない。North Starは長期の判断基準であり、Strategyは現在地の診断、基本方針、一貫した行動を結ぶ期間依存の選択である。

## 代表的な利用の流れ

1. `product-context`で現在地の証拠を分ける。
2. `product-north-star-planning`で長期の価値と非目標を決める。
3. `product-strategy-planning`で最重要課題、基本方針、行動を結ぶ。
4. `strategy-critique`で根拠、集中、整合性を独立して反証する。

```text
顧客調査と既存KPIから現在地を整理し、Product North Starを対話で決めて資料にして。
```

```text
既存North Starを変えずにProduct Strategyを作り、別観点で反証して。
```

## インストール

### Codex

Codexのpluginコマンドには`--scope`がない。通常の手順はuser単位でmarketplaceとpluginを登録する。

```bash
codex plugin marketplace add nakamori-naoya/product-planning-plugins
codex plugin add product-planning@product-planning
```

このrepositoryだけに分離したい場合は、repository専用の`CODEX_HOME`を作り、インストール時と利用時に同じ値を指定する。

```bash
mkdir -p .codex-home
export CODEX_HOME="$PWD/.codex-home"

codex plugin marketplace add nakamori-naoya/product-planning-plugins
codex plugin add product-planning@product-planning
codex
```

`CODEX_HOME`には認証、設定、ログ、session、plugin metadataも保存されるため、このdirectoryはGit管理しない。

### Claude Code

Claude Codeは次のscopeを選べる。

| scope | 対象 |
|---|---|
| `user` | user全体。省略時の既定値 |
| `project` | このrepositoryで有効にする設定をGitでチーム共有する |
| `local` | このrepositoryで有効にするが、Git共有せず自分だけで使う |

repository設定としてインストールする場合は`project`を指定する。`CLAUDE_PLUGIN_SCOPE`を`user`または`local`へ変えれば、同じ手順でscopeを切り替えられる。

```bash
CLAUDE_PLUGIN_SCOPE=project

claude plugin marketplace add nakamori-naoya/product-planning-plugins --scope "$CLAUDE_PLUGIN_SCOPE"
claude plugin install product-planning@product-planning --scope "$CLAUDE_PLUGIN_SCOPE"
```

利用者がインストールするのはこのpackageだけである。2つのplanning playbookと4つの下段機能は同梱し、内部機能を個別のインストール対象にはしない。

## インストール済みである必要があるplugin

このrepository外の依存だけを記載する。

- `grill@grill`
- `write-doc@write-doc`

別repositoryへの依存は公開playbook packageの`plugin@marketplace`だけを宣言し、内部機能名へ依存しない。versionは固定せず、開発用map、同じrepository、runtimeのinstall cacheの順に候補を調べ、解決したmanifestのidentityと必要なskillを検査する。

## 設定の上書きと優先順位

設定を持つpluginは、優先順位が最も高い1ファイルだけを選ぶ。複数層をマージしないため、上書きするYAMLには同梱設定と同じ必須項目をすべて含める。必須項目の不足、未知のキー、許可されていない値があれば実行を停止する。

skillの静的設定は、上から順に優先する。

1. scope: `<scope>/<plugin-name>.config.yml`。呼び出し元がscopeを渡した実行だけで使う
2. local: `<repo>/.harness-plugins/<plugin-name>.local.yml`。端末固有で、通常はcommitしない
3. repository: `<repo>/.harness-plugins/<plugin-name>.config.yml`
4. personal: `$XDG_CONFIG_HOME/harness-plugins/<plugin-name>.config.yml`（未設定時は `~/.config/harness-plugins/<plugin-name>.config.yml`）
5. bundled defaults: plugin同梱の既定設定

playbookの静的設定は、scope、repository、personal、同梱 `playbook.yml` の順で優先する。playbookにはlocal層がない。入口playbook自身は通常のrepository設定を使い、下段のpluginへscopeを渡す。単体呼び出しではscopeを読まない。

skillでは、同梱設定の `prompt_parameters` に宣言されたpathだけ、依頼で明示された値を `--override=<path>=<value>` として最終上書きできる。宣言されていないpathを任意に上書きすることはできない。

たとえば入口は `<repo>/.harness-plugins/product-strategy-planning.config.yml`、その入口から呼ぶ `grill` だけの設定は `<repo>/.harness-plugins/scopes/product-strategy-planning/grill.config.yml` に置く。

## 検証

```bash
bash scripts/validate.sh
```
