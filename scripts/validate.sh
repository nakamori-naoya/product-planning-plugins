#!/usr/bin/env bash
# Scenario: repositoryのplugin集合、manifest、marketplace、公開入口の構造、決定論的toolの契約が一致する
# 機械検査は宣言と実体の対応、隣接playbook.ymlの契約、verify / validate-north-star の閉じた入出力（標準入力の本文＋正本path）だけを判定する。
# North Starや戦略の内容、反証の妥当性、SKILL本文の判断基準の十分性は意味評価として残す。
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/plugin-repository-validation.XXXXXX") || exit 2
export TMPDIR="$TMP_ROOT"
trap 'rm -rf "$TMP_ROOT"' EXIT
failed=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failed=1; }

PACKAGE="$ROOT/plugins/product-planning"
ENTRIES=(set-product-north-star set-product-strategy)

# ── 配置と identity ──────────────────────────────────────────────────────
for market in .claude-plugin/marketplace.json .agents/plugins/marketplace.json; do
  if jq -e '.name=="product-planning" and (.plugins|length)==1 and .plugins[0].name=="product-planning" and .plugins[0].version=="5.0.0"
            and ((.plugins[0].source=="./plugins/product-planning") or (.plugins[0].source=={"source":"local","path":"./plugins/product-planning"}))' "$ROOT/$market" >/dev/null; then
    pass "$market identityとsource"
  else
    fail "$market identityとsource"
  fi
done
claude_identity=$(jq -c '{name,version,skills,harness:.metadata.harness}' "$PACKAGE/.claude-plugin/plugin.json")
codex_identity=$(jq -c '{name,version,skills,harness:.metadata.harness}' "$PACKAGE/.codex-plugin/plugin.json")
[ "$claude_identity" = "$codex_identity" ] && pass "両runtime manifestのidentity一致" || fail "両runtime manifestのidentity一致"
jq -e '.skills==["./skills/set-product-north-star","./skills/set-product-strategy"]
       and .metadata.harness=={"marketplace":"product-planning","contractVersion":1}' "$PACKAGE/.codex-plugin/plugin.json" >/dev/null \
  && pass "公開入口2つ、playbooks / internalPlugins / implements 無し" || fail "manifestの公開宣言"
manifest_dirs=$(find "$ROOT/plugins" -type d \( -name '.claude-plugin' -o -name '.codex-plugin' \) | sed "s#^$ROOT/##" | sort | tr '\n' ' ')
[ "$manifest_dirs" = "plugins/product-planning/.claude-plugin plugins/product-planning/.codex-plugin " ] \
  && pass "runtime manifest directoryはpackage rootの2つだけ" || fail "runtime manifest directoryが余分または欠落: $manifest_dirs"
skill_dirs=$(find "$PACKAGE/skills" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | tr '\n' ' ')
[ "$skill_dirs" = "set-product-north-star set-product-strategy " ] && pass "skills/直下は公開入口2つだけ" || fail "skills/直下: $skill_dirs"
skill_files=$(find "$ROOT/plugins" -name SKILL.md -type f | wc -l | tr -d ' ')
[ "$skill_files" -eq 2 ] && pass "SKILL.mdは公開入口の2本だけ（内部skillなし）" || fail "SKILL.mdの本数: $skill_files"
[ "$(find "$ROOT/plugins" -type l | wc -l | tr -d ' ')" -eq 0 ] && pass "配布物にsymlinkなし" || fail "配布物にsymlinkがある"

