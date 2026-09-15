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

# 負の試験で使う「外部packageの内部名」は、この file へ literal で書かない。
# 消費側lintが同じ語を探すため、既存の禁止表現検査と同じく文字列を割って組み立てる。
wd_internal_writer="write-""with-rules"
wd_internal_cleanup="remove-""intermediate-artifacts"
wd_internal_plugin="writing-""rules"
wd_internal_script="write-""doc.sh"
grill_internal_plugin="grill-""dialogue"
grill_internal_skill="ask-""until-agreed"

echo "Scenario: 二つのplaybookは責務境界を変更できない"
echo "  Given 正しいNorth Star策定とStrategy立案のplaybookがある"
echo "  When requires、steps、needs、判定契約を一つずつ壊して検査する"
"$NORTH_ROOT/scripts/validate-config.sh" <(yq -o=json '.' "$NORTH_ROOT/playbook.yml") && ok "north star playbook is valid" || ng "north star playbook validation"
for expr in '.requires = [.requires[] | select(.plugin != "grill")]' '.requires = [.requires[] | select(.plugin != "write-doc")]' '.requires[2].marketplace="product-planning"' '.steps[0] |= (del(.playbook) + {skill:"grill"})' '.steps[0].provides=["decisions","grounded_input"]' ".steps[1].script=\"scripts/$wd_internal_cleanup.py\"" ".steps[4] |= (del(.playbook) + {skill:\"$wd_internal_writer\"})" '.steps[4].input={}' ".steps[5] |= (del(.script) + {skill:\"$wd_internal_cleanup\"})" '.document_type="concept"' '.contract.forbidden_sections=[]'; do
  yq -o=json "$expr" "$NORTH_ROOT/playbook.yml" > "$TMP/north-mutated.json"
  expect_fail "$NORTH_ROOT/scripts/validate-config.sh" "$TMP/north-mutated.json"
done
"$STRATEGY_ROOT/scripts/validate-config.sh" <(yq -o=json '.' "$STRATEGY_ROOT/playbook.yml") && ok "strategy playbook is valid" || ng "strategy playbook validation"
for expr in '.requires = [.requires[] | select(.plugin != "grill")]' '.requires = [.requires[] | select(.plugin != "write-doc")]' '.requires[4].marketplace="product-planning"' '.steps[1].needs=[]' '.steps[2] |= (del(.playbook) + {skill:"grill"})' '.steps[2].provides=["decisions","unresolved","grounded_strategy"]' '.steps[6].needs=["product_strategy_path"]' ".steps[7] |= (del(.playbook) + {skill:\"$wd_internal_writer\"})" '.steps[7].input={}' ".steps[8] |= (del(.script) + {skill:\"$wd_internal_cleanup\"})" '.document_type="concept"' '.contract.critique_verdicts=["pass","revise"]'; do
  yq -o=json "$expr" "$STRATEGY_ROOT/playbook.yml" > "$TMP/strategy-mutated.json"
  expect_fail "$STRATEGY_ROOT/scripts/validate-config.sh" "$TMP/strategy-mutated.json"
done
echo "  Then どの変異も拒否される"

echo "Scenario: 外部依存は実際に配布されているpackageの公開playbookとして解決する"
echo "  Given 兄弟checkoutのgrill/write-doc配布物と、契約だけを実装するstub providerがある"

