#!/usr/bin/env bash
jq -e '.version==1 and (.output_dir|type=="string" and length>0) and
  (.artifact.kind=="product-north-star") and
  (.artifact.required_sections|type=="array" and length==9) and
  (.artifact.required_nonempty_sections|type=="array" and length>0) and
  (.instructions.direction.directive|type=="string" and length>0)' >/dev/null <<<"$merged" \
  || { echo "[error] product-north-star contractが不正" >&2; exit 2; }
output_dir=$(jq -r '.output_dir' <<<"$merged"); output_dir="${output_dir/#\~/$HOME}"
case "$output_dir" in /*) ;; *) output_dir="${root}/${output_dir}" ;; esac
out=$(jq -cn --arg kind "$(jq -r '.artifact.kind' <<<"$merged")" --arg output "$output_dir" \
  --arg ref "$PLUGIN_ROOT/references/product-north-star.md" --arg root "$root" --arg pr "$PLUGIN_ROOT" \
  --argjson required "$(jq -c '.artifact.required_sections' <<<"$merged")" \
  --argjson nonempty "$(jq -c '.artifact.required_nonempty_sections' <<<"$merged")" \
  --argjson instructions "$(jq -c '.instructions' <<<"$merged")" \
  '{contract:1, artifact_kind:$kind, output_dir:$output, required_sections:$required,
    required_nonempty_sections:$nonempty, product_north_star:$ref,
    instructions:$instructions, repo_root:$root, plugin_root:$pr}')
