#!/usr/bin/env bash
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/product-planning-test.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
NORTH_ROOT="$ROOT/plugins/product-planning/skills/set-product-north-star"
STRATEGY_ROOT="$ROOT/plugins/product-planning/skills/set-product-strategy"
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
# 旧「playbook包み」形（{playbook: {...}}）は受け付けない。contract を top-level に持つ playbook.yml だけを読む。
yq -o=json '.' "$NORTH_ROOT/playbook.yml" | jq '{playbook:.}' > "$TMP/north-wrapped.json"
yq -o=json '.' "$STRATEGY_ROOT/playbook.yml" | jq '{playbook:.}' > "$TMP/strategy-wrapped.json"


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

echo "Scenario: North Starは戦略へ越境しない"
echo "  Given 必須節を持つNorth Starがある"
echo "  When 保存後にplaybook境界を検査する"
cp "$TMP/north.md" "$TMP/out/north/sample.md" && ok "north star fixture is placed" || ng "north star fixture"
# 基準資料: playbook.yml の contract。入力: 標準入力の本文。正規化: H2見出しで節を切る。
# 合格述語: 節と順序が契約と一致し、全節が空でなく、戦略の節が無い。診断: 標準エラー。
# 正例: 契約どおりの本文。反例: 戦略の節の混入、空の必須節。境界例: 空stdin、契約path欠落、検査用fileを引数で渡す旧形。
if python3 "$NORTH_ROOT/scripts/verify.py" --config "$NORTH_ROOT/playbook.yml" < "$TMP/north.md" | jq -e '.verified==true and (.sections|length)==9' >/dev/null; then
  ok "標準入力の本文と公開playbook.ymlからnorth star境界を検査できる"
else
  ng "標準入力からのnorth star境界検査"
fi
echo "  Then 戦略の節と空の必須節を拒否する"
cp "$TMP/north.md" "$TMP/north-with-strategy.md"
printf '\n## 診断\n現在の問題\n' >> "$TMP/north-with-strategy.md"
expect_fail_stdin() { local input="$1"; shift; "$@" <"$input" >/dev/null 2>&1 && { ng "$* < $input should fail"; return; }; ok "$* < $(basename "$input") is rejected"; }
expect_fail_stdin "$TMP/north-with-strategy.md" python3 "$NORTH_ROOT/scripts/verify.py" --config "$NORTH_ROOT/playbook.yml"
sed '/^## 判断原則$/,/^## やらないこと$/{/^## やらないこと$/!d;}' "$TMP/north.md" > "$TMP/north-empty.md"
expect_fail_stdin "$TMP/north-empty.md" python3 "$NORTH_ROOT/scripts/verify.py" --config "$NORTH_ROOT/playbook.yml"
echo "  And 空の標準入力、契約の欠落、検査用fileの引数を拒否する"
: > "$TMP/empty.md"
expect_fail_stdin "$TMP/empty.md" python3 "$NORTH_ROOT/scripts/verify.py" --config "$NORTH_ROOT/playbook.yml"
expect_fail_stdin "$TMP/north.md" python3 "$NORTH_ROOT/scripts/verify.py" --config "$TMP/missing-playbook.yml"
expect_fail_stdin "$TMP/north.md" python3 "$NORTH_ROOT/scripts/verify.py" --config "$NORTH_ROOT/playbook.yml" --north-star "$TMP/north.md"
expect_fail_stdin "$TMP/north.md" python3 "$NORTH_ROOT/scripts/verify.py" --config "$TMP/north-wrapped.json"

