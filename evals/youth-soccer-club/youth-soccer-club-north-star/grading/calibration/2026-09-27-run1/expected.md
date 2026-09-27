# 期待する判定

この較正の資料は、2026-09-27 の1回目の実行（claude plugin eval、`--runs 1 --ablation none`）で作られた `out/north-star.md` と `grill-log/north-star.md` である。前の段の資料は、同じ日の discover-hidden-problem の1回目の実行の成果を写したもの（`materials/upstream/problem-hypothesis.md`）である。下の判定は、eval を組んだ担当が資料、記録、前の段の資料、依頼者の記憶を読んで出したもので、採点役がこれを再現できるかで採点の形を確かめる。採点役には、このファイルを読ませない。

## 判定

- future-who-and-state: PASS
- future-product-role: PASS
- no-strategy-content: PASS
- principle-real-choice: PASS
- non-goals-concrete: PASS
- evidence-separated: PASS
- guess-no-fabrication: FAIL
- review-conditions: PASS
- grill-value-judgments-only: PASS
- soccer-beneficiary-grounded: PASS
- soccer-upstream-risk-carried: PASS

## 理由

guess-no-fabrication は、「対象」と「その人が置かれた場面」にある「代表を含むコーチ3人」「代表は会社員で、平日の日中はクラブの連絡に時間を使えない」「練習は土曜の午前、試合は月に2回ほど日曜」「遠征は月に2回ほど」「小学生40人（1〜6年生）」が、依頼の文にも前の段の資料にも記録の依頼者の答えにも無く、依頼者の記憶の「クラブの今の状況」から直接入ったものなので FAIL とした。実行の担当が依頼者の役と作り手の役を一人で務めたために起きた漏れで、skill の欠陥とは限らない。

受益者は Q1 で推奨を仮置きし、「対象」と「未決」に仮置きと書かれているので soccer-beneficiary-grounded は PASS とした。前の段の最も危うい前提（保護者が変更を一か所へ出すか）は「現時点の見立て」と「見直し条件」に引き継がれているので soccer-upstream-risk-carried は PASS とした。
