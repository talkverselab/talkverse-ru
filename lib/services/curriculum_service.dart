import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/prefs.dart';
import 'dialogue_service.dart';
import 'learner_prefs.dart';

/// 토크버스 커리큘럼(전 언어 공통 기준 `~/talkverse/CURRICULUM_SPEC.md`, 2026-11-22 사용자 지시 · uk 정함).
/// 회화 레벨(R0~R5)에서 다이얼로그를 골라 코스 → 편마다 듣기·확인 문제 → 간격 반복 복습(1·3·7일)
/// → 코스 시험 80% 이상이면 통과 → 레벨 편을 다 통과하면 다음 레벨. 기기 저장, 키 `curriculum_v1`(전 언어 같게).

/// 하루 목표: 새 편 수.
const dailyGoals = {'light': 1, 'normal': 2, 'focus': 3};
const courseSizes = [3, 5, 10];
const reviewDays = [1, 3, 7];
const passPercent = 80;

/// 정답 수 / 문제 수, 소수점 버림(%).
int scorePercent(int correct, int total) => total <= 0 ? 0 : (correct * 100) ~/ total;
bool isPass(int percent) => percent >= passPercent;

String dayKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime _day(String k) => DateTime.parse(k);
String addDays(String day, int n) => dayKey(DateTime(_day(day).year, _day(day).month, _day(day).day + n));

class ReviewItem {
  final String lineId; // <편id>#<턴 번호>
  final String due; // yyyy-mm-dd
  final int step; // reviewDays 의 자리
  const ReviewItem(this.lineId, this.due, this.step);
  Map<String, dynamic> toJson() => {'lineId': lineId, 'due': due, 'step': step};
  factory ReviewItem.fromJson(Map<String, dynamic> j) => ReviewItem(j['lineId'] as String, j['due'] as String, (j['step'] as num?)?.toInt() ?? 0);

  /// 새로 넣음 = 내일.
  static ReviewItem fresh(String lineId, String today) => ReviewItem(lineId, addDays(today, reviewDays[0]), 0);

  /// 복습 답 반영. 맞히면 다음 간격(7일 칸을 맞히면 졸업 = null), 틀리면 1일로.
  ReviewItem? answer(bool correct, String today) {
    if (!correct) return ReviewItem(lineId, addDays(today, reviewDays[0]), 0);
    final next = step + 1;
    if (next >= reviewDays.length) return null;
    return ReviewItem(lineId, addDays(today, reviewDays[next]), next);
  }
}

class Course {
  final String id;
  final List<String> dialogueIds;
  final List<String> practiced;
  final List<int> examScores;
  final String? passedAt;
  const Course({required this.id, required this.dialogueIds, this.practiced = const [], this.examScores = const [], this.passedAt});
  bool get allPracticed => dialogueIds.every(practiced.contains);
  Course copyWith({List<String>? practiced, List<int>? examScores, String? passedAt}) =>
      Course(id: id, dialogueIds: dialogueIds, practiced: practiced ?? this.practiced, examScores: examScores ?? this.examScores, passedAt: passedAt ?? this.passedAt);
  Map<String, dynamic> toJson() => {'id': id, 'dialogueIds': dialogueIds, 'practiced': practiced, 'examScores': examScores, 'passedAt': passedAt};
  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: j['id'] as String,
        dialogueIds: (j['dialogueIds'] as List).cast<String>(),
        practiced: ((j['practiced'] as List?) ?? const []).cast<String>(),
        examScores: ((j['examScores'] as List?) ?? const []).map((e) => (e as num).toInt()).toList(),
        passedAt: j['passedAt'] as String?,
      );
}

class CurriculumState {
  String? level;
  String dailyGoal = 'normal';
  Course? course;
  List<String> passedDialogues = [];
  List<ReviewItem> review = [];
  int streakCount = 0;
  String? streakLastDay;
  // 오늘 한 양(형식 밖 보조 칸 — 서버 동기화 때 버려도 됨)
  String? todayDay;
  int todayNew = 0, todayReview = 0;

