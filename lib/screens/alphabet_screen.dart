import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/cyrillic_phonetics.dart';
import '../services/tts_service.dart';
import '../widgets/cyrillic_sound_sheet.dart';

/// 키릴 문자와 발음 — 일본어앱 「50음도와 발음」 구조(2026-11-08 공통 프롬프터 §5-3).
/// 격자 + 묶음 칩(전체 · 모음 · 짝 자음 · 공명음 · 짝 없는 자음 · 부호 · 강세·약화) + 로마자 토글. 칸 탭 = 발음 시트.
class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});
  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  int _group = 0;
  bool _lat = true;

  static const _order = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ';

  List<(String, List<CyrLetter>)> get _groups {
    List<CyrLetter> of(Set<LetterKind> k) => kLetters.where((l) => k.contains(l.kind)).toList();
    final all = [...kLetters]..sort((a, b) => _order.indexOf(a.upper).compareTo(_order.indexOf(b.upper)));
    return [
      (tr('전체 33'), all),
      (tr('모음 10'), of({LetterKind.vowelHard, LetterKind.vowelSoft})),
      (tr('유성·무성 짝 12'), of({LetterKind.voiced, LetterKind.voiceless})),
      (tr('공명음 5'), of({LetterKind.sonorant})),
      (tr('짝 없는 자음 4'), of({LetterKind.unpaired})),
      (tr('부호 2'), of({LetterKind.sign})),
      (tr('강세·약화'), kRules),
    ];
  }

  Color _color(CyrLetter l) => switch (l.kind) {
        LetterKind.vowelHard => AppColors.beni,
        LetterKind.vowelSoft => AppColors.kinDeep,
        LetterKind.voiced => AppColors.ir,
        LetterKind.voiceless => AppColors.oliva,
        LetterKind.sonorant => AppColors.er,
        LetterKind.unpaired => AppColors.irregular,
        LetterKind.sign => AppColors.neutral,
        LetterKind.rule => AppColors.fem,
      };

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    final (_, items) = groups[_group];
    final isRule = _group == groups.length - 1;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('키릴 문자와 발음'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(tr('탭하면 발음·IPA 상세'), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1)),
        ]),
        actions: [
          IconButton(
            tooltip: tr('로마자'),
            icon: Text('Aa', style: TextStyle(fontWeight: FontWeight.w900, color: _lat ? AppColors.beni : AppColors.sumiLight)),
            onPressed: () => setState(() => _lat = !_lat),
          ),
        ],
      ),
      body: Column(children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: groups.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final on = i == _group;
              return GestureDetector(
                onTap: () => setState(() => _group = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: on ? AppColors.beni : AppColors.washi,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.beni, width: on ? 1.5 : 0.8),
                  ),
                  child: Text(groups[i].$1, style: TextStyle(color: on ? AppColors.washi : AppColors.beni, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final cols = isRule ? (c.maxWidth > 700 ? 3 : 2) : (c.maxWidth > 900 ? 8 : c.maxWidth > 600 ? 6 : 5);
            return GridView.builder(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 80 + bottomInset(context)),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: isRule ? 1.9 : 0.86,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _cell(items[i], isRule),
            );
          }),
        ),
      ]),
    );
  }

  Widget _cell(CyrLetter l, bool isRule) {
    final color = _color(l);
    return InkWell(
      onTap: () => showCyrillicSoundSheet(context, l, color),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.washi,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.7)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(1, 2))],
        ),
        padding: const EdgeInsets.all(4),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          FittedBox(
            child: Text(isRule ? l.upper : '${l.upper}${l.lower}',
                style: TextStyle(fontSize: isRule ? 18 : 24, fontWeight: FontWeight.w900, color: AppColors.sumi, height: 1.1)),
          ),
          if (isRule)
            FittedBox(child: Text(l.example, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700)))
          else if (_lat)
            Text(l.lat, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
          if (!isRule)
            Text('[${l.ipa.split(' ').first}]', style: const TextStyle(fontSize: 9, color: AppColors.sumiLight)),
        ]),
      ),
    );
  }
}
