import 'package:flutter_test/flutter_test.dart';
import 'package:russian_universe/screens/word_quiz_screen.dart';

void main() {
  test('ruMisspellings gives sound-alike wrong forms, never the word itself', () {
    final m = ruMisspellings('молоко', {'молоко'});
    expect(m, contains('малоко'));
    expect(m, isNot(contains('молоко')));
    final h = ruMisspellings('хлеб', {'хлеб'});
    expect(h, contains('хлеп'));
    expect(ruMisspellings('дом', {'дом'}), contains('дам'));
  });
}
