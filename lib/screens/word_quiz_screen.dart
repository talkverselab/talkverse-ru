import 'dart:math';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import '../services/art_service.dart';
import '../services/tts_service.dart';

/// 절벽 단어 퀴즈 복습 (일본어앱 외국어 단어 퀴즈 꼴, 2026-11-22). Two kinds of question, each with choices 1~4.
/// - 철자: 한국어 뜻(+그림)을 보고 바르게 쓴 러시아어를 고른다. 틀린 보기는 소리로는 헷갈리는 꼴
///   (강세 없는 о↔а·е↔и, 끝소리 유성↔무성)로 만든다.
/// - 뜻: 러시아어(+그림)를 보고 뜻을 고른다.
/// 틀린 단어는 Prefs `word_quiz_wrong` 에 두고 다음 복습에 먼저 낸다.
const int kWordQuizSize = 10;
const String _kWrong = 'word_quiz_wrong';

/// 3단계 — 누적 범위(빈도 순위).
const List<(String, int)> kWordQuizStages = [
  ('1단계 · 1-251', 251),
  ('2단계 · 1-685', 685),
  ('3단계 · 1-2000', 2000),
];

class WQWord {
  final String ru, ko;
  final int rank;
  const WQWord(this.ru, this.ko, this.rank);
}

const _vowelSwap = {'о': 'а', 'а': 'о', 'е': 'и', 'и': 'е', 'я': 'е'};
const _finalSwap = {'б': 'п', 'п': 'б', 'в': 'ф', 'ф': 'в', 'г': 'к', 'к': 'г', 'д': 'т', 'т': 'д', 'з': 'с', 'с': 'з', 'ж': 'ш', 'ш': 'ж'};

/// 소리로 헷갈리는 틀린 철자들(실제 단어와 겹치는 것은 뺀다).
List<String> ruMisspellings(String w, Set<String> real) {
  final c = w.split('');
  final out = <String>{};
  for (var i = 0; i < c.length; i++) {
    final s = _vowelSwap[c[i]];
    if (s != null) out.add(([...c]..[i] = s).join());
  }
  final f = _finalSwap[c.last];
  if (f != null) out.add(([...c]..[c.length - 1] = f).join());
  // 두 군데를 함께 바꾼 꼴 — 보기가 모자랄 때
  if (out.length < 3) {
    for (final a in out.toList()) {
      final ac = a.split('');
      for (var i = 0; i < ac.length; i++) {
        final s = _vowelSwap[ac[i]];
        if (s != null && ac[i] == c[i]) out.add(([...ac]..[i] = s).join());
      }
    }
  }
  return out.where((s) => s != w && !real.contains(s)).toList();
}

class _Q {
  final WQWord w;
  final bool spelling; // true = 철자, false = 뜻
  final List<String> options;
  const _Q(this.w, this.spelling, this.options);
  String get answer => spelling ? w.ru : w.ko;
}

class WordQuizScreen extends StatefulWidget {
  final List<WQWord> words;
  final String title;
  final int? seed;
  const WordQuizScreen({super.key, required this.words, required this.title, this.seed});
  @override
  State<WordQuizScreen> createState() => _WordQuizScreenState();
}

