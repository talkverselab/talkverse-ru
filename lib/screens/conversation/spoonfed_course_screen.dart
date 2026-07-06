import 'package:flutter/material.dart';

import '../../data/spoonfed_sentences.dart';
import '../../domain/models/flashcard.dart';
import '../../services/tts_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/ui_kit.dart';
import 'flashcard_session_screen.dart';

/// 떠먹여주는 문장 코스 1개 — 100문장 리스트 + 플래시카드 세션.
class SpoonfedCourseScreen extends StatefulWidget {
  const SpoonfedCourseScreen({super.key, required this.course, this.fill = AppColors.sky});
  final SpoonfedCourse course;
  final Color fill;

  @override
  State<SpoonfedCourseScreen> createState() => _SpoonfedCourseScreenState();
}

class _SpoonfedCourseScreenState extends State<SpoonfedCourseScreen> {
  int? _expanded; // 펼쳐진 문장 index (주요단어 노트)

  void _openFlashcards() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FlashcardSessionScreen(
        title: widget.course.title,
        fill: widget.fill,
        items: [for (final s in widget.course.sentences) FlashItem.fromSpoonfed(s)],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(c.title, style: AppType.serif(18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.style_rounded),
            tooltip: '플래시카드',
            onPressed: _openFlashcards,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        itemCount: c.sentences.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GradientButton(
                label: '플래시카드 ${c.sentences.length}장',
                icon: Icons.style_rounded,
                onTap: _openFlashcards,
              ),
            );
          }
          final idx = i - 1;
          final s = c.sentences[idx];
          final open = _expanded == idx;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlineCard(
              fill: open ? widget.fill : AppColors.surface,
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              onTap: s.note == null
                  ? () => TtsService.instance.speak(s.ru)
                  : () => setState(() => _expanded = open ? null : idx),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NumChip(no: s.no, fill: widget.fill),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.ru, style: AppType.serif(17, height: 1.3)),
                            const SizedBox(height: 4),
                            Text(s.reading,
                                style: AppType.sans(12.5,
                                    weight: FontWeight.w600,
                                    color: AppColors.inkSoft,
                                    height: 1.35)),
                            const SizedBox(height: 5),
                            Text(s.ko,
                                style: AppType.sans(13.5,
                                    weight: FontWeight.w500, color: AppColors.ink, height: 1.4)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Tappable(
                        onTap: () => TtsService.instance.speak(s.ru),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.outline, width: 1.2),
                          ),
                          child: const Icon(Icons.volume_up_rounded,
                              color: AppColors.ink, size: 19),
                        ),
                      ),
                    ],
                  ),
                  if (open && s.note != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outline, width: 1.2),
                      ),
                      child: Text(s.note!,
                          style: AppType.sans(12.5,
                              weight: FontWeight.w500, color: AppColors.inkSoft, height: 1.5)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NumChip extends StatelessWidget {
  const _NumChip({required this.no, required this.fill});
  final int no;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline, width: 1.2),
      ),
      alignment: Alignment.center,
      child: Text('$no', style: AppType.sans(12.5, weight: FontWeight.w800, color: AppColors.ink)),
    );
  }
}
