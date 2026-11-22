import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:russian_universe/services/curriculum_service.dart';

void main() {
  test('score floors and 80% is the pass boundary', () {
    expect(scorePercent(8, 10), 80);
    expect(isPass(scorePercent(8, 10)), isTrue);
    expect(scorePercent(23, 29), 79); // 79.3 → 79
    expect(isPass(scorePercent(23, 29)), isFalse);
    expect(scorePercent(4, 5), 80);
    expect(scorePercent(0, 0), 0);
  });

  test('spaced review goes 1 → 3 → 7 days, wrong resets to 1, pass at 7 graduates', () {
    const t = '2026-11-22';
    final a = ReviewItem.fresh('x#1', t);
    expect(a.due, '2026-11-23');
    final b = a.answer(true, '2026-11-23')!;
    expect((b.due, b.step), ('2026-11-26', 1));
    final c = b.answer(true, '2026-11-26')!;
    expect((c.due, c.step), ('2026-12-03', 2));
    expect(c.answer(true, '2026-12-03'), isNull);
    final w = c.answer(false, '2026-12-03')!;
    expect((w.due, w.step), ('2026-12-04', 0));
  });

  test('exam: at least 3 per dialogue, at most 30', () {
    expect(examPerDialogue(3), 10);
    expect(examPerDialogue(5), 6);
    expect(examPerDialogue(10), 3);
  });

  test('practice questions: one per line up to 10, answer is the right choice', () {
    final lines = [for (var i = 0; i < 14; i++) QLine('d#$i', 'd', 'Приве́т, сло́во$i ко́шка$i', '뜻 $i')];
    final qs = practiceQuestions(lines, const [], Random(1));
    expect(qs.length, 10);
    for (final q in qs) {
      expect(q.choices.length, 4);
      final l = lines.firstWhere((l) => l.id == q.lineId);
      if (q.blank) {
        expect(q.prompt.contains('＿＿＿'), isTrue);
      } else {
        expect(q.choices[q.answer], l.ko);
      }
    }
  });

  test('state round-trips under curriculum_v1 shape and streak counts days', () {
    final s = CurriculumState()
      ..level = 'R1'
      ..course = const Course(id: 'c1', dialogueIds: ['a', 'b'], practiced: ['a'])
      ..review = [ReviewItem.fresh('a#1', '2026-11-22')];
    final j = json.decode(json.encode(s.toJson())) as Map<String, dynamic>;
    expect(j.keys, containsAll(['level', 'dailyGoal', 'course', 'passedDialogues', 'review', 'streak']));
    final r = CurriculumState.fromJson(j);
    expect(r.course!.practiced, ['a']);
    expect(r.newLeft('2026-11-22'), 1);
    r.touchStreak('2026-11-22');
    r.touchStreak('2026-11-23');
    expect(r.streakCount, 2);
    r.touchStreak('2026-11-25');
    expect(r.streakCount, 1);
  });
}
