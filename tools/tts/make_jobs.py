#!/usr/bin/python3
"""감정 계획 → PC 작업 파일(D:\\tts_test\\job). language 'Russian'. PC 출력은 ref_<lang>/, <lang>/<편>/ 로 나눈다(같은 이름의 다른 언어 파일을 건너뛰지 않게).
  python3 tools/tts/make_jobs.py <출력폴더> --refs [편id...]   쓰이는 (목소리, 감정) 참고 음성 → vox_jobs.json 에 덧붙임
  python3 tools/tts/make_jobs.py <출력폴더> <편id>...          문장 조각 → moss_jobs.json 에 덧붙임 (out/<lang>/<편>/<턴>_<조각>_<c|m|f>.wav)
같은 파일에 덧붙인다. 새로 만들려면 파일을 먼저 지운다."""
import json, os, sys
import ttslib as L


def add(path, rows):
    old = json.load(open(path, encoding='utf-8')) if os.path.exists(path) else []
    seen = {x['out'] for x in old}
    old += [r for r in rows if r['out'] not in seen]
    json.dump(old, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=0); print(os.path.basename(path), len(old))


def main():
    out, eps = sys.argv[1], sys.argv[2:]; G = L.LANG
    if eps and eps[0] == '--refs':
        ids = eps[1:] or L.planned()
        need = sorted({(v, e) for ep in ids for _, v, e, _ in L.seg_files(ep)})
        vox = [{'out': f'ref_{G}/{v}_base.wav', 'text': L.V['base_text'], 'instruct': L.desc(v)} for v in sorted({v for v, _ in need})]
        for v, e in need:
            E = L.V['emotions'][e]
            vox.append({'out': f'ref_{G}/{v}_{e}.wav', 'text': E['ref'], 'instruct': f"{L.desc(v)}, {E['instruct']}", 'reference': f'out/ref_{G}/{v}_base.wav'})
        add(f'{out}/vox_jobs.json', vox); return
    add(f'{out}/moss_jobs.json', [{'out': f'{G}/{ep}/{f}', 'text': text, 'language': 'Russian', 'reference': f'out/ref_{G}/{v}_{e}.wav'} for ep in eps for f, v, e, text in L.seg_files(ep)])


if __name__ == '__main__':
    main()
