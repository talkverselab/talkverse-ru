import 'package:flutter/foundation.dart';

/// 전역 표시 설정. SentenceText/Reading 가 구독해 즉시 반영.
class DisplaySettings {
  DisplaySettings._();

  /// 강세(악센트 ´) 표시 여부.
  static final ValueNotifier<bool> showAccents = ValueNotifier<bool>(true);

  /// 강세 기호(U+0301) 제거 헬퍼.
  static String strip(String s) => s.replaceAll('́', '');
}
