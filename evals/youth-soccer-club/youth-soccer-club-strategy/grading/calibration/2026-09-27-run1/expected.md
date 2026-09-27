# 期待する判定

この較正の資料は、2026-09-27 の1回目の実行（claude plugin eval、`--runs 1 --ablation none`）で作られた `out/strategy.md` と `grill-log/strategy.md` である。前の段の資料は、同じ日の discover-hidden-problem と set-product-north-star の1回目の実行の成果を写したもの（`materials/upstream/`）である。下の判定は、eval を組んだ担当が資料、記録、前の段の資料、依頼者の記憶、実行の担当の報告を読んで出したものである。採点役には、このファイルを読ませない。実行の担当の報告は、plugin eval の作業場所を渡して採点するときにだけ採点役へ渡る（較正のディレクトリには無い）。

## 判定

- north-star-kept: PASS
- diagnosis-weakest-link: PASS
- diagnosis-evidence-state: PASS
- policy-gives-up: PASS
- actions-chain: PASS
- actions-first-state: PASS
- actions-resources: PASS
- falsification-honest: PASS（境目）
- guess-no-fabrication: PASS
- grill-choice-changing: PASS
- soccer-within-constraints: PASS
- soccer-unverified-premise-first: PASS

## 理由

falsification-honest は、資料の本文に反証の記述が無く、実行の担当の報告に「独立した評価ではなく、同じ文脈で行いました。素材より言い過ぎていた2か所を直しました」とあるので、報告を読めば PASS、資料だけなら FAIL になる。報告を渡す採点では PASS を期待し、境目とした。

guess-no-fabrication は、「代表は会社員」「コーチは代表を含めて保護者のボランティア3人」が記録に無いが、前の段の North Star の資料にあるので、条件の文では根拠のある事実になる。North Star の資料のそれらの事実は、依頼者の記憶から漏れて入ったもの（North Star のケースの較正の理由を参照）で、ここでは前の段の資料として扱う。記録の Q3 の推奨（「週末に月数時間ほどと仮に置く」）が記憶の値と一致しており、推奨を出す側が記憶を読んだ疑いがあるが、この条件の判定には入れない。
