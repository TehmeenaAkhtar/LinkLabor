import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static FlutterTts? _tts;
  static bool _initialized = false;

  static Future<void> _init() async {
    if (_initialized) return;

    _tts = FlutterTts();

    await _tts!.setLanguage("ur-PK");
    await _tts!.setSpeechRate(0.5);
    await _tts!.setVolume(1.0);
    await _tts!.setPitch(1.0);
    _initialized = true;
  }

  static Future<void> speak(String urduText) async {
    await _init();
    await _tts!.stop();
    await _tts!.speak(urduText);
  }

  static Future<void> stop() async {
    await _tts?.stop();
  }
}