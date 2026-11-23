import 'package:flutter/material.dart';
import '../core/prefs.dart';

import '../screens/paywall_screen.dart';
import 'account.dart';
import 'curriculum_service.dart';
import 'dialogue_service.dart';
import 'purchase.dart';

/// 무료/유료 구분(일본어앱 방식, 2026-11-09).
/// `premium` = 기기 제작용 스위치 OR Talkverse 계정 이용권(lang 'ru') OR 이 기기에서 산·복원한 이용권(스토어).
/// 잠금 범위 = ~/talkverse/PAYWALL_SPEC.md(2026-11-23 사용자 「1 2 모두 진행」, uk 정함): 무료 = 커리큘럼 1단계·회화 1단계(R0·R1)·문법 1~2스텝·언어감각 1급,
/// 그 밖은 이용권. 무료 한도는 커리큘럼 JSON(서버)의 단계 `free`·`freeSteps`·`freeSenseLevels`, 없으면 기본값. 잠긴 곳은 숨기지 않고 자물쇠 → 결제 화면.
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

  static CurriculumPlan? get _plan => CurriculumService.instance.plan;

  /// 커리큘럼 단계(1~5)가 무료인가.
  static bool stageFree(int n) => _plan?.stages.where((s) => s.n == n).firstOrNull?.free ?? n == 1;

  /// 커리큘럼 레벨 키('1'~'5' 또는 옛 R 레벨)가 무료인가.
  static bool levelFree(String key) {
    final n = int.tryParse(key);
    return n != null ? stageFree(n) : (key == 'R0' || key == 'R1');
  }

  /// 회화 편이 무료인가 — 무료 단계에 든 편(단계 JSON 이 없으면 R0·R1).
  static bool dialogueFree(Dialogue d) {
    final p = _plan;
    if (p == null) return d.region == 'R0' || d.region == 'R1';
    for (final s in p.stages) {
      if (s.dialogueIds.contains(d.id)) return s.free;
    }
    return d.region == 'R0' || d.region == 'R1';
  }

  /// 문법 스텝(1부터)·언어감각 급(1부터)이 무료인가.
  static bool grammarStepFree(int step) => step <= (_plan?.freeSteps ?? 2);
  static bool senseLevelFree(int level) => level <= (_plan?.freeSenseLevels ?? 1);

  /// 잠긴 것을 열 때: 무료거나 이용권이 있으면 true, 아니면 결제 화면을 띄우고 산 뒤의 상태를 돌려준다.
  static Future<bool> unlock(BuildContext context, bool free) async {
    if (free || premium) return true;
    await showPaywall(context);
    return premium;
  }
}
