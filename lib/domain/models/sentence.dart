import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 성(性) — 형태소 색칠의 기준. 라임(어미 일치)을 한 색으로 묶는다.
enum Gender { masc, fem, neut, none }

extension GenderStyle on Gender {
  /// 차분한 팔레트 3색 (원색 회피).
  Color get color {
    switch (this) {
      case Gender.masc:
        return AppColors.cobalt; // 남성
      case Gender.fem:
        return AppColors.amberDeep; // 여성
      case Gender.neut:
        return AppColors.pineDeep; // 중성
      case Gender.none:
        return AppColors.ink;
    }
  }

  String get ko {
    switch (this) {
      case Gender.masc:
        return '남성';
      case Gender.fem:
        return '여성';
      case Gender.neut:
        return '중성';
      case Gender.none:
        return '';
    }
  }
}

/// 한 단어(토큰) = 차분한 어간 + 변하는 어미.
///
/// 색칠 규칙:
///  - [gender] != none  → 어미를 성(性) 색으로 (형용사·명사·과거동사 일치 = 라임)
///  - [verb] == true     → 어미를 굵게 (동사 활용 엔진). 과거형은 verb+gender 동시.
///  - [josa] != null     → 어미 뒤 작은 회색 라벨 (격 = 한국어 조사)
class Tok {
  final String stem; // 잉크색 어간 (키릴)
  final String infl; // 강조되는 어미 (키릴, 없으면 '')
  final String? stemKo; // 어간의 한글 독음 (잉크)
  final String? inflKo; // 어미의 한글 독음 (라임 = 성색)
  final Gender gender; // 성 일치 색
  final bool verb; // 동사 활용 → 굵게
  final String? josa; // 격 조사 라벨 (예: '을/를')

  const Tok(
    this.stem, {
    this.infl = '',
    this.stemKo,
    this.inflKo,
    this.gender = Gender.none,
    this.verb = false,
    this.josa,
  });

  /// TTS·복사용 표면형 (강세 기호 포함).
  String get surface => '$stem$infl';
}

/// 커리큘럼 한 문장.
class Sentence {
  final List<Tok> tokens;
  final String ko; // 한국어 뜻
  final String? note; // 한 줄 학습 포인트 (선택)

  const Sentence(this.tokens, {required this.ko, this.note});

  /// TTS에 넘길 평문 (강세 기호 제거 — 합성기 호환).
  String get plain =>
      tokens.map((t) => t.surface).join(' ').replaceAll('́', '');
}
