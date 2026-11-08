import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/cyrillic_phonetics.dart';
import '../services/tts_service.dart';

/// 키릴 글자 탭 → 발음 상세 시트(일본어앱 kana_sound_sheet 구조).
/// 열리면 1초 뒤 자동 재생(글자 이름 → 예시 낱말), 다시 듣기, IPA, 조음 위치 그림, 모음 위치(러 vs 한), 한국어 비교.
Future<void> showCyrillicSoundSheet(BuildContext context, CyrLetter l, Color color) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.washi,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _Sheet(l: l, color: color),
  );
}

String _plain(String s) => s.replaceAll('́', '');

Future<void> speakLetter(CyrLetter l) async {
  final tts = TtsService.instance;
  if (l.kind == LetterKind.rule) {
    await tts.speak(_plain(l.example));
    return;
  }
  await tts.speak('${_plain(l.name)}. ${_plain(l.example)}');
}

class _Sheet extends StatefulWidget {
  final CyrLetter l;
  final Color color;
  const _Sheet({required this.l, required this.color});
  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  Timer? _auto;

  @override
  void initState() {
    super.initState();
    _auto = Timer(const Duration(seconds: 1), () => speakLetter(widget.l));
  }

  @override
  void dispose() {
    _auto?.cancel();
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l, color = widget.color;
    final isRule = l.kind == LetterKind.rule;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scroll) => SafeArea(
        top: false,
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + bottomInset(context)),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.sumiLight.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 92,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                  child: FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        isRule ? l.upper : '${l.upper} ${l.lower}',
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.washi),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRule ? l.example : '${l.name} · ${l.lat}',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'IPA [${l.ipa}]',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.sumi),
                      ),
                      if (!isRule && l.pair.isNotEmpty) Text(trf('짝: {0}', [l.pair]), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
                    ],
                  ),
                ),
                IconButton(iconSize: 44, color: color, tooltip: tr('다시 듣기'), icon: const Icon(Icons.play_circle_fill), onPressed: () => speakLetter(l)),
              ],
            ),
            const SizedBox(height: 16),
            _section(tr('🔤 예시 낱말'), '${l.example}\n${l.exampleKo}', color),
            const SizedBox(height: 12),
            _section(tr('👄 소리 나는 곳 · 입 모양'), l.placeText, color),
            if (l.place != Place.none && !l.isVowel) ...[
              const SizedBox(height: 12),
              _box(color, tr('📍 조음 위치'), ArticulationDiagram(active: l.place, color: color)),
            ],
            if (l.ru != null) ...[const SizedBox(height: 12), _box(color, tr('📍 모음 위치 — 러시아어 vs 한국어'), VowelCompareChart(ru: l.ru!, ko: l.ko))],
            const SizedBox(height: 12),
            _section(tr('🇰🇷 한국어와 비교'), trf('비슷한 소리: {0}\n\n{1}', [l.korSim, l.korDiff]), color),
          ],
        ),
      ),
    );
  }

  Widget _box(Color color, String title, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.washiDeep,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );

  Widget _section(String title, String body, Color color) =>
      _box(color, title, Text(body, style: const TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.sumi)));
}

/// 간이 옆모습 조음 위치 그림(자체 제작 — 외부 그림 없음). 입술 → 목 순서로 8자리, 현재 자리를 강조.
class ArticulationDiagram extends StatelessWidget {
  final Place active;
  final Color color;
  const ArticulationDiagram({super.key, required this.active, required this.color});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 460),
    child: AspectRatio(
      aspectRatio: 1.6,
      child: CustomPaint(
        painter: _ArtPainter(active, color, DefaultTextStyle.of(context).style.fontFamily, {
          Place.lips: tr('입술'),
          Place.labiodental: tr('윗니+아랫입술'),
          Place.dental: tr('윗니 뒤'),
          Place.alveolar: tr('잇몸'),
          Place.postalveolar: tr('잇몸 뒤'),
          Place.palatal: tr('센입천장'),
          Place.velar: tr('여린입천장'),
        }),
      ),
    ),
  );
}

class _ArtPainter extends CustomPainter {
  final Place active;
  final Color color;
  final Map<Place, String> labels;
  final String? font;
  _ArtPainter(this.active, this.color, this.font, this.labels);

  // 입천장 곡선이 지나는 자리(가로 0 = 입술 쪽 → 1 = 목 쪽). 곡선은 이 점들을 그대로 잇는다.
  static const _spots = {
    Place.lips: Offset(0.05, 0.56),
    Place.labiodental: Offset(0.11, 0.44),
    Place.dental: Offset(0.18, 0.36),
    Place.alveolar: Offset(0.28, 0.27),
    Place.postalveolar: Offset(0.39, 0.20),
    Place.palatal: Offset(0.56, 0.14),
    Place.velar: Offset(0.74, 0.18),
  };
  static const _tail = [Offset(0.86, 0.30), Offset(0.91, 0.55), Offset(0.92, 0.95)];

