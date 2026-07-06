# -*- coding: utf-8 -*-
"""떠먹여주는 러시아어 문장 xlsx 6개 -> lib/data/spoonfed_sentences.dart 생성.

사용법: pdf_notes.py 먼저 실행(101~200 단어설명 추출) 후 이 스크립트 실행.
"""
import json, openpyxl, os, re, sys
sys.stdout.reconfigure(encoding='utf-8')

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = r"H:\내 드라이브\러시아어공부"
OUT = os.path.join(HERE, "..", "lib", "data", "spoonfed_sentences.dart")
PDF_NOTES = os.path.join(HERE, "pdf_notes.json")

# (파일, 파싱모드) — 모드별 컬럼 배치가 다름
SOURCES = [
    ("떠먹여주는 러시아어 문장 001번~100번 파일.xlsx", "combined_bcd", (1, 100)),
    ("떠먹여주는 러시아어 문장 101번~200번 파일_퀴즐렛.xlsx", "combined_bc", (101, 200)),
    ("떠먹여주는 러시아어 문장 201번~300번 파일_퀴즐렛.xlsx", "split_bdef", (201, 300)),
    ("떠먹여주는 러시아어 문장 301번~400번 파일.xlsx", "split_bcde", (301, 400)),
    ("떠먹여주는 러시아어 문장 401번~500번 파일_퀴즐렛.xlsx", "split_bdef", (401, 500)),
    ("떠먹여주는 러시아어 문장 501번~600번 파일.xlsx", "split_ru_first", (501, 600)),
]

COMBINED_RE = re.compile(r"^(.*?)\s*\(([^()]*)\)\s*$", re.S)


def clean(s):
    if s is None:
        return ""
    return re.sub(r"\s+", " ", str(s)).strip()


def norm_note(s):
    s = clean(s)
    if not s:
        return None
    if "*" in s:  # '*야: 나는 *뽐뉴: 기억한다' -> '야: 나는 · 뽐뉴: 기억한다'
        parts = [p.strip() for p in s.split("*") if p.strip()]
        s = " · ".join(parts)
    return s or None


def split_combined(cell):
    """'Здравствуйте. (즈드라스트부이쩨)' -> (ru, reading)"""
    m = COMBINED_RE.match(clean(cell))
    if not m:
        return clean(cell), ""
    return m.group(1).strip(), m.group(2).strip()


def parse(path, mode):
    wb = openpyxl.load_workbook(path, read_only=True)
    ws = wb.worksheets[0]
    rows = []
    for i, row in enumerate(ws.iter_rows(values_only=True)):
        if i == 0:
            continue  # header
        if row is None or row[0] is None:
            continue
        try:
            no = int(row[0])
        except (TypeError, ValueError):
            continue
        if mode == "combined_bcd":
            ko = clean(row[1]); ru, rd = split_combined(row[2]); note = norm_note(row[3] if len(row) > 3 else None)
        elif mode == "combined_bc":
            ko = clean(row[1]); ru, rd = split_combined(row[2]); note = None
        elif mode == "split_bdef":
            ko = clean(row[1]); ru = clean(row[3]); rd = clean(row[4]); note = norm_note(row[5] if len(row) > 5 else None)
        elif mode == "split_bcde":
            ko = clean(row[1]); ru = clean(row[2]); rd = clean(row[3]); note = norm_note(row[4] if len(row) > 4 else None)
        elif mode == "split_ru_first":
            ru = clean(row[1]); rd = clean(row[2]); ko = clean(row[3]); note = norm_note(row[4] if len(row) > 4 else None)
        else:
            raise ValueError(mode)
        if not ru:
            continue
        rows.append((no, ru, rd, ko, note))
    wb.close()
    return rows


def dq(s):
    """Dart single-quoted string escape"""
    return s.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$")


pdf_notes = {}
if os.path.exists(PDF_NOTES):
    pdf_notes = {int(k): v for k, v in json.load(open(PDF_NOTES, encoding="utf-8")).items()}

all_rows = []
problems = []
for fname, mode, (lo, hi) in SOURCES:
    rows = parse(os.path.join(BASE, fname), mode)
    nos = [r[0] for r in rows]
    expect = set(range(lo, hi + 1))
    got = set(nos)
    if got != expect:
        problems.append(f"{fname}: missing={sorted(expect-got)[:5]} extra={sorted(got-expect)[:5]} count={len(rows)}")
    # xlsx에 설명 없으면 PDF에서 추출한 노트로 보충
    rows = [(no, ru, rd, ko, note or pdf_notes.get(no)) for no, ru, rd, ko, note in rows]
    for r in rows:
        if not r[3]:
            problems.append(f"{fname}: #{r[0]} ko empty")
        if not r[2]:
            problems.append(f"{fname}: #{r[0]} reading empty -> '{r[1][:30]}'")
    all_rows.extend(rows)

all_rows.sort(key=lambda r: r[0])

lines = []
lines.append("/// 떠먹여주는 러시아어 문장 600 — xlsx 원본에서 자동 생성 (gen_spoonfed.py).")
lines.append("/// 편집하지 말 것: 원본 수정 후 재생성.")
lines.append("library;")
lines.append("")
lines.append("/// 문장 1개 — 러시아어 · 한글 독음 · 뜻 · 주요단어.")
lines.append("class SpoonfedSentence {")
lines.append("  final int no;")
lines.append("  final String ru;")
lines.append("  final String reading;")
lines.append("  final String ko;")
lines.append("  final String? note;")
lines.append("  const SpoonfedSentence(this.no, this.ru, this.reading, this.ko, [this.note]);")
lines.append("}")
lines.append("")
lines.append("/// 코스 1개 = 문장 100개 묶음.")
lines.append("class SpoonfedCourse {")
lines.append("  final String id;")
lines.append("  final String title;")
lines.append("  final int start;")
lines.append("  final int end;")
lines.append("  final List<SpoonfedSentence> sentences;")
lines.append("  const SpoonfedCourse(this.id, this.title, this.start, this.end, this.sentences);")
lines.append("}")
lines.append("")
lines.append("const spoonfedCourses = <SpoonfedCourse>[")
for idx, (fname, mode, (lo, hi)) in enumerate(SOURCES, 1):
    lines.append(f"  SpoonfedCourse('sp{idx:02d}', '문장 {lo}~{hi}', {lo}, {hi}, [")
    for no, ru, rd, ko, note in [r for r in all_rows if lo <= r[0] <= hi]:
        note_part = f", '{dq(note)}'" if note else ""
        lines.append(f"    SpoonfedSentence({no}, '{dq(ru)}', '{dq(rd)}', '{dq(ko)}'{note_part}),")
    lines.append("  ]),")
lines.append("];")
lines.append("")

with open(OUT, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

print(f"OK: {len(all_rows)} sentences -> {OUT}")
if problems:
    print("PROBLEMS:")
    for p in problems:
        print(" -", p)