echo "Scenario: Strategyは入力North Starを保ち、要修正で停止する"
echo "  Given 検査済みNorth Star、戦略、合格と要修正の反証結果がある"
north_result=$(python3 "$STRATEGY_ROOT/scripts/validate-north-star.py" --config "$STRATEGY_ROOT/playbook.yml" --north-star "$TMP/out/north/sample.md") || { ng "公開playbook.ymlからのnorth star input validation"; north_result='{}'; }
north_path=$(jq -r '.product_north_star_path // ""' <<<"$north_result")
north_hash=$(jq -r '.product_north_star_sha256 // ""' <<<"$north_result")
cp "$TMP/strategy.md" "$TMP/out/strategy/sample.md" && ok "strategy fixture is placed" || ng "strategy fixture"
# 基準資料: playbook.yml の contract と Product North Star資料のsha256。入力: 標準入力のJSON {strategy, critique}。
# 正規化: JSON parse後、各本文をH2見出しで節に切る。合格述語: sha256一致、戦略の節と順序が契約と一致し空でない、反証の判定が許容語彙。
# 診断: 標準エラー。正例: 合格/要修正の反証。反例: 節の欠落、旧構成の節、判定欄が語彙外、North Star変更。
# 境界例: 空stdin、不正JSON、keyの過不足、空文字列。
strategy_json() { jq -n --rawfile s "$1" --rawfile c "$2" '{strategy:$s, critique:$c}'; }
verify_strategy() { local s="$1" c="$2"; shift 2; strategy_json "$s" "$c" | python3 "$STRATEGY_ROOT/scripts/verify.py" "$@"; }
expect_fail_strategy() { local s="$1" c="$2"; shift 2; verify_strategy "$s" "$c" "$@" >/dev/null 2>&1 && { ng "verify $(basename "$s") $(basename "$c") should fail"; return; }; ok "verify $(basename "$s") + $(basename "$c") is rejected"; }
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
  cp "$TMP/$verdict.md" "$TMP/out/critique/$topic.md"
done
echo "  When 最終検査を行う"
sed '/^## 一貫した行動$/,$d' "$TMP/strategy.md" > "$TMP/strategy-no-actions.md"
printf '\n## 一貫した行動\n' >> "$TMP/strategy-no-actions.md"
expect_fail_strategy "$TMP/strategy-no-actions.md" "$TMP/out/critique/accepted.md" --config "$STRATEGY_ROOT/playbook.yml" --north-star "$north_path" --north-star-sha256 "$north_hash"
cp "$TMP/strategy.md" "$TMP/strategy-old-shape.md"
printf '\n## 鎖構造と近い目標\n旧構成の独立節\n' >> "$TMP/strategy-old-shape.md"
expect_fail_strategy "$TMP/strategy-old-shape.md" "$TMP/out/critique/accepted.md" --config "$STRATEGY_ROOT/playbook.yml" --north-star "$north_path" --north-star-sha256 "$north_hash"
if verify_strategy "$TMP/out/strategy/sample.md" "$TMP/out/critique/needs-revision.md" --config "$STRATEGY_ROOT/playbook.yml" --north-star "$north_path" --north-star-sha256 "$north_hash" | jq -e '.verdict=="要修正" and (.product_north_star_path|endswith("sample.md"))' >/dev/null; then
  ok "構造検査は合法な要修正判定を改変せず返す"
else
  ng "構造検査が要修正という意味判定を合否へ流さない"
fi
if verify_strategy "$TMP/out/strategy/sample.md" "$TMP/out/critique/accepted.md" --config "$STRATEGY_ROOT/playbook.yml" --north-star "$north_path" --north-star-sha256 "$north_hash" | jq -e '.verdict=="合格" and (.product_north_star_path|endswith("sample.md"))' >/dev/null; then
  ok "合格だけが検証済み戦略を返す"
else
  ng "合格の戦略検査"
fi
sed 's/合格/保留/g' "$TMP/out/critique/accepted.md" > "$TMP/critique-invalid-verdict.md"
expect_fail_strategy "$TMP/out/strategy/sample.md" "$TMP/critique-invalid-verdict.md" --config "$STRATEGY_ROOT/playbook.yml" --north-star "$north_path" --north-star-sha256 "$north_hash"
echo "  Then North Star変更は拒否し、要修正判定は責任agentの修正工程へ渡す"
cp "$north_path" "$TMP/changed-north.md"
printf '\n変更\n' >> "$TMP/changed-north.md"
expect_fail_strategy "$TMP/out/strategy/sample.md" "$TMP/out/critique/accepted.md" --config "$STRATEGY_ROOT/playbook.yml" --north-star "$TMP/changed-north.md" --north-star-sha256 "$north_hash"
echo "  And 空の標準入力、不正JSON、keyの過不足、空文字列を拒否する"
strategy_args=(--config "$STRATEGY_ROOT/playbook.yml" --north-star "$north_path" --north-star-sha256 "$north_hash")
expect_fail_stdin "$TMP/empty.md" python3 "$STRATEGY_ROOT/scripts/verify.py" "${strategy_args[@]}"
expect_fail_stdin "$TMP/strategy.md" python3 "$STRATEGY_ROOT/scripts/verify.py" "${strategy_args[@]}"
printf '{"strategy":"## 診断\\nx"}' > "$TMP/strategy-missing-key.json"
expect_fail_stdin "$TMP/strategy-missing-key.json" python3 "$STRATEGY_ROOT/scripts/verify.py" "${strategy_args[@]}"
jq -n --rawfile s "$TMP/strategy.md" '{strategy:$s, critique:"", extra:1}' > "$TMP/strategy-extra-key.json"
expect_fail_stdin "$TMP/strategy-extra-key.json" python3 "$STRATEGY_ROOT/scripts/verify.py" "${strategy_args[@]}"
jq -n --rawfile s "$TMP/strategy.md" '{strategy:$s, critique:""}' > "$TMP/strategy-empty-critique.json"
expect_fail_stdin "$TMP/strategy-empty-critique.json" python3 "$STRATEGY_ROOT/scripts/verify.py" "${strategy_args[@]}"
echo "  And 旧「playbook包み」形の契約fileは verify / validate-north-star とも拒否する"
expect_fail_strategy "$TMP/out/strategy/sample.md" "$TMP/out/critique/accepted.md" --config "$TMP/strategy-wrapped.json" --north-star "$north_path" --north-star-sha256 "$north_hash"
expect_fail python3 "$STRATEGY_ROOT/scripts/validate-north-star.py" --config "$TMP/strategy-wrapped.json" --north-star "$TMP/out/north/sample.md"