# ── 公開入口ごとの構造 ─────────────────────────────────────────────────
for entry in "${ENTRIES[@]}"; do
  dir="$PACKAGE/skills/$entry"
  name=$(awk 'NR==1 { if ($0 != "---") exit 2; next } $0=="---" { exit } { print }' "$dir/SKILL.md" | yq -r '.name')
  [ "$name" = "$entry" ] && pass "$entry: SKILL frontmatter name" || fail "$entry: SKILL frontmatter name = $name"
  pb=$(yq -o=json -I=0 '.' "$dir/playbook.yml")
  jq -e --arg n "$entry" '.version==2 and .name==$n
      and (.requires|map(.plugin)|sort)==["grill","write-doc"] and all(.requires[]; .marketplace==.plugin)
      and ((.steps|map(.id)|unique|length)==(.steps|length))
      and all(.steps[]; ([has("agent_work"),has("script"),has("skill"),has("playbook")]|map(select(.))|length)==1)
      and all(.steps[]|select(has("playbook")); .playbook=="grill" or .playbook=="write-doc")
      and ((.steps[]|select(.id=="document")).input.document_type|type)=="string"' <<<"$pb" >/dev/null \
    && pass "$entry: playbook.yml identity・外部requires・工程種別" || fail "$entry: playbook.yml"
  scripts_ok=1
  while IFS= read -r script; do [ -f "$dir/$script" ] || scripts_ok=0; done < <(jq -r '.steps[]|select(has("script")).script' <<<"$pb")
  [ "$scripts_ok" -eq 1 ] && pass "$entry: steps.script は入口内の実在file" || fail "$entry: steps.script の参照先"
  if rg -n --fixed-strings -e '${.' -e '<!-- BEGIN shared:' -e 'CLAUDE_PLUGIN_ROOT' -e 'BUNDLE_ROOT' "$dir/SKILL.md" "$dir/playbook.yml" "$dir/references" >/dev/null \
    || rg -n 'prepare\.sh|resolve\.sh|run-config\.py|state\.py|artifact\.py' "$dir/SKILL.md" "$dir/references" >/dev/null; then
    fail "$entry: 禁止参照形または旧runtime呼び出しが残っている"
  else
    pass "$entry: 禁止参照形と旧runtime呼び出しが無い"
  fi
done

# ── 構文 ────────────────────────────────────────────────────────────────
while IFS= read -r script; do bash -n "$script" || failed=1; done < <(find "$ROOT/scripts" "$ROOT/tests" -type f -name '*.sh' | sort)
while IFS= read -r script; do PYTHONPYCACHEPREFIX="$TMP_ROOT/pycache" python3 -m py_compile "$script" || failed=1; done < <(find "$PACKAGE" -type f -name '*.py' | sort)

# ── 決定論的toolの契約（BDD） ────────────────────────────────────────────
bash "$ROOT/tests/test-product-planning.sh" || failed=1
# ── 消費側の契約lint（G2同期後の共有版）: 外部依存の内部名を消費側の文書・script・設定へ書いていない ──
# 検出語は兄弟checkoutの実配布物（provider package root）から作る。兄弟が無ければ緑にせず失敗させる。
lint_consumer_contract() {
  local map="$TMP_ROOT/lint-dev-map.json" status=0 runtime
  local grill="$ROOT/../grill-plugins/plugins/grill" write_doc="$ROOT/../write-doc-plugins/plugins/write-doc" awp="$ROOT/../agent-work-policy-plugins/plugins/agent-work-policy"
  for provider in "$grill" "$write_doc" "$awp"; do
    [ -d "$provider" ] || { echo "[error] 依存先の配布物checkoutが無い: $provider" >&2; return 1; }
  done
  jq -n --arg g "$(cd "$grill" && pwd -P)" --arg w "$(cd "$write_doc" && pwd -P)" --arg a "$(cd "$awp" && pwd -P)" \
    '{schema:1,dependencies:{"grill/grill":$g,"write-doc/write-doc":$w,"agent-work-policy/agent-work-policy":$a}}' > "$map" || return 1
  for runtime in claude codex; do
    HARNESS_PLUGIN_DEV_ROOTS="$map" python3 "$ROOT/scripts/lint-consumer-contract.py" --repo "$ROOT" --runtime "$runtime" || status=1
  done
  return "$status"
}
lint_consumer_contract && pass "消費側契約lint（両runtime。依存先の内部名を書いていない）" || fail "消費側契約lint"

if [ "$failed" -eq 0 ]; then echo 'Validation: passed'; else echo 'Validation: failed'; fi
[ "$failed" -eq 0 ]
