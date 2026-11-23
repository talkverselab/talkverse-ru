import 'package:flutter_test/flutter_test.dart';
import 'package:russian_universe/services/curriculum_service.dart';
import 'package:russian_universe/services/dialogue_service.dart';
import 'package:russian_universe/services/entitlement.dart';
import 'package:russian_universe/services/purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 이용권 잠금 경계(PAYWALL_SPEC, 2026-11-23): 1단계 열림 · 2단계 잠김 · 이용권 있으면 열림.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'ru_migrated_v1': true});
    await DialogueService.instance.ensureLoaded();
    final svc = CurriculumService.instance;
    svc.usePlan(CurriculumPlan.fromJson(await svc.debugAssetPlan()));
  });
  tearDown(() => Purchase.owned.value = const {});

  test('이용권 없음: 1단계·R1 편·문법 1~2·언어감각 1급만 열림', () {
    Purchase.owned.value = const {};
    expect(Entitlement.premium, isFalse);
    expect(Entitlement.levelFree('1'), isTrue);
    expect(Entitlement.levelFree('2'), isFalse);
    expect(Entitlement.levelFree('5'), isFalse);
    expect(Entitlement.dialogueFree(DialogueService.instance.list(region: 'R1').first), isTrue);
    expect(Entitlement.dialogueFree(DialogueService.instance.list(region: 'R2').first), isFalse);
    expect(Entitlement.grammarStepFree(2), isTrue);
    expect(Entitlement.grammarStepFree(3), isFalse);
    expect(Entitlement.senseLevelFree(1), isTrue);
    expect(Entitlement.senseLevelFree(2), isFalse);
  });

  test('러시아어 이용권 또는 종합 이용권이 있으면 열림, 다른 언어 이용권·만료는 아님', () {
    Purchase.owned.value = const {'lang_ru_life': 0};
    expect(Entitlement.premium, isTrue);
    Purchase.owned.value = const {'all_1y': 9999999999999};
    expect(Entitlement.premium, isTrue);
    Purchase.owned.value = const {'lang_ja_life': 0};
    expect(Entitlement.premium, isFalse);
    Purchase.owned.value = const {'lang_ru_1m': 1};
    expect(Entitlement.premium, isFalse);
  });

  test('서버 값이 바뀌면 그대로: 2단계를 무료로, 문법 3스텝까지', () {
    final svc = CurriculumService.instance;
    final r0 = DialogueService.instance.list(region: 'R0').first.id;
    final r2 = DialogueService.instance.list(region: 'R2').first.id;
    svc.usePlan(CurriculumPlan.fromJson({
      'rev': 3,
      'freeSteps': 3,
      'stages': [
        {'n': 1, 'dialogueIds': [r0]},
        {'n': 2, 'dialogueIds': [r2], 'free': true},
      ],
    }));
    expect(Entitlement.levelFree('2'), isTrue);
    expect(Entitlement.grammarStepFree(3), isTrue);
    expect(Entitlement.dialogueFree(DialogueService.instance.byId(r2)!), isTrue);
  });
}
