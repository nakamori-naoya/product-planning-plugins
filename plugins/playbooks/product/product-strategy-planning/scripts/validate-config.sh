#!/usr/bin/env bash
set -euo pipefail
file="$1"
jq -e '
  .contract.north_star_sections==["対象","望む状態","約束する価値","プロダクトの役割","判断原則","やらないこと","根拠と仮説","見直し条件","未決"] and
  .contract.forbidden_north_star_sections==["診断","基本方針","一貫した行動","資源配分","行動計画","ロードマップ","期限つき施策"] and
  .contract.strategy_sections==["診断","基本方針","一貫した行動"] and
  .contract.critique_verdicts==["合格","要修正"] and
  .requirements.interactive_with_grill==true and
  .requirements.independent_critique==true and
  .requirements.preserve_north_star==true and
  .requirements.stop_on_required_revision==true and
  .document_type=="strategy" and
  [.requires[].plugin]==["product-context","grill","product-strategy","strategy-critique","write-doc"] and
  [.requires[].marketplace]==["product-planning","grill","product-planning","product-planning","write-doc"] and
  .contract.cleanup.delete_after_document==["product_context_path","product_strategy_path","strategy_critique_path","verified_strategy_path"] and
  .contract.cleanup.preserve==["product_north_star_path","product_strategy_document_path"] and
  [.steps[].id]==["validate-north-star","map-context","settle-strategy","ground-strategy","form-strategy","critique","verify","document","cleanup"] and
  [.steps[] | (.skill // .script // .playbook)]==["scripts/validate-north-star.py","map-product-context","grill","scripts/ground.py","form-product-strategy","challenge-strategy","scripts/verify.py","write-doc","scripts/cleanup.py"] and
  ([.steps[] | select(has("skill")) | .skill]==["map-product-context","form-product-strategy","challenge-strategy"]) and
  ([.steps[] | select(has("playbook")) | .playbook]==["grill","write-doc"]) and
  ([.steps[] | select(has("plugin"))]|length)==0 and
  .steps[0].provides==["product_north_star_path","product_north_star_sha256"] and
  .steps[1].needs==["product_north_star_path"] and
  .steps[1].provides==["product_context_path","context_unknowns","challenges"] and
  .steps[2].needs==["product_north_star_path","product_context_path","context_unknowns","challenges"] and
  .steps[2].provides==["decisions","open_questions"] and
  (.steps[2]|has("input")|not) and
  .steps[3].needs==["product_north_star_path","product_context_path","challenges","decisions","open_questions"] and
  .steps[3].provides==["grounded_strategy"] and
  .steps[4].needs==["product_north_star_path","product_context_path","challenges","grounded_strategy"] and
  .steps[4].provides==["product_strategy_path"] and
  .steps[5].needs==["product_north_star_path","product_context_path","product_strategy_path","grounded_strategy"] and
  .steps[6].needs==["product_north_star_path","product_north_star_sha256","product_strategy_path","strategy_critique_path","critique_verdict"] and
  .steps[6].provides==["verified_strategy_path"] and
  .steps[7].needs==["verified_strategy_path","product_north_star_path","product_context_path","strategy_critique_path"] and
  .steps[7].provides==["status","product_strategy_document_path","reason"] and
  .steps[7].input=={"document_type":"${.document_type}"} and
  .steps[8].needs==["product_context_path","product_strategy_path","strategy_critique_path","verified_strategy_path","product_north_star_path","product_strategy_document_path"] and
  .steps[8].provides==["cleanup_report"]
' "$file" >/dev/null || {
  echo "[error] product-strategy-planningはnorth-star検査→context→grill→根拠づけ→strategy→critique→verify→write-doc→自分の中間生成物の後片付けという契約を変えられない" >&2
  exit 2
}
