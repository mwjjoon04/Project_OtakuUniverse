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

      // 🔍 自动检索系统内所有可用的日文语音包
      final List<dynamic>? voices = await _flutterTts.getVoices;
      if (voices != null) {
        for (var v in voices) {
          final Map<String, dynamic> voiceMap = Map<String, dynamic>.from(v as Map);
          final String name = (voiceMap['name'] ?? '').toString().toLowerCase();
          final String locale = (voiceMap['locale'] ?? '').toString();

          if (locale.startsWith('ja')) {
            // Google TTS 中通常包含 'jab'、'jad' 或 'male' 的为男声
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
      debugPrint("TTS 初始化失败: $e");
    }
  }

  /// 播放指定角色的 TTS 语音
  Future<void> speak(String text, String character, {String locale = "ja-JP"}) async {
    try {
      await _flutterTts.stop();

      if (!_isInitialized) {
        await _initTts();
      }

      await _flutterTts.setLanguage(locale);

      if (character.contains("Luffy") || character == "Monkey D. Luffy") {
        // 🍖 路飞：切换男声包 + 少年音调 (0.85) + 稍快语速
        if (_maleVoice != null) {
          await _flutterTts.setVoice(_maleVoice!);
        }
        await _flutterTts.setPitch(0.85);
        await _flutterTts.setSpeechRate(0.55);

      } else if (character.contains("Nezuko") || character == "Nezuko Kamado") {
        // 🎀 祢豆子：女声包 + 柔和高音调 (1.35) + 慢语速
        if (_femaleVoice != null) {
          await _flutterTts.setVoice(_femaleVoice!);
        }
        await _flutterTts.setPitch(1.35);
        await _flutterTts.setSpeechRate(0.42);

      } else {
        // ⚔️ 炭治郎 (默认)：切换男声包 + 低沉雄浑音调 (0.65) + 标准语速
        if (_maleVoice != null) {
          await _flutterTts.setVoice(_maleVoice!);
        }
        await _flutterTts.setPitch(0.65); // 显著拉低音调，呈现厚重男声
        await _flutterTts.setSpeechRate(0.48);
      }

      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("TTS 播放出错: $e");
    }
  }

  /// 停止播放
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint("TTS 停止出错: $e");
    }
  }
}