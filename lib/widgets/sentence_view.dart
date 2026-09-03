import 'package:flutter/material.dart';

import '../core/display_settings.dart';
import '../domain/models/sentence.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 문장 카드 — 색칠된 러시아어 + 독음 + 한국어 뜻 + TTS.
class SentenceCard extends StatelessWidget {
  const SentenceCard({super.key, required this.sentence, this.accent = AppColors.amber});
  final Sentence sentence;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline, width: 1.6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SentenceText(tokens: sentence.tokens),
                const SizedBox(height: 8),
                SentenceReading(tokens: sentence.tokens),
                const SizedBox(height: 10),
                Text(sentence.ko,
                    style: AppType.sans(13.5, weight: FontWeight.w500, color: AppColors.inkSoft, height: 1.4)),
                if (sentence.note != null) ...[
                  const SizedBox(height: 6),
                  Text(sentence.note!, style: AppType.sans(11.5, weight: FontWeight.w600, color: accent)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          _SpeakerButton(text: sentence.plain, accent: accent),
        ],
      ),
    );
  }
}

/// 색칠된 러시아어 텍스트 (어간 잉크 / 어미 성색·동사굵게 / 격 조사칩).
/// [emphasize] 인덱스 = 성별에 따라 바뀌는 단어(형광 하이라이트). 악센트 표시는 전역 설정 구독.
class SentenceText extends StatelessWidget {
  const SentenceText({super.key, required this.tokens, this.size = 20, this.emphasize = const {}});
  final List<Tok> tokens;
  final double size;
  final Set<int> emphasize;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DisplaySettings.showAccents,
      builder: (context, showAccent, _) => Wrap(
        crossAxisAlignment: WrapCrossAlignment.start,
        spacing: 7,
        runSpacing: 10,
        children: [
          for (var i = 0; i < tokens.length; i++)
            _Word(tok: tokens[i], size: size, emphasize: emphasize.contains(i), showAccent: showAccent),
        ],
      ),
    );
  }
}

class _Word extends StatelessWidget {
  const _Word({required this.tok, this.size = 20, this.emphasize = false, this.showAccent = true});
  final Tok tok;
  final double size;
  final bool emphasize;
  final bool showAccent;

  @override
  Widget build(BuildContext context) {
    final stem = showAccent ? tok.stem : DisplaySettings.strip(tok.stem);
    final inflTxt = showAccent ? tok.infl : DisplaySettings.strip(tok.infl);

    final inflColor = tok.gender == Gender.none ? AppColors.ink : tok.gender.color;
    final inflWeight = tok.verb ? FontWeight.w800 : FontWeight.w700;
    final hasInfl = inflTxt.isNotEmpty;

    // 형광 = 남/여 토글로 바뀌는 부분(emphasize). 밑줄 = 동사 활용 어미(verb).
    final hl = emphasize ? (Paint()..color = inflColor.withValues(alpha: 0.24)) : null;
    final stemStyle = AppType.sans(size, weight: FontWeight.w600, color: AppColors.ink, height: 1.25)
        .copyWith(background: hl);
    final inflStyle = AppType.sans(size, weight: inflWeight, color: inflColor, height: 1.25).copyWith(
      background: hl,
      decoration: tok.verb ? TextDecoration.underline : TextDecoration.none,
      decorationColor: inflColor,
      decorationThickness: 2,
    );

    return GestureDetector(
      onTap: () => TtsService.instance.speak(tok.surface),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: stem, style: stemStyle),
        if (hasInfl) TextSpan(text: inflTxt, style: inflStyle),
      ])),
    );
  }
}

/// 한국어 독음 줄 — 어간(잉크) + 어미(성색/동사굵게). 성별 변화부는 형광 하이라이트.
class SentenceReading extends StatelessWidget {
  const SentenceReading({super.key, required this.tokens, this.size = 14, this.emphasize = const {}});
  final List<Tok> tokens;
  final double size;
  final Set<int> emphasize;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DisplaySettings.showReading,
      builder: (context, on, _) {
        if (!on) return const SizedBox.shrink();
        return _readingWrap();
      },
    );
  }

  Widget _readingWrap() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (var i = 0; i < tokens.length; i++)
          if ((tokens[i].stemKo ?? '').isNotEmpty || (tokens[i].inflKo ?? '').isNotEmpty)
            Builder(builder: (_) {
              final t = tokens[i];
              final emp = emphasize.contains(i);
              final inflColor = t.gender == Gender.none ? AppColors.ink : t.gender.color;
              final hl = emp ? (Paint()..color = inflColor.withValues(alpha: 0.24)) : null;
              return GestureDetector(
                onTap: () => TtsService.instance.speak(t.surface),
                child: Text.rich(TextSpan(children: [
                  if ((t.stemKo ?? '').isNotEmpty)
                    TextSpan(
                      text: t.stemKo,
                      style: AppType.sans(size, weight: FontWeight.w500, color: AppColors.inkSoft).copyWith(background: hl),
                    ),
                  if ((t.inflKo ?? '').isNotEmpty)
                    TextSpan(
                      text: t.inflKo,
                      style: AppType.sans(size, weight: t.verb ? FontWeight.w800 : FontWeight.w700, color: inflColor).copyWith(
                        background: hl,
                        decoration: t.verb ? TextDecoration.underline : TextDecoration.none,
                        decorationColor: inflColor,
                      ),
                    ),
                ])),
              );
            }),
      ],
    );
  }
}

class _SpeakerButton extends StatelessWidget {
  const _SpeakerButton({required this.text, required this.accent});
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => TtsService.instance.speak(text),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(Icons.volume_up_rounded, color: accent, size: 21),
      ),
    );
  }
}

/// 색칠 규칙 범례.
class RhymeLegend extends StatelessWidget {
  const RhymeLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 14, runSpacing: 8, children: const [
            _Swatch(color: AppColors.cobalt, label: '남성'),
            _Swatch(color: AppColors.amberDeep, label: '여성'),
            _Swatch(color: AppColors.pineDeep, label: '중성'),
          ]),
          const SizedBox(height: 8),
          Text.rich(TextSpan(children: [
            TextSpan(text: '색 = ', style: _meta),
            TextSpan(text: '성에 따라 변하는 어미', style: _metaInk),
            TextSpan(text: '  ·  ', style: _meta),
            TextSpan(text: '굵게', style: _metaInk.copyWith(fontWeight: FontWeight.w800)),
            TextSpan(text: ' = 동사 활용', style: _meta),
            TextSpan(text: '\n어미 밑 ', style: _meta),
            TextSpan(text: '한글 = 소리(라임)', style: _metaInk),
            TextSpan(text: '  ·  회색칩 = 격(조사)', style: _meta),
          ])),
        ],
      ),
    );
  }

  static final TextStyle _meta = AppType.sans(11.5, weight: FontWeight.w500, color: AppColors.inkFaint);
  static final TextStyle _metaInk = AppType.sans(11.5, weight: FontWeight.w600, color: AppColors.inkSoft);
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 11, height: 11, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 5),
      Text(label, style: AppType.sans(11.5, weight: FontWeight.w700, color: color)),
    ]);
  }
}
