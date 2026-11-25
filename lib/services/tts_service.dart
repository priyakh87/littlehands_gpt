import 'package:flutter_tts/flutter_tts.dart';

enum NarrationSpeed { slow, normal, fast }

/// On-device text-to-speech only. No cloud call, no API key, no audio
/// ever recorded or sent anywhere — this just reads fixed script text
/// using the phone's built-in speech engine.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05); // slightly higher pitch reads as warmer
    _initialized = true;
  }

  double _rateFor(NarrationSpeed speed) {
    switch (speed) {
      case NarrationSpeed.slow:
        return 0.35;
      case NarrationSpeed.normal:
        return 0.5;
      case NarrationSpeed.fast:
        return 0.65;
    }
  }

  /// [locale]: 'en-US' or 'ar-SA' (or 'ar-AE' for Gulf Arabic phonetics).
  Future<void> speak(
    String text, {
    String locale = 'en-US',
    NarrationSpeed speed = NarrationSpeed.normal,
  }) async {
    await _ensureInit();
    await _tts.stop(); // cancel anything currently speaking first
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(_rateFor(speed));
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
