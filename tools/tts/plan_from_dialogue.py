#!/usr/bin/python3
"""회화 파일의 감정 → 감정 계획 data/tts/plan/<편id>.json. 음성 도구는 이 계획만 읽는다.
  python3 tools/tts/plan_from_dialogue.py [편id...]    (없으면 전편)
턴마다 `emotion`(감정 하나) 또는 `segs`([[감정, 본문]…], 여자판 본문이 다르면 `segs_f`)를 쓴다. 감정이 없는 턴이 있으면 그 편은 만들지 않고 오류로 끝난다.
목소리: 고정 인물은 voices.json 의 names, 그 밖의 인물은 편의 `cast`({"B":"woman_y"})."""
import json, sys
import ttslib as L


def plan(ep):
    d = json.load(open(L.EP[ep], encoding='utf-8')); errs = []; cast = {}
    for k, name in d['speakers'].items():
        if k != 'A':
            cast[k] = d.get('cast', {}).get(k) or L.V['names'].get(name)
            if cast[k] not in L.V['voices']:
                errs.append(f'목소리 없음 {k}={name}')
    turns = {}
    for t in d['turns']:
        n = str(t['num'])
        if t.get('segs'):
            turns[n] = {k: t[k] for k in ('segs', 'segs_f') if t.get(k)}
            if t.get('es_f'):
                turns[n]['differs'] = True
            names = [x[0] for k in ('segs', 'segs_f') for x in t.get(k, [])]
        elif t.get('emotion'):
            turns[n] = names = [t['emotion']]
        else:
            errs.append(f'턴 {n} 감정 없음'); continue
        errs += [f'턴 {n} 모르는 감정 {e}' for e in names if e not in L.V['emotions']]
    return {'ep': ep, 'cast': cast, 'turns': turns}, errs


def main():
    ids = sys.argv[1:] or sorted(L.EP); bad = 0
    for ep in ids:
        P, errs = plan(ep)
        if errs:
            bad += 1; print(ep, *errs[:8], sep='\n  '); continue
        json.dump(P, open(f'{L.R}/data/tts/plan/{ep}.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('계획', len(ids) - bad, '문제', bad)
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
