# Product Planning

Product North Starを定義し、そこからRumelt型Product Strategyを立案・独立反証するClaude Code/Codex両対応marketplaceである。電子チケット題材のHTML作例を`docs/exercises/product-planning`に含む。

## こんなときに使う

**プロダクトの長期的な価値と、現在地からそこへ進む方針を分けて決めたいときに使う。** 機能一覧やロードマップを先に作らず、誰にどんな未来を実現するか、何が現在の障壁か、どこへ資源を集中するかを順番に明確にする。

- チームごとにプロダクトの目的や優先順位が違う
- 目標はあるが、現在地を裏付ける事実と仮説が混ざっている
- North Starはあるが、どの課題へ集中するか決まっていない
- 戦略が願望や施策一覧になっていないか独立して反証したい

## 公開入口を選ぶ

次の入口から依頼します。内部のスキルや処理は、入口が必要に応じて呼び出します。

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

内部のスキルは同梱されています。個別にインストールせず、公開入口から利用してください。

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

別repositoryへの依存は公開playbook packageの`plugin@marketplace`だけを宣言し、`playbook:`の工程として呼ぶ。内部機能名へ依存しない。versionは固定せず、開発用map、同じrepository、runtimeのinstall cacheの順に候補を調べ、解決したmanifestのidentityと自己宣言した契約（`metadata.harness.implements`）を検査する。

差し替えたい場合は`~/.config/harness-plugins/dependencies.yml`（利用者ごと）、`<repo>/.harness-plugins/dependencies.yml`（repositoryごと）、`<repo>/.harness-plugins/scopes/<入口playbook>/dependencies.yml`（入口ごと）で、契約ID（`grill/grill`、`write-doc/write-doc`）に`{plugin, marketplace}`を束縛する。playbookの`requires`は変えない。

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

## 実行契約と保守

設定はprepareが返すrun専用の絶対pathで引き継ぐ。別shellで同じpathを明示し、完了・失敗停止の最後に同梱run-configのcleanupを呼ぶ。中断後は保存したpathを使い、既にcleanup済みなら設定を再解決する。

依存宣言のversionは固定しない。対応する実行契約は`contractVersion: 1`で、未宣言の旧fixtureは契約1として扱う。未知の契約版は拒否する。installed cacheでは安定版の最大SemVerを選び、prereleaseは`HARNESS_PLUGIN_ALLOW_PRERELEASE=1`を明示した場合だけ候補にする。解決したversion、内容hash、契約版を記録し、工程直前とwrite-doc再開時に内容変更を拒否する。

[doctor](scripts/doctor.py)は`python3 scripts/doctor.py --repo <対象project>`でCLI構文、両runtime公開入口、依存、設定の解決元を読み取り専用で診断する。`--distribution-only`は依存・project設定を検査しない限定診断であり、full診断の代用にはしない。

doctorのfull診断は、依存を**実配布物**に対して解く。依存先は`HARNESS_PLUGIN_REAL_ROOTS`（契約ID→package rootのJSON）か、兄弟checkout `../<marketplace>-plugins/plugins`（親directoryは`HARNESS_PLUGIN_SIBLING_ROOT`で差し替える）から探し、どちらでも見つからなければfixtureへ倒さず理由付きでNGにする。同梱既定に実値を置かない`prompt_parameters`（`required: true`で`default`が無いもの）を持つskillは、上書きが無ければ必ず落ちるので実行せず、`skipped: requires-override`と必要なパラメータ名を出す。これは配布物の不具合ではないのでNGにしない。

依存参照の検査はresolverとlintが同じ関数で行う。外部依存を指せるのは`${.deps.<論理名>.root}`直下3点と`${.deps.<論理名>.entry}`だけで、それ以外は`external-dependency-path`で落ちる。内部依存（同一package）の`${.deps.<内部名>.skills.<名前>}`は、解決結果に実在するskill名だけを許し、綴り違いや名前の無い形は`internal-skill-unknown`で落ちる。`--explain`の依存行は`[外部] <論理名> → <marketplace>/<plugin> <version> [runtime/source_kind]: <root>`の形で、束縛で実体が変わったときだけ行末に`← <層>`が付く。

CIは同ownerの依存repositoryを兄弟directoryへcheckoutしてからvalidate.shを走らせる。**兄弟のrefは既定でmainである。** PR headと同名のbranchを採るのは、(1)実行が`pull_request`であり、(2)PR headが同一repository（forkではない）で、(3)同ownerの兄弟repoにその名前のbranchが実在する、の3つが揃うときだけで、選んだrefと理由はログへ出る。forkのPR作者はownerの兄弟repoにbranchを作れないため、PRから兄弟checkoutの内容を差し替える経路は無い。code scanningの`actions/untrusted-checkout/medium`はこの根拠により`won't fix`として扱う。

