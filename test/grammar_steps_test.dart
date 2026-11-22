import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:russian_universe/screens/grammar_lesson_screen.dart';
import 'package:russian_universe/services/script_sync.dart';

String sha(String s) => sha1.convert(utf8.encode(s)).toString().substring(0, 12);

/// 문법 스텝은 데이터 목록 그대로: 서버 것이 있으면 서버 것, 서버에서 빠지면 숨김·더해지면 보임, 못 받으면 앱 안 목록, 내용 없는 스텝은 숨김(사용자 지시 2026-11-23).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  final orig = ScriptSync.instance;
  setUp(() => dir = Directory.systemTemp.createTempSync('grammar_steps'));
  tearDown(() {
    ScriptSync.instance = orig;
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  String lesson(int n, String title, {int patterns = 1}) => json.encode({
        'lesson': n,
        'title': title,
        'patterns': [
          for (var i = 0; i < patterns; i++) {'id': 'p$i', 'label': 'x', 'examples': []}
        ],
      });

  test('서버를 못 받으면 앱 안 목록(스텝 1)', () async {
    final s0 = ScriptSync.forTest(dir: dir, fetch: (_) async => null, baseline: {'rev': 1, 'files': {'grammar/lesson1.json': 'bundle'}});
    ScriptSync.instance = s0;
    expect(await s0.refresh(), isFalse);
    final l = await GrammarLesson.loadAll();
    expect(l.map((e) => e.number), [1]);
  });

  ScriptSync server(Directory dir, Map<String, String> files) => ScriptSync.forTest(
        dir: dir,
        baseline: {'rev': 1, 'files': {'grammar/lesson1.json': 'bundle'}},
        fetch: (url) async {
          if (url.endsWith('/index.json')) return json.encode({'rev': 2, 'files': files.map((k, v) => MapEntry(k, sha(v)))});
          for (final e in files.entries) {
            if (url.contains(e.key)) return e.value;
          }
          return null;
        },
      );

  test('서버 목록에서 스텝 1 이 빠지면 안 보이고, 스텝 12 가 더해지면 보임(15 넘어도 그대로)', () async {
    final s = server(dir, {'grammar/lesson12.json': lesson(12, '스텝 12'), 'grammar/lesson16.json': lesson(16, '스텝 16')});
    ScriptSync.instance = s;
    expect(await s.refresh(), isTrue);
    final l = await GrammarLesson.loadAll();
    expect(l.map((e) => e.number), [12, 16]);
  });

  test('서버 원고가 오면 스텝 1 을 덮어쓰고 새 스텝 2 가 나타나며, 패턴 없는 스텝 4 는 숨김', () async {
    final l1 = lesson(1, '서버판 1'), l2 = lesson(2, '새 스텝 2'), l4 = lesson(4, '빈 스텝', patterns: 0);
    final files = {'grammar/lesson1.json': l1, 'grammar/lesson2.json': l2, 'grammar/lesson4.json': l4};
    final s = ScriptSync.forTest(
      dir: dir,
      baseline: {'rev': 1, 'files': {'grammar/lesson1.json': 'bundle'}},
      fetch: (url) async {
        if (url.endsWith('/index.json')) return json.encode({'rev': 2, 'files': files.map((k, v) => MapEntry(k, sha(v)))});
        for (final e in files.entries) {
          if (url.contains(e.key)) return e.value;
        }
        return null;
      },
    );
    ScriptSync.instance = s;
    expect(await s.refresh(), isTrue);
    final l = await GrammarLesson.loadAll();
    expect(l.map((e) => (e.number, e.title)), [(1, '서버판 1'), (2, '새 스텝 2')]);
  });
}
