# Product Planning

Product North Starを定義し、そこからRumelt型Product Strategyを立案・独立反証するClaude Code/Codex両対応marketplaceである。公開するインストール対象はpackage `product-planning`（`./plugins/product-planning`）1件で、公開入口は自己完結skill `set-product-north-star` と `set-product-strategy` の2つである。電子チケット題材のHTML作例を`docs/exercises/product-planning`に含む。

## こんなときに使う

**プロダクトの長期的な価値と、現在地からそこへ進む方針を分けて決めたいときに使う。** 機能一覧やロードマップを先に作らず、誰にどんな未来を実現するか、何が現在の障壁か、どこへ資源を集中するかを順番に明確にする。

- チームごとにプロダクトの目的や優先順位が違う
- 目標はあるが、現在地を裏付ける事実と仮説が混ざっている
- North Starはあるが、どの課題へ集中するか決まっていない
- 戦略が願望や施策一覧になっていないか独立して反証したい

## 公開入口を選ぶ

次の入口から依頼します。各入口は `SKILL.md`（目的・入力・判断基準・手順・停止条件・出力）、隣接 `playbook.yml`（同じagentが辿る工程順と外部依存）、`references/`（判断規律）、`scripts/`（決定論的な検査と後片付け）だけで完結し、内部skillを持ちません。

| 今の状況 | 公開入口 |
|---|---|
| 対話で判断を確かめながらNorth Star資料まで完成させたい | `set-product-north-star` |
| 対話と資料化を含め、戦略資料まで完成させたい | `set-product-strategy` |

North StarとStrategyは一つの資料へ混ぜない。North Starは長期の判断基準であり、Strategyは現在地の診断、基本方針、一貫した行動を結ぶ期間依存の選択である。

## 代表的な利用の流れ

1. 顧客調査や現在の指標など、判断の材料を用意する。
2. `set-product-north-star`で長期の価値と対象外の範囲を決める。
3. `set-product-strategy`で現在の課題から戦略を作り、反証と資料化まで進める。

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

別repositoryへの依存は各入口の `playbook.yml` の `requires` に `{plugin, marketplace}` で宣言し、`playbook:` の工程として呼ぶ。相手の内部機能名へ依存せず、versionは固定しない。呼び出しは相手の `CONTRACT.md` が定める入力objectと返却objectだけを使う。

## 設定

入口は設定fileを持たない。保存先は公開入力 `document_destination`（新規は `output_directory` + `name`、更新は `update_target`）で受け取り、既定の置き場を補わない。中間成果物はsystem temporary directory内のrun専用directoryに置き、最終資料の保存後に入口の `scripts/cleanup.py` が自分の候補fileだけを削除する。

## 検証

```bash
bash scripts/validate.sh
```

## 保守tool

`scripts/doctor.py`、`scripts/lint-consumer-contract.py`、`scripts/evaluate-skills.py`、`scripts/release.py`、`scripts/sync-runtime.py`、`scripts/test-hardening.py`、`scripts/validate-distribution.py` と `shared/` は、このrepositoryの `shared/runtime-source` を正本とする保守用の複製である。実行時に別repositoryや生成CLIは不要である。

[意味評価fixture](evals/scenarios.json)を[評価runner](scripts/evaluate-skills.py)へ渡した記録は、criterionの真偽を機械の合否にせず、人またはエージェントが根拠付きで評価する。

## 配置の変更（2026-09-16）

- marketplaceの `source` を `./plugins` から `./plugins/product-planning` へ、公開入口を `plugins/playbooks/product/{product-north-star-planning, product-strategy-planning}` から `plugins/product-planning/skills/{set-product-north-star, set-product-strategy}` へ移した。隣接 `playbook.yml` の `name` は入口名と同じになった。配置変更はinstall identityを変えるため、release時にmajor bumpが要る。
- 内部skill `product-context` / `product-north-star` / `product-strategy` / `strategy-critique` は、それを使う公開入口が1つずつだったため入口へ統合した。判断規律の参照文書は入口の `references/` へ移した。
- 設定解決runtime（`prepare.sh` / `resolve.sh` / `run-config.py` / `state.py`）、`config/defaults.yml`、入口ごとのnested manifest、`artifact.py` による中間保存を撤去した。`verify.py` / `validate-north-star.py` / `cleanup.py` は公開 `playbook.yml` の `contract` を直接読む。
- 外部依存の実行時解決（`dependencies.yml` による束縛、`--explain`）は撤去した。`requires` は外部package（`grill` / `write-doc`）だけを列挙する。
