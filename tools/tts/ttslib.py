"""회화 음성 공통(러시아어). 일본어앱 tools/tts/ttslib.py 와 같은 구조, 절차는 일본어앱 docs/DIALOGUE_AUDIO.md.
감정 계획 = data/tts/plan/<편id>.json. 회화 파일의 emotion·segs 에서 tools/tts/plan_from_dialogue.py 가 만든다(손으로 적지 않는다).
audio_lines 열: text = 러시아어 본문(강세 부호 포함), reading = 빈 값, rd = 한글 독음, ko = 한국어 뜻. 모델에는 강세 부호를 뺀 글을 준다."""
import glob, json, os, re, sys
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LANG = 'ru'
if '--lang' in sys.argv:
    _i = sys.argv.index('--lang'); del sys.argv[_i:_i + 2]
V = json.load(open(f'{R}/data/tts/voices.json', encoding='utf-8'))
EP = {os.path.basename(p)[:-5]: p for p in glob.glob(f'{R}/assets/data/dialogues/R*/*/*.json')}
SENT = re.compile(r'(?<=[.?!…»])\s+')
WORD = re.compile(r'[^\w]+', re.U)
EMOJI = re.compile('[\U0001F000-\U0001FAFF☀-➿️]')


def plain(s):
    return s.replace('́', '')


def desc(v):
    return V['voices'][v]['desc']


def fill(s, g, key):
    for k, x in V['fill'].items():
        s = s.replace(k, x[g][key])
    return s


def spoken(s):
    """모델이 읽을 글: 강세 부호·이모지·따옴표를 빼고 말줄임은 쉼표로(끝이면 마침표)."""
    s = re.sub(r'[«»]', '', EMOJI.sub('', plain(s))).strip()
    s = re.sub(r'\s*(…|\.\.\.)\s*$', '.', s)
    return re.sub(r'\s*(…|\.\.\.)\s*', ', ', s)


def split(tl, emos, raw=False):
    """본문을 문장으로 나눠 감정을 붙이고, 이웃한 같은 감정·두 낱말 이하 문장은 합친다."""
    out = []; parts = []
    for x in SENT.split(tl.strip()):
        if parts and x[:1].islower():
            parts[-1] += ' ' + x
        elif x:
            parts.append(x)
    carry = ''
    for i, s in enumerate(parts):
        e = emos[min(i, len(emos) - 1)]; s = (carry + ' ' + s).strip(); carry = ''
        if out and (out[-1][0] == e or len(s.split()) <= 2):
            out[-1] = (out[-1][0], out[-1][1] + ' ' + s)
        elif len(s.split()) <= 2 and i < len(parts) - 1:
            carry = s
        else:
            out.append((e, s))
    return out if raw else [(e, spoken(s)) for e, s in out]


def segments(T, tl, g):
    """계획의 한 턴 → [(감정, 읽을 글)]. T = 감정 목록(문장마다 차례로) 또는 {"segs":[[감정, 본문]…], "segs_f":…}."""
    if isinstance(T, list):
        return split(tl, T)
    x = T.get('segs_f') if g == 'f' else None
    if x:
        return [(e, spoken(fill(s, g, 'es'))) for e, s in x]
    if g == 'f' and T.get('differs'):           # 여자판 본문이 다른데 segs_f 가 없으면 같은 감정을 문장마다 준다
        return split(tl, [e for e, _ in T['segs']])
    return [(e, spoken(fill(s, g, 'es'))) for e, s in T['segs']]


def turns(ep):
    """[{num, speaker, m:{voice,text,reading,rd,ko,segs}, f:{…}, same}]"""
    P = json.load(open(f'{R}/data/tts/plan/{ep}.json', encoding='utf-8')); d = json.load(open(EP[ep], encoding='utf-8'))
    out = []
    for t in d['turns']:
        row = {'num': t['num'], 'speaker': t['speaker']}; emos = P['turns'][str(t['num'])]
        for g in 'mf':
            fx = '_f' if g == 'f' else ''
            tl = fill(t.get('es' + fx) or t['es'], g, 'es')
            row[g] = {'voice': ('am' if g == 'm' else 'af') if t['speaker'] == 'A' else P['cast'][t['speaker']], 'text': tl, 'reading': '',
                      'rd': fill(t.get('rd' + fx) or t.get('rd', ''), g, 'rd'), 'ko': fill(t.get('ko' + fx) or t['ko'], g, 'ko'), 'segs': segments(emos, tl, g)}
        row['same'] = row['m']['voice'] == row['f']['voice'] and row['m']['segs'] == row['f']['segs']
        out.append(row)
    return out


def seg_files(ep):
    """생성할 조각 [(파일이름, 목소리, 감정, 읽기)] — 두 판이 같으면 c 하나, 다르면 m·f."""
    out = []
    for r in turns(ep):
        for tag in (['c'] if r['same'] else ['m', 'f']):
            x = r['m' if tag == 'c' else tag]
            for i, (emo, text) in enumerate(x['segs']):
                out.append((f"{r['num']:02d}_{i}_{tag}.wav", x['voice'], emo, text))
    return out


def planned():
    return sorted(os.path.basename(p)[:-5] for p in glob.glob(f'{R}/data/tts/plan/*.json') if os.path.basename(p)[:-5] in EP)
