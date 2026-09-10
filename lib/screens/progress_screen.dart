import 'package:flutter/material.dart';

import 'update_screen.dart';

import '../data/l2_dialogues.dart';
import '../data/spoonfed_sentences.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/ui_kit.dart';
import 'cases/cases_home_screen.dart';

/// 진행 탭 — 전체 진행 · 스트릭 · 주간 활동 · 섹션별 진행. (zh ProgressScreen 구조 이식)
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ps = ProgressService.instance;
    return ValueListenableBuilder<int>(
      valueListenable: ps.revision,
      builder: (context, _, _) {
        final visited = ps.visitedDialogues.length;
        final dialogueTotal = l2Dialogues.length;
        final spoonSeen = [
          for (final c in spoonfedCourses) ps.spoonfedSeen(c.id)
        ].fold<int>(0, (a, b) => a + b);
        final spoonTotal = [
          for (final c in spoonfedCourses) c.sentences.length
        ].fold<int>(0, (a, b) => a + b);
        final done = visited + spoonSeen;
        final total = dialogueTotal + spoonTotal;
        final pct = total > 0 ? done / total : 0.0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            const UpdateEntryTile(),
            Text('진행', style: AppType.serif(26)),
            const SizedBox(height: 6),
            Text('다이얼로그 · 떠먹여주는 문장 · 연속 학습',
                style: AppType.sans(13, color: AppColors.inkSoft)),
            const SizedBox(height: 18),

            // ── 전체 진행 ────────────────────────────────
            OutlineCard(
              fill: AppColors.sky,
              radius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('전체 진행'),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${(pct * 100).toStringAsFixed(1)}%',
                          style: AppType.serif(36, height: 1)),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('$done / $total 문장·다이얼로그',
                            style: AppType.sans(12.5,
                                weight: FontWeight.w700,
                                color: AppColors.inkSoft)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 10,
                      backgroundColor: AppColors.surface,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 스탯 3칸 ─────────────────────────────────
            Row(
              children: [
                Expanded(
                    child: _StatBox(
                        value: '${ps.streak}일',
                        label: '연속 학습 🔥',
                        fill: AppColors.peach)),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatBox(
                        value: '$visited/$dialogueTotal',
                        label: '다이얼로그',
                        fill: AppColors.mint)),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatBox(
                        value: '$spoonSeen',
                        label: '본 문장 카드',
                        fill: AppColors.lilac)),
              ],
            ),
            const SizedBox(height: 20),

            // ── 주간 활동 ────────────────────────────────
            const Eyebrow('이번 주'),
            const SizedBox(height: 10),
            OutlineCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: _WeekRow(active: ps.weekActive),
            ),
            const SizedBox(height: 20),

            // ── 섹션별 진행 ──────────────────────────────
            const Eyebrow('섹션별 진행'),
            const SizedBox(height: 10),
            _SectionBar(
              title: 'L2 회화 다이얼로그',
              done: visited,
              total: dialogueTotal,
              fill: AppColors.sky,
            ),
            const SizedBox(height: 10),
            for (final c in spoonfedCourses) ...[
              _SectionBar(
                title: '떠먹여주는 ${c.title}',
                done: ps.spoonfedSeen(c.id),
                total: c.sentences.length,
                fill: AppColors.mint,
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),

            // ── 사전 (기존 내 학습 카드 이식) ─────────────
            const Eyebrow('사전'),
            const SizedBox(height: 10),
            OutlineCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CasesHomeScreen()),
              ),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.peach,
                      borderRadius: BorderRadius.circular(13),
                      border:
                          Border.all(color: AppColors.outline, width: 1.4),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: AppColors.ink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('단어 사전 · cliff browser',
                            style: AppType.serif(16)),
                        const SizedBox(height: 3),
                        Text('격변화 5단계 절벽 탐색',
                            style: AppType.sans(12.5,
                                color: AppColors.inkSoft)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.inkFaint),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(
      {required this.value, required this.label, required this.fill});
  final String value;
  final String label;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return OutlineCard(
      fill: fill,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(value, style: AppType.serif(19)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: AppType.sans(11,
                  weight: FontWeight.w700, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.active});
  final List<bool> active;

  static const _labels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final todayIdx = DateTime.now().weekday - 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: active[i] ? AppColors.ink : AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: i == todayIdx
                        ? AppColors.outline
                        : AppColors.line,
                    width: i == todayIdx ? 1.8 : 1.2,
                  ),
                ),
                child: active[i]
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.inkOnDark, size: 16)
                    : null,
              ),
              const SizedBox(height: 5),
              Text(_labels[i],
                  style: AppType.sans(10.5,
                      weight:
                          i == todayIdx ? FontWeight.w800 : FontWeight.w600,
                      color: i == todayIdx
                          ? AppColors.ink
                          : AppColors.inkFaint)),
            ],
          ),
      ],
    );
  }
}

class _SectionBar extends StatelessWidget {
  const _SectionBar(
      {required this.title,
      required this.done,
      required this.total,
      required this.fill});
  final String title;
  final int done;
  final int total;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? done / total : 0.0;
    return OutlineCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(title,
                      style: AppType.sans(13.5,
                          weight: FontWeight.w700, color: AppColors.ink))),
              Text('$done / $total',
                  style: AppType.sans(12,
                      weight: FontWeight.w800, color: AppColors.inkSoft)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(
                  pct >= 1 ? AppColors.online : AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