# stub provider（契約ID → 実体 の配線だけを試す最小package）。
# 本物の代わりではない。実配布物が契約を宣言していない間の穴埋めにだけ使う。
stub_provider() { # stub_provider <dir> <plugin名> <marketplace> <playbook名> <契約ID> [types...]
  local dir="$1" name="$2" market="$3" playbook="$4" contract="$5"; shift 5
  local types; types=$(printf '%s\n' "$@" | jq -R . | jq -sc .)
  local contract_version=1
  [ "$contract" = "write-doc/write-doc" ] && contract_version=2
  mkdir -p "$dir/playbooks/$playbook/.claude-plugin" \
           "$dir/playbooks/$playbook/.codex-plugin" "$dir/.claude-plugin" "$dir/.codex-plugin" \
           "$dir/skills/worker/.claude-plugin" "$dir/skills/worker/.codex-plugin"
  printf -- '---\nname: %s\ndescription: stub\n---\nstub\n' "$playbook" > "$dir/playbooks/$playbook/SKILL.md"
  printf -- '---\nname: %s-worker\ndescription: stub\n---\nstub\n' "$name" > "$dir/skills/worker/SKILL.md"
  printf '%s\n' 'version: 2' "name: $playbook" 'description: stub' \
    'instructions: {execution: {directive: stub}}' \
    "requires: [{plugin: ${name}-worker, marketplace: $market}]" \
    "steps: [{id: run, skill: ${name}-worker, purpose: stub}]" > "$dir/playbooks/$playbook/playbook.yml"
  local runtime
  for runtime in claude codex; do
    jq -n --arg n "$name" --arg m "$market" --arg pb "$playbook" --arg id "$contract" \
      --argjson types "$types" --argjson contract_version "$contract_version" '
      {name:$n, version:"0.1.0", description:"stub", author:{name:"tests"},
       skills:[("./playbooks/"+$pb)],
       metadata:{harness:{installationSurface:"playbook-package", marketplace:$m,
         entryRoot:("./playbooks/"+$pb), playbooks:{($pb):("./playbooks/"+$pb)},
         internalPlugins:{(($n+"-worker")):"./skills/worker"}, contractVersion:$contract_version,
         implements:[({id:$id, version:$contract_version, kind:"playbook", playbook:$pb}
                      + (if ($types|length)>0 then {types:$types} else {} end))]}}}' \
      > "$dir/.${runtime}-plugin/plugin.json"
    printf '%s\n' "{\"name\":\"$playbook\",\"version\":\"0.1.0\"}" > "$dir/playbooks/$playbook/.${runtime}-plugin/plugin.json"
    printf '%s\n' "{\"name\":\"${name}-worker\",\"version\":\"0.1.0\"}" > "$dir/skills/worker/.${runtime}-plugin/plugin.json"
  done
}

# 実配布物がその契約を自己宣言しているか。宣言していなければ配線試験はstubで続け、
# 実配布物に対する解決は「保留」として報告する（黙って緑にしない）。
declares_contract() { # declares_contract <package root> <契約ID>
  local package="$1" contract="$2" runtime
  local contract_version=1
  [ "$contract" = "write-doc/write-doc" ] && contract_version=2
  for runtime in claude codex; do
    [ -f "$package/.${runtime}-plugin/plugin.json" ] || return 1
    jq -e --arg id "$contract" --argjson contract_version "$contract_version" \
      '[.metadata.harness.implements // [] | .[] | select(.id==$id and .version==$contract_version and .kind=="playbook")] | length==1' \
      "$package/.${runtime}-plugin/plugin.json" >/dev/null || return 1
  done
  return 0
}

stub_provider "$TMP/stub-grill" grill grill grill grill/grill
stub_provider "$TMP/stub-write-doc" write-doc write-doc write-doc write-doc/write-doc north-star strategy

# 実配布物（兄弟checkoutの plugins/）を必ず解決対象にする。無ければ落とす。
# stubは負の試験の配線にだけ使い、実配布物の代わりにはしない。
real_grill="$ROOT/../grill-plugins/plugins"
real_write_doc="$ROOT/../write-doc-plugins/plugins"
grill_root=""; write_doc_root=""
if [ -d "$real_grill" ] && declares_contract "$real_grill" grill/grill; then
  grill_root=$(cd "$real_grill" && pwd -P); ok "grillの実配布物がgrill/grill v1を宣言している"
else
  ng "grillの実配布物が無い、またはgrill/grill v1を宣言していない"; grill_root="$TMP/stub-grill"
