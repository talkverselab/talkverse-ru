#!/usr/bin/env python3
"""전편 회화 음성 생성 진행기(M6 에서 길게 돈다). 묶음마다: 작업 파일 → PC 생성 → 받아 오기 → 받아쓰기 검사·재생성(두 번까지) → mp4·R2·D1.
  <venv>/bin/python tools/tts/run_all.py <작업폴더> [묶음 크기=12] [편id...]   끝난 편은 <작업폴더>/done.txt 에 적히고 다시 돌리면 건너뛴다.
  <venv>/bin/python tools/tts/run_all.py <작업폴더> --refs [편id...]            참고 음성만 만든다.
작업폴더 = ~/tts_work/ru.
PC 쪽은 작업 스케줄러 'TTS job 2060'(run_job.sh)이 돈다 — 참고 음성 2060, 문장 3090. 중간에 멈춰도 있는 파일은 건너뛰고 이어서 한다."""
import glob, json, os, subprocess, sys, time
import ttslib as L
PC = 'Administrator@100.127.143.37'; HERE = os.path.dirname(os.path.abspath(__file__))
G = []; work = sys.argv[1]; REFS = sys.argv[2:3] == ['--refs']
A = sys.argv[3:] if REFS else sys.argv[2:]
N = int(A.pop(0)) if A and A[0].isdigit() else 12
os.makedirs(f'{work}/job', exist_ok=True); os.makedirs(f'{work}/wav', exist_ok=True)
log = lambda *a: print(time.strftime('%H:%M:%S'), *a, flush=True)


def sh(*a, check=True, **k):
    return subprocess.run(a, check=check, capture_output=True, text=True, **k)


def pc_run(name='moss_jobs.json'):
    """작업 스케줄러를 돌리고 끝날 때까지 기다린다. name = 이번에 보낼 작업 파일(다른 쪽 작업 파일은 PC 에서 지운다)."""
    while 'Ready' not in sh('ssh', PC, "(Get-ScheduledTask -TaskName 'TTS job 2060').State", check=False).stdout:
        time.sleep(30)                     # 앞선 작업(참고 음성 등)이 끝날 때까지
    other = 'vox_jobs.json' if name == 'moss_jobs.json' else 'moss_jobs.json'
    sh('scp', '-q', f'{work}/job/{name}', f'{PC}:D:/tts_test/job/')
    sh('ssh', PC, f"Remove-Item D:\\tts_test\\job\\{other} -ErrorAction SilentlyContinue; Start-ScheduledTask -TaskName 'TTS job 2060'")
    time.sleep(20)
    while True:
        r = sh('ssh', PC, "(Get-ScheduledTask -TaskName 'TTS job 2060').State", check=False).stdout
        if 'Ready' in r:
            return
        time.sleep(30)


def fetch(path):
    os.makedirs(os.path.dirname(f'{work}/wav/{path}'), exist_ok=True)
    sh('scp', '-q', '-r', f'{PC}:D:/tts_test/job/out/{L.LANG}/{path}', os.path.dirname(f'{work}/wav/{path}') + '/', check=False)


if REFS:
    if not os.path.exists(f'{work}/job/vox_jobs.json'):
        sh(sys.executable, f'{HERE}/make_jobs.py', *G, f'{work}/job', '--refs', *A)
    pc_run('vox_jobs.json'); log('참고 음성 끝'); sys.exit()
sh(sys.executable, f'{HERE}/plan_from_dialogue.py')   # 회화 파일의 감정 → 계획
done = set(open(f'{work}/done.txt').read().split()) if os.path.exists(f'{work}/done.txt') else set()
ids = [e for e in (A or L.planned()) if e not in done]
log('남은 편', len(ids))
for i in range(0, len(ids), N):
    eps = ids[i:i + N]
    if os.path.exists(f'{work}/job/moss_jobs.json'):
        os.remove(f'{work}/job/moss_jobs.json')
    sh(sys.executable, f'{HERE}/make_jobs.py', *G, f'{work}/job', *eps); pc_run()
    for ep in eps:
        fetch(ep)
    for rnd in range(3):
        # whisper 가 한 파일에서 멈추는 일이 있어(일본어 7시간) 편별 하위 프로세스 + 600초 제한. 넘기면 그 편 재생성본은 버리고 넘어간다.
        tot = 0
        for ep in eps:
            try:
                r = subprocess.run([sys.executable, f'{HERE}/qa.py', *G, f'{work}/wav', ep, '--jobs', f'{work}/job/qa_{ep}.json'], capture_output=True, text=True, timeout=600)
                log(r.stdout.strip() or r.stderr.strip()[-200:])
            except subprocess.TimeoutExpired:
                log('TIMEOUT', ep)
                for f in glob.glob(f'{work}/wav/retake/{ep}/*.wav'):
                    os.remove(f)
        jobs = []
        for ep in eps:
            p = f'{work}/job/qa_{ep}.json'
            if os.path.exists(p):
                jobs += json.load(open(p)); os.remove(p)
        tot = len(jobs)
        if tot == 0:
            break
        json.dump(jobs, open(f'{work}/job/moss_jobs.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
        pc_run()
        for ep in eps:
            fetch(f'retake/{ep}')
    for ep in eps:
        r = sh(sys.executable, f'{HERE}/pack.py', *G, f'{work}/wav', ep, '--upload', check=False)
        if r.returncode:
            log('실패', ep, (r.stderr or r.stdout)[-300:]); continue
        log(r.stdout.strip()); open(f'{work}/done.txt', 'a').write(ep + '\n')
log('끝')
