import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import '../core/embed_env.dart';
import '../core/prefs.dart';

import 'learner_prefs.dart';
import 'script_sync.dart';

/// 회화 리더(일본어앱 시안 02 「만화책 읽기형」)용 회화 모델 — 2026-11-02, 일본어앱 `dialogue_service.dart` 를 옮김.
///
/// 2026-11-18: 새 구조(R0~R5·주제별 편 파일)를 읽고, 서버에 더 새 원고가 있으면 그것([ScriptSync], 일본어앱 빌드 113·114).
/// 칸: tl = 러시아어(강세 부호 포함, 데이터 칸 이름은 키트 그대로 `es`), gloss = 없음, rd = 한글 독음, ko = 한국어.
class DialogueTurn {
  final int num;
  final String speaker; // A·B·C·D
  final String _tl, _rd, _ko;
  final String? tlF, rdF, koF; // 학습자(A)가 여성일 때의 판(성별이 드러나는 줄만)
  final String emotion; // 음성 감정(원고 emotion 칸)
  final String gloss;
  String get tl => LearnerPrefs.isFemale && (tlF ?? '').isNotEmpty ? tlF! : _tl;
  String get rd => LearnerPrefs.isFemale && (tlF ?? '').isNotEmpty && (rdF ?? '').isNotEmpty ? rdF! : _rd;
  String get ko => LearnerPrefs.isFemale && (koF ?? '').isNotEmpty ? koF! : _ko;
  final String note;
  final List<String> tags;
  final String? art; // 장면 그림 URL(나중에 채움)
  const DialogueTurn({
    required this.num,
    required this.speaker,
    required String tl,
    required this.gloss,
    required String rd,
    required String ko,
    this.tlF,
    this.rdF,
    this.koF,
    this.emotion = 'neutral',
    required this.note,
    required this.tags,
    this.art,
  })  : _tl = tl,
        _rd = rd,
        _ko = ko;

  factory DialogueTurn.fromL1(Map<String, dynamic> j) => DialogueTurn(
        num: j['num'] as int? ?? 0,
        speaker: j['speaker'] as String? ?? 'A',
        tl: j['es'] as String? ?? '',
        gloss: j['gloss'] as String? ?? '',
        rd: j['rd'] as String? ?? '',
        ko: j['ko'] as String? ?? '',
        note: j['note'] as String? ?? '',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        art: j['art'] as String?,
        tlF: j['es_f'] as String?,
        rdF: j['rd_f'] as String?,
        koF: j['ko_f'] as String?,
        emotion: j['emotion'] as String? ?? 'neutral',
      );

  /// 그림 조회용 핵심 단어 후보: 러시아어 낱말(강세 부호를 빼고 소문자).
  List<String> get pictureWords => [
        for (final m in RegExp(r'[А-Яа-яЁё]+').allMatches(tl.replaceAll('\u0301', ''))) m.group(0)!.toLowerCase(),
      ];
}

class Dialogue {
  final String id;
  final String region; // 지금은 옛 레벨 이름(L1) 그대로 — R 재태그는 회화 작업 때
  final String island; // 주제
  final String title;
  final String emoji;
  final String scene;
  final Map<String, String> speakers;
  final Map<String, String> genders;
  final List<String> expressions;
  final List<DialogueTurn> turns;
  final String? art;
  const Dialogue({
    required this.id,
    required this.region,
    required this.island,
    required this.title,
    required this.emoji,
    required this.scene,
    required this.speakers,
    required this.genders,
    required this.expressions,
    required this.turns,
    this.art,
  });