echo "Scenario: grill直接結果を同じagentが判断し、typed write-doc入力へ接続する"
echo "  Given 契約どおりの直接結果objectと明示された保存先がある"
work="$TMP/work"
mkdir -p "$work"
# 公開YAMLのdocument_destinationがdocument工程まで届き、旧output_targetが無いことを見る。
for playbook_root in "$NORTH_ROOT" "$STRATEGY_ROOT"; do
  playbook_name=$(basename "$playbook_root")
  yq -o=json -I=0 '.' "$playbook_root/playbook.yml" > "$TMP/$playbook_name-destination.json"
  jq -e '(.inputs|index("document_destination")) and ((.inputs|index("output_target"))|not)
         and ((.steps[]|select(.id=="document")).needs|index("document_destination"))
         and ((.steps[]|select(.id=="document")).playbook=="write-doc")
         and ((.steps[]|select(.id=="document")).input.document_type|test("^[a-z-]+$"))
         and all(.requires[]; .marketplace!="product-planning")' "$TMP/$playbook_name-destination.json" >/dev/null \
    || ng "$playbook_nameの公開保存先接続"
done
ok "2入口とも公開document_destinationをdocumentまで運び、旧output_targetとneed欠落を拒否する"
# 基準資料: grill v1 / write-doc v2公開契約。入力: direct object。
# 正規化: JSON objectをjqで検査。合格述語: completedの2配列とtyped material、排他的保存先。
# 反例: failed、配列欠落/null、保存先同時指定。境界例: 両配列空、output_to省略。
# 意味評価: 根拠・決定・未決をどう本文へ統合するかは同じagentが読む。
jq -n '{contract:"grill/grill",version:1,status:"completed",
  decisions:[{id:"q1",question:"受益者は誰か",answer:"経理組織",rationale:"転記が最も重い"}],
  open_questions:[{id:"q2",question:"補助指標を置くか",state:"open",reason:"観測データが無い"}]}' > "$TMP/grill-result.json"
grill_completed='(.contract=="grill/grill" and .version==1 and .status=="completed" and
  (.decisions|type=="array") and (.open_questions|type=="array"))'
jq -e "$grill_completed" "$TMP/grill-result.json" >/dev/null \
  && ok "grillの直接結果を中間出力へ変換せず受け取る" || ng "grill直接結果"
jq '.status="failed" | del(.decisions,.open_questions) | .reason="input invalid"' \
  "$TMP/grill-result.json" > "$TMP/grill-failed.json"
expect_fail jq -e "$grill_completed" "$TMP/grill-failed.json"
for key in decisions open_questions; do
  jq "del(.$key)" "$TMP/grill-result.json" > "$TMP/grill-${key}-missing.json"
  expect_fail jq -e "$grill_completed" "$TMP/grill-${key}-missing.json"
  jq ".$key=null" "$TMP/grill-result.json" > "$TMP/grill-${key}-null.json"
  expect_fail jq -e "$grill_completed" "$TMP/grill-${key}-null.json"
done
jq '.decisions=[] | .open_questions=[]' "$TMP/grill-result.json" > "$TMP/grill-empty-arrays.json"
jq -e "$grill_completed" "$TMP/grill-empty-arrays.json" >/dev/null \
  && ok "completedの合法な空配列は保持する" || ng "合法な空配列の保持"

