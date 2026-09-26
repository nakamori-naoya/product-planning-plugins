# Product Planning

見えない課題とその本質を取り出して価値仮説を立て、Product North Starを定義し、そこからRumelt型Product Strategyを立案・反証するClaude Code/Codex両対応marketplaceである。公開するインストール対象はpackage `product-planning`（`./plugins/product-planning`）1件で、公開入口は自己完結skill `discover-hidden-problem`、`set-product-north-star`、`set-product-strategy` の3つである。電子チケット題材のHTML作例を`docs/exercises/product-planning`に含む。

## こんなときに使う

**何を作るかを決める前に、解く課題、プロダクトの長期的な価値、現在地からそこへ進む方針を分けて決めたいときに使う。** 機能一覧やロードマップを先に作らず、誰のどんな課題を解くか、誰にどんな未来を実現するか、何が現在の障壁か、どこへ資源を集中するかを順番に明確にする。

- 困りごとや思いついた解決策はあるが、本当の課題が言葉になっていない
- チームごとにプロダクトの目的や優先順位が違う
- 目標はあるが、現在地を裏付ける事実と仮説が混ざっている
- North Starはあるが、どの課題へ集中するか決まっていない
- 戦略が願望や施策一覧になっていないか反証したい

## 公開入口を選ぶ

次の入口から依頼します。各入口は `SKILL.md` と、必要なら `references/` だけで完結し、内部skillを持ちません。

| 今の状況 | 公開入口 |
|---|---|
| 困りごとや解決策の案から、見えない課題と価値仮説、最初に確かめる前提を資料にしたい | `discover-hidden-problem` |
| 対話で判断を確かめながらNorth Star資料まで完成させたい | `set-product-north-star` |
| 対話と資料化を含め、戦略資料まで完成させたい | `set-product-strategy` |

North StarとStrategyは一つの資料へ混ぜない。North Starは長期の判断基準であり、Strategyは現在地の診断、基本方針、一貫した行動を結ぶ期間依存の選択である。

## 代表的な利用の流れ

1. 課題がまだ言葉になっていなければ、`discover-hidden-problem`で課題の本質と価値仮説を資料にし、最も危うい前提を確かめて同じ入口で書き直す。
2. 顧客調査や現在の指標、課題と価値仮説の資料など、判断の材料を用意する。
3. `set-product-north-star`で長期の価値と対象外の範囲を決める。
4. `set-product-strategy`で現在の課題から戦略を作り、反証と資料化まで進める。

```text
困りごとのメモと思いついたアプリの案から、本当の課題と最初に確かめることを資料にして。
```

```text
顧客調査と既存KPIから現在地を整理し、Product North Starを対話で決めて資料にして。
```

```text
既存North Starを変えずにProduct Strategyを作り、別観点で反証して。
```

## インストール

インストールするのは`product-planning@product-planning`です。外部の工程を実行するため、`grill@grill`、`write-doc@write-doc`も必要です。下のコマンドには、それらも含めています。

### Codex

利用するCodexと同じ設定環境で実行してください。

```bash
codex plugin marketplace add nakamori-naoya/grill-plugins
codex plugin add grill@grill
codex plugin marketplace add nakamori-naoya/write-doc-plugins
codex plugin add write-doc@write-doc
codex plugin marketplace add nakamori-naoya/product-planning-plugins
codex plugin add product-planning@product-planning
codex plugin list
```

一覧で導入先を確認し、新しい会話で利用してください。

### Claude Code

次は自分の全プロジェクトで使う例です。このプロジェクトのチームで共有する場合は`project`、このプロジェクトで自分だけが使う場合は`local`に変更し、利用先のディレクトリで実行してください。

```bash
CLAUDE_PLUGIN_SCOPE=user
claude plugin marketplace add nakamori-naoya/grill-plugins --scope "$CLAUDE_PLUGIN_SCOPE"
claude plugin install grill@grill --scope "$CLAUDE_PLUGIN_SCOPE"
claude plugin marketplace add nakamori-naoya/write-doc-plugins --scope "$CLAUDE_PLUGIN_SCOPE"
claude plugin install write-doc@write-doc --scope "$CLAUDE_PLUGIN_SCOPE"
claude plugin marketplace add nakamori-naoya/product-planning-plugins --scope "$CLAUDE_PLUGIN_SCOPE"
claude plugin install product-planning@product-planning --scope "$CLAUDE_PLUGIN_SCOPE"
claude plugin list
```

一覧で導入を確認し、Claude Codeを再起動してください。すでに導入しているパッケージは、次の更新手順を使ってください。

## 更新する

GitHubから登録したmarketplaceを更新し、その公開パッケージを更新します。新規インストールと同じCodexの設定環境、Claude Codeの適用範囲を使ってください。

### Codex

```bash
codex plugin marketplace upgrade product-planning
codex plugin add product-planning@product-planning
codex plugin list
```

更新後は新しい会話で確認してください。ローカルのパスからmarketplaceを登録した場合は、Git版の更新コマンドではなく、その登録先のソースを更新してから追加し直します。

### Claude Code

```bash
# インストール時に合わせてuser / project / localを選ぶ
CLAUDE_PLUGIN_SCOPE=user
claude plugin marketplace update product-planning
claude plugin update product-planning@product-planning --scope "$CLAUDE_PLUGIN_SCOPE"
claude plugin list
```

更新後はClaude Codeを再起動してください。外部の依存パッケージも使っている場合は、それぞれのREADMEの更新手順を実行してください。

marketplaceの取得と、インストール済みパッケージの更新は分けて確認します。同じバージョンとして公開された変更は、更新コマンドだけでは反映されない場合があります。「最新」と表示された場合は公開バージョンを確認し、キャッシュ内のファイルを直接編集しないでください。

コマンドは2026-09-06時点のCLIヘルプと、[Codexのmarketplace管理](https://developers.openai.com/plugins/build/plugins)、[Claude Codeの更新仕様](https://code.claude.com/docs/en/plugins-reference#plugin-update)を確認しています。

## インストール済みである必要があるplugin

このrepository外の依存だけを記載する。

- `grill@grill`
- `write-doc@write-doc`

各入口は、利用者に問うときに `grill` を、資料を保存するときに `write-doc` を呼ぶ。相手の内部の作りには依存しない。

## 設定

入口は設定fileを持たない。保存先は依頼で受け取り、既定の置き場を補わない。

## 検証

```bash
bash scripts/validate.sh
```

## 保守tool

保守用tool（release / test-hardening / validate-plugin-repository）の参照元は兄弟checkoutの `../harness-tools/` であり、このrepositoryは複製を持たない。`scripts/validate.sh` は `../harness-tools/tools/` の実在を確認してから呼び、無ければ止まる。CIの `validate.yml` も `harness-tools` を兄弟checkoutして `harness-tools/ci/validate.sh` を実行する。呼び方は `../harness-tools/README.md` にある。
