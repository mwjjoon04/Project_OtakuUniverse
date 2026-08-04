import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';


class AudioService {

  // ============================================================
  // Audio Player
  // ============================================================

  final AudioPlayer _audioPlayer =
      AudioPlayer();


  // ============================================================
  // Python FastAPI Backend
  //
  // Android Emulator:
  // 10.0.2.2 = Windows Host Computer
  // ============================================================

  final String _backendRvcUrl =
      "http://10.0.2.2:8000/api/voice-clone";


  // ============================================================
  // HTTP Timeout
  //
  // Applio 可能需要比较长时间
  // ============================================================

  static const Duration _requestTimeout =
      Duration(seconds: 240);


  // ============================================================
  // Cache Directory
  // ============================================================

  Directory? _cacheDirectory;


  // ============================================================
  // Request Counter
  //
  // 防止快速连续点击播放时，
  // 旧 Request 完成后覆盖最新播放
  // ============================================================

  int _requestVersion = 0;


  // ============================================================
  // Get Cache Directory
  // ============================================================

  Future<Directory> _getCacheDirectory() async {

    if (_cacheDirectory != null) {

      return _cacheDirectory!;

    }


    final Directory appDirectory =
        await getApplicationDocumentsDirectory();


    final Directory audioCacheDirectory =
        Directory(

      "${appDirectory.path}/rvc_audio_cache",

    );


    if (!await audioCacheDirectory.exists()) {

      await audioCacheDirectory.create(
        recursive: true,
      );

    }


    _cacheDirectory =
        audioCacheDirectory;


    debugPrint(
      "📦 [Audio Cache Directory]"
    );

    debugPrint(
      audioCacheDirectory.path
    );


    return audioCacheDirectory;

  }


  // ============================================================
  // Create Cache Key
  //
  // 相同：
  //
  // Character
  // +
  // Pitch
  // +
  // Text
  //
  // = 相同 Cache
  // ============================================================

  String _createCacheKey(

    String text,

    String character,

    int pitch,

  ) {

    final String rawKey =

        "$character|$pitch|${text.trim()}";


    int hash = 0;


    for (

      int i = 0;

      i < rawKey.length;

      i++

    ) {

      hash =

          0x1fffffff &

          (

            hash +

            rawKey.codeUnitAt(i)

          );


      hash =

          0x1fffffff &

          (

            hash +

            (

              (0x0007ffff & hash)

              << 10

            )

          );


      hash ^=

          (

            hash >> 6

          );

    }


    hash =

        0x1fffffff &

        (

          hash +

          (

            (0x03ffffff & hash)

            << 3

          )

        );


    hash ^=

        (

          hash >> 11

        );


    hash =

        0x1fffffff &

        (

          hash +

          (

            (0x00003fff & hash)

            << 15

          )

        );


    return hash

        .toUnsigned(32)

        .toRadixString(16);

  }


  // ============================================================
  // Get Cache File
  // ============================================================

  Future<File> _getCacheFile(

    String text,

    String character,

    int pitch,

  ) async {

    final Directory cacheDirectory =

        await _getCacheDirectory();


    final String cacheKey =

        _createCacheKey(

      text,

      character,

      pitch,

    );


    return File(

      "${cacheDirectory.path}/"

      "${character}_${pitch}_$cacheKey.wav",

    );

  }


  // ============================================================
  // Speak
  // ============================================================

