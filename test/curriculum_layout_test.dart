import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:russian_universe/screens/curriculum_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 코스 고르기 화면(3·5·10 칩 + 「추천으로 채우기」)이 폰 폭·300px 폭에서 넘치지 않는다 — 넘치면 렌더 예외로 실패(mn c774c05, uk 11-22).
void main() {
  for (final w in [390.0, 300.0]) {
    testWidgets('코스 고르기 $w px 폭 넘침 없음', (t) async {
      SharedPreferences.setMockInitialValues({
        'ru_migrated_v1': true,
        'ru_curriculum_v1': json.encode({'level': 'R1', 'dailyGoal': 2}),
      });
      t.view.physicalSize = Size(w, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const MaterialApp(home: CurriculumScreen()));
      for (var i = 0; i < 30 && find.text('추천으로 채우기').evaluate().isEmpty; i++) {
        await t.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
        await t.pump();
      }
      expect(find.text('추천으로 채우기'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
