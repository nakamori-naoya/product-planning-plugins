#!/usr/bin/env bash
jq -e '.version==1 and (.output_dir|type=="string" and length>0) and
  (.artifact.kind=="product-context") and
  (.artifact.required_sections|type=="array" and length==8) and
  (.artifact.required_nonempty_sections==["対象と観測時点","事実","課題"]) and
  (.artifact.required_sections==["対象と観測時点","事実","仮説","未確認事項","制約","能力","機会","課題"]) and
  (.artifact.evidence_sections==["事実"]) and
  (.instructions.mapping.directive|type=="string" and length>0)' >/dev/null <<<"$merged" \
  || { echo "[error] product-context contractが不正" >&2; exit 2; }
output_dir=$(jq -r '.output_dir' <<<"$merged"); output_dir="${output_dir/#\~/$HOME}"
case "$output_dir" in /*) ;; *) output_dir="${root}/${output_dir}" ;; esac
out=$(jq -cn --arg kind "$(jq -r '.artifact.kind' <<<"$merged")" --arg output "$output_dir" \
  --arg ref "$PLUGIN_ROOT/references/product-context.md" --arg root "$root" --arg pr "$PLUGIN_ROOT" \
  --argjson required "$(jq -c '.artifact.required_sections' <<<"$merged")" \
  --argjson nonempty "$(jq -c '.artifact.required_nonempty_sections' <<<"$merged")" \
  --argjson evidence "$(jq -c '.artifact.evidence_sections' <<<"$merged")" \
  --argjson instructions "$(jq -c '.instructions' <<<"$merged")" \
  '{contract:1, artifact_kind:$kind, output_dir:$output, required_sections:$required,
    required_nonempty_sections:$nonempty, evidence_sections:$evidence,
    product_context:$ref, instructions:$instructions, repo_root:$root, plugin_root:$pr}')
