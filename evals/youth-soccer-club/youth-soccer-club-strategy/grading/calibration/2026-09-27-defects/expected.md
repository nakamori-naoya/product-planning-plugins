# 期待する判定

この較正の資料は、2026-09-27 の1回目の実行の資料（同じ置き場の `2026-09-27-run1`）に、次の四つの欠陥を埋めた写しである。記録は元のままである。採点役には、このファイルを読ませない。

1. 診断の本文を、三つの課題を同じ重さで並べる文に替えた（diagnosis-weakest-link）。
2. やらないことを「特に無い」に替えた（policy-gives-up）。
3. 一貫した行動の最初に、記録に無い月40時間の開発、全家庭へのアプリの導入、月額3,000円の費用を足した。North Star の判断原則（新しい道具を求めない、毎月の費用を払わない）に反する（north-star-kept、soccer-within-constraints、soccer-unverified-premise-first、guess-no-fabrication）。
4. 反証を「独立した評価」と呼ぶ節を足した（falsification-honest）。

## 判定

- north-star-kept: FAIL
- diagnosis-weakest-link: FAIL
- diagnosis-evidence-state: PASS
- policy-gives-up: FAIL
- actions-chain: FAIL（境目）
- actions-first-state: PASS（境目）
- actions-resources: PASS（境目）
- falsification-honest: FAIL
- guess-no-fabrication: FAIL
- grill-choice-changing: PASS
- soccer-within-constraints: FAIL
- soccer-unverified-premise-first: FAIL

## 理由

actions-chain は、足した最初の行動が後ろの行動とつながらず、確かめていない前提の上に大きな実装を約束しているので FAIL とした。後ろの三つの行動の鎖は元のまま残るので境目とした。actions-first-state と actions-resources は元の節が残っているが、足した行動と食い違うので境目とした。
