#!/usr/bin/env python3
"""회화 리뷰 페이지(폰 열람, 단일 HTML) — 일본어·베트남어앱 tools/review_html.py 를 러시아어용으로.
  python3 tools/review_html.py [편id...]   → data/review/REVIEW_ru.html (편을 안 주면 초안 전부)
음성 파일이 없는 턴은 재생 버튼을 그리지 않는다. 리뷰 키: <편id>:all, <편id>:audio, <편id>:<턴>. 게시는 uk 세션."""
import datetime, glob, html, json, os, sys
from pathlib import Path
R = Path(__file__).resolve().parent.parent
_a = R / 'data/tts/audio_ru.json'
AUD = json.load(open(_a, encoding='utf-8')) if _a.exists() else {}
EMO = {'stiff': '긴장·딱딱', 'flustered': '당황', 'excited': '흥분', 'amused': '유쾌', 'teasing': '놀림', 'shout': '버럭', 'cheerful': '밝음', 'tsukkomi': '받아치기', 'gentle': '다정',
       'neutral': '담담', 'polite': '공손', 'sad': '슬픔', 'annoyed': '짜증', 'surprised': '놀람', 'shy': '수줍음', 'worried': '걱정'}
EPS = {Path(p).stem: p for p in glob.glob(str(R / 'assets/data/dialogues/R*/*/*.json'))}
esc = html.escape


def aurl(r):
    return f"https://auth.talkverse.uk/art/{r['key']}?v={r['sha1'][:8]}"


def play(eid, n):
    rs = {r['voice']: r for r in AUD.get(eid, []) if r['turn'] == n}
    if not rs:
        return ''
    m, f = rs.get('m'), rs.get('f')
    em = lambda x: ' → '.join(EMO.get(e, e) for e in x['emotion'].split('+'))
    bs = ''.join(f"<button class='pl v{k}' data-u='{aurl(x)}' onclick='p1(this)'>▶ {lb}</button>" for k, x, lb in (('m', m, '남자 학습자판'), ('f', f, '여자 학습자판')) if x)
    return f"<div class=au>{bs}<span class=em>감정: {em(m or f)}</span></div>"


def box(k):
    return f"<div class=rv><textarea data-k='{k}' placeholder='리뷰…'></textarea><button onclick=\"sv(this)\">저장</button></div><div class=rs data-s='{k}'></div>"


def block(e):
    eid = e['id']; o = ['<section class=d>']
    if eid in AUD:
        o.append(f"<div class=aubox><b>🔊 음성</b> — 학습자 이름은 남성판 「알렉스」, 여성판 「에마」입니다.<div class=au><button class=pl onclick=\"pa(this,'m')\">▶ 전체 듣기(남자 학습자)</button><button class=pl onclick=\"pa(this,'f')\">▶ 전체 듣기(여자 학습자)</button></div>{box(f'{eid}:audio')}</div>")
    for t in e['turns']:
        n = t['num']; alt = ''; name = e['speakers'].get(t['speaker'], t['speaker'])
        if t.get('es_f') or t.get('ko_f'):
            es = t.get('es_f', t['es'])
            alt = f"<div class=fv>여자 학습자판: {esc(es)}<br><span class=rd>{esc(t.get('rd_f', t.get('rd', '')))}</span><br>{esc(t.get('ko_f', t.get('ko', '')))}</div>"
        o.append(f"<div class='t {t['speaker']}'><div class=sp>{n} {esc(name)}</div><div class=tl>{esc(t['es'])}</div><div class=rd>{esc(t.get('rd', ''))}</div><div class=ko>{esc(t.get('ko', ''))}</div>{alt}{play(eid, n)}{box(f'{eid}:{n}')}</div>")
    o.append('</section>')
    return ''.join(o)


