#!/usr/bin/env python3
"""러시아어 → 한글 독음(rd) 변환기. 강세 부호(◌́)가 달린 문장을 받는다. 표기표 = docs/RD_RULES_RU.md.

  python tools/rd_ru.py "Приве́т! Как дела́?"
"""
import re
import sys
import unicodedata

ACC = '́'
VOW = 'аеёиоуыэюя'
CHO = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ'
JUNG = 'ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ'
JONG = ['', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ']
ONSET = dict(б='ㅂ', в='ㅂ', г='ㄱ', д='ㄷ', ж='ㅈ', з='ㅈ', к='ㄲ', л='ㄹ', м='ㅁ', н='ㄴ', п='ㅃ', р='ㄹ', с='ㅅ', т='ㄸ', ф='ㅍ', х='ㅎ', ц='ㅉ', ч='ㅊ', ш='ㅅ', щ='ㅅ')
CLUSTER = dict(б='브', в='브', г='그', д='드', ж='즈', з='즈', к='끄', л='르', м='므', н='느', п='쁘', р='르', с='스', т='뜨', ф='프', х='흐', ц='쯔', ч='치', ш='시', щ='시')
FINAL = dict(б='ㅂ', п='ㅂ', г='ㄱ', к='ㄱ', д='ㅌ', т='ㅌ', м='ㅁ', н='ㄴ', л='ㄹ')  # 낱말 끝 받침
FINAL_SYL = dict(в='프', ф='프', ж='시', ш='시', щ='시', з='스', с='스', х='흐', ц='쯔', ч='치', р='르')
SOFT_END = dict(т='찌', д='찌', с='시', з='시', л='리', н='니', р='리', м='미', в='피', б='피', п='삐', ф='피', ш='시', ч='치', ж='시')
DEVOICE = dict(б='п', в='ф', г='к', д='т', ж='ш', з='с')
VOICELESS = 'кпстфхцчшщ'
HARD = 'жшц'  # 뒤의 е·и·ё 가 딱딱해지는 자음
# 철자대로 읽지 않는 낱말 → 소리대로 다시 쓴 철자(강세 포함)
RESPELL = {
    'что': 'што', 'чтобы': 'што́бы', 'что-то': 'што́-та', 'что-нибудь': 'што-ни́буть', 'конечно': 'кане́шна', 'скучно': 'ску́шна',
    'сегодня': 'сево́дня', 'откуда': 'аку́да', 'сейчас': 'сича́с', 'его': 'иво́', 'ничего': 'ничиво́', 'чего': 'чиво́', 'кого': 'каво́', 'него': 'ниво́', 'сего': 'сиво́',
    'здравствуйте': 'здра́ствуйти', 'здравствуй': 'здра́ствуй', 'пожалуйста': 'пажа́луста', 'солнце': 'со́нцэ',
    'легко': 'лихко́', 'мягко': 'мяхко́', 'лёгкий': 'лёхкий', 'счастье': 'ща́стье', 'счёт': 'щёт',
    'спасибо': 'спаси́ба', 'может': 'мо́жет', 'лол': 'лол', 'ок': 'о́кэй',
}
# 강세 없이 뒷말에 붙는 한 음절 낱말
CLITIC = {'не': '니', 'ни': '니', 'на': '나', 'по': '빠', 'до': '다', 'но': '나', 'за': '자', 'из': '이즈', 'от': '앝', 'об': '압', 'о': '아',
          'про': '쁘라', 'под': '빹', 'без': '비스', 'в': '브', 'с': '스', 'к': '끄', 'же': '제', 'ли': '리', 'бы': '븨', 'то': '따'}
SH = {'ㅏ': 'ㅑ', 'ㅗ': 'ㅛ', 'ㅜ': 'ㅠ', 'ㅔ': 'ㅖ', 'ㅢ': 'ㅣ'}


def compose(cho, jung, jong=''):
    return chr(0xAC00 + CHO.index(cho) * 588 + JUNG.index(jung) * 28 + JONG.index(jong))


def add_jong(syl, jong):
    code = ord(syl[-1]) - 0xAC00
    if not 0 <= code < 11172 or code % 28:
        return None
    return syl[:-1] + chr(ord(syl[-1]) + JONG.index(jong))


def vowel_jung(v, stressed, prev, first, last=False):
    """(중성, 앞 자음을 무시하고 쓸 초성 또는 None)."""
    hard = bool(prev) and prev in HARD
    if v == 'а':
        return 'ㅏ'
    if v == 'о':
        return ('ㅗ' if stressed else 'ㅏ')
    if v == 'у':
        return 'ㅜ'
    if v == 'э':
        return 'ㅔ' if stressed else 'ㅣ'
    if v == 'ы':
        return 'ㅢ' if prev and prev not in HARD else 'ㅣ'
    if v == 'и':
        return 'ㅢ' if prev in ('ж', 'ш') else 'ㅣ'
    if v == 'е':
        if stressed:
            return 'ㅔ' if hard else 'ㅖ'
        if not prev:
            return 'ㅣ' if first else 'ㅖ'
        return 'ㅣ'
    if v == 'ё':
        return 'ㅗ' if hard else 'ㅛ'
    if v == 'ю':
        return 'ㅜ' if hard else 'ㅠ'
    if v == 'я':
        if stressed or not prev or last:
            return 'ㅑ'
        return 'ㅣ'
    raise ValueError(v)


def word_rd(word):
    low = unicodedata.normalize('NFD', word.lower())
    low = low.replace('й', 'й').replace('ё', 'ё')
    plain = low.replace(ACC, '')
    if plain in RESPELL:
        low = RESPELL[plain]
        low = unicodedata.normalize('NFD', low).replace('й', 'й').replace('ё', 'ё')
    if low in CLITIC:
        return CLITIC[low]
    low = re.sub('т(ь)?ся$', 'ца', low)
    low = re.sub('ся$', 'ша', low)
    low = re.sub('([иы]' + ACC + '?)й$', r'\1', low)
    low = re.sub('(о' + ACC + '?)го$', lambda m: m.group(1) + 'во', low) if len(low) > 4 else low
    low = re.sub('(е' + ACC + '?)го$', lambda m: m.group(1) + 'во', low) if len(low) > 4 else low
    low = low.replace('вств', 'ств').replace('стн', 'сн').replace('здн', 'зн').replace('лнц', 'нц').replace('сч', 'щ').replace('дц', 'ц')
    chars = []  # (글자, 강세)
    for c in low:
        if c == ACC and chars:
            chars[-1] = (chars[-1][0], True)
        elif c == '-':
            chars.append((' ', False))
        else:
            chars.append((c, False))
    # 단음절이면 그 모음에 강세
    vs = [i for i, (c, _) in enumerate(chars) if c in VOW]
    if len(vs) == 1 or any(c == 'ё' for c, _ in chars):
        for i in vs:
            if len(vs) == 1 or chars[i][0] == 'ё':
                chars[i] = (chars[i][0], True)
    out = ''
    i, n = 0, len(chars)
    prev_vowel = False
    while i < n:
        c, st = chars[i]
        nxt = chars[i + 1][0] if i + 1 < n else ''
        if c == ' ':
            out += ' '; prev_vowel = False; i += 1; continue
        if c in 'ъ':
            i += 1; continue
        if c == 'й':
            if nxt in VOW and nxt:
                v = chars[i + 1]
                out += compose('ㅇ', vowel_jung(v[0], v[1], '', True)); i += 2; prev_vowel = True; continue
            out += '이'; i += 1; prev_vowel = False; continue
        if c in VOW:
            out += compose('ㅇ', vowel_jung(c, st, '', i == 0)); prev_vowel = True; i += 1; continue
        if c == 'ь':
            i += 1; continue
        # 자음
        soft = nxt == 'ь'
        after = chars[i + 2][0] if soft and i + 2 < n else nxt
        if soft and after in VOW and after:  # 분리 부호: семья·пьёт
            v = chars[i + 2]
            out += dict(SOFT_END, з='지', д='지').get(c, ''); out += compose('ㅇ', vowel_jung(v[0], v[1], '', False)); i += 3; prev_vowel = True; continue
        if soft:
            if prev_vowel and c in 'лнм' and after:
                j = add_jong(out, {'л': 'ㄹ', 'н': 'ㄴ', 'м': 'ㅁ'}[c])
                if j:
                    out = j; i += 2; prev_vowel = False; continue
            if prev_vowel and c == 'л' and not after:
                out = (add_jong(out, 'ㄹ') or out) + '리'; i += 2; prev_vowel = False; continue
            out += (dict(SOFT_END, з='지', д='지') if after else SOFT_END).get(c, ''); i += 2; prev_vowel = False; continue
        if nxt and nxt in VOW:
            v, vs_ = chars[i + 1]
            nn = chars[i + 2][0] if i + 2 < n else ''
            cho = ONSET[c]
            jung = vowel_jung(v, vs_, c, False, i + 2 >= n)
            if c in 'шщ':
                jung = SH.get(jung, jung)
            if c == 'т' and v in 'еиёюя':
                cho = 'ㅉ'
                jung = {'ㅖ': 'ㅔ'}.get(jung, jung)
            elif c == 'д' and v in 'еиёюя':
                cho = 'ㅈ'
                jung = {'ㅖ': 'ㅔ'}.get(jung, jung)
            elif c == 'с' and v == 'и':
                cho = 'ㅆ'
            elif c == 'л' and out and out[-1] != ' ':
                j = add_jong(out, 'ㄹ')
                if j:
                    out = j
            out += compose(cho, jung); prev_vowel = True; i += 2; continue
        if not nxt or nxt == ' ':  # 낱말 끝
            d = DEVOICE.get(c, c)
            if prev_vowel and (c in FINAL):
                j = add_jong(out, FINAL[c])
                if j:
                    out = j; i += 1; prev_vowel = False; continue
            out += FINAL_SYL.get(d, FINAL_SYL.get(c, CLUSTER[c])); i += 1; prev_vowel = False; continue
        # 자음 앞 자음
        if prev_vowel and c in 'лмн':
            j = add_jong(out, {'л': 'ㄹ', 'м': 'ㅁ', 'н': 'ㄴ'}[c])
            if j:
                out = j; i += 1; prev_vowel = False; continue
        d = DEVOICE.get(c, c) if nxt in VOICELESS else c
        if c == nxt:  # 겹자음 하나로
            i += 1; continue
        out += CLUSTER[d]; prev_vowel = False; i += 1
    return out


def to_rd(text):
    text = unicodedata.normalize('NFD', text)
    text = text.replace('й', 'й').replace('Й', 'Й').replace('ё', 'ё').replace('Ё', 'Ё')
    parts = re.findall(r'\{[a-z_]+\}|[А-Яа-яЁё́]+(?:-[А-Яа-яЁё́]+)*|[A-Za-z0-9]+', text)
    return ' '.join(p if p.startswith('{') or re.match('[A-Za-z0-9]', p) else word_rd(p) for p in parts)


if __name__ == '__main__':
    print(to_rd(' '.join(sys.argv[1:])))
