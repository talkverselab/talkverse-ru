import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 러시아어 cliff 한 구간. lemma rank 누적 커버리지 기반.
class CliffStage {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int rankFrom;
  final int rankTo;
  final IconData icon;
  final Color accent;

  const CliffStage({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.rankFrom,
    required this.rankTo,
    required this.icon,
    required this.accent,
  });

  int get count => rankTo - rankFrom + 1;
}

/// `analysis_domestic/cliff_summary.txt` 매핑 (L = Level, 빈도 rank 절벽구간):
///   L1 55% @ 156 · L2 60% @ 251 · L3 70% @ 685 · L4 80% @ 1985 · L5 90% @ ~5500
/// 색조는 자작나무·계피·앰버·테라코타 계열로 통일.
const cliffStages = <CliffStage>[
  CliffStage(
    id: 'l1',
    title: 'L1 · 골격 156',
    subtitle: 'TOP 1–156 · 누적 55%',
    description:
        'я·не·ты·в·что·быть … 회화의 뼈대. 대명사·전치사·필러+양태 동사. '
        '156 lemma만 익혀도 회화 절반 노출. 격변화 전체 시스템 첫 노출.',
    rankFrom: 1,
    rankTo: 156,
    icon: Icons.bolt,
    accent: AppColors.amberDeep,
  ),
  CliffStage(
    id: 'l2',
    title: 'L2 · 양태·필러 확장',
    subtitle: 'TOP 157–251 · 누적 60%',
    description:
        'нужно·нельзя·пусть·разве·через·про … 양태·전치사 보강 95 lemma. '
        '여기서 GRAMMAR 골격 81개 완성(필러 21·전치사 18 등).',
    rankFrom: 157,
    rankTo: 251,
    icon: Icons.tune,
    accent: AppColors.pineDeep,
  ),
  CliffStage(
    id: 'l3',
    title: 'L3 · 일상 동사·명사',
    subtitle: 'TOP 252–685 · 누적 70%',
    description:
        'работа·человек·сейчас·прийти·думать · 일상 동사와 시간/관계 명사 434 추가. '
        '실제 회화 진입 임계점. 격 지배 다양화.',
    rankFrom: 252,
    rankTo: 685,
    icon: Icons.forum,
    accent: AppColors.cobalt,
  ),
  CliffStage(
    id: 'l4',
    title: 'L4 · 화제 명사 폭증',
    subtitle: 'TOP 686–1985 · 누적 80%',
    description:
        '구체 명사·형용사 1,300 추가. 가족·직업·신체·감정·평가 어휘 확장. '
        '자유 화제 가능 80% 커버 라인.',
    rankFrom: 686,
    rankTo: 1985,
    icon: Icons.school,
    accent: AppColors.lilacDeep,
  ),
  CliffStage(
    id: 'l5',
    title: 'L5 · 자유 회화',
    subtitle: 'TOP 1986–5000 · 누적 ~90%',
    description:
        '전문어·문화어·고급 표현 3,016 추가. 자유 회화·문어 진입 임계점. '
        '드라마·영화 자막 90%+ 자체 해독 가능.',
    rankFrom: 1986,
    rankTo: 5000,
    icon: Icons.workspace_premium,
    accent: AppColors.amberDeep,
  ),
];