fi
if [ -d "$real_write_doc" ] && declares_contract "$real_write_doc" write-doc/write-doc; then
  write_doc_root=$(cd "$real_write_doc" && pwd -P); ok "write-docの実配布物がwrite-doc/write-doc v2を宣言している"
else
  ng "write-docの実配布物が無い、またはwrite-doc/write-doc v2を宣言していない"; write_doc_root="$TMP/stub-write-doc"
fi

jq -n --arg w "$write_doc_root" --arg g "$grill_root" \
  '{schema:1,dependencies:{"write-doc/write-doc":$w,"grill/grill":$g}}' > "$TMP/dev-map.json"

echo "  When 両playbookを両runtimeで解決する"
for runtime in codex claude; do
  for item in "$NORTH_ROOT:north" "$STRATEGY_ROOT:strategy"; do
    playbook_root=${item%%:*}
    label=${item#*:}
    if HARNESS_PLUGIN_RUNTIME="$runtime" HARNESS_PLUGIN_DEV_ROOTS="$TMP/dev-map.json" \
       bash "$playbook_root/scripts/resolve.sh" "$TMP" > "$TMP/${label}-${runtime}.yml" 2> "$TMP/${label}-${runtime}.err"; then
      yq -o=json '.' "$TMP/${label}-${runtime}.yml" | jq -e --arg w "$write_doc_root" --arg g "$grill_root" --arg cleanup "$wd_internal_cleanup" '
        (.deps["write-doc"].dependency_scope=="external") and
        (.deps["write-doc"].contract=="write-doc/write-doc") and
        (.deps["write-doc"].package_root==$w) and
        (.deps["write-doc"].source_kind=="dev-map") and
        ([.deps["write-doc"].implements[] | select(.id=="write-doc/write-doc" and .version==2 and .kind=="playbook")]|length==1) and
        (.deps["write-doc"].entry==(.deps["write-doc"].root+"/SKILL.md")) and
        (.deps["write-doc"].entry_skill=="write-doc") and
        (.deps.grill.dependency_scope=="external") and
        (.deps.grill.contract=="grill/grill") and
        (.deps.grill.package_root==$g) and
        ([.deps.grill.implements[] | select(.id=="grill/grill" and .version==1 and .kind=="playbook")]|length==1) and
        (.deps.grill.entry==(.deps.grill.root+"/SKILL.md")) and
        (.deps.grill.entry_skill=="grill") and
        ([.deps[] | select(.dependency_scope=="internal") | .entry] | all(.==null)) and
        ([.deps[] | select(.dependency_scope=="internal")]|length>0) and
        ([.playbook.steps[] | select(has("playbook")) | .playbook]==["grill","write-doc"]) and
        ([.playbook.steps[] | select(has("skill")) | .skill] | all(. != "grill" and . != $cleanup))
      ' >/dev/null && ok "${label}/${runtime}は外部依存を公開playbookとして解決する" \
        || ng "${label}/${runtime}の外部依存の解決結果"
      # direct invocation の公開面は playbook.yml と .entry（入口SKILL.md）。実在を確かめる。
      for dep in grill write-doc; do
        for member in playbook.yml; do
          [ -f "$(yq -er ".deps[\"$dep\"].root" "$TMP/${label}-${runtime}.yml")/$member" ] \
            || ng "${dep}の公開入口が無い: $member"
        done
        entry_path=$(yq -er ".deps[\"$dep\"].entry" "$TMP/${label}-${runtime}.yml")
        entry_name=$(yq -er ".deps[\"$dep\"].entry_skill" "$TMP/${label}-${runtime}.yml")
        if [ -f "$entry_path" ] && [ "$(basename "$entry_path")" = SKILL.md ] &&
           rg -q "^name: ${entry_name}\$" "$entry_path"; then
          ok "${dep}/${label}/${runtime}のentryは入口SKILL.mdの実pathでentry_skillと一致する"
        else
          ng "${dep}/${label}/${runtime}のentryが入口SKILL.mdと一致しない: $entry_path ($entry_name)"
        fi
      done
    else
      ng "${label}/${runtime}の公開依存解決: $(head -1 "$TMP/${label}-${runtime}.err")"
    fi
  done
done

echo "  Then 規則違反へ戻すと解決が止まる"
# package まるごと写してから playbook.yml を壊す。所属bundleの宣言を保ったまま
# 同梱playbook.yml そのものを変異させるので、同梱固定の requires 検査も通り抜けて
# 規則違反そのものが検出理由になる。
mutate_resolve() { # mutate_resolve <playbook名> <jq式> <期待するerror code> <説明>
  local playbook_name="$1" expr="$2" code="$3" label="$4"
  local work="$TMP/mutated"
  local playbook_root="$work/plugins/playbooks/product/$playbook_name"
  rm -rf "$work"; mkdir -p "$work"
  cp -R "$ROOT/plugins" "$work/plugins"
  yq -o=json -I=0 '.' "$playbook_root/playbook.yml" | jq "$expr" | yq -P > "$work/mutated.yml"
  mv "$work/mutated.yml" "$playbook_root/playbook.yml"
  # 責務契約の固定はここでの検査対象ではない。resolverが規則違反そのもので止まることを見る。
  printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$playbook_root/scripts/validate-config.sh"
  # install cacheは空にする。dev-mapで解決できない依存はdependency-missingで止まるべきである。
  mkdir -p "$playbook_root/.harness-plugin-test-cache"
  if HARNESS_PLUGIN_RUNTIME=codex HARNESS_PLUGIN_DEV_ROOTS="$TMP/dev-map.json" \
     HARNESS_PLUGIN_CACHE_ROOT="$playbook_root/.harness-plugin-test-cache" \
     bash "$playbook_root/scripts/resolve.sh" "$TMP" >/dev/null 2> "$TMP/mutated.err"; then
    ng "$label が解決できてしまう"
  elif rg -q "\[error:$code\]" "$TMP/mutated.err"; then
    ok "$label は $code で止まる"
  else
    ng "$label が $code 以外で落ちた: $(head -1 "$TMP/mutated.err")"
  fi
}
# 外部依存を skill: で掴み直す（`skill: grill` への差し戻し）。
mutate_resolve product-north-star-planning '.steps[0] |= (del(.playbook) + {skill:"grill"})' \
  external-dependency-skill "north-starの対話工程をskill: grillへ戻す"
mutate_resolve product-strategy-planning '.steps[2] |= (del(.playbook) + {skill:"grill"})' \
  external-dependency-skill "strategyの対話工程をskill: grillへ戻す"
# 外部packageの内部pluginを requires して内部skillを掴む。
mutate_resolve product-north-star-planning \
  ".requires += [{plugin:\"$grill_internal_plugin\",marketplace:\"grill\"}] | .steps[0] |= (del(.playbook) + {skill:\"$grill_internal_skill\"})" \
  dependency-missing "north-starがgrillの内部pluginを指す"
mutate_resolve product-strategy-planning \
  ".requires += [{plugin:\"$wd_internal_plugin\",marketplace:\"write-doc\"}] | .steps[7] |= (del(.playbook) + {skill:\"$wd_internal_writer\"})" \
  dependency-missing "strategyがwrite-docの内部pluginを指す"
# 外部依存の root から公開面4点以外のpathを組み立てる。
mutate_resolve product-north-star-planning \
  '.steps[4].arguments=["--from=${.deps[\"write-doc\"].root}/scripts/'"$wd_internal_script"'"]' \
  external-dependency-path "north-starがwrite-doc rootから別のpathを組み立てる"
# 外部依存の script を直接実行する。
mutate_resolve product-north-star-planning \
  '.steps[4] |= (del(.playbook) + {script:"scripts/persist.sh", plugin:"write-doc"})' \
  external-dependency-script "north-starがwrite-docのscriptを直接実行する"
# 契約を宣言しない実体へ束縛すると座に着けない。
no_contract="$TMP/no-contract"
stub_provider "$no_contract" grill grill grill grill/grill
for runtime in claude codex; do
  jq 'del(.metadata.harness.implements)' "$no_contract/.${runtime}-plugin/plugin.json" > "$TMP/no-contract.json"
  mv "$TMP/no-contract.json" "$no_contract/.${runtime}-plugin/plugin.json"
done
jq -n --arg w "$write_doc_root" --arg g "$no_contract" \
  '{schema:1,dependencies:{"write-doc/write-doc":$w,"grill/grill":$g}}' > "$TMP/no-contract-map.json"
if HARNESS_PLUGIN_RUNTIME=codex HARNESS_PLUGIN_DEV_ROOTS="$TMP/no-contract-map.json" \
   bash "$NORTH_ROOT/scripts/resolve.sh" "$TMP" >/dev/null 2> "$TMP/no-contract.err"; then
  ng "契約を宣言しない実体が依存として座に着いてしまう"
elif rg -q '\[error:external-dependency-no-playbook\]' "$TMP/no-contract.err"; then
  ok "契約を宣言しない実体はexternal-dependency-no-playbookで止まる"
else
  ng "契約未宣言を期待した理由で拒否できない: $(head -1 "$TMP/no-contract.err")"
fi
# 公開packageのmanifest identityは依存契約として検査される。
wrong="$TMP/wrong-identity"
rm -rf "$wrong"; mkdir -p "$wrong"; cp -R "$TMP/stub-grill/." "$wrong/"
for runtime in claude codex; do
  jq '.name="wrong-grill"' "$wrong/.${runtime}-plugin/plugin.json" > "$TMP/wrong.json"
  mv "$TMP/wrong.json" "$wrong/.${runtime}-plugin/plugin.json"
done
jq -n --arg w "$write_doc_root" --arg g "$wrong" \
  '{schema:1,dependencies:{"write-doc/write-doc":$w,"grill/grill":$g}}' > "$TMP/wrong-map.json"
if HARNESS_PLUGIN_RUNTIME=codex HARNESS_PLUGIN_DEV_ROOTS="$TMP/wrong-map.json" \
   bash "$NORTH_ROOT/scripts/resolve.sh" "$TMP" >/dev/null 2> "$TMP/wrong.err"; then
  ng "identityの違うpackageを依存として受け入れてしまう"
else
  ok "identityの違うpackageを依存として拒否する"
fi

echo "Scenario: 対話の出力を束ねる工程と後片付け工程は消費側が持つ"
echo "  Given 実配布物で解決した実行設定と、契約どおりの対話工程出力がある"
work="$TMP/work"
mkdir -p "$work"
git -C "$work" init -q
git -C "$work" config user.email tests@example.invalid
git -C "$work" config user.name tests
printf 'tracked\n' > "$work/tracked.md"
git -C "$work" add tracked.md
git -C "$work" -c commit.gpgsign=false commit -qm fixture
cfg=$(HARNESS_PLUGIN_RUNTIME=claude HARNESS_PLUGIN_DEV_ROOTS="$TMP/dev-map.json" \
  bash "$NORTH_ROOT/scripts/prepare.sh" "$work" 2>/dev/null) \
  && ok "実配布物に対してprepareが実行設定を返す" || ng "prepareの実行設定"
cat > "$TMP/dialogue-output.yml" <<'YML'
contract: grill/grill
version: 1
status: completed
decisions:
  - {id: q1, question: 受益者は誰か, answer: 経理組織, rationale: 転記が最も重い}
open_questions:
  - {id: q2, question: 補助指標を置くか, state: open, reason: 観測データが無い}
YML
printf 'request\n' > "$work/request.md"
echo "  When 束ねる工程を実行する"
if python3 "$NORTH_ROOT/scripts/ground.py" --config "$cfg" \
     --dialogue-output "$TMP/dialogue-output.yml" --request "$work/request.md" \
     --output "$TMP/grounded.json" >/dev/null &&
   jq -e '.decisions|length==1' "$TMP/grounded.json" >/dev/null &&
   jq -e '.open_questions[0].state=="open"' "$TMP/grounded.json" >/dev/null &&
   jq -e '.document_type=="north-star"' "$TMP/grounded.json" >/dev/null; then
  ok "決定と未決を根拠づけられた入力へ束ねる"
else
  ng "根拠づけられた入力の生成"
fi
echo "  Then 契約を満たさない対話出力では束ねない"
sed 's|grill/grill|other/other|' "$TMP/dialogue-output.yml" > "$TMP/dialogue-wrong-contract.yml"
expect_fail python3 "$NORTH_ROOT/scripts/ground.py" --config "$cfg" \
  --dialogue-output "$TMP/dialogue-wrong-contract.yml" --output "$TMP/g-bad.json"
sed 's|status: completed|status: failed|' "$TMP/dialogue-output.yml" > "$TMP/dialogue-failed.yml"
expect_fail python3 "$NORTH_ROOT/scripts/ground.py" --config "$cfg" \
  --dialogue-output "$TMP/dialogue-failed.yml" --output "$TMP/g-bad.json"
sed '/rationale/s|, rationale: 転記が最も重い||' "$TMP/dialogue-output.yml" > "$TMP/dialogue-no-why.yml"
expect_fail python3 "$NORTH_ROOT/scripts/ground.py" --config "$cfg" \
  --dialogue-output "$TMP/dialogue-no-why.yml" --output "$TMP/g-bad.json"

echo "  When 後片付け工程を実行する"
seed_artifacts() {
  printf 'candidate\n' > "$work/candidate.md"
  printf 'verified\n' > "$work/verified.md"
  printf 'document\n' > "$work/document.md"
}
seed_artifacts
if python3 "$NORTH_ROOT/scripts/cleanup.py" --config "$cfg" \
     --artifact candidate_product_north_star_path="$work/candidate.md" \
     --artifact product_north_star_path="$work/verified.md" \
     --artifact product_north_star_document_path="$work/document.md" >/dev/null \
   && [ ! -e "$work/candidate.md" ] && [ ! -e "$work/verified.md" ] && [ -f "$work/document.md" ]; then
  ok "削除候補だけを消し、最終資料を保持する"
else
  ng "後片付けの範囲"
fi
echo "  Then 最終資料・repository外・追跡済みファイルには手を触れない"
seed_artifacts
expect_fail python3 "$NORTH_ROOT/scripts/cleanup.py" --config "$cfg" \
  --artifact candidate_product_north_star_path="$work/candidate.md" \
  --artifact product_north_star_document_path="$work/absent.md"
[ -f "$work/candidate.md" ] && ok "最終資料が無いときは何も削除しない" || ng "最終資料の確認"
expect_fail python3 "$NORTH_ROOT/scripts/cleanup.py" --config "$cfg" \
  --artifact candidate_product_north_star_path="$TMP/dialogue-output.yml" \
  --artifact product_north_star_document_path="$work/document.md"
expect_fail python3 "$NORTH_ROOT/scripts/cleanup.py" --config "$cfg" \
  --artifact candidate_product_north_star_path="$work/tracked.md" \
  --artifact product_north_star_document_path="$work/document.md"
[ -f "$work/tracked.md" ] && ok "追跡済みファイルを消さない" || ng "追跡済みファイルの保護"
expect_fail python3 "$NORTH_ROOT/scripts/cleanup.py" --config "$cfg" \
  --artifact unknown_path="$work/candidate.md" \
  --artifact product_north_star_document_path="$work/document.md"
python3 "$NORTH_ROOT/scripts/run-config.py" cleanup --config "$cfg" >/dev/null 2>&1 || true

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
    ng "${plugin}が別のskillを参照している"
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
