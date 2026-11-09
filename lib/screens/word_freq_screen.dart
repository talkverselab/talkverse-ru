import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../core/embed_env.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/tts_service.dart';

/// 절벽 단어 — 빈도 1~3,000위를 절벽구간(R1~R5)별 **20어 단원**, 단어는 **네모 타일**(일본어앱 구조, 2026-11-07).
/// 「회화 단어 포함」이면 assets/data/freq/conv_words_ru.json 의 단어가 「회화」 구간으로 뒤에 붙는다.
/// 빈도표가 비어 있으면(콘텐츠 동결 중) 준비 중 안내만 보인다.
class WordFreqScreen extends StatefulWidget {
  const WordFreqScreen({super.key});

  @override
  State<WordFreqScreen> createState() => _WordFreqScreenState();
}

const int kWordCap = 2000;
const int kUnit = 20;

class _WordFreqScreenState extends State<WordFreqScreen> {
  List<WordEntry> _words = [];
  List<WordEntry> _conv = [];
  bool _loading = true;
  bool _withConv = false;
  String _filter = 'ALL';

  static Map<String, _Region> get _regions => {
        'ALL': _Region(tr('전체'), AppColors.sumi),
        'R1': const _Region('R1 · 1-156', AppColors.beni),
        'R2': const _Region('R2 · 157-251', AppColors.beniLight),
        'R3': const _Region('R3 · 252-685', AppColors.kinDeep),
        'R4': const _Region('R4 · 686-1985', AppColors.matcha),
        'R5': const _Region('R5 · 1986-3000', AppColors.muted),
        'C': _Region(tr('회화'), AppColors.ai),
      };

  static String _regionOf(int rank) => rank <= 156
      ? 'R1'
      : rank <= 251
          ? 'R2'
          : rank <= 685
              ? 'R3'
              : rank <= 1985
                  ? 'R4'
                  : 'R5';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = <WordEntry>[];
    try {
      // header: rank,word,pos,gender,ko,freq,cum_pct,region,cefr
      final raw = await rootBundle.loadString(assetPath('assets/data/freq/lang_es_top.csv'));
      final rows = const CsvToListConverter(eol: '\n').convert(raw);
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 5) continue;
        final rank = int.tryParse('${row[0]}') ?? 0;
        if (rank < 1 || rank > kWordCap) continue;
        entries.add(WordEntry(rank: rank, word: '${row[1]}', region: _regionOf(rank), ko: '${row[4]}'.trim()));
      }
    } catch (_) {}
    final conv = <WordEntry>[];
    try {
      final j = json.decode(await rootBundle.loadString(assetPath('assets/data/freq/conv_words_ru.json'))) as Map<String, dynamic>;
      var n = 0;
      for (final w in (j['words'] as List).cast<Map<String, dynamic>>()) {
        n++;
        conv.add(WordEntry(rank: n, word: w['word'] as String, region: 'C', ko: (w['ko'] as String?) ?? ''));
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _words = entries;
      _conv = conv;
      _loading = false;
    });
  }

  List<WordEntry> get _pool => _withConv ? [..._words, ..._conv] : _words;

  @override
  Widget build(BuildContext context) {
    final pool = _pool;
    final filtered = _filter == 'ALL' ? pool : pool.where((w) => w.region == _filter).toList();
    final units = <List<WordEntry>>[];
    for (var i = 0; i < filtered.length; i += kUnit) {
      units.add(filtered.sublist(i, (i + kUnit).clamp(0, filtered.length)));
    }
    final chips = _regions.entries.where((e) => e.key != 'C' || _withConv).toList();

    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('절벽 단어'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(trf('빈도 {0}위 · {1}어 단원 · 탭하면 발음', ['2,000', kUnit]),
                style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.beni))
          : Column(
              children: [
                Container(
                  color: AppColors.washiDeep,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _ModeButton(
                              label: tr('절벽구간 단어만'),
                              selected: !_withConv,
                              onTap: () => setState(() {
                                    _withConv = false;
                                    if (_filter == 'C') _filter = 'ALL';
                                  })),
                          const SizedBox(width: 8),
                          _ModeButton(label: trf('회화 단어 포함 (+{0})', [_conv.length]), selected: _withConv, onTap: () => setState(() => _withConv = true)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: chips.map((e) {
                            final selected = _filter == e.key;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _filter = e.key),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selected ? e.value.color : AppColors.washi,
                                    border: Border.all(color: e.value.color, width: selected ? 1.5 : 0.8),
                                  ),
                                  child: Text(e.value.label,
                                      style: TextStyle(color: selected ? AppColors.washi : e.value.color, fontWeight: FontWeight.w700, fontSize: 12)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: units.isEmpty
                      ? Center(child: Text(tr('단어 목록 준비 중'), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)))
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(12, 8, 12, 16 + bottomInset(context)),
                          itemCount: units.length,
                          itemBuilder: (context, i) => _UnitBlock(index: i + 1, words: units[i], regions: _regions),
                        ),
                ),
              ],
            ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.sumi : AppColors.washi,
              border: Border.all(color: selected ? AppColors.sumi : AppColors.line),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label, style: TextStyle(color: selected ? AppColors.washi : AppColors.sumi, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
      );
}

/// 한 단원 = 20어. 머리줄(단원 번호·순위 범위·구간) + 네모 타일 격자.
class _UnitBlock extends StatelessWidget {
  final int index;
  final List<WordEntry> words;
  final Map<String, _Region> regions;
  const _UnitBlock({required this.index, required this.words, required this.regions});

  @override
  Widget build(BuildContext context) {
    final first = words.first;
    final last = words.last;
    final region = regions[first.region];
    final range = first.region == 'C' ? trf('회화 {0}-{1}', [first.rank, last.rank]) : '#${first.rank}-${last.rank}';
    final cols = (MediaQuery.sizeOf(context).width / 112).floor().clamp(3, 8);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
            child: Row(
              children: [
                Text(trf('{0}단원', [index]), style: const TextStyle(color: AppColors.sumi, fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                Text(range, style: const TextStyle(color: AppColors.sumiLight, fontSize: 11)),
                const Spacer(),
                if (region != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: region.color, borderRadius: BorderRadius.circular(2)),
                    child: Text(first.region == 'C' ? tr('회화') : first.region,
                        style: const TextStyle(color: AppColors.washi, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 6, crossAxisSpacing: 6),
            itemCount: words.length,
            itemBuilder: (context, i) => _WordTile(w: words[i], color: region?.color ?? AppColors.sumi),
          ),
        ],
      ),
    );
  }
}

/// 네모 타일 — 순위 · 단어 · 뜻. 탭하면 발음.
class _WordTile extends StatelessWidget {
  final WordEntry w;
  final Color color;
  const _WordTile({required this.w, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => TtsService.instance.speak(w.word),
      child: Container(
        decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(w.region == 'C' ? tr('회화') : '#${w.rank}', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w800)),
            ),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(w.word, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                ),
              ),
            ),
            if (w.ko.isNotEmpty)
              Text(w.ko, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: AppColors.sumiLight)),
          ],
        ),
      ),
    );
  }
}

class WordEntry {
  final int rank;
  final String word;
  final String region; // R1~R5 · C(회화 단어)
  final String ko;
  WordEntry({required this.rank, required this.word, required this.region, required this.ko});
}

class _Region {
  final String label;
  final Color color;
  const _Region(this.label, this.color);
}
