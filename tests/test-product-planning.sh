#!/usr/bin/env bash
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/product-planning-test.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
WRITER="$ROOT/shared/product/artifact.py"
NORTH_ROOT="$ROOT/plugins/playbooks/product/product-north-star-planning"
STRATEGY_ROOT="$ROOT/plugins/playbooks/product/product-strategy-planning"
PASS=0
FAIL=0

ok() { echo "  ok: $1"; PASS=$((PASS + 1)); }
ng() { echo "  NG: $1"; FAIL=$((FAIL + 1)); }
expect_fail() { "$@" >/dev/null 2>&1 && { ng "$* should fail"; return; }; ok "$* is rejected"; }
expect_status() {
  local want="$1"; shift
  "$@" >/dev/null 2>&1
  local got=$?
  [ "$got" = "$want" ] && ok "$* exits $want" || ng "$* exits $got, expected $want"
}

mkdir -p "$TMP/out/context" "$TMP/out/north" "$TMP/out/strategy" "$TMP/out/critique"
yq -o=json '.' "$NORTH_ROOT/playbook.yml" | jq '{playbook:.}' > "$TMP/north-resolved.json"
yq -o=json '.' "$STRATEGY_ROOT/playbook.yml" | jq '{playbook:.}' > "$TMP/strategy-resolved.json"

cat > "$TMP/context.json" <<JSON
{"artifact_kind":"product-context","output_dir":"$TMP/out/context","required_sections":["対象と観測時点","事実","仮説","未確認事項","制約","能力","機会","課題"],"required_nonempty_sections":["対象と観測時点","事実","課題"],"evidence_sections":["事実"]}
JSON
cat > "$TMP/north.json" <<JSON
{"artifact_kind":"product-north-star","output_dir":"$TMP/out/north","required_sections":["対象","望む状態","約束する価値","プロダクトの役割","判断原則","やらないこと","根拠と仮説","見直し条件","未決"],"required_nonempty_sections":["対象","望む状態","約束する価値","プロダクトの役割","判断原則","やらないこと","見直し条件"]}
JSON
cat > "$TMP/strategy.json" <<JSON
{"artifact_kind":"product-strategy","output_dir":"$TMP/out/strategy","required_sections":["診断","基本方針","一貫した行動"],"required_nonempty_sections":["診断","基本方針","一貫した行動"]}
JSON
cat > "$TMP/critique.json" <<JSON
{"artifact_kind":"strategy-critique","output_dir":"$TMP/out/critique","required_sections":["判定","診断への反証","基本方針への反証","一貫した行動への反証","鎖構造と近い目標への反証","制約・根拠・鮮度","修正要求"],"required_nonempty_sections":["判定","診断への反証","基本方針への反証","一貫した行動への反証","鎖構造と近い目標への反証","制約・根拠・鮮度"],"verdict_section":"判定","allowed_verdicts":["合格","要修正"]}
JSON

cat > "$TMP/context.md" <<'MD'
## 対象と観測時点
会計プロダクト、2026-08-01
## 事実
- 導入完了まで中央値30日（出典：導入記録10件、観測時点：2026-08-01）
## 仮説
- 承認者への価値不足が待ち時間の主因。承認者面談で反証する。
## 未確認事項
- 承認者が判断に必要とする情報。確認先：承認者面談。
## 制約
- 今期の開発は2チーム。
## 能力
- 導入支援の知見を使える。
## 機会
- 制度変更により再設計需要が生じる可能性がある。
## 課題
- 現状が生む問題：導入待ちで利用開始が遅れる。
- 目標へ進む際の障壁：承認者が価値を判断できる情報が不足している可能性がある。
MD
cat > "$TMP/north.md" <<'MD'
## 対象
経理組織
## 望む状態
判断へ時間を使える
## 約束する価値
転記せず確かな情報を得る
## プロダクトの役割
業務情報を連続させる
## 判断原則
入力削減を機能数より優先する
## やらないこと
全業務の汎用化
## 根拠と仮説
顧客対話の観測と価値仮説を分けて記す
## 見直し条件
主要な受益者が価値を認めない
## 未決
価値提供を観測する補助指標
MD
cat > "$TMP/strategy.md" <<'MD'
## 診断
North Starは転記をなくし判断へ時間を戻すことである。承認者が価値を判断できる情報の不足が導入を止める最重要課題であり、ここが全体を止める弱い環である。
## 基本方針
承認判断に必要な情報の連続性へ集中し、周辺業務の機能追加は行わない。承認待ちが短縮しなければ方針を見直す。
## 一貫した行動
まず承認者が実際に使う情報を観察する。その結果から判断材料を一画面にまとめた試作を作り、限定導入で判断時間を測る。観察が試作の対象を絞り、試作が限定導入を可能にし、限定導入の結果が次の観察を具体化する。まず今月中に一組織で判断時間を観測できる状態へ到達する。
MD