  Map<String, dynamic> toJson() => {
        'level': level,
        'dailyGoal': dailyGoal,
        'course': course?.toJson(),
        'passedDialogues': passedDialogues,
        'review': review.map((r) => r.toJson()).toList(),
        'streak': {'count': streakCount, 'lastDay': streakLastDay},
        'today': {'day': todayDay, 'new': todayNew, 'review': todayReview},
      };

  static CurriculumState fromJson(Map<String, dynamic> j) {
    final s = CurriculumState()
      ..level = j['level'] as String?
      ..dailyGoal = dailyGoals.containsKey(j['dailyGoal']) ? j['dailyGoal'] as String : 'normal'
      ..course = j['course'] is Map ? Course.fromJson((j['course'] as Map).cast<String, dynamic>()) : null
      ..passedDialogues = ((j['passedDialogues'] as List?) ?? const []).cast<String>().toList()
      ..review = ((j['review'] as List?) ?? const []).map((e) => ReviewItem.fromJson((e as Map).cast<String, dynamic>())).toList();
    final st = (j['streak'] as Map?) ?? const {};
    s.streakCount = (st['count'] as num?)?.toInt() ?? 0;
    s.streakLastDay = st['lastDay'] as String?;
    final t = (j['today'] as Map?) ?? const {};
    s.todayDay = t['day'] as String?;
    s.todayNew = (t['new'] as num?)?.toInt() ?? 0;
    s.todayReview = (t['review'] as num?)?.toInt() ?? 0;
    return s;
  }

  int get goalNew => dailyGoals[dailyGoal] ?? 2;
  List<ReviewItem> dueOn(String today) => review.where((r) => r.due.compareTo(today) <= 0).toList();

  /// 날이 바뀌었으면 오늘 칸을 비운다.
  void rollDay(String today) {
    if (todayDay == today) return;
    todayDay = today;
    todayNew = 0;
    todayReview = 0;
  }

  /// 오늘 남은 새 편 수(코스에 연습할 편이 없으면 0).
  int newLeft(String today) {
    final c = course;
    final open = c == null || c.passedAt != null ? 0 : c.dialogueIds.where((id) => !c.practiced.contains(id)).length;
    final want = todayDay == today ? max(0, goalNew - todayNew) : goalNew;
    return min(want, open);
  }

  bool doneToday(String today) => dueOn(today).isEmpty && newLeft(today) == 0 && (todayDay == today && (todayNew > 0 || todayReview > 0));

  /// 오늘 분량을 처음 끝냈을 때 연속 일수.
  void touchStreak(String today) {
    if (streakLastDay == today) return;
    streakCount = streakLastDay == addDays(today, -1) ? streakCount + 1 : 1;
    streakLastDay = today;
  }
}

/// 문제 한 개(4지선다). 뜻 고르기(러시아어 → 한국어) 또는 빈칸 낱말 고르기.
class CQuestion {
  final String lineId;
  final String dialogueId;
  final String prompt; // 위에 크게
  final String? hint; // 아래 작게(한국어 뜻 등)
  final List<String> choices;
  final int answer;
  final bool blank;
  const CQuestion({required this.lineId, required this.dialogueId, required this.prompt, this.hint, required this.choices, required this.answer, this.blank = false});
}

/// 문제를 만들 줄(러시아어·한국어만).
class QLine {
  final String id, dialogueId, tl, ko;
  const QLine(this.id, this.dialogueId, this.tl, this.ko);
}

final _word = RegExp(r'[А-Яа-яЁё́-]+');
String _plain(String s) => s.replaceAll('́', '').toLowerCase();

List<QLine> linesOf(Dialogue d) {
  final name = LearnerPrefs.name.value;
  return [
    for (final t in d.turns)
      if (t.tl.trim().isNotEmpty && t.ko.trim().isNotEmpty)
        QLine('${d.id}#${t.num}', d.id, t.tl.replaceAll('{name}', name.isEmpty ? 'Ми́ша' : name).replaceAll(RegExp(r'\{[a-z_]+\}'), '').trim(),
            t.ko.replaceAll('{name}', name.isEmpty ? '나' : name).replaceAll(RegExp(r'\{[a-z_]+\}'), '').trim()),
  ];
}