  @override
  void paint(Canvas canvas, Size s) {
    Offset p(Offset o) => Offset(o.dx * s.width, o.dy * s.height);
    final line = Paint()
      ..color = AppColors.sumiLight.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    // 입천장(위): 자리 점들을 지나는 매끄러운 곡선
    final pts = [..._spots.values, ..._tail].map(p).toList();
    final roof = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var k = 1; k < pts.length; k++) {
      final mid = Offset((pts[k - 1].dx + pts[k].dx) / 2, (pts[k - 1].dy + pts[k].dy) / 2);
      roof.quadraticBezierTo(pts[k - 1].dx, pts[k - 1].dy, mid.dx, mid.dy);
    }
    roof.lineTo(pts.last.dx, pts.last.dy);
    canvas.drawPath(roof, line);
    // 아랫입술·혀(아래)
    final tongue = Path()
      ..moveTo(p(const Offset(0.05, 0.70)).dx, p(const Offset(0.05, 0.70)).dy)
      ..quadraticBezierTo(p(const Offset(0.12, 0.62)).dx, p(const Offset(0.12, 0.62)).dy, p(const Offset(0.22, 0.58)).dx, p(const Offset(0.22, 0.58)).dy)
      ..quadraticBezierTo(p(const Offset(0.50, 0.38)).dx, p(const Offset(0.50, 0.38)).dy, p(const Offset(0.74, 0.46)).dx, p(const Offset(0.74, 0.46)).dy)
      ..quadraticBezierTo(p(const Offset(0.84, 0.54)).dx, p(const Offset(0.84, 0.54)).dy, p(const Offset(0.82, 0.95)).dx, p(const Offset(0.82, 0.95)).dy);
    canvas.drawPath(
      tongue,
      Paint()
        ..color = AppColors.beniLight.withValues(alpha: 0.8)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    _label(canvas, tr('혀'), p(const Offset(0.46, 0.50)), AppColors.beniLight, 10);
    _label(canvas, tr('입'), p(const Offset(0.0, 0.76)), AppColors.sumiLight, 10);
    _label(canvas, tr('목'), p(const Offset(0.90, 0.96)), AppColors.sumiLight, 10);
    for (final e in _spots.entries) {
      final on = e.key == active;
      final c = p(e.value);
      canvas.drawCircle(c, on ? 9 : 4, Paint()..color = on ? color : AppColors.sumiLight.withValues(alpha: 0.5));
      if (on) {
        canvas.drawCircle(
          c,
          9,
          Paint()
            ..color = AppColors.washi
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        _label(canvas, labels[e.key] ?? '', c + const Offset(-20, -26), color, 12, bold: true);
      }
    }
  }

  void _label(Canvas canvas, String t, Offset o, Color c, double fs, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(fontFamily: font, fontSize: fs, color: c, fontWeight: bold ? FontWeight.w900 : FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _ArtPainter old) => old.active != active || old.color != color;
}

/// IPA 모음 사다리꼴 위에 러시아어 모음(파랑)과 이웃 한국어 모음(주황)을 함께 찍는다.
class VowelCompareChart extends StatelessWidget {
  final VowelSpot ru;
  final List<VowelSpot> ko;
  const VowelCompareChart({super.key, required this.ru, required this.ko});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AspectRatio(
          aspectRatio: 1.45,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 20, 10, 8),
            child: CustomPaint(
              painter: _VowelPainter(ru, ko, [tr('앞'), tr('가운데'), tr('뒤'), tr('높음'), tr('낮음')], DefaultTextStyle.of(context).style.fontFamily),
              size: Size.infinite,
            ),
          ),
        ),
      ),
      Row(children: [_dot(AppColors.beni, tr('러시아어')), const SizedBox(width: 12), _dot(AppColors.er, tr('한국어'))]),
    ],
  );

  Widget _dot(Color c, String t) => Row(
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        t,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c),
      ),
    ],
  );
}

class _VowelPainter extends CustomPainter {
  final VowelSpot ru;
  final List<VowelSpot> ko;
  final List<String> axis;
  final String? font;
  _VowelPainter(this.ru, this.ko, this.axis, this.font);

  Offset _m(double x, double y, Size s) {
    final left = 0.38 * s.width * y;
    return Offset(left + (s.width - left) * x, y * s.height);
  }

  @override
  void paint(Canvas canvas, Size s) {
    final g = Paint()
      ..color = AppColors.sumiLight.withValues(alpha: 0.45)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawPath(Path()..addPolygon([_m(0, 0, s), _m(1, 0, s), _m(1, 1, s), _m(0, 1, s)], true), g);
    for (final y in [1 / 3, 2 / 3]) {
      canvas.drawLine(_m(0, y, s), _m(1, y, s), g);
    }
    canvas.drawLine(_m(0.5, 0, s), _m(0.5, 1, s), g);
    _t(canvas, axis[0], Offset(0, -16), AppColors.sumiLight, 9);
    _t(canvas, axis[1], Offset(_m(0.5, 0, s).dx - 12, -16), AppColors.sumiLight, 9);
    _t(canvas, axis[2], Offset(s.width - 14, -16), AppColors.sumiLight, 9);
    _t(canvas, axis[3], const Offset(-26, -4), AppColors.sumiLight, 9);
    _t(canvas, axis[4], Offset(-26, s.height - 10), AppColors.sumiLight, 9);
    final r = _m(ru.x, ru.y, s);
    for (final k in ko) {
      final p = _m(k.x, k.y, s);
      canvas.drawLine(
        r,
        p,
        Paint()
          ..color = AppColors.sumiLight.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(p, 5, Paint()..color = AppColors.er);
      _t(canvas, '${k.label} [${k.ipa}]', p + const Offset(8, -6), AppColors.er, 10.5);
    }
    canvas.drawCircle(r, 7, Paint()..color = AppColors.beni);
    _t(canvas, '${ru.label} [${ru.ipa}]', r + const Offset(-36, 8), AppColors.beni, 12, bold: true);
  }

  void _t(Canvas canvas, String t, Offset o, Color c, double fs, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(fontFamily: font, fontSize: fs, color: c, fontWeight: bold ? FontWeight.w900 : FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _VowelPainter old) => old.ru != ru;
}
