import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 전역 표시 설정. SentenceText/Reading 가 구독해 즉시 반영.
class DisplaySettings {
  DisplaySettings._();

  /// 강세(악센트 ´) 표시 여부.
  static final ValueNotifier<bool> showAccents = ValueNotifier<bool>(true);

  /// 한글 독음 줄 표시 여부 — 모든 메뉴 공용, 영구 저장 (zh 앱 패턴).
  static final ValueNotifier<bool> showReading = ValueNotifier<bool>(true);

  static const _readingKey = 'show_ko_reading';

  /// 앱 시작 시 1회 로드.
  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    showReading.value = p.getBool(_readingKey) ?? true;
  }

  static Future<void> toggleReading() async {
    showReading.value = !showReading.value;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_readingKey, showReading.value);
  }

  /// 강세 기호(U+0301) 제거 헬퍼.
  static String strip(String s) => s.replaceAll('́', '');
}

/// 앱바용 한글독음 토글 (악센트 토글과 같은 원형 버튼 스타일).
class ReadingToggleAction extends StatelessWidget {
  const ReadingToggleAction({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DisplaySettings.showReading,
      builder: (context, on, _) => GestureDetector(
        onTap: DisplaySettings.toggleReading,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.ink : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.outline, width: 1.4),
          ),
          child: Text('한',
              style: AppType.sans(14,
                  weight: FontWeight.w800,
                  color: on ? AppColors.inkOnDark : AppColors.inkFaint)),
        ),
      ),
    );
  }
}
