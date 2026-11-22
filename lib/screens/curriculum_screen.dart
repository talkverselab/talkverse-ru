import 'dart:math';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/theme.dart';
import '../services/curriculum_service.dart';
import '../services/dialogue_audio.dart';
import '../services/dialogue_service.dart';
import '../widgets/episode_play_pane.dart';
import '../widgets/spanish_decor.dart';

/// 토크버스 커리큘럼 — 레벨 고르기 → 코스(고른 다이얼로그) → 편 연습·복습 → 코스 시험(80%) (`CURRICULUM_SPEC.md`).
class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});
  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  final svc = CurriculumService.instance;
  bool _loading = true;
  bool _pickLevel = false;
  String? _notice;

  CurriculumState get s => svc.state;

  @override
  void initState() {
    super.initState();
    svc.ensureLoaded().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.calDeep,
      appBar: AppBar(title: Text(tr('토크버스 커리큘럼'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (s.level == null || _pickLevel)
              ? _levelPicker()
              : _course(),
    );
  }

  Widget _levelPicker() {
    final levels = svc.levels;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(tr('회화 레벨을 고르세요'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.tinta)),
        const SizedBox(height: 4),
        Text(tr('처음이면 가장 낮은 레벨부터 권해요'), style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
        const SizedBox(height: 12),
        for (final (i, lv) in levels.indexed)
          Card(
            child: ListTile(
              leading: TileBadge(text: lv, size: 36),
              title: Text('${DialogueService.levelKo[lv] ?? lv} · ${svc.dialoguesOf(lv).length}${tr('편')}', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                [
                  if (i == 0 && s.level == null) tr('추천'),
                  if (s.level == lv) tr('지금 레벨'),
                  '${tr('통과')} ${svc.dialoguesOf(lv).where((d) => s.passedDialogues.contains(d.id)).length}',
                ].join(' · '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await svc.setLevel(lv);
                setState(() => _pickLevel = false);
              },
            ),
          ),
      ],
    );
  }

  Widget _course() {
    final today = svc.today();
    s.rollDay(today);
    final due = s.dueOn(today);
    final newLeft = s.newLeft(today);
    final doneN = s.todayNew + s.todayReview;
    final total = doneN + due.length + newLeft;
    final c = s.course;
    final active = c != null && c.passedAt == null;
    final ds = {for (final d in svc.dialoguesOf(s.level!)) d.id: d};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          TileBadge(text: s.level!, size: 32),
          const SizedBox(width: 8),
          Expanded(child: Text(DialogueService.levelKo[s.level] ?? s.level!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.tinta))),
          TextButton(onPressed: () => setState(() => _pickLevel = true), child: Text(tr('레벨 바꾸기'))),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: [
          for (final (g, label) in [('light', tr('가볍게')), ('normal', tr('보통')), ('focus', tr('집중'))])
            ChoiceChip(
              label: Text('$label · ${tr('새 편')} ${dailyGoals[g]}'),
              selected: s.dailyGoal == g,
              onSelected: (_) async {
                await svc.setGoal(g);
                setState(() {});
              },
            ),
        ]),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                s.doneToday(today) ? '${tr('오늘 분량 끝')} 🎉 · ${tr('연속')} ${s.streakCount}${tr('일')}' : '${tr('오늘')}: ${tr('복습')} ${due.length} · ${tr('새 편')} $newLeft',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.tinta),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: total == 0 ? 0 : doneN / total, minHeight: 6, color: AppColors.matcha, backgroundColor: AppColors.calDeep),
              if (due.isNotEmpty) ...[
                const SizedBox(height: 10),
                FilledButton.icon(onPressed: () => _review(due), icon: const Icon(Icons.replay), label: Text('${tr('복습 시작')} (${min(due.length, 20)})')),
              ],
            ]),
          ),
        ),
        if (_notice != null)
          Card(color: const Color(0xFFE8F5EE), child: Padding(padding: const EdgeInsets.all(12), child: Text(_notice!, style: const TextStyle(color: AppColors.matcha, fontWeight: FontWeight.w700)))),
        const SizedBox(height: 8),
        if (!active) ...[
          if (c?.passedAt != null) Text('${tr('지난 코스 통과')} · ${c!.examScores.last}%', style: const TextStyle(color: AppColors.matcha, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          FilledButton(onPressed: () => _pick(), child: Text(c == null ? tr('코스 만들기') : tr('다음 코스 고르기'))),
        ] else ...[
          Text('${tr('지금 코스')} · ${c.practiced.length}/${c.dialogueIds.length} ${tr('연습')}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.tinta)),
          const SizedBox(height: 6),
          for (final id in c.dialogueIds)
            if (ds[id] != null)
              Card(
                child: ListTile(
                  leading: Text(ds[id]!.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(ds[id]!.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(DialogueService.islandKo[ds[id]!.island] ?? ds[id]!.island),
                  trailing: c.practiced.contains(id) ? const Icon(Icons.check_circle, color: AppColors.matcha) : const Icon(Icons.chevron_right),
                  onTap: () => _practice(ds[id]!),
                ),
              ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: c.allPracticed ? () => _exam(c) : null,
            icon: const Icon(Icons.flag),
            label: Text(c.allPracticed ? tr('코스 시험 보기') : tr('모든 편을 연습하면 코스 시험')),
          ),
          if (c.examScores.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('${tr('지난 시험')}: ${c.examScores.map((e) => '$e%').join(' · ')} (${tr('80% 이상 통과')})', style: const TextStyle(fontSize: 12, color: AppColors.tintaLight))),
          const SizedBox(height: 4),
          TextButton(onPressed: () => _pick(), child: Text(tr('새 코스 만들기'))),
        ],
      ],
    );
  }

  Future<void> _pick() async {
    final ok = await openPane<bool>(context, (_) => _PickScreen(level: s.level!));
    if (ok == true && mounted) setState(() => _notice = null);
  }

  Future<void> _practice(Dialogue d) async {
    final lines = linesOf(d);
    final pool = svc.dialoguesOf(s.level!).where((x) => x.id != d.id).expand(linesOf).toList();
    final go = await openFull<bool>(context, (_) => _ListenScreen(dialogue: d));
    if (go != true || !mounted) return;
    final qs = practiceQuestions(lines, pool, Random());
    final r = await openFull<_QuizResult>(context, (_) => _QuizScreen(title: d.title, questions: qs));
    if (r == null) return;
    await svc.finishPractice(d.id, lines.map((l) => l.id), r.wrongLines);
    if (mounted) setState(() => _notice = '${d.title} · ${r.correct}/${r.total}');
  }

  Future<void> _review(List<ReviewItem> due) async {
    final items = [...due]..shuffle();
    final pick = items.take(20).toList();
    final r = Random();
    final qs = <CQuestion>[];
    for (final it in pick) {
      final l = svc.lineById(it.lineId);
      if (l == null) {
        await svc.answerReview(it.lineId, true); // 원고에서 사라진 줄 — 졸업 처리
        continue;
      }
      final d = DialogueService.instance.byId(l.dialogueId)!;
      final pool = [...linesOf(d), ...svc.dialoguesOf(d.region).take(6).expand(linesOf)];
      final q = questionFor(l, pool, r, preferBlank: qs.length.isOdd);
      if (q != null) qs.add(q);
    }
    if (!mounted || qs.isEmpty) return setState(() {});
    final res = await openFull<_QuizResult>(context, (_) => _QuizScreen(title: tr('복습'), questions: qs, onAnswer: (q, ok) => svc.answerReview(q.lineId, ok)));
    if (mounted) setState(() => _notice = res == null ? null : '${tr('복습')} ${res.correct}/${res.total}');
  }

  Future<void> _exam(Course c) async {
    final by = <String, List<QLine>>{};
    for (final id in c.dialogueIds) {
      final d = DialogueService.instance.byId(id);
      if (d != null) by[id] = linesOf(d);
    }
    final qs = examQuestions(by, Random());
    final r = await openFull<_QuizResult>(context, (_) => _QuizScreen(title: tr('코스 시험'), questions: qs, exam: true));
    if (r == null) return;
    final passed = await svc.finishExam(r.correct, r.total, r.wrongDialogues);
    final p = scorePercent(r.correct, r.total);
    String msg;
    if (passed) {
      final next = svc.nextLevelIfComplete();
      msg = '${tr('코스 통과')} $p% 🎉';
      if (next != null) {
        await svc.setLevel(next);
        msg += ' · ${tr('레벨을 모두 통과해 다음 레벨이 열렸어요')}: $next';
      }
    } else {
      msg = '$p% · ${tr('80% 미만 — 틀린 편을 다시 연습한 뒤 다시 시험')}';
    }
    if (mounted) setState(() => _notice = msg);
  }
}

/// 코스 고르기: 3·5·10편, 추천으로 채우기, 진행 중 코스가 있으면 화면 안에서 버릴지 확인.
class _PickScreen extends StatefulWidget {
  final String level;
  const _PickScreen({required this.level});
  @override
  State<_PickScreen> createState() => _PickScreenState();
}

class _PickScreenState extends State<_PickScreen> {
  final svc = CurriculumService.instance;
  int _size = 5;
  final List<String> _sel = [];
  bool _confirm = false;

  @override
  void initState() {
    super.initState();
    _fill();
  }

  void _fill() {
    final passed = svc.state.passedDialogues.toSet();
    _sel
      ..clear()
      ..addAll(recommend(svc.dialoguesOf(widget.level), passed, _size));
    if (_sel.length < _size) _sel.addAll(recommend(svc.dialoguesOf(widget.level), _sel.toSet(), _size - _sel.length));
  }

  @override
  Widget build(BuildContext context) {
    final ds = svc.dialoguesOf(widget.level);
    final passed = svc.state.passedDialogues.toSet();
    final c = svc.state.course;
    final inProgress = c != null && c.passedAt == null;
    return Scaffold(
      backgroundColor: AppColors.calDeep,
      appBar: AppBar(title: Text(tr('코스 고르기'))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            for (final n in courseSizes)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(label: Text('$n${tr('편')}'), selected: _size == n, onSelected: (_) => setState(() {
                  _size = n;
                  if (_sel.length > n) _sel.removeRange(n, _sel.length);
                })),
              ),
            const Spacer(),
            TextButton.icon(onPressed: () => setState(_fill), icon: const Icon(Icons.auto_awesome, size: 18), label: Text(tr('추천으로 채우기'))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(alignment: Alignment.centerLeft, child: Text('${_sel.length}/$_size ${tr('편 고름')}', style: const TextStyle(fontSize: 12, color: AppColors.tintaLight))),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            children: [
              for (final d in ds)
                CheckboxListTile(
                  value: _sel.contains(d.id),
                  onChanged: (v) => setState(() {
                    if (v == true && _sel.length < _size) _sel.add(d.id);
                    if (v != true) _sel.remove(d.id);
                  }),
                  secondary: Text(d.emoji, style: const TextStyle(fontSize: 22)),
                  title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text([DialogueService.islandKo[d.island] ?? d.island, if (passed.contains(d.id)) '✓ ${tr('통과함')}'].join(' · ')),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _confirm
                ? Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(tr('지금 코스를 버리고 새 코스를 시작할까요?'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: OutlinedButton(onPressed: () => setState(() => _confirm = false), child: Text(tr('취소')))),
                      const SizedBox(width: 8),
                      Expanded(child: FilledButton(onPressed: _start, child: Text(tr('새 코스 시작')))),
                    ]),
                  ])
                : SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _sel.isEmpty ? null : () => inProgress ? setState(() => _confirm = true) : _start(),
                      child: Text(tr('코스 시작')),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }

  Future<void> _start() async {
    await svc.startCourse([..._sel]);
    if (mounted) Navigator.of(context).pop(true);
  }
}

/// 연습 1·2단계: 회화 듣기·읽기(녹음 → 없으면 TTS), 줄을 눌러 반복 듣기. 아래 단추로 확인 문제.
class _ListenScreen extends StatelessWidget {
  final Dialogue dialogue;
  const _ListenScreen({required this.dialogue});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.washi,
        appBar: AppBar(title: Text('${dialogue.emoji} ${dialogue.title}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
        body: EpisodePlayPane(dialogue: dialogue, autoPlay: false),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: FilledButton.icon(
              onPressed: () {
                DialogueAudio.instance.stop();
                Navigator.of(context).pop(true);
              },
              icon: const Icon(Icons.quiz),
              label: Text(tr('확인 문제 풀기')),
            ),
          ),
        ),
      );
}

class _QuizResult {
  final int correct, total;
  final Set<String> wrongLines, wrongDialogues;
  const _QuizResult(this.correct, this.total, this.wrongLines, this.wrongDialogues);
}

/// 4지선다 문제 풀이(뜻 고르기 · 빈칸 낱말). 끝나면 결과를 돌려준다.
class _QuizScreen extends StatefulWidget {
  final String title;
  final List<CQuestion> questions;
  final bool exam;
  final Future<void> Function(CQuestion q, bool correct)? onAnswer;
  const _QuizScreen({required this.title, required this.questions, this.exam = false, this.onAnswer});
  @override
  State<_QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<_QuizScreen> {
  int _i = 0, _correct = 0;
  int? _picked;
  final Set<String> _wrongLines = {}, _wrongDialogues = {};

  @override
  Widget build(BuildContext context) {
    final qs = widget.questions;
    if (qs.isEmpty) {
      return Scaffold(appBar: AppBar(title: Text(widget.title)), body: Center(child: FilledButton(onPressed: () => Navigator.pop(context, const _QuizResult(0, 0, {}, {})), child: Text(tr('문제가 없어요 · 돌아가기')))));
    }
    final done = _i >= qs.length;
    return Scaffold(
      backgroundColor: AppColors.calDeep,
      appBar: AppBar(title: Text('${widget.title} · ${min(_i + 1, qs.length)}/${qs.length}')),
      body: done ? _result() : _question(qs[_i]),
    );
  }

  Widget _result() {
    final p = scorePercent(_correct, widget.questions.length);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_correct / ${widget.questions.length}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.tinta)),
          const SizedBox(height: 6),
          Text('$p%${widget.exam ? (isPass(p) ? ' · ${tr('통과')}' : ' · ${tr('80% 미만')}') : ''}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: !widget.exam || isPass(p) ? AppColors.matcha : AppColors.fem)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context, _QuizResult(_correct, widget.questions.length, _wrongLines, _wrongDialogues)),
            child: Text(tr('확인')),
          ),
        ]),
      ),
    );
  }

  Widget _question(CQuestion q) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(q.blank ? tr('빈칸에 맞는 낱말') : tr('뜻을 고르세요'), style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(q.prompt, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.tinta)),
              if (q.hint != null) ...[const SizedBox(height: 6), Text(q.hint!, style: const TextStyle(color: AppColors.tintaLight))],
            ]),
          ),
        ),
        const SizedBox(height: 10),
        for (final (k, ch) in q.choices.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(14),
                backgroundColor: _picked == null ? null : (k == q.answer ? const Color(0xFFE8F5EE) : (k == _picked ? const Color(0xFFFDECEC) : null)),
              ),
              onPressed: _picked != null ? null : () => _answer(q, k),
              child: Text(ch, style: const TextStyle(fontSize: 15, color: AppColors.tinta)),
            ),
          ),
        if (_picked != null)
          FilledButton(onPressed: () => setState(() { _i++; _picked = null; }), child: Text(_i + 1 >= widget.questions.length ? tr('결과 보기') : tr('다음'))),
      ],
    );
  }

  Future<void> _answer(CQuestion q, int k) async {
    final ok = k == q.answer;
    setState(() {
      _picked = k;
      if (ok) {
        _correct++;
      } else {
        _wrongLines.add(q.lineId);
        _wrongDialogues.add(q.dialogueId);
      }
    });
    await widget.onAnswer?.call(q, ok);
  }
}