共通実装の開発時正本はProduct Planning repositoryの`shared/runtime-source`にある。更新時はそのsource checkoutを取得し、[生成CLI](scripts/sync-runtime.py)へ`--source <取得した正本directory>`を渡す。`--check`は生成差分と[生成履歴](shared/runtime-manifest.json)のversion・内容hash・対象集合を検査する。正本checkoutなしのCIでも同梱物のhashと対象集合を検査できる。実行時に別repositoryや生成CLIは不要である。変更は正本へ加え、同じ生成コマンドを各source repositoryへ適用する。

[release CLI](scripts/release.py)は`--plugin --version --notes --breaking --migration --checks`で更新計画を返す。`--checks`にはcodex/claudeの実検証結果、または未検証と理由を明示する。`--apply`で両manifestとcatalogの整合を確認して一括更新し、releases配下へ変更内容・移行・検証結果のJSON記録を残す。依存宣言は変更しない。

[意味評価fixture](evals/scenarios.json)を[評価runner](scripts/evaluate-skills.py)へ渡し、異なる生成modelとjudge modelを指定する。モデル名、実model利用、適用設定、入力、出力、SKILL hash、判定の引用と理由を保存する。criterionの真偽は意味評価の記録であり、CLIの合否にはしない。CLIの非zero終了はadapter失敗、不正な応答、根拠不整合など記録を完了できない操作失敗を示す。人またはエージェントが記録を読み、根拠付きで評価する。これはツール無効の次応答を対象とした代表caseであり、実ツールを使った全工程E2Eや全行動の保証ではない。保存・CLI・再開の検証は[振る舞い回帰試験](scripts/test-hardening.py)と既存validateが担う。実モデル未実行のfixtureを合格扱いにしない。

### 依存先を束縛する`dependencies.yml`

契約ID（`marketplace/plugin`）に対する実体を`{plugin, marketplace}`で束縛する。**top-levelは`version: 1`と`bindings`の2つだけである。** それ以外のキーがあると`[error:binding-file-invalid] reason=top-level-keys`で停止する。

```yaml
version: 1
bindings:
  "grill/grill": {plugin: ask-one, marketplace: my-marketplace}
  "write-doc/write-doc": {plugin: write-documents, marketplace: my-marketplace}
```

置き場所は3層で、下ほど優先する。**層はマージせず、見つかった最優先の1ファイルだけを使う。**

1. personal: `$XDG_CONFIG_HOME/harness-plugins/dependencies.yml`（未設定時は`~/.config/harness-plugins/dependencies.yml`）
2. repository: `<repo>/.harness-plugins/dependencies.yml`
3. scope: `<repo>/.harness-plugins/scopes/<入口playbook>/dependencies.yml`

値に書けるのは`plugin`と`marketplace`だけで、**pathやversionは書けない。** 差し替え先はmarketplace経由（installed cache、同一repository、開発時の`HARNESS_PLUGIN_DEV_ROOTS`）で解決でき、manifestの`metadata.harness.implements`にその契約IDを宣言しているpluginでなければならない。宣言が無ければ`[error:binding-not-implemented]`で停止する。playbook側の`requires`は書き換えない。

入口が選んだ束縛はrun専用のlockへ固定して子へ渡す。同じ実行の中で実体が食い違うことはなく、実行中に`dependencies.yml`を書き換えても、そのrunの解決は変わらない。

### explainの読み方

`scripts/prepare.sh`は`--explain`を引数に取らない。**explainは常にstderrへ出る。** stdoutは解決済みYAMLの絶対path1行だけなので、解決の内訳（選んだ設定層、依存の実体、束縛の出どころ、静的に解けた工程入力）はstderrで読む。`--explain`のような未知optionを渡すとusageを表示してexit 2で止まる。

### 破壊的変更の移行

重複した薄いSKILL入口を廃止した。利用者は公開manifestに列挙された入口を使い、旧入口pathを保存した独自ランチャーは新しい宣言へ切り替える。設定のEXIT trapは廃止し、返されたrun pathを明示して完了・停止時にcleanupする。旧式の一時pathやshell変数だけを再利用しない。

### 開発CLIの入力境界

`doctor`、`release`、`sync-runtime`、意味評価runnerは、操作者が明示したローカルsource、出力先、adapter argvを扱う開発CLIである。外部から受け取った文書やモデル出力をCLI引数へ自動変換しない。doctorのfull modeは選んだrepositoryのresolverを実行するため、信頼するsource checkoutを対象にする。doctorは配布treeのsymlinkを読取・実行前に拒否し、sync-runtimeは生成先と正本treeのsymlinkをcopy前に拒否する。評価の会話・fixture・モデル出力はadapterへstdinデータとして渡し、実行argvに混ぜない。