css = """:root{--bg:#fff;--fg:#0a2540;--mut:#6b7c93;--card:#f6f8fb;--a:#f0f8f6;--line:#e6ebf1;--pri:#635bff;--warm:#b77548}
@media(prefers-color-scheme:dark){:root{--bg:#10151c;--fg:#e8edf3;--mut:#93a1b3;--card:#1a212b;--a:#17262a;--line:#2b3542;--pri:#8f88ff;--warm:#e0a878}}
body{font-family:-apple-system,'Noto Sans KR',sans-serif;max-width:860px;margin:0 auto;padding:16px;background:var(--bg);color:var(--fg);line-height:1.5}
h1{font-size:20px}h2{font-size:17px;margin:28px 0 4px}h3{font-size:15px;margin:18px 0 6px;color:var(--warm)}.meta{font-size:12px;color:var(--mut);margin-bottom:12px}
.t{margin:10px 0;padding:10px 12px;border-radius:12px;background:var(--card);border:1px solid var(--line)}.t.A{background:var(--a)}.t.now{outline:2px solid var(--pri)}
.sp{font-size:11px;color:var(--mut)}.tl{font-size:17px;font-weight:600}.rd{font-size:13px;color:var(--pri)}.ko{font-size:14px}.fv{font-size:13px;color:var(--mut);margin-top:6px;border-top:1px dashed var(--line);padding-top:4px}
.nav a{display:inline-block;margin:2px 6px 2px 0;font-size:12px;color:var(--pri)}
.rv{display:flex;gap:6px;margin-top:8px}.rv textarea{flex:1;min-width:0;min-height:38px;border:1px solid var(--line);border-radius:8px;padding:6px 8px;font:inherit;font-size:14px;background:var(--bg);color:var(--fg);resize:vertical}
.rv button{border:0;border-radius:8px;padding:0 12px;background:var(--pri);color:#fff;font-size:13px;cursor:pointer}.rv button.ok{background:#1b7f3b}.rv button.err{background:#b42318}.rs{font-size:11px;color:var(--mut);margin-top:2px}
.au{display:flex;flex-wrap:wrap;align-items:center;gap:6px;margin-top:6px}.pl{border:1px solid var(--line);border-radius:16px;padding:5px 12px;background:var(--bg);color:var(--fg);font-size:13px;cursor:pointer}.pl.on{background:var(--pri);border-color:var(--pri);color:#fff}
.em{font-size:12px;color:var(--warm)}.aubox{margin:10px 0;padding:10px 12px;border:1px solid var(--warm);border-radius:12px;font-size:14px}"""
JS = """const API='https://talkverse.uk/api/review/ru',LS='review_ru_v1';
function ld(){try{return JSON.parse(localStorage.getItem(LS)||'{}')}catch(e){return {}}}
function st(k,m,c){const el=document.querySelector(`[data-s="${k}"]`);if(el)el.textContent=m;document.querySelector(`[data-k="${k}"]`).nextElementSibling.className=c||'';}
function fill(d){for(const k in d){const t=document.querySelector(`[data-k="${k}"]`);if(t&&!t.value){t.value=d[k].text||'';const s=document.querySelector(`[data-s="${k}"]`);if(s)s.textContent='저장됨 '+(d[k].at||'');}}}
async function sv(b){const ta=b.previousElementSibling,k=ta.dataset.k,text=ta.value.trim(),at=new Date().toLocaleString('ko-KR',{hour12:false});
 const d=ld();d[k]={text,at};try{localStorage.setItem(LS,JSON.stringify(d))}catch(e){}st(k,'저장 중…','');
 try{const r=await fetch(API,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({key:k,text,at})});if(!r.ok)throw new Error(r.status);st(k,'서버 저장됨 '+at,'ok');}
 catch(e){st(k,'폰에만 저장됨 '+at+' (서버 연결 안 됨)','err');}}
const AU=new Audio();AU.preload='auto';let Q=[],B=null;
function off(){if(B)B.classList.remove('on');document.querySelectorAll('.t.now').forEach(x=>x.classList.remove('now'));}
function stop(){Q=[];AU.pause();off();B=null;}
function p1(b){if(B===b&&!AU.paused){stop();return;}stop();B=b;b.classList.add('on');AU.src=b.dataset.u;AU.play().catch(stop);}
function pa(b,g){if(B===b){stop();return;}stop();Q=[...b.closest('section').querySelectorAll('.t .pl.v'+g)];B=b;b.classList.add('on');nx();}
function nx(){const x=Q.shift();if(!x){stop();return;}const t=x.closest('.t');document.querySelectorAll('.t.now').forEach(y=>y.classList.remove('now'));t.classList.add('now');t.scrollIntoView({block:'center',behavior:'smooth'});AU.src=x.dataset.u;AU.play().catch(stop);}
AU.onended=()=>{if(Q.length)setTimeout(nx,350);else stop();};
(async()=>{fill(ld());try{const r=await fetch(API);if(r.ok)fill(await r.json());}catch(e){}})();"""
ids = sys.argv[1:] or sorted(EPS)
head = f"<!doctype html><html lang=ko><head><meta charset=utf-8><meta name=viewport content='width=device-width,initial-scale=1'><title>러시아어 회화 리뷰</title><style>{css}</style></head><body>"
parts = [head, f"<h1>러시아어 회화 리뷰</h1><div class=meta>갱신 {datetime.datetime.now():%Y-%m-%d %H:%M} · Claude 초안 · 레벨별 한 편 · 목소리·감정·강세·속도를 들어 주세요</div>{('<div class=aubox>' + esc(os.environ['REVIEW_NOTE']) + '</div>') if os.environ.get('REVIEW_NOTE') else ''}<div class=nav>"]
eps = [json.load(open(EPS[i], encoding='utf-8')) for i in ids]
parts += [f"<a href='#{e['id']}'>{e['region']} {esc(e['title'])}</a>" for e in eps] + ['</div>']
for e in eps:
    i = e['id']
    parts.append(f"<h2 id='{i}'>{esc(e.get('emoji', ''))} {e['region']} {esc(e['title'])} <small>{i}</small></h2><div class=meta>{esc(e['scene'])} · 반전 {e['twist_type']}(턴 {e['twist']})</div>{box(f'{i}:all')}")
    parts.append(block(e))
parts.append(f"<script>{JS}</script></body></html>")
out = R / 'data/review/REVIEW_ru.html'; out.write_text('\n'.join(parts), encoding='utf-8'); print(out, len(eps))
