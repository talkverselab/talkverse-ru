import 'package:flutter_test/flutter_test.dart';

import 'package:russian_universe/data/sentence_sentences.dart';

void main() {
  test('문장 — 코스 6개 × 100문장, 번호 연속', () {
    expect(sentenceCourses.length, 6);
    var expectedNo = 1;
    for (final c in sentenceCourses) {
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
