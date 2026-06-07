import 'package:flutter_tts/flutter_tts.dart';

/// 러시아어 음성 합성 — 차분한 학습용 속도.
///
/// 한 번에 하나씩만 재생(이전 재생 중단). ru-RU 음성이 기기에 없으면
/// [available]=false 로 떨어져 화면에서 안내할 수 있다.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _inited = false;
  bool available = true;

  Future<void> _init() async {
    if (_inited) return;
    _inited = true;
    try {
      final langs = (await _tts.getLanguages) as List?;
      available = langs == null ||
          langs.any((l) => l.toString().toLowerCase().startsWith('ru'));
      await _tts.setLanguage('ru-RU');
      await _tts.setSpeechRate(0.42); // 학습자용 느린 속도
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {
      available = false;
    }
  }

  /// 강세 기호(´)는 제거해 합성기 호환을 높인다.
  /// [delay] — 자동 재생 시 읽을 시간을 주기 위한 지연(수동 탭은 0).
  Future<void> speak(String text, {Duration delay = Duration.zero}) async {
    await _init();
    final clean = text.replaceAll('́', '').trim();
    if (clean.isEmpty) return;
    await _tts.stop();
    if (delay > Duration.zero) await Future.delayed(delay);
    await _tts.speak(clean);
  }

  Future<void> stop() => _tts.stop();
}
