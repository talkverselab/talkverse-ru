import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'ui_kit.dart';

/// '오늘의 학습' 이어하기 카드 — daydream 톤 (zh TodayMissionCard 구조 이식).
class TodayCard extends StatelessWidget {
  const TodayCard({
    super.key,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.total,
    this.fill = AppColors.sky,
    this.onTap,
  });

  final String tag; // 'L2 회화' / '떠먹여주는' 등
  final String title;
  final String subtitle;
  final int progress;
  final int total;
  final Color fill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? progress / total : 0.0;
    return OutlineCard(
      fill: fill,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outline, width: 1.2),
                ),
                child: Text(tag.toUpperCase(),
                    style: AppType.sans(10,
                        weight: FontWeight.w800,
                        color: AppColors.ink,
                        spacing: 1.2)),
              ),
              const Spacer(),
              const Icon(Icons.play_circle_outline_rounded,
                  color: AppColors.ink, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: AppType.serif(21, height: 1.15)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: AppType.sans(12.5,
                  weight: FontWeight.w500,
                  color: AppColors.inkSoft,
                  height: 1.4)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: AppColors.surface,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.ink),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('$progress / $total',
                  style: AppType.sans(12,
                      weight: FontWeight.w800, color: AppColors.ink)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 🔥 연속 학습 칩 — 홈 헤더용 (zh StreakChip 이식).
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline, width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text('$days',
              style: AppType.sans(13,
                  weight: FontWeight.w900, color: AppColors.ink)),
        ],
      ),
    );
  }
}