  /// 새 회화 편 파일(`assets/data/dialogues/R<급>/<주제>/<편id>.json`, 2026-11-18).
  factory Dialogue.fromJson(Map<String, dynamic> j) {
    final sp = ((j['speakers'] as Map?) ?? const {}).map((k, v) => MapEntry(k.toString(), v.toString()));
    return Dialogue(
      id: j['id'] as String,
      region: j['region'] as String? ?? 'R1',
      island: j['island'] as String? ?? 'friends',
      title: j['title'] as String? ?? j['id'] as String,
      emoji: j['emoji'] as String? ?? '💬',
      scene: j['scene'] as String? ?? '',
      speakers: sp,
      genders: const {},
      expressions: (j['expressions'] as List?)?.cast<String>() ?? const [],
      turns: ((j['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromL1(t as Map<String, dynamic>)).toList(),
      art: j['art'] as String?,
    );
  }

  /// 화면에 보일 장면 설명 — 원고의 「A」(학습자)를 이름(없으면 「나」)으로(일본어앱 빌드 111).
  String get sceneShown => scene.replaceAllMapped(RegExp(r'(?<![A-Za-z])A(?![A-Za-z]) ?(?=[가-힣])'), (_) => speakerName('A'));

  /// 편 순서 키: survival → a → b → c, 번호 순.
  String get orderKey {
    final m = RegExp(r'_([abcs])(\d+)$').firstMatch(id);
    if (m == null) return id;
    const o = {'s': 0, 'a': 1, 'b': 2, 'c': 3};
    return '${o[m.group(1)]}${m.group(2)!.padLeft(2, '0')}';
  }

  /// 화자 표시 이름. `{name}` 자리는 학습자 이름(없으면 「나」).
  String speakerName(String sp) {
    final raw = speakers[sp] ?? sp;
    if (raw.contains('{name}')) return LearnerPrefs.name.value.isNotEmpty ? LearnerPrefs.name.value : '나';
    return raw.replaceAll(RegExp(r'[{}]'), '');
  }

  /// 목소리 성별 — 지금 회화는 화자 성별이 데이터에 정해져 있다(A Daniel 남 · B 현지인 여).
  String voiceGender(String sp) => genders[sp] ?? LearnerPrefs.voiceGender(sp);
}

class DialogueService {
  DialogueService._();
  static final DialogueService instance = DialogueService._();

  static const islands = ['survival', 'friends', 'love', 'life', 'travel', 'culture', 'work', 'study'];
  static const islandKo = {
    'survival': '서바이벌',
    'friends': '친구',
    'love': '사랑',
    'life': '생활',
    'travel': '여행',
    'culture': '문화',
    'work': '일',
    'study': '학업',
  };
  static const islandEmoji = {
    'survival': '🆘',
    'friends': '🤝',
    'love': '💘',
    'life': '🏠',
    'travel': '✈️',
    'culture': '🎬',
    'work': '💼',
    'study': '🎓',
  };
  static const levelKo = {'R0': '왕초보', 'R1': '초보', 'R2': '초중급', 'R3': '중급', 'R4': '고급', 'R5': '최상급'};
  static const _prefLast = 'dialogue_last';

  final List<Dialogue> _all = [];
  bool _loaded = false;
  String? _lastOpened;
  String? get lastOpenedId => _lastOpened;
  Future<void> setLastOpened(String id) async {
    _lastOpened = id;
    (await Prefs.getInstance()).setString(_prefLast, id);
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _lastOpened = (await Prefs.getInstance()).getString(_prefLast);
    await _readAll();
    _loaded = true;
    // 서버에 더 새 원고가 있으면 뒤에서 받아 다시 읽는다(없거나 실패하면 그대로)
    ScriptSync.instance.refresh().then((changed) async {
      if (!changed) return;
      await _readAll();
      revision.value++;
    });
  }

  /// 원고가 서버 판으로 바뀌어 다시 읽힐 때마다 오른다.
  final ValueNotifier<int> revision = ValueNotifier(0);

  /// 앱 안 편 + 서버에서 받은 새 편(R0~R5). 각 파일은 덮어쓴 판이 있으면 그것([ScriptSync]).
  Future<void> _readAll() async {
    final sync = ScriptSync.instance;
    await sync.init();
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final pat = RegExp(r'^assets/data/dialogues/R[0-5]/[^/]+/[^/]+\.json$');
    final rels = <String>{
      for (final p in manifest.listAssets().map(stripAssetPrefix).where(pat.hasMatch)) p.substring('assets/data/'.length),
      ...sync.added.where((p) => pat.hasMatch('assets/data/$p')),
    }..removeAll(sync.removed);
    final next = <Dialogue>[];
    for (final rel in rels) {
      try {
        final d = Dialogue.fromJson(json.decode(await sync.load(rel)) as Map<String, dynamic>);
        if (d.turns.isNotEmpty) next.add(d);
      } catch (_) {}
    }
    next.sort((a, b) => '${a.region}/${a.island}/${a.orderKey}'.compareTo('${b.region}/${b.island}/${b.orderKey}'));
    _all
      ..clear()
      ..addAll(next);
  }

  Dialogue? byId(String id) => _all.where((d) => d.id == id).firstOrNull;
  List<Dialogue> get all => List.unmodifiable(_all);
  List<String> get regions => _all.map((d) => d.region).toSet().toList()..sort();

  List<Dialogue> list({String? region, String? island}) =>
      _all.where((d) => (region == null || d.region == region) && (island == null || d.island == island)).toList();

  List<String> islandsOf(String region) {
    final has = _all.where((d) => d.region == region).map((d) => d.island).toSet();
    return islands.where(has.contains).toList();
  }

  int count(String region) => _all.where((d) => d.region == region).length;
}
