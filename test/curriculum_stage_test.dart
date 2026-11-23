import 'package:flutter_test/flutter_test.dart';
import 'package:russian_universe/services/curriculum_service.dart';
import 'package:russian_universe/services/dialogue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 커리큘럼 §12(2026-11-23): 단계·편 목록은 JSON(서버) — 앱에 없는 편 id 는 건너뜀, 편 0개 단계는 숨김, 옛 R 진도는 단계로, JSON 이 없으면 회화 레벨.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'ru_migrated_v1': true});
    await DialogueService.instance.ensureLoaded();
  });

  test('단계 JSON: 없는 편 id 건너뜀 · 빈 단계 숨김 · 옛 R3 진도 → 3단계 · 다음 단계', () {
    final ids = DialogueService.instance.list(region: 'R3').map((d) => d.id).toList();
    final r0 = DialogueService.instance.list(region: 'R0').first.id;
    final svc = CurriculumService.instance;
    svc.state = CurriculumState(level: 'R3');
    svc.usePlan(CurriculumPlan.fromJson({
      'rev': 5,
      'stages': [
        {'n': 3, 'title': '3단계', 'dialogueIds': [...ids, 'no_such_episode']},
        {'n': 1, 'title': '1단계', 'dialogueIds': [r0]},
        {'n': 2, 'title': '2단계', 'dialogueIds': ['missing_only']},
      ],
    }));
    expect(svc.levels, ['1', '3']);
    expect(svc.state.level, '3');
    expect(svc.levelList('3').map((d) => d.id), ids);
    expect(svc.levelLabel('1'), '1단계');
    expect(svc.nextLevel('1'), '3');
    expect(svc.state.toJson()['level'], 3);
  });

  test('JSON 이 없으면 회화 레벨(R) 그대로', () {
    final svc = CurriculumService.instance;
    svc.state = CurriculumState(level: 'R1');
    svc.usePlan(null);
    expect(svc.levels.first, 'R0');
    expect(svc.state.level, 'R1');
    expect(svc.levelList('R1'), isNotEmpty);
  });

  test('앱에 넣은 기본 JSON 의 편 id 는 모두 앱에 있다', () async {
    final svc = CurriculumService.instance;
    svc.usePlan(null);
    final p = CurriculumPlan.fromJson(await svc.debugAssetPlan());
    final missing = [for (final s in p.stages) for (final id in s.dialogueIds) if (DialogueService.instance.byId(id) == null) id];
    expect(missing, isEmpty);
    expect(p.stages.map((s) => s.n), [1, 2, 3, 4, 5]);
  });

  test('단계 JSON 의 pick·pass·daily 를 씀(없으면 3·5·10 / 80 / 1·2·3)', () {
    final r0 = DialogueService.instance.list(region: 'R0').first.id;
    final svc = CurriculumService.instance;
    svc.state = CurriculumState(level: '1', dailyGoal: 3);
    svc.usePlan(CurriculumPlan.fromJson({
      'rev': 9,
      'stages': [
        {'n': 1, 'dialogueIds': [r0], 'pick': [2, 4], 'pass': 70, 'daily': {'light': 1, 'normal': 3, 'focus': 5}},
        {'n': 2, 'dialogueIds': [r0]},
      ],
    }));
    expect(svc.pickFor(), [2, 4]);
    expect(svc.passFor(), 70);
    expect(svc.state.dailyNew, 5);
    expect(svc.levelLabel('2'), '2단계');
    expect(svc.pickFor('2'), [3, 5, 10]);
    expect(svc.passFor('2'), 80);
    final st = CurriculumState(course: Course('c', ['a']));
    expect(st.recordExam(7, 10, {}, '2026-11-23', pass: svc.passFor()), isTrue);
  });
}
