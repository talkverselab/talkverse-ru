import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 문법 커리큘럼 한 단계.
/// spec §4 의 10단계(+ §2 알파벳 단계)를 정확히 반영.
class GrammarStage {
  final String id;         // 'alpha' | 's1' | 's2' | 's3' | 's3p' | 's4' | 's4p' | 's5' | 's6'
  final String label;      // 카드 좌측 짧은 라벨
  final String title;      // 본문 제목
  final String subtitle;   // 한 줄 예문 또는 부제
  final String description;
  final TrackKind track;
  final Color accent;
  final IconData icon;
  final bool implemented;  // 화면 구현 여부 — false면 SnackBar

  const GrammarStage({
    required this.id,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.track,
    required this.accent,
    required this.icon,
    this.implemented = false,
  });
}

/// spec §3 트랙 분리: 규칙 vs 불규칙 통문장.
enum TrackKind {
  foundation,   // 알파벳 등 토대
  rules,        // 트랙 A: 규칙 엔진 (불규칙 0%)
  patterns,     // 트랙 A 보조: 격·전치사 패턴
  irregular,    // 트랙 B: 불규칙 통문장
  aspect,       // вид(상) — 자체 영역
}

extension TrackKindKo on TrackKind {
  String get ko {
    switch (this) {
      case TrackKind.foundation: return '입문';
      case TrackKind.rules:      return '트랙 A · 규칙';
      case TrackKind.patterns:   return '트랙 A · 패턴';
      case TrackKind.irregular:  return '트랙 B · 통문장';
      case TrackKind.aspect:     return '상(вид) · 씨앗';
    }
  }
}

/// 11개 카드 (알파벳 + 10단계). spec §4 선형 순서 강제.
const grammarStages = <GrammarStage>[
  GrammarStage(
    id: 'alpha',
    label: '0',
    title: '알파벳 · 50 내용어',
    subtitle: 'мама · кот · друг · молоко́ · хорошо́',
    description:
        '1군(영어와 같음 А К М О Т) → 2군(false friend В Н Р С У Х) → 3군(새 글자). '
        '발음규칙은 단원으로 만들지 않고 카드 뒤 [소리]에 묻어서. '
        '"대충 읽을 수 있다" 수준에서 졸업 — 키릴 숙달은 음독으로 떠넘김.',
    track: TrackKind.foundation,
    accent: AppColors.cobalt,
    icon: Icons.abc_outlined,
  ),
  GrammarStage(
    id: 's1',
    label: '1',
    title: '형용사 + 명사 (주격)',
    subtitle: 'но́вый дом · хоро́шая ма́ма',
    description:
        '성·수 일치 첫 노출. 목적어 없는 1형식으로 "두 개의 성 충돌" 회피. '
        '형용사 -ый/-ая/-ое 라임만 입에 박는다.',
    track: TrackKind.rules,
    accent: AppColors.pineDeep,
    icon: Icons.crop_square_outlined,
  ),
  GrammarStage(
    id: 's2',
    label: '2',
    title: '과거동사 + 가정법(бы)',
    subtitle: 'Я хоте́л · Я хоте́л бы ко́фе',
    description:
        '과거형 = 부정사어간 + -л/-ла/-ло/-ли. 인칭 무시, 성·수만. '
        '입문은 -л/-ла 둘이면 끝. '
        '가정법은 과거 + бы 하나로 끝나니 같이 도입. '
        '정중요청(хоте́л бы), 후회(е́сли бы) 즉시 사용 가능.',
    track: TrackKind.rules,
    accent: AppColors.amberDeep,
    icon: Icons.history_edu_outlined,
  ),
  GrammarStage(
    id: 's3',
    label: '3',
    title: '과거동사 + 대/여/생격',
    subtitle: 'Я знал дру́га · дал ма́ме',
    description:
        '동사가 격을 결정 → 명사 성이 어미 결정 (2단계 메커니즘). '
        '대격(знать)·여격(дать)·생격(боя́ться) 동사 짝 만남. '
        '주어 바꿔도 목적어 격 불변 — 검증 실험.',
    track: TrackKind.patterns,
    accent: AppColors.lilacDeep,
    icon: Icons.compare_arrows_outlined,
  ),
  GrammarStage(
    id: 's3p',
    label: "3'",
    title: '전치사구 + с(동반)',
    subtitle: 'в Москве́ · с дру́гом · к ма́ме',
    description:
        '전치사가 격을 정한다 (다격 전치사 в/на만 의미별 분기). '
        'с+조격(동반)을 여기에 합류 — 도구·신분은 4\'에서 분리.',
    track: TrackKind.patterns,
    accent: AppColors.cobalt,
    icon: Icons.link_outlined,
  ),
  GrammarStage(
    id: 's4',
    label: '4',
    title: '일반동사 1식·2식 (단수 3인칭)',
    subtitle: 'Я знаю / Ты зна́ешь / Он зна́ет',
    description:
        '규칙 동사 1식·2식만. я/ты/он 3인칭 단수만. '
        '복수는 레벨 잠금 — 단수 패턴 자동화 후 해금. '
        '불규칙 0% 섞기 (트랙 A 순수).',
    track: TrackKind.rules,
    accent: AppColors.pineDeep,
    icon: Icons.account_tree_outlined,
  ),
  GrammarStage(
    id: 's4p',
    label: "4'",
    title: '조격 단독 · быть 보어',
    subtitle: 'был учи́телем · ру́чкой',
    description:
        '도구(ру́чкой)·신분(врачо́м)·быть 보어(был студе́нтом). '
        '동반(с)은 3\'에서 처리됨. '
        '조격은 양다리(с와 단독)라 두 곳에 분산.',
    track: TrackKind.patterns,
    accent: AppColors.amberDeep,
    icon: Icons.handshake_outlined,
  ),
  GrammarStage(
    id: 's5',
    label: '5',
    title: '불규칙 동사 (통문장)',
    subtitle: 'Я хочу́ есть · Я могу́ · Я иду́',
    description:
        'быть · есть · мочь · хоте́ть · дать · идти́ · пойти́ · прийти́. '
        '인칭표가 아니라 **통문장 카드**로. 원어민도 표로 보유하지 않는다.',
    track: TrackKind.irregular,
    accent: AppColors.lilacDeep,
    icon: Icons.menu_book_outlined,
  ),
  GrammarStage(
    id: 's6',
    label: '6',
    title: 'вид(상) + 미래',
    subtitle: 'де́лать/сде́лать · бу́ду де́лать / сде́лаю',
    description:
        '동사 짝 하나로 시제·상 통합 시연. '
        '과거 де́лал/сде́лал · 미래 бу́ду де́лать(불완료) / сде́лаю(완료). '
        'вид는 한국 2달엔 정복 불가 — **씨앗만 심고** 현지 듣기로 떠넘김.',
    track: TrackKind.aspect,
    accent: AppColors.cobalt,
    icon: Icons.workspace_premium_outlined,
  ),
];
