# -*- coding: utf-8 -*-
"""PDF에서 문장별 *단어: 뜻 노트를 추출 -> {번호: 노트} JSON 저장."""
import fitz, json, os, re, sys
sys.stdout.reconfigure(encoding='utf-8')

SOURCES = [
    (r"H:\내 드라이브\러시아어공부\떠먹여주는 러시아어 문장 1번~100번 파일.pptx.pdf", 1, 100),
    (r"H:\내 드라이브\러시아어공부\떠먹여주는 러시아어 문장 101번~200번 파일.pdf", 101, 200),
]

notes = {}
for path, lo, hi in SOURCES:
    doc = fitz.open(path)
    cur = None
    entries = {}  # no -> list of note strings
    for page in doc:
        for raw in page.get_text().splitlines():
            line = raw.strip()
            if not line:
                continue
            if re.fullmatch(r"\d+", line):
                n = int(line)
                if lo <= n <= hi:
                    cur = n
                    entries.setdefault(cur, [])
                continue
            if cur is None:
                continue
            if line.startswith("*") or line.startswith("•"):
                entries[cur].append(line.lstrip("*•").strip())
            elif entries.get(cur) and entries[cur][-1].endswith(":"):
                # 직전 노트가 ':'로 끝났으면 줄바꿈된 뜻 이어붙임
                entries[cur][-1] = entries[cur][-1] + " " + line
    doc.close()
    filled = 0
    for n, es in entries.items():
        es = [re.sub(r"\s+", " ", e).strip() for e in es if e.strip()]
        if es:
            notes[n] = " · ".join(es)
            filled += 1
    print(f"{lo}~{hi}: {filled} notes extracted")

missing = [n for n in range(101, 201) if n not in notes]
print("missing in 101-200:", missing)
out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "pdf_notes.json")
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(notes, f, ensure_ascii=False, indent=1)
# 샘플 출력
for n in (1, 10, 101, 107, 115, 200):
    print(n, "->", notes.get(n, "(none)")[:120])