/// 홈 맨 위 카드: 「오늘: 복습 N · 새 편 N」 + 진행 막대 + 연속 일수.
class CurriculumHomeCard extends StatefulWidget {
  const CurriculumHomeCard({super.key});
  @override
  State<CurriculumHomeCard> createState() => _CurriculumHomeCardState();
}

class _CurriculumHomeCardState extends State<CurriculumHomeCard> {
  final svc = CurriculumService.instance;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    svc.revision.addListener(_on);
    svc.ensureLoaded().then((_) => _on());
  }

  void _on() {
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    svc.revision.removeListener(_on);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = svc.state;
    final today = svc.today();
    String line = tr('레벨을 고르고 다이얼로그로 코스를 만들어요');
    double prog = 0;
    if (_ready && s.level != null) {
      s.rollDay(today);
      final due = s.dueOn(today).length, nl = s.newLeft(today), d = s.todayNew + s.todayReview;
      final total = d + due + nl;
      prog = total == 0 ? 0 : d / total;
      line = s.doneToday(today) ? '${tr('오늘 분량 끝')} · ${tr('연속')} ${s.streakCount}${tr('일')}' : '${tr('오늘')}: ${tr('복습')} $due · ${tr('새 편')} $nl';
      if (s.course == null || s.course!.passedAt != null) line = '${s.level} · ${tr('새 코스를 만들어요')}';
    }
    return InkWell(
      onTap: () => openPane(context, (_) => const CurriculumScreen()),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.cal, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gualda)),
        child: Row(children: [
          const TileBadge(text: 'TV', size: 44, color: AppColors.beni),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('토크버스 커리큘럼'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.tinta)),
              const SizedBox(height: 2),
              Text(line, style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: prog, minHeight: 5, color: AppColors.matcha, backgroundColor: AppColors.calDeep),
            ]),
          ),
          const Icon(Icons.chevron_right),
        ]),
      ),
    );
  }
}
