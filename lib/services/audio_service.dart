import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal() {
    _initTts();
  }

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  Map<String, String>? _maleVoice;
  Map<String, String>? _femaleVoice;

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("ja-JP");
      await _flutterTts.setVolume(1.0);
      await _flutterTts.awaitSpeakCompletion(true);

      final List<dynamic>? voices = await _flutterTts.getVoices;
      if (voices != null) {
        for (var v in voices) {
          final Map<String, dynamic> voiceMap = Map<String, dynamic>.from(v as Map);
          final String name = (voiceMap['name'] ?? '').toString().toLowerCase();
          final String locale = (voiceMap['locale'] ?? '').toString();

          if (locale.startsWith('ja')) {
            if (name.contains('male') || name.contains('jad') || name.contains('jab') || name.contains('ja-jp-x-htm')) {
              _maleVoice ??= {"name": voiceMap['name'], "locale": locale};
            } else {
              _femaleVoice ??= {"name": voiceMap['name'], "locale": locale};
            }
          }
        }
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint("TTS initialization failed: $e");
    }
  }

  Future<void> speak(String text, String character, {String locale = "ja-JP"}) async {
    try {
      await _flutterTts.stop();

      if (!_isInitialized) {
        await _initTts();
      }

      await _flutterTts.setLanguage(locale);

      if (character.contains("Luffy") || character == "Monkey D. Luffy") {
        if (_maleVoice != null) {
          await _flutterTts.setVoice(_maleVoice!);
        }
        await _flutterTts.setPitch(0.85);
        await _flutterTts.setSpeechRate(0.55);

      } else if (character.contains("Nezuko") || character == "Nezuko Kamado") {
        if (_femaleVoice != null) {
          await _flutterTts.setVoice(_femaleVoice!);
        }
        await _flutterTts.setPitch(1.35);
        await _flutterTts.setSpeechRate(0.42);

      } else {
        if (_maleVoice != null) {
          await _flutterTts.setVoice(_maleVoice!);
        }
        await _flutterTts.setPitch(0.65); 
        await _flutterTts.setSpeechRate(0.48);
      }

      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("TTS playback error: $e");
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint("TTS stop error: $e");
    }
  }
}