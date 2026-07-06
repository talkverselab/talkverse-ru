import 'package:flutter_test/flutter_test.dart';

import 'package:russian_universe/data/spoonfed_sentences.dart';

void main() {
  test('떠먹여주는 문장 — 코스 6개 × 100문장, 번호 연속', () {
    expect(spoonfedCourses.length, 6);
    var expectedNo = 1;
    for (final c in spoonfedCourses) {
      expect(c.sentences.length, 100, reason: c.title);
      for (final s in c.sentences) {
        expect(s.no, expectedNo++);
        expect(s.ru, isNotEmpty);
        expect(s.reading, isNotEmpty);
        expect(s.ko, isNotEmpty);
      }
    }
  });
}