echo "Scenario: 日本語の証拠契約と課題節を持つ現在地だけを保存する"
echo "  Given 出典・観測時点と二種類の課題候補を持つ現在地がある"
echo "  When writerで検査して保存する"
python3 "$WRITER" write --config "$TMP/context.json" --topic sample --body-file "$TMP/context.md" >/dev/null && ok "context is written" || ng "context write"
echo "  Then 英語の証拠ラベルと課題欠落を拒否する"
sed 's/出典：/source:/' "$TMP/context.md" > "$TMP/context-english-label.md"
expect_fail python3 "$WRITER" check --config "$TMP/context.json" --topic bad --body-file "$TMP/context-english-label.md"
sed '/^## 課題$/,$d' "$TMP/context.md" > "$TMP/context-no-challenge.md"
expect_fail python3 "$WRITER" check --config "$TMP/context.json" --topic bad --body-file "$TMP/context-no-challenge.md"

echo "Scenario: North Starは戦略へ越境しない"
echo "  Given 必須節を持つNorth Starがある"
echo "  When 保存後にplaybook境界を検査する"
python3 "$WRITER" write --config "$TMP/north.json" --topic sample --body-file "$TMP/north.md" >/dev/null && ok "north star is written" || ng "north star write"
python3 "$NORTH_ROOT/scripts/verify.py" --config "$TMP/north-resolved.json" --north-star "$TMP/out/north/sample.md" >/dev/null && ok "north star boundary is valid" || ng "north star boundary"
echo "  Then 戦略の節と空の必須節を拒否する"
cp "$TMP/north.md" "$TMP/north-with-strategy.md"
printf '\n## 診断\n現在の問題\n' >> "$TMP/north-with-strategy.md"
expect_fail python3 "$NORTH_ROOT/scripts/verify.py" --config "$TMP/north-resolved.json" --north-star "$TMP/north-with-strategy.md"
sed '/^## 判断原則$/,/^## やらないこと$/{/^## やらないこと$/!d;}' "$TMP/north.md" > "$TMP/north-empty.md"
expect_fail python3 "$NORTH_ROOT/scripts/verify.py" --config "$TMP/north-resolved.json" --north-star "$TMP/north-empty.md"

echo "Scenario: Strategyは入力North Starを保ち、要修正で停止する"
echo "  Given 検査済みNorth Star、戦略、合格と要修正の反証結果がある"
north_result=$(python3 "$STRATEGY_ROOT/scripts/validate-north-star.py" --config "$TMP/strategy-resolved.json" --north-star "$TMP/out/north/sample.md") || { ng "north star input validation"; north_result='{}'; }
north_path=$(jq -r '.product_north_star_path // ""' <<<"$north_result")
north_hash=$(jq -r '.product_north_star_sha256 // ""' <<<"$north_result")
python3 "$WRITER" write --config "$TMP/strategy.json" --topic sample --body-file "$TMP/strategy.md" >/dev/null && ok "strategy is written" || ng "strategy write"
for item in needs-revision:要修正 accepted:合格; do
  topic="${item%%:*}"
  verdict="${item#*:}"
  cat > "$TMP/$verdict.md" <<MD
## 判定
$verdict
## 診断への反証
課題の選択と反対説明を確認した
## 基本方針への反証
制約への態度と捨てる選択を確認した
## 一貫した行動への反証
相互補強と資源配分を確認した
## 鎖構造と近い目標への反証
弱い環と手の届く次の到達点を確認した
## 制約・根拠・鮮度
観測時点を確認した
## 修正要求
なし
MD
  python3 "$WRITER" write --config "$TMP/critique.json" --topic "$topic" --body-file "$TMP/$verdict.md" >/dev/null
