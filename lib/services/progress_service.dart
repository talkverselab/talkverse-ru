import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 경량 학습 진행 트래킹 — shared_preferences 기반.
/// (zh 앱의 Drift UserProgress UX를 ru에 맞게 축소 이식)
///
/// 기록: 방문한 다이얼로그 id · 떠먹여주는 코스별 본 카드 수 · 활동 날짜 · 마지막 활동.
/// 파생: 연속 학습(streak) · 주간 활동 7칸.
class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  static const _kDialogues = 'progress_dialogues_visited';
  static const _kDays = 'progress_active_days';
  static const _kLast = 'progress_last_activity';
  static const _kSpoonPrefix = 'progress_spoonfed_'; // + courseId → int(본 카드 수)

  SharedPreferences? _prefs;

  /// UI 갱신 신호 — 기록이 바뀔 때마다 +1.
  final ValueNotifier<int> revision = ValueNotifier(0);

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  void _bump() => revision.value++;

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── 활동 날짜 ─────────────────────────────────────────────

  Future<void> touchToday() async {
    final p = _prefs;
    if (p == null) return;
    final days = (p.getStringList(_kDays) ?? <String>[]).toSet();
    final today = _dayKey(DateTime.now());
    if (days.add(today)) {
      await p.setStringList(_kDays, days.toList()..sort());
      _bump();
    }
  }

  Set<DateTime> get activeDates {
    final raw = _prefs?.getStringList(_kDays) ?? const <String>[];
    final out = <DateTime>{};
    for (final s in raw) {
      final parts = s.split('-');
      if (parts.length != 3) continue;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y == null || m == null || d == null) continue;
      out.add(DateTime(y, m, d));
    }
    return out;
  }

  /// 오늘부터 거꾸로 연속 활동일 수.
  int get streak {
    final dates = activeDates;
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    var n = 0;
    while (dates.contains(cursor)) {
      n++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return n;
  }

  /// 이번 주(월~일) 활동 여부 7칸.
  List<bool> get weekActive {
    final dates = activeDates;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(
        7, (i) => dates.contains(monday.add(Duration(days: i))));
  }

  // ── 회화 다이얼로그 ───────────────────────────────────────

  Set<String> get visitedDialogues =>
      (_prefs?.getStringList(_kDialogues) ?? const <String>[]).toSet();

  Future<void> markDialogueVisited(String id) async {
    final p = _prefs;
    if (p == null) return;
    await touchToday();
    final v = visitedDialogues;
    if (v.add(id)) {
      await p.setStringList(_kDialogues, v.toList()..sort());
    }
    await p.setString(_kLast, 'dialogue:$id');
    _bump();
  }

  // ── 떠먹여주는 문장 코스 ──────────────────────────────────

  int spoonfedSeen(String courseId) =>
      _prefs?.getInt('$_kSpoonPrefix$courseId') ?? 0;

  Future<void> recordSpoonfed(String courseId, int seen) async {
    final p = _prefs;
    if (p == null) return;
    await touchToday();
    if (seen > spoonfedSeen(courseId)) {
      await p.setInt('$_kSpoonPrefix$courseId', seen);
    }
    await p.setString(_kLast, 'spoonfed:$courseId');
    _bump();
  }

  /// 'dialogue:l2_d05' | 'spoonfed:sp01' | null.
  String? get lastActivity => _prefs?.getString(_kLast);
}
