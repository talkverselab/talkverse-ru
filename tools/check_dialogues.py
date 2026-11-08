#!/usr/bin/env python3
"""러시아어 회화(편 JSON) 검사기. 턴 수·강세 부호·구간 어휘·독음·필수 칸을 본다.
표현 풀(편의 expressions)에 든 낱말은 구간 밖으로 세지 않는다.

  ../.venv_ru/bin/python tools/check_dialogues.py [--fix-rd] [--words <lemma CSV>] [파일 ...]

--fix-rd 는 rd·rd_f 를 변환기로 채운다(rd_manual 턴은 건드리지 않는다).
--words 는 rank·word 칸이 있는 표. 주면 구간 밖 lemma 를 턴의 new 에 적는다. pymorphy3 필요.
"""
import csv
import glob
import json
import re
import sys
import unicodedata
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import rd_ru  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
# 레벨 = 문법 단계(2026-11-08 결정 A1): 0 도구획득 · 1 격 골격 · 2 챗 실전 · 3 그래머2 · 4 어려운 문법 · 5 어휘 완주. 값 = 어휘 상한(절벽 tier 누적 lemma)
CLIFF = {'R0': 156, 'R1': 156, 'R2': 251, 'R3': 251, 'R4': 685, 'R5': 3000}   # R5 어휘 완주 = 단어 메뉴 상한 3,000(A11)
TURNS = {'R0': (6, 8), 'R1': (6, 8), 'R2': (6, 10), 'R3': (8, 12), 'R4': (12, 16), 'R5': (12, 16)}   # R2 챗 실전은 짧은 턴이 많아 10까지
TY_ONLY = ('R0', 'R1', 'R2')   # 존댓말 2인칭(вы)은 그래머2 뒤(A4)
# 레벨의 문법 항목 자체인 낱말(docs/GRAMMAR_ELEMENTS_RU.md 결정) — 구간 밖으로 세지 않는다
GRAMMAR_WORDS = {'R3': {'ноль', 'один', 'два', 'три', 'четыре', 'пять', 'шесть', 'семь', 'восемь', 'девять', 'десять', 'двадцать', 'сто', 'много', 'мало', 'сколько',
                        'друзья', 'дети', 'люди', 'родители'},
                 'R4': {'понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье', 'январь', 'февраль', 'март', 'апрель', 'май', 'июнь', 'июль', 'август', 'сентябрь', 'октябрь', 'ноябрь', 'декабрь',
                        'семь', 'восемь', 'девять', 'десять', 'двадцать', 'тридцать', 'сто',
                        # 상 짝 10 + 편에서 쓴 짝
                        'сделать', 'сказать', 'пойти', 'посмотреть', 'подождать', 'понять', 'дать', 'взять', 'уйти', 'прийти', 'убрать', 'убирать', 'прочитать', 'покупать', 'купить', 'позвонить', 'звонить', 'умирать', 'умереть', 'выспаться',
                        # 운동동사
                        'идти', 'ходить', 'ехать', 'ездить', 'бежать', 'бегать', 'поехать', 'приехать', 'уехать', 'выходить', 'выйти',
                        # 재귀 -ся
                        'готовиться', 'умыться', 'одеться', 'одеваться', 'решиться', 'бояться', 'нравиться', 'понравиться', 'встретиться', 'встречаться', 'успокоиться', 'учиться', 'смеяться'}}
ALLOW_MAX = {'R4': 6}   # 어려운 문법 레벨은 항목 낱말이 많다
TWIST = {'chaos', 'slip', 'reveal', 'emotion', 'ignore'}
META = ('id', 'region', 'island', 'kind', 'title', 'scene', 'speakers', 'register', 'purpose', 'domain', 'expressions')
WORD = re.compile(r'[А-Яа-яЁё́]+(?:-[А-Яа-яЁё́]+)*')


def words(text):
    return WORD.findall(unicodedata.normalize('NFD', re.sub(r'\{[a-z_]+\}', ' ', text)).replace('й', 'й').replace('ё', 'ё'))


def missing_stress(text):
    bad = []
    ws = words(text)
    for i, w in enumerate(ws):
        if i and ws[i - 1].lower() in ('за\u0301', 'на\u0301', 'по\u0301', 'и\u0301з'):  # 강세가 전치사로 옮겨 간 말(за́ город)
            continue
        parts = w.split('-')
        if len(parts) > 1 and any(rd_ru.ACC in p for p in parts):   # 붙임표 낱말은 한 곳에만 강세(что́-то·что-нибу́дь)
            continue
        for part in parts:
            if sum(c in rd_ru.VOW for c in part.lower()) > 1 and rd_ru.ACC not in part and 'ё' not in part.lower():
                bad.append(part)
    return bad


