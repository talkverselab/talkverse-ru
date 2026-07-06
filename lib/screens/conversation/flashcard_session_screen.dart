import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/flashcard.dart';
import '../../services/tts_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/sentence_view.dart';
import '../../widgets/ui_kit.dart';

/// 플래시카드 학습 세션 — 카드 탭하면 뒤집기, 🔊 발음, 이전/다음/섞기.
class FlashcardSessionScreen extends StatefulWidget {
  const FlashcardSessionScreen({
    super.key,
    required this.title,
    required this.items,
    this.fill = AppColors.sky,
  });
  final String title;
  final List<FlashItem> items;
  final Color fill;

  @override
  State<FlashcardSessionScreen> createState() => _FlashcardSessionScreenState();
}

class _FlashcardSessionScreenState extends State<FlashcardSessionScreen>
    with SingleTickerProviderStateMixin {
  late final List<FlashItem> _items = [...widget.items];
  int _i = 0;
  bool _koFirst = true; // true = 한→러 (기본), false = 러→한
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  FlashItem get _cur => _items[_i];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakIfRuVisible(delayed: true));
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  /// 러시아어 면이 보일 때만 자동 발음 (한→러 앞면에서 정답 유출 방지).
  void _speakIfRuVisible({bool delayed = false}) {
    if (_koFirst) return;
    TtsService.instance
        .speak(_cur.tts, delay: delayed ? const Duration(seconds: 1) : Duration.zero);
  }

  void _toggleFlip() {
    if (_flip.isAnimating) return;
    final revealing = _flip.value < 0.5;
    revealing ? _flip.forward() : _flip.reverse();
    if (revealing && _koFirst) TtsService.instance.speak(_cur.tts);
  }

  void _toggleDirection() {
    setState(() {
      _koFirst = !_koFirst;
      _flip.value = 0;
    });
    _speakIfRuVisible();
  }

  void _go(int delta) {
    final n = _items.length;
    setState(() {
      _i = (_i + delta) % n;
      if (_i < 0) _i += n;
      _flip.value = 0;
    });
    _speakIfRuVisible(delayed: true);
  }

  void _shuffle() {
    setState(() {
      _items.shuffle(math.Random(_i + 7));
      _i = 0;
      _flip.value = 0;
    });
    _speakIfRuVisible(delayed: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: AppType.serif(18)),
        actions: [
          TextButton.icon(
            onPressed: _toggleDirection,
            icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.ink, size: 20),
            label: Text(_koFirst ? '한 → 러' : '러 → 한',
                style: AppType.sans(13, weight: FontWeight.w800, color: AppColors.ink)),
          ),
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            tooltip: '섞기',
            onPressed: _shuffle,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              _progress(),
              const SizedBox(height: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _toggleFlip,
                  child: AnimatedBuilder(
                    animation: _flip,
                    builder: (context, _) {
                      final angle = _flip.value * math.pi;
                      final showBack = _flip.value > 0.5;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0012)
                          ..rotateY(angle),
                        child: showBack
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(math.pi),
                                child: _back(),
                              )
                            : _front(),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _controls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progress() {
    final p = (_i + 1) / _items.length;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: p,
              minHeight: 8,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation(AppColors.ink),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('${_i + 1} / ${_items.length}',
            style: AppType.sans(13, weight: FontWeight.w800, color: AppColors.inkSoft)),
      ],
    );
  }

  /// 러시아어 면 — 색칠 토큰 / plain 문장+독음 / 단어.
  List<Widget> _ruSide(FlashItem it) => [
        if (it.tokens != null) ...[
          SentenceText(tokens: it.tokens!, size: 26),
          const SizedBox(height: 12),
          SentenceReading(tokens: it.tokens!, size: 15),
        ] else if (it.reading != null) ...[
          Text(it.word ?? '',
              textAlign: TextAlign.center, style: AppType.serif(25, height: 1.25)),
          const SizedBox(height: 12),
          Text(it.reading!,
              textAlign: TextAlign.center,
              style: AppType.sans(15,
                  weight: FontWeight.w600, color: AppColors.inkSoft, height: 1.4)),
        ] else
          Text(it.word ?? '',
              textAlign: TextAlign.center, style: AppType.serif(44, height: 1.1)),
      ];

  /// 한국어 면 — 뜻.
  List<Widget> _koSide(FlashItem it) => [
        Text(it.back, textAlign: TextAlign.center, style: AppType.serif(26, height: 1.25)),
      ];

  Widget _front() {
    final it = _cur;
    return _CardShell(
      fill: widget.fill,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...(_koFirst ? _koSide(it) : _ruSide(it)),
          const SizedBox(height: 22),
          if (!_koFirst) ...[
            _SpeakBtn(text: it.tts),
            const SizedBox(height: 8),
          ],
          Text(_koFirst ? '탭하면 러시아어 보기' : '탭하면 뜻 보기',
              style: AppType.sans(11.5, weight: FontWeight.w600, color: AppColors.inkSoft)),
        ],
      ),
    );
  }

  Widget _back() {
    final it = _cur;
    return _CardShell(
      fill: AppColors.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...(_koFirst ? _ruSide(it) : _koSide(it)),
          if (it.note != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: widget.fill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outline, width: 1.2),
              ),
              child: Text(it.note!,
                  textAlign: TextAlign.center,
                  style: AppType.sans(12.5, weight: FontWeight.w700, color: AppColors.ink)),
            ),
          ],
          const SizedBox(height: 18),
          _SpeakBtn(text: it.tts),
        ],
      ),
    );
  }

  Widget _controls() {
    return Row(
      children: [
        Expanded(child: GhostButton(label: '이전', icon: Icons.chevron_left_rounded, onTap: () => _go(-1))),
        const SizedBox(width: 12),
        Expanded(child: GradientButton(label: '다음', icon: Icons.chevron_right_rounded, onTap: () => _go(1))),
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, required this.fill});
  final Widget child;
  final Color fill;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.outline, width: 1.8),
      ),
      child: Center(child: SingleChildScrollView(child: child)),
    );
  }
}

class _SpeakBtn extends StatelessWidget {
  const _SpeakBtn({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: () => TtsService.instance.speak(text),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outline, width: 1.6),
        ),
        child: const Icon(Icons.volume_up_rounded, color: AppColors.ink, size: 26),
      ),
    );
  }
}
