#!/usr/bin/env bash
set -euo pipefail
file="$1"
jq -e '
  .contract.north_star_sections==["対象","望む状態","約束する価値","プロダクトの役割","判断原則","やらないこと","根拠と仮説","見直し条件","未決"] and
  .contract.forbidden_sections==["診断","基本方針","一貫した行動","資源配分","行動計画","ロードマップ","期限つき施策"] and
  .requirements.interactive_with_grill==true and
  .requirements.no_strategy_output==true and
  .document_type=="north-star" and
  .output_format=="markdown" and
  [.requires[].plugin]==["grill","product-north-star","write-doc","intermediate-cleanup"] and
  .contract.cleanup.delete_after_document==["candidate_product_north_star_path","product_north_star_path"] and
  .contract.cleanup.preserve==["product_north_star_document_path"] and
  [.steps[].id]==["settle-north-star","define-north-star","verify","document","cleanup"] and
  [.steps[] | (.skill // .script // .playbook)]==["grill","define-product-north-star","scripts/verify.py","write-doc","remove-intermediate-artifacts"] and
  .steps[0].provides==["north_star_evidence","decisions","unresolved"] and
  .steps[1].needs==["north_star_evidence","decisions","unresolved"] and
  .steps[1].provides==["candidate_product_north_star_path"] and
  .steps[2].needs==["candidate_product_north_star_path"] and
  .steps[2].provides==["product_north_star_path"] and
  .steps[3].needs==["product_north_star_path"] and
  .steps[3].provides==["product_north_star_document_path"] and
  .steps[4].needs==["candidate_product_north_star_path","product_north_star_path","product_north_star_document_path"] and
  .steps[4].provides==["cleanup_report"]
' "$file" >/dev/null || {
  echo "[error] product-north-star-planningはgrill→north-star→verify→write-doc→中間生成物の後片付けという契約を変えられない" >&2
  exit 2
}