done
echo "  When 最終検査を行う"
sed '/^## 一貫した行動$/,$d' "$TMP/strategy.md" > "$TMP/strategy-no-actions.md"
printf '\n## 一貫した行動\n' >> "$TMP/strategy-no-actions.md"
expect_fail python3 "$WRITER" check --config "$TMP/strategy.json" --topic bad --body-file "$TMP/strategy-no-actions.md"
cp "$TMP/strategy.md" "$TMP/strategy-old-shape.md"
printf '\n## 鎖構造と近い目標\n旧構成の独立節\n' >> "$TMP/strategy-old-shape.md"
expect_fail python3 "$STRATEGY_ROOT/scripts/verify.py" --config "$TMP/strategy-resolved.json" --north-star "$north_path" --north-star-sha256 "$north_hash" --strategy "$TMP/strategy-old-shape.md" --critique "$TMP/out/critique/accepted.md"
expect_status 3 python3 "$STRATEGY_ROOT/scripts/verify.py" --config "$TMP/strategy-resolved.json" --north-star "$north_path" --north-star-sha256 "$north_hash" --strategy "$TMP/out/strategy/sample.md" --critique "$TMP/out/critique/needs-revision.md"
if python3 "$STRATEGY_ROOT/scripts/verify.py" --config "$TMP/strategy-resolved.json" --north-star "$north_path" --north-star-sha256 "$north_hash" --strategy "$TMP/out/strategy/sample.md" --critique "$TMP/out/critique/accepted.md" | jq -e '.verdict=="合格" and (.verified_strategy_path|endswith("sample.md"))' >/dev/null; then
  ok "合格だけが検証済み戦略を返す"
else
  ng "合格の戦略検査"
fi
echo "  Then North Star変更と要修正判定は検証済み戦略を返さない"
cp "$north_path" "$TMP/changed-north.md"
printf '\n変更\n' >> "$TMP/changed-north.md"
expect_fail python3 "$STRATEGY_ROOT/scripts/verify.py" --config "$TMP/strategy-resolved.json" --north-star "$TMP/changed-north.md" --north-star-sha256 "$north_hash" --strategy "$TMP/out/strategy/sample.md" --critique "$TMP/out/critique/accepted.md"

echo "Scenario: 二つのplaybookは責務境界を変更できない"
echo "  Given 正しいNorth Star策定とStrategy立案のplaybookがある"
echo "  When requires、steps、needs、判定契約を一つずつ壊して検査する"
"$NORTH_ROOT/scripts/validate-config.sh" <(yq -o=json '.' "$NORTH_ROOT/playbook.yml") && ok "north star playbook is valid" || ng "north star playbook validation"
for expr in '.requires = [.requires[] | select(.plugin != "grill")]' '.requires = [.requires[] | select(.plugin != "write-doc")]' '.requires[2].marketplace="product-planning"' '.steps[0].skill="define-product-north-star"' '.steps[3].playbook="grill-to-doc"' '.steps[4].skill="grill"' '.document_type="concept"' '.contract.forbidden_sections=[]'; do
  yq -o=json "$expr" "$NORTH_ROOT/playbook.yml" > "$TMP/north-mutated.json"
  expect_fail "$NORTH_ROOT/scripts/validate-config.sh" "$TMP/north-mutated.json"
done
"$STRATEGY_ROOT/scripts/validate-config.sh" <(yq -o=json '.' "$STRATEGY_ROOT/playbook.yml") && ok "strategy playbook is valid" || ng "strategy playbook validation"
for expr in '.requires = [.requires[] | select(.plugin != "grill")]' '.requires = [.requires[] | select(.plugin != "write-doc")]' '.requires[4].marketplace="product-planning"' '.steps[1].needs=[]' '.steps[5].needs=["product_strategy_path"]' '.steps[6].playbook="grill-to-doc"' '.steps[7].skill="grill"' '.document_type="concept"' '.contract.critique_verdicts=["pass","revise"]'; do
  yq -o=json "$expr" "$STRATEGY_ROOT/playbook.yml" > "$TMP/strategy-mutated.json"
  expect_fail "$STRATEGY_ROOT/scripts/validate-config.sh" "$TMP/strategy-mutated.json"
