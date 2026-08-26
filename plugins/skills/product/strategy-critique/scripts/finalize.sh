#!/usr/bin/env bash
jq -e '.version==1 and (.output_dir|type=="string" and length>0) and
  (.artifact.kind=="strategy-critique") and
  (.artifact.required_sections==["判定","診断への反証","基本方針への反証","一貫した行動への反証","鎖構造と近い目標への反証","制約・根拠・鮮度","修正要求"]) and
  (.artifact.required_nonempty_sections==["判定","診断への反証","基本方針への反証","一貫した行動への反証","鎖構造と近い目標への反証","制約・根拠・鮮度"]) and
  (.artifact.verdict_section=="判定") and (.artifact.allowed_verdicts==["合格","要修正"]) and
  (.instructions.critique.directive|type=="string" and length>0)' >/dev/null <<<"$merged" \
  || { echo "[error] strategy-critique contractが不正" >&2; exit 2; }
output_dir=$(jq -r '.output_dir' <<<"$merged"); output_dir="${output_dir/#\~/$HOME}"
case "$output_dir" in /*) ;; *) output_dir="${root}/${output_dir}" ;; esac
out=$(jq -cn --arg kind "$(jq -r '.artifact.kind' <<<"$merged")" --arg output "$output_dir" \
  --arg context "$PLUGIN_ROOT/references/product-context.md" \
  --arg north "$PLUGIN_ROOT/references/product-north-star.md" \
  --arg strategy "$PLUGIN_ROOT/references/product-strategy.md" --arg root "$root" --arg pr "$PLUGIN_ROOT" \
  --argjson required "$(jq -c '.artifact.required_sections' <<<"$merged")" \
  --argjson nonempty "$(jq -c '.artifact.required_nonempty_sections' <<<"$merged")" \
  --arg verdict "$(jq -r '.artifact.verdict_section' <<<"$merged")" \
  --argjson allowed "$(jq -c '.artifact.allowed_verdicts' <<<"$merged")" \
  --argjson instructions "$(jq -c '.instructions' <<<"$merged")" \
  '{contract:1, artifact_kind:$kind, output_dir:$output, required_sections:$required,
    required_nonempty_sections:$nonempty, verdict_section:$verdict, allowed_verdicts:$allowed,
    product_context:$context, product_north_star:$north, product_strategy:$strategy,
    instructions:$instructions, repo_root:$root, plugin_root:$pr}')