class _WordQuizScreenState extends State<WordQuizScreen> {
  late final _rnd = Random(widget.seed);
  List<_Q>? _qs;
  int _i = 0;
  String? _picked;
  int _right = 0;
  final List<WQWord> _missed = [];

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    final p = await Prefs.getInstance();
    final wrong = (p.getStringList(_kWrong) ?? const []).toSet();
    final usable = widget.words.where((w) => w.ko.isNotEmpty && w.ru.length >= 2).toList();
    final uniq = <String, WQWord>{for (final w in usable) w.ru: w}.values.toList()..shuffle(_rnd);
    uniq.sort((a, b) => (wrong.contains(b.ru) ? 1 : 0) - (wrong.contains(a.ru) ? 1 : 0));
    final picked = uniq.take(kWordQuizSize).toList()..shuffle(_rnd);
    final real = {for (final w in widget.words) w.ru};
    final qs = <_Q>[];
    for (var k = 0; k < picked.length; k++) {
      final w = picked[k];
      final miss = (ruMisspellings(w.ru, real)..shuffle(_rnd)).take(3).toList();
      if (k.isEven && miss.length == 3 && w.ru.length >= 3) {
        qs.add(_Q(w, true, [w.ru, ...miss]..shuffle(_rnd)));
      } else {
        final others = ({for (final o in uniq) if (o.ko != w.ko) o.ko}.toList()..shuffle(_rnd)).take(3);
        qs.add(_Q(w, false, [w.ko, ...others]..shuffle(_rnd)));
      }
    }
    if (mounted) setState(() => _qs = qs);
  }

  Future<void> _record(String ru, bool ok) async {
    final p = await Prefs.getInstance();
    final s = (p.getStringList(_kWrong) ?? const []).toSet();
    ok ? s.remove(ru) : s.add(ru);
    await p.setStringList(_kWrong, s.toList());
  }

  void _again() => setState(() {
        _qs = null;
        _i = 0;
        _picked = null;
        _right = 0;
        _missed.clear();
        _build();
      });

  @override
  Widget build(BuildContext context) {
    final qs = _qs;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text('${tr('퀴즈 복습')} · ${widget.title}')),
      body: qs == null
          ? const Center(child: CircularProgressIndicator())
          : qs.isEmpty
              ? Center(child: Text(tr('단어 목록 준비 중')))
              : _i >= qs.length
                  ? _summary(qs.length)
                  : _question(qs[_i], qs.length),
    );
  }

  Widget _summary(int n) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            Text(trf('{0}문제 중 {1}개 맞힘', [n, _right]), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi)),
            if (_missed.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(tr('틀린 단어 — 다음 복습에 먼저 나와요'), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
              const SizedBox(height: 6),
              for (final w in _missed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${w.ru}  ·  ${w.ko}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                ),
            ],
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              OutlinedButton(key: const ValueKey('wq-again'), onPressed: _again, child: Text(tr('한 번 더'))),
              const SizedBox(width: 10),
              FilledButton(onPressed: () => Navigator.of(context).maybePop(), style: FilledButton.styleFrom(backgroundColor: AppColors.sumi), child: Text(tr('나가기'))),
            ]),
          ]),
        ),
      );

  Widget _question(_Q q, int n) {
    final w = q.w;
    return SingleChildScrollView(
      key: ValueKey('wq-q-$_i'),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${tr(q.spelling ? '철자' : '뜻')} · ${_i + 1} / $n', style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
        const SizedBox(height: 10),
        _Picture(word: w.ru),
        Text(
          q.spelling ? w.ko : w.ru,
          key: const ValueKey('wq-stem'),
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.sumi),
        ),
        const SizedBox(height: 8),
        Text(tr(q.spelling ? '러시아어로 바르게 쓴 것을 고르세요.' : '뜻으로 맞는 것을 고르세요.'), style: const TextStyle(fontSize: 14, color: AppColors.sumi)),
        const SizedBox(height: 14),
        for (var k = 0; k < q.options.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              key: ValueKey('wq-opt-$k'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                backgroundColor: _picked == null ? null : (q.options[k] == q.answer ? const Color(0x3336A35B) : (q.options[k] == _picked ? const Color(0x33D83A3A) : null)),
                side: BorderSide(color: _picked != null && q.options[k] == q.answer ? AppColors.matcha : AppColors.line, width: 1.4),
              ),
              onPressed: _picked != null
                  ? null
                  : () {
                      final ok = q.options[k] == q.answer;
                      TtsService.instance.speak(w.ru);
                      _record(w.ru, ok);
                      setState(() {
                        _picked = q.options[k];
                        ok ? _right++ : _missed.add(w);
                      });
                    },
              child: Row(children: [
                SizedBox(width: 26, child: Text('${k + 1}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumiLight))),
                Expanded(child: Text(q.options[k], style: TextStyle(fontSize: q.spelling ? 20 : 16, fontWeight: FontWeight.w800, color: AppColors.sumi))),
              ]),
            ),
          ),
        if (_picked != null)
          FilledButton(
            key: const ValueKey('wq-next'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.sumi, minimumSize: const Size.fromHeight(48)),
            onPressed: () => setState(() {
              _i++;
              _picked = null;
            }),
            child: Text(tr('다음 →')),
          ),
      ]),
    );
  }
}

/// 단어 그림(우리 DB). 없으면 아무것도 안 보인다.
class _Picture extends StatelessWidget {
  final String word;
  const _Picture({required this.word});
  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
        future: ArtService.instance.urlFor(word),
        builder: (context, snap) {
          final url = snap.data;
          if (url == null) return const SizedBox(height: 4);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(url, height: 150, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
              ),
            ),
          );
        },
      );
}
