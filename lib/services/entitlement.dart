import 'package:flutter/material.dart';
import '../core/prefs.dart';

import '../screens/paywall_screen.dart';
import 'account.dart';
import 'purchase.dart';

/// 무료/유료 구분(일본어앱 방식, 2026-11-09).
/// `premium` = 기기 제작용 스위치 OR Talkverse 계정 이용권(lang 'ru') OR 이 기기에서 산·복원한 이용권(스토어).
/// 지금 잠긴 것 없음 — 출시 첫 판은 전부 무료(~/talkverse/PRICING.md). 결제 화면은 설정에서만 열린다.
class Entitlement {
  Entitlement._();
  static const lang = 'ru';
  static bool _local = false;
  static bool get premium => _local || Account.has(lang) || Purchase.owns(lang);

  static Future<void> load() async => _local = (await Prefs.getInstance()).getBool('premium') ?? false;
  static Future<void> set(bool v) async {
    _local = v;
    (await Prefs.getInstance()).setBool('premium', v);
  }

  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);
}
