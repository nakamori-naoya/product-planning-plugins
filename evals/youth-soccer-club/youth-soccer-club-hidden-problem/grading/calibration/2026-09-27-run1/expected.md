# 期待する判定

この較正の資料は、2026-09-27 の1回目の実行（claude plugin eval、`--runs 1 --ablation none`）で作られた `out/problem-hypothesis.md` と `grill-log/problem-hypothesis.md` である。下の判定は、eval を組んだ担当が資料、記録、依頼、依頼者の記憶を読んで出したもので、採点役がこれを再現できるかで採点の形を確かめる。採点役には、このファイルを読ませない。

## 判定

- event-not-opinion: PASS
- event-coping-counted: PASS
- event-questions-no-leading: PASS
- event-per-person: PASS
- essence-explains-symptoms: PASS
- essence-solution-traced: PASS
- hypothesis-one-sentence: PASS
- hypothesis-directions-few: PASS
- risk-four-kinds: PASS
- risk-first-test: PASS
- guess-no-fabrication: PASS
- scope-no-north-star: PASS
- soccer-events-elicited: PASS
- soccer-essence-not-solution-inverse: PASS
- soccer-extras-not-adopted: PASS

## 理由

出来事はどれも記録の Q1〜Q3、Q6 の答えにあり、Q4 の「いつもそう」は自己申告として出来事と分けられ、Q5 の会計の保護者の話は又聞きとして未決に置かれている。本質は「予定と変更の行き先が代表一人」で、採らなかった候補（返事の遅さ、LINE が流れること、配車を一人で担うこと）ごとに説明できない症状が書かれ、集金と当番は説明しない症状として別に扱われている。価値仮説は機能でなく代表の状況の変化で、方向は二つ、最初に確かめる前提は価値と実現性の二つを同じ方法でまとめ、崩れたとする結果と残す結果が決まっている。「前日18時以降」は確かめ方の区切りとして置いた値で、事実として書いていないので guess-no-fabrication は PASS とした。
