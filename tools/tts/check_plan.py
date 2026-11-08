#!/usr/bin/python3
"""감정 계획 검사. python3 tools/tts/check_plan.py [편id...] — 문제 있는 편만 출력하고 끝에 합계."""
import json, sys
import ttslib as L
ids = sys.argv[1:] or sorted(L.EP); bad = 0
W = lambda s: [w for w in L.WORD.split(L.spoken(s).lower()) if w]
for ep in ids:
    errs = []; P = json.load(open(f'{L.R}/data/tts/plan/{ep}.json', encoding='utf-8')); d = json.load(open(L.EP[ep], encoding='utf-8'))
    for k in d['speakers']:
        if k != 'A' and P['cast'].get(k) not in L.V['voices']:
            errs.append(f'cast {k}')
    for t in d['turns']:
        E = P['turns'].get(str(t['num']))
        if not E:
            errs.append(f"턴 {t['num']} 없음"); continue
        names = E if isinstance(E, list) else [x[0] for k in ('segs', 'segs_f') for x in E.get(k, [])]
        errs += [f"턴 {t['num']} 감정 {e}" for e in names if e not in L.V['emotions']]
    if not errs:
        for r in L.turns(ep):
            for g in 'mf':
                got = ' '.join(s[1] for s in r[g]['segs'])
                if W(got) != W(r[g]['text']):
                    errs.append(f"턴 {r['num']} {g} 본문 다름: {got}")
                if '{' in r[g]['text'] + r[g]['rd'] + r[g]['ko']:
                    errs.append(f"턴 {r['num']} {g} 자리 표시 남음")
    if errs:
        bad += 1; print(ep, *errs[:8], sep='\n  ')
print('검사', len(ids), '문제', bad)
