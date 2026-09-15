#!/usr/bin/env bash
set -euo pipefail
file="$1"
jq -e '
  .contract.north_star_sections==["対象","望む状態","約束する価値","プロダクトの役割","判断原則","やらないこと","根拠と仮説","見直し条件","未決"] and
  .contract.forbidden_sections==["診断","基本方針","一貫した行動","資源配分","行動計画","ロードマップ","期限つき施策"] and
  .requirements.interactive_with_grill==true and .requirements.no_strategy_output==true and .document_type=="north-star" and .inputs==["user_input","referenced_artifacts","document_destination"] and
  [.requires[].plugin]==["grill","product-north-star","write-doc"] and [.requires[].marketplace]==["grill","product-planning","write-doc"] and
  .contract.cleanup.delete_after_document==["candidate_product_north_star_path"] and .contract.cleanup.preserve==["product_north_star_document_path"] and
  [.steps[].id]==["settle-north-star","ground-north-star","define-north-star","verify","document","cleanup"] and
  [.steps[] | (.agent_work // .script // .playbook)]==["grill","invoking_agent","invoking_agent","scripts/verify.py","write-doc","scripts/cleanup.py"] and
  all(.steps[]; ([has("agent_work"),has("script"),has("playbook"),has("skill")]|map(select(.))|length)==1) and
  ([.steps[] | select(has("agent_work")) | .agent_work]==["invoking_agent","invoking_agent"]) and
  ([.steps[] | select(has("playbook")) | .playbook]==["grill","write-doc"]) and
  ([.steps[] | select(has("skill") or has("plugin"))]|length)==0 and
  .steps[0].needs==["user_input","referenced_artifacts"] and .steps[0].provides==["status","decisions","open_questions","reason"] and
  .steps[1].needs==["status","decisions","open_questions"] and .steps[1].provides==["north_star_evidence"] and
  .steps[2].needs==["north_star_evidence"] and .steps[2].provides==["final_markdown","candidate_product_north_star_path","work_directory"] and
  .steps[3].needs==["candidate_product_north_star_path"] and .steps[3].provides==["validation_report"] and
  .steps[4].needs==["final_markdown","validation_report","document_destination"] and .steps[4].provides==["status","path","reason"] and
  .steps[4].input=={"document_type":"${.document_type}"} and
  .steps[5].needs==["work_directory","candidate_product_north_star_path","path"] and .steps[5].provides==["cleanup_report"]
' "$file" >/dev/null || {
  echo "[error] product-north-star-planningはYAML順のgrill→同一agentの根拠整理→本文作成→構造検査→text資料化→安全な後片付けで構成する" >&2
  exit 2
}
