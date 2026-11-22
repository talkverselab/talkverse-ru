import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'dialogue_service.dart';
import 'learner_prefs.dart';
import 'tts_service.dart';

/// 회화 턴의 녹음 음성(mp4, 서버 `…/art/ru/audio/manifest`) — 있으면 녹음, 없으면 기기 TTS(사용자 지시 2026-11-22, uk 전달).
/// 일본어앱 `DialogueAudio` 꼴. 녹음 문장이 지금 대사와 다르면(대사가 고쳐짐) 녹음을 쓰지 않고 TTS 로 읽는다.
/// 학습자 이름 자리({name})가 있는 줄도 TTS(녹음엔 다른 이름이 들어 있음). 목록은 앱이 처음 회화를 읽을 때 한 번 받는다.
class DialogueAudio {
  DialogueAudio._();
  static final DialogueAudio instance = DialogueAudio._();

  static const manifestUrl = 'https://auth.talkverse.uk/art/ru/audio/manifest';

  String _base = '';
  final Map<String, Map<int, Map<String, ({String key, String text, int ms})>>> _idx = {};
  Future<void>? _loading;
  AudioPlayer? _player;
  Completer<void>? _wait;
  int _gen = 0;

  Future<void> _load() => _loading ??= () async {
        try {
          final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
          final req = await client.getUrl(Uri.parse(manifestUrl));
          req.headers.set(HttpHeaders.userAgentHeader, 'talkverse-ru/0.1');
          final res = await req.close().timeout(const Duration(seconds: 12));
          if (res.statusCode == 200) {
            final j = json.decode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
            _base = (j['base'] as String? ?? '').replaceAll(RegExp(r'/$'), '');
            for (final it in (j['items'] as List? ?? const [])) {
              final m = it as Map<String, dynamic>;
              final ep = m['episode'] as String?, turn = m['turn'], key = m['key'] as String?;
              if (ep == null || turn is! int || key == null) continue;
              (_idx[ep] ??= {})[turn] ??= {};
              _idx[ep]![turn]![(m['voice'] as String?) ?? 'm'] = (key: key, text: m['text'] as String? ?? '', ms: (m['ms'] as num?)?.toInt() ?? 4000);
            }
          }
          client.close();
        } catch (e) {
          debugPrint('DialogueAudio: manifest 실패 $e'); // 목록이 없으면 전부 TTS
        }
      }();

  static String _norm(String s) => s.replaceAll('́', '').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// 이 턴에 쓸 녹음(없거나 대사가 달라졌으면 null).
  Future<({String key, String text, int ms})?> line(String episodeId, DialogueTurn t) async {
    await _load();
    if (t.tl.contains('{')) return null;
    final l = _idx[episodeId]?[t.num]?[LearnerPrefs.isFemale ? 'f' : 'm'];
    if (l == null || _norm(l.text) != _norm(t.tl)) return null;
    return l;
  }

  /// 녹음을 끝까지 재생. 녹음이 없거나 실패하면 false(부르는 쪽이 TTS 로 넘긴다).
  Future<bool> play(String episodeId, DialogueTurn t, {double rate = 1.0}) async {
    final l = await line(episodeId, t);
    if (l == null || _base.isEmpty) return false;
    final my = ++_gen;
    try {
      await TtsService.instance.stop();
      final p = _player ??= AudioPlayer();
      await p.stop();
      _wait?.complete();
      final done = _wait = Completer<void>();
      final sub = p.onPlayerComplete.listen((_) {
        if (!done.isCompleted) done.complete();
      });
      try {
        await p.setPlaybackRate(rate);
        await p.play(UrlSource('$_base/${l.key}')).timeout(const Duration(seconds: 12));
        if (my != _gen) return true;
        await p.setPlaybackRate(rate);
        await done.future.timeout(Duration(milliseconds: (l.ms / rate).round() + 6000), onTimeout: () {});
      } finally {
        await sub.cancel();
      }
      return true;
    } catch (e) {
      debugPrint('DialogueAudio: 재생 실패 $episodeId/${t.num} $e');
      return false;
    }
  }

  Future<void> stop() async {
    _gen++;
    final w = _wait;
    if (w != null && !w.isCompleted) w.complete();
    try {
      await _player?.stop();
    } catch (_) {}
    await TtsService.instance.stop();
  }
}

/// 턴 하나 읽기: 녹음이 있으면 녹음, 없으면 기기 TTS. rate = 재생 패널 속도(1.0 기준).
Future<void> speakTurn(Dialogue d, DialogueTurn t, {double rate = 1.0}) async {
  if (await DialogueAudio.instance.play(d.id, t, rate: rate)) return;
  final s = t.tl.replaceAll(RegExp(r'\([^)]*\)'), '').replaceAll(RegExp(r'\{[a-z_]+\}'), '').trim();
  await TtsService.instance.speakAs(s, gender: d.voiceGender(t.speaker), rate: rate * 0.45);
}
