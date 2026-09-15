#!/usr/bin/env bash
set -euo pipefail
file="$1"
jq -e '
  .contract.north_star_sections==["対象","望む状態","約束する価値","プロダクトの役割","判断原則","やらないこと","根拠と仮説","見直し条件","未決"] and
  .contract.strategy_sections==["診断","基本方針","一貫した行動"] and .contract.critique_verdicts==["合格","要修正"] and
  .requirements.interactive_with_grill==true and .requirements.independent_critique==true and .requirements.preserve_north_star==true and .requirements.stop_on_required_revision==true and
  .document_type=="strategy" and .inputs==["product_north_star_path","user_input","referenced_artifacts","document_destination"] and [.requires[].plugin]==["product-context","grill","product-strategy","strategy-critique","write-doc"] and
  [.requires[].marketplace]==["product-planning","grill","product-planning","product-planning","write-doc"] and
  .contract.cleanup.delete_after_document==["candidate_strategy_path","critique_path"] and .contract.cleanup.preserve==["product_north_star_path","product_strategy_document_path"] and
  [.steps[].id]==["validate-north-star","map-context","settle-strategy","form-strategy","critique","verify","decide-after-critique","document","cleanup"] and
  [.steps[] | (.agent_work // .script // .playbook)]==["scripts/validate-north-star.py","invoking_agent","grill","invoking_agent","invoking_agent","scripts/verify.py","invoking_agent","write-doc","scripts/cleanup.py"] and
  all(.steps[]; ([has("agent_work"),has("script"),has("playbook"),has("skill")]|map(select(.))|length)==1) and
  ([.steps[] | select(has("agent_work")) | .agent_work]==["invoking_agent","invoking_agent","invoking_agent","invoking_agent"]) and
  ([.steps[] | select(has("playbook")) | .playbook]==["grill","write-doc"]) and
  ([.steps[] | select(has("skill") or has("plugin"))]|length)==0 and
  .steps[0].needs==["product_north_star_path"] and .steps[0].provides==["product_north_star_path","product_north_star_sha256"] and
  .steps[1].needs==["product_north_star_path"] and .steps[1].provides==["product_context","context_unknowns","challenges"] and
  .steps[2].needs==["product_north_star_path","product_context","context_unknowns","challenges"] and .steps[2].provides==["status","decisions","open_questions","reason"] and
  .steps[3].needs==["product_north_star_path","product_context","challenges","status","decisions","open_questions"] and .steps[3].provides==["final_markdown","candidate_strategy_path","work_directory"] and
  .steps[4].needs==["product_north_star_path","product_context","final_markdown"] and .steps[4].provides==["critique","critique_path","critique_verdict"] and
  .steps[5].needs==["product_north_star_path","product_north_star_sha256","candidate_strategy_path","critique_path","critique_verdict"] and .steps[5].provides==["validation_report"] and
  .steps[6].needs==["final_markdown","critique","critique_verdict","validation_report"] and .steps[6].provides==["approved_strategy"] and
  .steps[7].needs==["approved_strategy","critique","validation_report","product_north_star_path","document_destination"] and .steps[7].provides==["status","path","reason"] and .steps[7].input=={"document_type":"${.document_type}"} and
  .steps[8].needs==["work_directory","candidate_strategy_path","critique_path","product_north_star_path","path"] and .steps[8].provides==["cleanup_report"]
' "$file" >/dev/null || {
  echo "[error] product-strategy-planningはYAML順のNorth Star検査→同一agentのcontext→grill→戦略→反証→構造検査→text資料化→安全な後片付けで構成する" >&2
  exit 2
}