jq -n --arg out "$work" '{output_directory:$out,name:"north-star.md"}' > "$TMP/document-destination-create.json"
write_doc_destination='((type=="object") and
  (((keys|sort)==["name","output_directory"] and (.output_directory|type=="string" and startswith("/")) and (.name|type=="string" and endswith(".md"))) or
   ((keys|sort)==["update_target"] and (.update_target|type=="string" and startswith("/") and endswith(".md")))))'
write_doc_input_destination='((has("output_directory") and has("name") and (has("update_target")|not)) or
  (has("update_target") and (has("output_directory")|not) and (has("name")|not)))'
jq -e "$write_doc_destination" "$TMP/document-destination-create.json" >/dev/null \
  || ng "公開新規保存先object"
jq -s '.[0] + {material:[{kind:"text",content:"# North Star\n検査済み本文"}],document_type:"north-star"}' \
  "$TMP/document-destination-create.json" > "$TMP/write-doc-create.json"
jq -e '(.material|type=="array" and length>0 and all(.[]; .kind=="text" or .kind=="file")) and '"$write_doc_input_destination" \
  "$TMP/write-doc-create.json" >/dev/null && ok "typed materialと新規保存先を直接渡す" || ng "write-doc新規入力"
jq -n --arg target "$work/existing.md" '{update_target:$target}' > "$TMP/document-destination-update.json"
jq -e "$write_doc_destination" "$TMP/document-destination-update.json" >/dev/null \
  && ok "更新先はupdate_targetだけを渡す" || ng "write-doc更新入力"
jq -s '.[0] + {material:[{kind:"text",content:"updated"}]}' \
  "$TMP/document-destination-update.json" > "$TMP/write-doc-update.json"
jq '.update_target="/tmp/also.md"' "$TMP/write-doc-create.json" > "$TMP/write-doc-both.json"
expect_fail jq -e "$write_doc_input_destination" "$TMP/write-doc-both.json"
jq 'del(.name)' "$TMP/document-destination-create.json" > "$TMP/write-doc-create-missing-name.json"
expect_fail jq -e "$write_doc_destination" "$TMP/write-doc-create-missing-name.json"
jq -n '{}' > "$TMP/write-doc-destination-unconfirmed.json"
expect_fail jq -e "$write_doc_destination" "$TMP/write-doc-destination-unconfirmed.json"
echo "  Then failedまたは明示合意待ちは本文作成へ進めず、保存成功時だけ直接pathを使う"

echo "  And 検査のためだけのfileと後片付け工程を持たない"
for playbook_root in "$NORTH_ROOT" "$STRATEGY_ROOT"; do
  playbook_name=$(basename "$playbook_root")
  if jq -e '(.contract|has("cleanup")|not) and ([.steps[].id]|index("cleanup")|not) and ([.steps[].id]|index("prepare-work-directory")|not)
            and ([.steps[]|.provides[]?]|index("work_directory")|not)' "$TMP/$playbook_name-destination.json" >/dev/null \
     && [ ! -e "$playbook_root/scripts/cleanup.py" ]; then
    ok "$playbook_name は作業directory・候補file・cleanup工程を持たない"
  else
    ng "$playbook_name に一時file配管が残っている"
  fi
done

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

echo "Scenario: 公開入口は旧内部skill名と配管を前提にしない"
echo "  Given 単独で公開される二つの入口がある"
self_contained=1
for entry in "$NORTH_ROOT" "$STRATEGY_ROOT"; do
  if rg -n -e 'map-product-context|define-product-north-star|form-product-strategy|challenge-strategy|prepare\.sh|run-config\.py|artifact\.py' "$entry/SKILL.md" "$entry/references" >/dev/null; then
    ng "$(basename "$entry")が旧内部skill名または配管を参照している"
    self_contained=0
  fi
done
[ "$self_contained" = 1 ] && ok "二つの入口はそれぞれ単独で成立する"

echo "Scenario: product配布物へ不要な英語ラベルと特定企業名を戻さない"
echo "  Given product関連の基準資料、skill、playbookがある"
echo "  When 禁止する利用者向け表現を走査する"
paths=(
  "$NORTH_ROOT"
  "$STRATEGY_ROOT"
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
rg -F "Product North Star" "$NORTH_ROOT/references/product-north-star.md" >/dev/null && rg -F "Rumelt" "$STRATEGY_ROOT/references/product-strategy.md" >/dev/null && ok "North StarとRumeltは保持される" || ng "保持すべき固有概念"

echo "product planning BDD: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