done
echo "  Then どの変異も拒否される"

echo "Scenario: write-docの公開依存だけを明示dev-mapで解決する"
echo "  Given write-doc playbook packageが資料作成と後片付けのskillを内包する"
write_doc_root="$TMP/write-doc"
grill_root="$TMP/grill"
mkdir -p "$write_doc_root/.codex-plugin" "$write_doc_root/.claude-plugin" "$write_doc_root/scripts" "$write_doc_root/skills/remove-intermediate-artifacts"
mkdir -p "$grill_root/.codex-plugin" "$grill_root/.claude-plugin"
write_doc_root=$(cd "$write_doc_root" && pwd -P)
grill_root=$(cd "$grill_root" && pwd -P)
printf '%s\n' '---' 'name: remove-intermediate-artifacts' 'description: fixture' '---' > "$write_doc_root/skills/remove-intermediate-artifacts/SKILL.md"
printf '%s\n' '{"name":"write-doc","version":"0.6.0","skills":["./skills/remove-intermediate-artifacts"]}' > "$write_doc_root/.codex-plugin/plugin.json"
printf '%s\n' '{"name":"write-doc","version":"0.6.0","skills":["./skills/remove-intermediate-artifacts"]}' > "$write_doc_root/.claude-plugin/plugin.json"
printf '%s\n' 'version: 2' 'name: write-doc' 'description: fixture' 'instructions: {execution: {directive: fixture}}' 'requires: [{plugin: content-types, marketplace: write-doc}]' 'steps: [{id: fixture, skill: fixture, purpose: fixture}]' > "$write_doc_root/playbook.yml"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$write_doc_root/scripts/resolve.sh"
chmod +x "$write_doc_root/scripts/resolve.sh"
printf '%s\n' '{"name":"grill","version":"0.3.0"}' > "$grill_root/.codex-plugin/plugin.json"
printf '%s\n' '{"name":"grill","version":"0.3.0"}' > "$grill_root/.claude-plugin/plugin.json"
printf '%s\n' '---' 'name: grill' 'description: fixture' '---' > "$grill_root/SKILL.md"
jq -n --arg write_doc "$write_doc_root" --arg grill "$grill_root" '{schema:1,dependencies:{"write-doc/write-doc":$write_doc,"grill/grill":$grill}}' > "$TMP/write-doc-dev-map.json"
echo "  When 両playbookを標準resolverで解決する"
for item in "$NORTH_ROOT:north" "$STRATEGY_ROOT:strategy"; do
  playbook_root=${item%%:*}
  label=${item#*:}
  if HARNESS_PLUGIN_RUNTIME=codex HARNESS_PLUGIN_DEV_ROOTS="$TMP/write-doc-dev-map.json" bash "$playbook_root/scripts/resolve.sh" "$TMP" > "$TMP/${label}-with-cleanup.yml"; then
    yq -o=json '.' "$TMP/${label}-with-cleanup.yml" | jq -e --arg root "$write_doc_root" '(( [.playbook.requires[] | select(.plugin=="write-doc" and .marketplace=="write-doc") ] | length)==1) and (.deps["write-doc"].root==$root) and (.deps["write-doc"].source_kind=="dev-map")' >/dev/null && ok "${label}はwrite-doc playbook packageを公開契約で解決する" || ng "${label}のwrite-doc依存"
  else
    ng "${label}の公開依存解決"
  fi
done
echo "  Then 公開packageのmanifest identityと同梱skillを依存契約として検査する"
mv "$write_doc_root/.codex-plugin/plugin.json" "$TMP/write-doc-plugin.json"
printf '%s\n' '{"name":"wrong-write-doc","version":"0.6.0","skills":["./skills/remove-intermediate-artifacts"]}' > "$write_doc_root/.codex-plugin/plugin.json"
if HARNESS_PLUGIN_RUNTIME=codex HARNESS_PLUGIN_DEV_ROOTS="$TMP/write-doc-dev-map.json" bash "$NORTH_ROOT/scripts/resolve.sh" "$TMP" > "$TMP/north-invalid-cleanup.yml" 2> "$TMP/north-invalid-cleanup.err"; then
  ng "不正なwrite-doc packageのmanifestを拒否する"
else
  ok "不正なwrite-doc packageのmanifestをNGとして集計する"
fi
mv "$TMP/write-doc-plugin.json" "$write_doc_root/.codex-plugin/plugin.json"

echo "Scenario: product repositoryには電子チケットの業界課題とHTML作例だけを置く"
echo "  Given ドメイン・データモデリングの題材をBDD repositoryへ分離した"
echo "  When docs配下のファイルを列挙する"
find "$ROOT/docs" -type f | sed "s#^$ROOT/##" | sort > "$TMP/docs-files"
printf '%s\n' \
  "docs/exercises/product-planning/electronic-ticket-industry-challenges.md" \
  "docs/exercises/product-planning/electronic-ticket-product-planning.html" > "$TMP/docs-expected"
echo "  Then product planningの題材とHTML作例だけが残る"
cmp -s "$TMP/docs-expected" "$TMP/docs-files" && ok "docsにはproduct planningの題材とHTML作例だけがある" || ng "docsの整理結果"
if [ ! -d "$ROOT/domain" ] &&
   rg -n '紙のチケット' "$ROOT/docs/exercises/product-planning/electronic-ticket-industry-challenges.md" >/dev/null &&
   rg -n '不正転売' "$ROOT/docs/exercises/product-planning/electronic-ticket-industry-challenges.md" >/dev/null &&
   rg -n '不正入場' "$ROOT/docs/exercises/product-planning/electronic-ticket-industry-challenges.md" >/dev/null; then
  ok "旧domainを削除し、電子チケットに至る業界課題を題材化した"
else
  ng "domain削除または業界課題の題材"
fi

echo "Scenario: product skillは別のskillを前提にしない"
echo "  Given 単独で公開される四つのproduct skillがある"
echo "  When 各SKILLから他の公開skill名への参照を走査する"
self_contained=1
checks=(
  "product-context:define-product-north-star|form-product-strategy|challenge-strategy"
  "product-north-star:map-product-context|form-product-strategy|challenge-strategy"
  "product-strategy:map-product-context|define-product-north-star|challenge-strategy"
  "strategy-critique:map-product-context|define-product-north-star|form-product-strategy"
)
for check in "${checks[@]}"; do
  plugin=${check%%:*}
  pattern=${check#*:}
  if rg -n -e "$pattern" "$ROOT/plugins/skills/product/$plugin/SKILL.md" >/dev/null; then
    ng "$pluginが別のskillを参照している"
    self_contained=0
  fi
done
[ "$self_contained" = 1 ] && ok "四つのproduct skillはそれぞれ単独で成立する"
echo "  Then skillの組み合わせはplaybookだけが持つ"

echo "Scenario: product配布物へ不要な英語ラベルと特定企業名を戻さない"
echo "  Given product関連の正本、skill、playbookがある"
echo "  When 禁止する利用者向け表現を走査する"
paths=(
  "$ROOT/shared/product"
  "$ROOT/plugins/skills/product"
  "$ROOT/plugins/playbooks/product/product-north-star-planning"
  "$ROOT/plugins/playbooks/product/product-strategy-planning"
)
terms=(
  "Layer""X"
  "Fa""ct"
  "Assump""tion"
  "Unk""nown"
  "Constra""int"
  "Capabi""lity"
  "Opportu""nity"
  "source"":"
  "as-of"":"
  "Diagno""sis"
  "Guiding Pol""icy"
  "Coherent Act""ions"
  "Ver""dict"
  "Strategy critique con""tract"
  "米""軍"
  "ケネ""ディ"
)
bad=0
for term in "${terms[@]}"; do
  if rg -n -F "$term" "${paths[@]}" >/dev/null; then
    ng "不要な表現が残っている: $term"
    bad=1
  fi
done
[ "$bad" = 0 ] && ok "不要な英語ラベルと特定企業名が無い"
echo "  Then Product North StarとRumeltの固有概念だけは利用者向け表現として残る"
rg -F "Product North Star" "$ROOT/shared/product/product-north-star.md" >/dev/null && rg -F "Rumelt" "$ROOT/shared/product/product-strategy.md" >/dev/null && ok "North StarとRumeltは保持される" || ng "保持すべき固有概念"

echo "product planning BDD: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