  Future<void> speak(

    String text,

    String characterName, {

    String locale = "ja-JP",

  }) async {

    // ==========================================================
    // Generate Request Version
    // ==========================================================

    final int currentRequestVersion =

        ++_requestVersion;


    try {

      // ========================================================
      // Stop Previous Audio
      // ========================================================

      await _audioPlayer.stop();


      // ========================================================
      // Validate Text
      // ========================================================

      final String cleanText =
          text.trim();


      if (cleanText.isEmpty) {

        debugPrint(
          "⚠️ [AudioService] Text is empty"
        );

        return;

      }


      // ========================================================
      // Identify Character
      // ========================================================

      String characterKey =
          "tanjiro";


      final String normalizedCharacter =
          characterName.toLowerCase();


      if (

        normalizedCharacter.contains(
          "luffy"
        ) ||

        normalizedCharacter.contains(
          "monkey"
        )

      ) {

        characterKey =
            "luffy";


      } else if (

        normalizedCharacter.contains(
          "tanjiro"
        )

      ) {

        characterKey =
            "tanjiro";


      } else if (

        normalizedCharacter.contains(
          "nezuko"
        )

      ) {

        // 当前 Python 后端还没有 Nezuko 模型
        // 所以这里暂时不要发送 nezuko
        //
        // 如果以后加入 Nezuko 模型，
        // 再加入 CHARACTER_MODEL_MAP

        debugPrint(
          "⚠️ Nezuko 模型目前未配置"
        );

        debugPrint(
          "⚠️ 暂时使用 Tanjiro 模型"
        );

        characterKey =
            "tanjiro";

      }


      // ========================================================
      // Pitch
      // ========================================================

      int pitchShift =
          0;


      if (

        characterKey ==
        "luffy"

      ) {

        pitchShift =
            2;


      } else if (

        characterKey ==
        "tanjiro"

      ) {

        pitchShift =
            -6;

      }


      // ========================================================
      // Get Cache File
      // ========================================================

      final File cacheFile =

          await _getCacheFile(

        cleanText,

        characterKey,

        pitchShift,

      );


      // ========================================================
      // CACHE HIT
      // ========================================================

      if (

        await cacheFile.exists()

      ) {

        final int fileSize =

            await cacheFile.length();


        if (

          fileSize > 44

        ) {

          // ----------------------------------------------------
          // Check Request Version
          // ----------------------------------------------------

          if (

            currentRequestVersion !=
            _requestVersion

          ) {

            debugPrint(
              "⚠️ [CACHE] Request 已过期，取消播放"
            );

            return;

          }


          debugPrint(
            "======================================"
          );

          debugPrint(
            "⚡ [CACHE HIT]"
          );

          debugPrint(
            "🎭 Character: "
            "$characterKey"
          );

          debugPrint(
            "📝 Text: "
            "$cleanText"
          );

          debugPrint(
            "📦 File Size: "
            "$fileSize bytes"
          );

          debugPrint(
            "🚀 直接播放本地缓存"
          );

          debugPrint(
            "======================================"
          );


          await _audioPlayer.play(

            DeviceFileSource(

              cacheFile.path,

            ),

          );


          return;

        }

      }


      // ========================================================
      // CACHE MISS
      // ========================================================

      debugPrint(
        "======================================"
      );

      debugPrint(
        "🌐 [CACHE MISS]"
      );

      debugPrint(
        "🎭 Character: "
        "$characterKey"
      );

      debugPrint(
        "📝 Text: "
        "$cleanText"
      );

      debugPrint(
        "⏳ 请求 Python + Applio"
      );

      debugPrint(
        "======================================"
      );


      // ========================================================
      // Request Body
      // ========================================================

      final Map<String, dynamic> requestBody = {

        "text":
            cleanText,

        "character":
            characterKey,

        "pitch_shift":
            pitchShift,

      };


      // ========================================================
      // HTTP Request
      // ========================================================

      debugPrint(
        "📡 [RVC] Sending request..."
      );


      final http.Response response =

          await http.post(

        Uri.parse(
          _backendRvcUrl,
        ),

        headers: {

          "Content-Type":
              "application/json",

          "Accept":
              "audio/wav",

        },

        body:

            jsonEncode(
              requestBody,
            ),

      ).timeout(

        _requestTimeout,

      );


      // ========================================================
      // Check Request Version
      //
      // 如果用户已经输入新句子，
      // 旧 Request 即使完成也不能播放
      // ========================================================

      if (

        currentRequestVersion !=
        _requestVersion

      ) {

        debugPrint(
          "⚠️ [RVC] 当前 Request 已过期"
        );

        debugPrint(
          "⚠️ 不播放旧 Request 的音频"
        );

        return;

      }


      // ========================================================
      // HTTP 200
      // ========================================================

      if (

        response.statusCode ==
        200

      ) {

        final Uint8List audioBytes =

            response.bodyBytes;


        debugPrint(
          "✅ [RVC] Audio received"
        );

        debugPrint(
          "📦 Size: "
          "${audioBytes.length} bytes"
        );


        // ======================================================
        // Validate Audio
        // ======================================================

        if (

          audioBytes.length <=
          44

        ) {

          debugPrint(
            "❌ Audio file 太小"
          );

          return;

        }


        // ======================================================
        // Save Cache
        // ======================================================

        debugPrint(
          "💾 [CACHE] Saving audio..."
        );


        await cacheFile.writeAsBytes(

          audioBytes,

          flush: true,

        );


        debugPrint(
          "✅ [CACHE] Audio saved"
        );

        debugPrint(
          cacheFile.path
        );


        // ======================================================
        // Final Request Check
        // ======================================================

        if (

          currentRequestVersion !=
          _requestVersion

        ) {

          debugPrint(
            "⚠️ 用户已经请求新的音频"
          );

          debugPrint(
            "⚠️ 当前旧音频只保存 Cache，不播放"
          );

          return;

        }


        // ======================================================
        // Play
        // ======================================================

        debugPrint(
          "🔊 [PLAY] Playing RVC audio..."
        );


        await _audioPlayer.play(

          BytesSource(

            audioBytes,

          ),

        );


        debugPrint(
          "🎉 [SUCCESS] RVC audio playing!"
        );


      } else {

        // ======================================================
        // HTTP Error
        // ======================================================

        debugPrint(
          "❌ [Python Backend Error]"
        );

        debugPrint(
          "Status: "
          "${response.statusCode}"
        );

        debugPrint(
          "Body:"
        );

        debugPrint(
          response.body
        );

      }


    // ==========================================================
    // Timeout
    // ==========================================================

    } on TimeoutException catch (e) {

      debugPrint(
        "❌ [TIMEOUT]"
      );

      debugPrint(
        "Python RVC 超过 "
        "${_requestTimeout.inSeconds} 秒"
      );

      debugPrint(
        "$e"
      );


    // ==========================================================
    // HTTP Client Exception
    // ==========================================================

    } on http.ClientException catch (e) {

      debugPrint(
        "❌ [HTTP Client Error]"
      );

      debugPrint(
        "$e"
      );


    // ==========================================================
    // Other Exception
    // ==========================================================

    } catch (

      e,

      stackTrace

    ) {

      debugPrint(
        "❌ [AudioService Error]"
      );

      debugPrint(
        "Error: $e"
      );

      debugPrint(
        "StackTrace:"
      );

      debugPrint(
        stackTrace.toString()
      );

    }

  }


  // ============================================================
  // Stop Audio
  // ============================================================

  Future<void> stop() async {

    // 让正在进行的 Request 失效

    _requestVersion++;


    try {

      await _audioPlayer.stop();


      debugPrint(
        "⏹️ [Audio] Stopped"
      );


    } catch (e) {

      debugPrint(
        "❌ Stop Audio Error: $e"
      );

    }

  }


  // ============================================================
  // Clear All Cache
  // ============================================================

  Future<void> clearAudioCache() async {

    try {

      final Directory cacheDirectory =

          await _getCacheDirectory();


      if (

        await cacheDirectory.exists()

      ) {

        await cacheDirectory.delete(

          recursive: true,

        );


        _cacheDirectory =
            null;


        debugPrint(
          "🗑️ [CACHE] All audio cache deleted"
        );

      }


    } catch (e) {

      debugPrint(
        "❌ Clear Cache Error: $e"
      );

    }

  }


  // ============================================================
  // Dispose
  // ============================================================

  Future<void> dispose() async {

    try {

      await _audioPlayer.dispose();


      debugPrint(
        "🧹 AudioPlayer disposed"
      );


    } catch (e) {

      debugPrint(
        "❌ Dispose Error: $e"
      );

    }

  }

}