/// 한 줄로 문제 하나. `pool` = 오답 후보(다른 줄). 짝수 번째는 뜻 고르기, 홀수 번째는 빈칸 낱말(낱말이 모자라면 뜻 고르기).
CQuestion? questionFor(QLine l, List<QLine> pool, Random r, {bool preferBlank = false}) {
  final others = pool.where((o) => o.id != l.id).toList()..shuffle(r);
  if (preferBlank) {
    final words = _word.allMatches(l.tl).map((m) => m.group(0)!).where((w) => _plain(w).replaceAll('-', '').length >= 3).toList();
    if (words.isNotEmpty) {
      final w = words[r.nextInt(words.length)];
      final seen = {_plain(w)};
      final wrong = <String>[];
      for (final o in others) {
        for (final m in _word.allMatches(o.tl)) {
          final x = m.group(0)!;
          if (_plain(x).replaceAll('-', '').length >= 3 && seen.add(_plain(x))) wrong.add(x);
        }
      }
      wrong.shuffle(r);
      if (wrong.length >= 3) {
        final ch = [w, ...wrong.take(3)]..shuffle(r);
        return CQuestion(lineId: l.id, dialogueId: l.dialogueId, prompt: l.tl.replaceFirst(w, '＿＿＿'), hint: l.ko, choices: ch, answer: ch.indexOf(w), blank: true);
      }
    }
  }
  final seen = {l.ko};
  final wrong = [for (final o in others) if (seen.add(o.ko)) o.ko];
  if (wrong.length < 3) return null;
  final ch = [l.ko, ...wrong.take(3)]..shuffle(r);
  return CQuestion(lineId: l.id, dialogueId: l.dialogueId, prompt: l.tl, choices: ch, answer: ch.indexOf(l.ko));
}

/// 편 하나의 확인 문제: 줄 수만큼, 최대 [max].
List<CQuestion> practiceQuestions(List<QLine> lines, List<QLine> extraPool, Random r, {int max = 10}) {
  final pool = [...lines, ...extraPool];
  final pick = [...lines]..shuffle(r);
  final out = <CQuestion>[];
  for (final l in pick) {
    if (out.length >= max) break;
    final q = questionFor(l, pool, r, preferBlank: out.length.isOdd);
    if (q != null) out.add(q);
  }
  return out;
}

/// 코스 시험: 편당 최소 3문제, 합 최대 30문제.
int examPerDialogue(int dialogues) => dialogues <= 0 ? 0 : max(3, 30 ~/ dialogues);

List<CQuestion> examQuestions(Map<String, List<QLine>> byDialogue, Random r) {
  final all = byDialogue.values.expand((e) => e).toList();
  final per = examPerDialogue(byDialogue.length);
  final out = <CQuestion>[];
  for (final ls in byDialogue.values) {
    out.addAll(practiceQuestions(ls, all, r, max: per));
  }
  out.shuffle(r);
  return out.take(30).toList();
}

/// 추천으로 채우기: 아직 통과·선택 안 한 편에서 주제가 겹치지 않게 돌아가며.
List<String> recommend(List<Dialogue> levelDialogues, Set<String> exclude, int n) {
  final byIsland = <String, List<Dialogue>>{};
  for (final d in levelDialogues) {
    if (!exclude.contains(d.id)) (byIsland[d.island] ??= []).add(d);
  }
  final out = <String>[];
  while (out.length < n && byIsland.values.any((l) => l.isNotEmpty)) {
    for (final l in byIsland.values) {
      if (l.isNotEmpty && out.length < n) out.add(l.removeAt(0).id);
    }
  }
  return out;
}

class CurriculumService {
  CurriculumService._();
  static final CurriculumService instance = CurriculumService._();
  static const key = 'curriculum_v1';