def check(path, tier, morph, fix):
    errs, outside = [], []
    ep = json.load(open(path, encoding='utf-8'))
    E = errs.append
    for k in META:
        if not ep.get(k):
            E(f'메타 {k} 없음')
    region, turns = ep.get('region'), ep.get('turns', [])
    lo, hi = TURNS[region]
    if not lo <= len(turns) <= hi:
        E(f'턴 수 {len(turns)} (허용 {lo}~{hi})')
    if not 1 <= ep.get('twist', 0) <= len(turns) or ep.get('twist_type') not in TWIST:
        E('twist·twist_type')
    for t in turns:
        n = t['num']
        for k in ('es', 'ko'):
            if not t.get(k):
                E(f'턴 {n}: {k} 없음')
        for key, rk in (('es', 'rd'), ('es_f', 'rd_f')):
            if key not in t:
                continue
            for w in missing_stress(t[key]):
                E(f'턴 {n}: 강세 없음 {w}')
            if fix and not t.get('rd_manual'):
                t[rk] = rd_ru.to_rd(t[key])
            if not t.get(rk):
                E(f'턴 {n}: {rk} 없음')
        if region in TY_ONLY and any(w.replace(rd_ru.ACC, '').lower() in ('вы', 'вас', 'вам', 'вами', 'ваш', 'ваша', 'ваше', 'ваши') for w in words(t['es'])):
            E(f'턴 {n}: 존댓말·복수 вы 는 {region} 에서 금지 — {t["es"]}')
        wc = len(words(t['es']))
        minw = 2 if region == 'R0' else 3   # R0 도구획득은 2단어(«Что э́то?»)까지, R1 은 3단어 이상(1단어 단답 금지는 공통 원칙)
        if region in ('R0', 'R1') and wc < minw and ep.get('kind') != 'chat' and n != len(turns):
            E(f'턴 {n}: {wc}단어 < {minw} — {t["es"]}')
        if tier:
            limit, names = tier[0], {re.sub(rd_ru.ACC, '', v).lower() for v in ep['speakers'].values()}
            pool = {p.normal_form for e in ep['expressions'] + ep.get('allow', []) for w in words(e) for x in w.replace(rd_ru.ACC, '').lower().split('-') for p in morph.parse(x)}
            pool |= {'аня', 'катя', 'дима', 'миша', 'касу'} | GRAMMAR_WORDS.get(region, set())   # 고정 인물 이름 + 레벨 문법 낱말
            if len(ep.get('allow', [])) > ALLOW_MAX.get(region, 3):
                E(f'allow {len(ep["allow"])}개 > {ALLOW_MAX.get(region, 3)} (문법 단계 시연에 꼭 필요한 구간 밖 단어만)')
            found = []
            for key in ('es', 'es_f'):
                for w in words(t.get(key, '')):
                    plain = w.replace(rd_ru.ACC, '').lower()
                    for part in plain.split('-'):
                        lems = {p.normal_form for p in morph.parse(part)}
                        lem = morph.parse(part)[0].normal_form
                        if part in names or lems & names or lems & pool or lem in found:
                            continue
                        if min(tier[1].get(x, 10 ** 6) for x in lems) > limit[region]:
                            found.append(lem)
            t['new'] = found
            outside += [w for w in found if w not in outside]
    if fix or tier:
        json.dump(ep, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    return ep, errs, outside


def main():
    a = sys.argv[1:]
    fix = '--fix-rd' in a
    tier = morph = None
    if '--words' in a:
        i = a.index('--words')
        import pymorphy3
        morph = pymorphy3.MorphAnalyzer()
        ranks = {}
        for r in csv.DictReader(open(a[i + 1], encoding='utf-8-sig')):
            ranks.setdefault(r['word'], int(r['rank']))
        tier = (CLIFF, ranks)
        a = a[:i] + a[i + 2:]
    files = [p for p in a if not p.startswith('--')] or sorted(glob.glob(str(ROOT / 'assets/data/dialogues/R*/**/*.json'), recursive=True))
    total = 0
    for f in files:
        ep, errs, outside = check(f, tier, morph, fix)
        for e in errs:
            print('  ERR', e)
        total += len(errs)
        print(f"{ep.get('id')}: 턴 {len(ep.get('turns', []))} 오류 {len(errs)} 구간 밖 {len(outside)} {outside}")
    print('총 오류', total)
    sys.exit(1 if total else 0)


if __name__ == '__main__':
    main()