  CurriculumState state = CurriculumState();
  bool _loaded = false;
  final ValueNotifier<int> revision = ValueNotifier(0);
  String Function() today = () => dayKey(DateTime.now());

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await DialogueService.instance.ensureLoaded();
    final raw = (await Prefs.getInstance()).getString(key);
    if (raw != null) {
      try {
        state = CurriculumState.fromJson(json.decode(raw) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('curriculum: 저장 읽기 실패 $e');
      }
    }
    state.rollDay(today());
    _loaded = true;
  }

  Future<void> save() async {
    await (await Prefs.getInstance()).setString(key, json.encode(state.toJson()));
    revision.value++;
  }

  List<String> get levels => DialogueService.instance.regions;
  List<Dialogue> dialoguesOf(String level) => DialogueService.instance.list(region: level);

  Future<void> setLevel(String level) async {
    state.level = level;
    await save();
  }

  Future<void> setGoal(String goal) async {
    state.dailyGoal = goal;
    await save();
  }

  Future<void> startCourse(List<String> ids) async {
    state.course = Course(id: 'c${DateTime.now().millisecondsSinceEpoch}', dialogueIds: ids);
    await save();
  }

  /// 편 연습 끝: 연습한 편의 줄 전부 복습 대기열로(이미 있으면 틀린 줄만 1일로 되돌림).
  Future<void> finishPractice(String dialogueId, Iterable<String> lineIds, Set<String> wrong) async {
    final t = today();
    state.rollDay(t);
    final c = state.course;
    if (c != null && !c.practiced.contains(dialogueId)) {
      state.course = c.copyWith(practiced: [...c.practiced, dialogueId]);
      state.todayNew++;
    }
    final have = {for (final r in state.review) r.lineId: r};
    for (final id in lineIds) {
      if (!have.containsKey(id) || wrong.contains(id)) have[id] = ReviewItem.fresh(id, t);
    }
    state.review = have.values.toList();
    _checkDone(t);
    await save();
  }

  Future<void> answerReview(String lineId, bool correct) async {
    final t = today();
    state.rollDay(t);
    final i = state.review.indexWhere((r) => r.lineId == lineId);
    if (i >= 0) {
      final n = state.review[i].answer(correct, t);
      if (n == null) {
        state.review.removeAt(i);
      } else {
        state.review[i] = n;
      }
    }
    state.todayReview++;
    _checkDone(t);
    await save();
  }

  /// 시험 결과 기록. 통과면 코스 완료 + 편 통과, 아니면 틀린 편을 다시 연습하게 연습 표시를 지운다.
  Future<bool> finishExam(int correct, int total, Set<String> wrongDialogues) async {
    final c = state.course;
    if (c == null) return false;
    final p = scorePercent(correct, total);
    if (isPass(p)) {
      state.course = c.copyWith(examScores: [...c.examScores, p], passedAt: today());
      state.passedDialogues = {...state.passedDialogues, ...c.dialogueIds}.toList();
    } else {
      state.course = c.copyWith(examScores: [...c.examScores, p], practiced: c.practiced.where((id) => !wrongDialogues.contains(id)).toList());
    }
    await save();
    return isPass(p);
  }

  /// 레벨의 편을 다 통과했으면 다음 레벨(있으면)로.
  String? nextLevelIfComplete() {
    final lv = state.level;
    if (lv == null) return null;
    final ds = dialoguesOf(lv);
    if (ds.isEmpty || !ds.every((d) => state.passedDialogues.contains(d.id))) return null;
    final ls = levels;
    final i = ls.indexOf(lv);
    return i >= 0 && i + 1 < ls.length ? ls[i + 1] : null;
  }

  void _checkDone(String t) {
    if (state.doneToday(t)) state.touchStreak(t);
  }

  QLine? lineById(String lineId) {
    final d = DialogueService.instance.byId(lineId.split('#').first);
    if (d == null) return null;
    return linesOf(d).where((l) => l.id == lineId).firstOrNull;
  }
}
