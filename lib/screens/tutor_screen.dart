import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import '../services/audio_service.dart';          
import '../widgets/sign_language_translator.dart'; 

// 轻量级导航外壳
class TutorScreen extends StatelessWidget {
  const TutorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NihongoAudioTutorWidget();
  }
}

class NihongoAudioTutorWidget extends StatefulWidget {
  const NihongoAudioTutorWidget({super.key});
  
  @override
  State<NihongoAudioTutorWidget> createState() => _NihongoAudioTutorWidgetState();
}

class _NihongoAudioTutorWidgetState extends State<NihongoAudioTutorWidget> {
  final AudioService _audioService = AudioService(); 
  
  bool _isPlaying = false;
  bool _isNezukoSigning = false; 

  Timer? _mockTimer;
  int _elapsedMilliseconds = 0;
  int _totalMockDurationMs = 4000; 

  String _selectedCharacter = 'Tanjiro Kamado';
  String _selectedLanguage = 'English (EN)'; 

  List<String> _jpWords = ["全集中！", "今日", "の稽古", "を始め", "ましょう！"];
  List<String> _romajiWords = ["Zen ", "shuu ", "chuu! ", "Kyou ", "no ", "keiko ", "o ", "hajimemashou!"];
  
  Map<String, String> _currentTranslations = {
    'English (EN)': "Total concentration! Let's start today's training!",
    'Chinese (ZH)': "全神贯注！开始今天的训练吧！",
    'Malay (MS)': "Konsentrasi penuh! Mari mulakan latihan hari ini!"
  };

  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    String japaneseText = _jpWords.join('');
    
    double speechRate = 0.5; 
    if (_selectedCharacter == 'Nezuko') speechRate = 0.4; 
    if (_selectedCharacter == 'Luffy') speechRate = 0.6;   

    int msPerChar = (130 / speechRate).round(); 
    int calculatedDuration = (japaneseText.length * msPerChar) + 600;

    if (_selectedCharacter == 'Nezuko') {
      calculatedDuration = 6000; 
    }

    setState(() {
      _isPlaying = true;
      _elapsedMilliseconds = 0;
      _totalMockDurationMs = calculatedDuration; 
      if (_selectedCharacter == 'Nezuko') {
        _isNezukoSigning = true;
      }
    });

    String mappedCharacterName = "Tanjiro Kamado";
    if (_selectedCharacter == 'Nezuko') mappedCharacterName = "Nezuko Kamado";
    if (_selectedCharacter == 'Luffy') mappedCharacterName = "Monkey D. Luffy";

    if (_selectedCharacter != 'Nezuko') {
      _audioService.speak(japaneseText, mappedCharacterName, locale: "ja-JP");
    }

    _mockTimer?.cancel();
    _mockTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedMilliseconds += 50;
        if (_elapsedMilliseconds >= _totalMockDurationMs) {
          _stopPlayback();
        }
      });
    });
  }

  void _stopPlayback() {
    _mockTimer?.cancel();
    _audioService.stop(); 
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _isNezukoSigning = false; 
        _elapsedMilliseconds = 0; 
      });
    }
  }

  Future<void> _handleTranslate() async {
    String text = _inputController.text.trim();
    if (text.isEmpty) return;

    _stopPlayback();

    setState(() {
      _jpWords = ["翻", "译", "中", "..."];
      _romajiWords = ["Translating..."];
      _currentTranslations = {
        'English (EN)': "Translating in real-time...",
        'Chinese (ZH)': "正在实时翻译中...",
        'Malay (MS)': "Sedang menterjemah..."
      };
    });

    _inputController.clear();
    FocusScope.of(context).unfocus();

    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=ja&dt=t&dt=rm&q=${Uri.encodeComponent(text)}'
      );
      
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, Gecko) Chrome/120.0.0.0'
      });

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        String translatedJp = "";
        String romajiString = "";

        if (jsonData.isNotEmpty && jsonData[0] != null) {
          final List<dynamic> blocks = jsonData[0];
          
          for (var block in blocks) {
            if (block != null && block is List && block.isNotEmpty) {
              if (block[0] != null && block[1] != null) {
                translatedJp += block[0].toString();
              }
            }
          }
          
          for (var block in blocks) {
            if (block != null && block is List && block.length >= 3) {
              if (block[0] == null && block[2] != null) {
                romajiString = block[2].toString();
                break;
              }
            }
          }
        }

        if (romajiString.isEmpty || !RegExp(r'[a-zA-Z]').hasMatch(romajiString)) {
          String lowerInput = text.toLowerCase();
          if (lowerInput.contains("hello") || lowerInput.contains("你好")) {
            romajiString = "Konnichiwa";
          } else if (lowerInput.contains("thank you") || lowerInput.contains("谢谢")) {
            romajiString = "Arigatou gozaimasu";
          } else if (lowerInput.contains("goodbye") || lowerInput.contains("再见")) {
            romajiString = "Sayounara";
          } else {
            romajiString = "Nihongo dojo gaku-shuu";
          }
        }

        List<String> jpSegments = [];
        for (int i = 0; i < translatedJp.length; i++) {
          jpSegments.add(translatedJp[i]);
        }

        List<String> romajiSegments = romajiString.split(' ').where((e) => e.isNotEmpty).map((e) => "$e ").toList();

        if (mounted) {
          setState(() {
            _jpWords = jpSegments;
            _romajiWords = romajiSegments;
            _currentTranslations = {
              'English (EN)': "Translation of: \"$text\"",
              'Chinese (ZH)': "以下文字的翻译结果: \"$text\"",
              'Malay (MS)': "Terjemahan untuk: \"$text\""
            };
          });
        }
      } else {
        throw Exception("Server status code: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("API 异常: $e");
      String lowerInput = text.toLowerCase();
      String localJp = "翻译出错";
      String localRm = "Han'yaku era-";

      if (lowerInput.contains("hello") || lowerInput.contains("你好")) {
        localJp = "こんにちは"; localRm = "Konnichiwa";
      } else if (lowerInput.contains("thank you") || lowerInput.contains("谢谢")) {
        localJp = "ありがとう"; localRm = "Arigatou";
      } else if (lowerInput.contains("goodbye") || lowerInput.contains("再见")) {
        localJp = "さようなら"; localRm = "Sayounara";
      }

      if (mounted) {
        setState(() {
          _jpWords = localJp.split('');
          _romajiWords = localRm.split(' ').map((e) => "$e ").toList();
          _currentTranslations = {
            'English (EN)': "Result of: \"$text\"",
            'Chinese (ZH)': "翻译结果为: \"$text\"",
            'Malay (MS)': "Keputusan untuk: \"$text\""
          };
        });
      }
    }
  }

  // 泛型通用卡片列表渲染组件
  Widget _buildVerticalListRow(List<Map<String, dynamic>> phrases) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: phrases.map((phrase) {
        final String localizedLabel = (phrase['label'] as Map<String, String>)[_selectedLanguage] 
            ?? (phrase['label'] as Map<String, String>)['English (EN)']!;

        return Container(
          width: double.infinity, 
          margin: const EdgeInsets.only(bottom: 8), 
          child: Card(
            color: Colors.white.withOpacity(0.09), 
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Colors.white.withOpacity(0.28), 
                width: 1.5,
              ),
            ),
            margin: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _stopPlayback();
                setState(() {
                  _jpWords = List<String>.from(phrase['jp']);
                  _romajiWords = List<String>.from(phrase['romaji']);
                  _currentTranslations = Map<String, String>.from(phrase['trans']);
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        localizedLabel, 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 14, 
                          fontWeight: FontWeight.bold
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios, 
                      color: Colors.white30, 
                      size: 13
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 安全占位符头像组件
  Widget _buildSafeDropdownAvatar(String imagePath) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.white10,
              child: const Icon(Icons.account_circle, size: 18, color: Colors.white38),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progressFraction = _elapsedMilliseconds / _totalMockDurationMs;
    if (progressFraction > 1.0) progressFraction = 1.0;

    int currentJpIndex = -1;
    int currentRomajiIndex = -1;

    if (_isPlaying && _elapsedMilliseconds > 0) {
      currentJpIndex = (progressFraction * _jpWords.length).floor();
      currentRomajiIndex = (progressFraction * _romajiWords.length).floor();
      
      if (currentJpIndex >= _jpWords.length) currentJpIndex = _jpWords.length - 1;
      if (currentRomajiIndex >= _romajiWords.length) currentRomajiIndex = _romajiWords.length - 1;
    }

    bool isChinese = _selectedLanguage == 'Chinese (ZH)';
    bool isMalay = _selectedLanguage == 'Malay (MS)';

    // 主标题多语言联动映射
    String mainTitleText = '';
    if (_selectedCharacter == 'Nezuko') {
      if (isChinese) {
        mainTitleText = '手语学习';
      } else if (isMalay) {
        mainTitleText = 'Pembelajaran Bahasa Isyarat';
      } else {
        mainTitleText = 'Sign Language Learning';
      }
    } else {
      if (isChinese) {
        mainTitleText = '日语学习';
      } else if (isMalay) {
        mainTitleText = 'Pembelajaran Bahasa Jepun';
      } else {
        mainTitleText = 'Japanese Learning';
      }
    }

    // 🚀【大升级】：折叠菜单大标题也全额接入多语言动态联动路由矩阵
    String phrasesTitle = '';
    if (isChinese) {
      phrasesTitle = '💡 推荐基本用语';
    } else if (isMalay) {
      phrasesTitle = '💡 Ungkapan Disyorkan';
    } else {
      phrasesTitle = '💡 Recommended Phrases';
    }

    String wordsTitle = '';
    if (isChinese) {
      wordsTitle = '💡 手语单字';
    } else if (isMalay) {
      wordsTitle = '💡 Perkataan Bahasa Isyarat';
    } else {
      wordsTitle = '💡 Sign Language Words';
    }

    String sentencesTitle = '';
    if (isChinese) {
      sentencesTitle = '💬 手语句子';
    } else if (isMalay) {
      sentencesTitle = '💬 Ayat Bahasa Isyarat';
    } else {
      sentencesTitle = '💬 Sign Language Sentences';
    }

    String customInputTitle = isChinese ? '✍️ 自定义输入翻译去日语' : (isMalay ? '✍️ Terjemah ke Bahasa Jepun' : '✍️ Translate anything to Japanese');
    String hintText = isChinese ? '输入任何文字，开始翻译学习...' : (isMalay ? 'Taip untuk mula belajar...' : 'Type anything to start learning...');

    // 数据源字典
    final List<Map<String, dynamic>> nezukoPhrases = [
      {
        "type": "word", 
        "label": {'English (EN)': "👋 hello", 'Chinese (ZH)': "👋 你好", 'Malay (MS)': "👋 halo"},
        "jp": ["こんにちは"], "romaji": ["Konnichiwa "],
        "trans": {'English (EN)': "Hello", 'Chinese (ZH)': "你好", 'Malay (MS)': "Halo"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "👿 angry", 'Chinese (ZH)': "👿 生气", 'Malay (MS)': "👿 marah"},
        "jp": ["怒る"], "romaji": ["Okoru "],
        "trans": {'English (EN)': "Angry", 'Chinese (ZH)': "生气", 'Malay (MS)': "Marah"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "📞 call", 'Chinese (ZH)': "📞 打电话", 'Malay (MS)': "📞 telefon"},
        "jp": ["電話する"], "romaji": ["Denwa suru "],
        "trans": {'English (EN)': "Call", 'Chinese (ZH)': "打电话", 'Malay (MS)': "Telefon"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "😢 cry", 'Chinese (ZH)': "😢 哭泣", 'Malay (MS)': "😢 menangis"},
        "jp": ["泣く"], "romaji": ["Naku "],
        "trans": {'English (EN)': "Cry", 'Chinese (ZH)': "哭泣", 'Malay (MS)': "Menangis"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "😊 happy", 'Chinese (ZH)': "😊 高兴", 'Malay (MS)': "😊 gembira"},
        "jp": ["嬉しい"], "romaji": ["Ureshii "],
        "trans": {'English (EN)': "Happy", 'Chinese (ZH)': "高兴", 'Malay (MS)': "Gembira"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "💵 money", 'Chinese (ZH)': "💵 钱", 'Malay (MS)': "💵 wang"},
        "jp": ["お金"], "romaji": ["Okane "],
        "trans": {'English (EN)': "Money", 'Chinese (ZH)': "钱", 'Malay (MS)': "Wang"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "😭 sad", 'Chinese (ZH)': "😭 悲伤", 'Malay (MS)': "😭 sedih"},
        "jp": ["悲しい"], "romaji": ["Kanashii "],
        "trans": {'English (EN)': "Sad", 'Chinese (ZH)': "悲伤", 'Malay (MS)': "Sedih"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "🚽 toilet", 'Chinese (ZH)': "🚽 厕所", 'Malay (MS)': "🚽 tandas"},
        "jp": ["トイレ"], "romaji": ["Toire "],
        "trans": {'English (EN)': "Toilet", 'Chinese (ZH)': "厕所", 'Malay (MS)': "Tandas"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "✨ goodbye", 'Chinese (ZH)': "✨ 再见", 'Malay (MS)': "✨ selamat tinggal"},
        "jp": ["さようなら"], "romaji": ["Sayounara "],
        "trans": {'English (EN)': "Good Bye", 'Chinese (ZH)': "再见", 'Malay (MS)': "Selamat tinggal"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "👌 fine", 'Chinese (ZH)': "👌 我没事", 'Malay (MS)': "👌 saya ok"},
        "jp": ["大丈夫"], "romaji": ["Daijoubu "],
        "trans": {'English (EN)': "Fine", 'Chinese (ZH)': "我没事", 'Malay (MS)': "Saya ok"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "🆘 help", 'Chinese (ZH)': "🆘 帮我", 'Malay (MS)': "🆘 tolong"},
        "jp": ["手伝って"], "romaji": ["Tetsudatte "],
        "trans": {'English (EN)': "Help", 'Chinese (ZH)': "帮我", 'Malay (MS)': "Tolong"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "👩 mom", 'Chinese (ZH)': "👩 妈妈", 'Malay (MS)': "👩 ibu"},
        "jp": ["お母さん"], "romaji": ["Okaasan "],
        "trans": {'English (EN)': "Mom", 'Chinese (ZH)': "妈妈", 'Malay (MS)': "Ibu"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "👨 dad", 'Chinese (ZH)': "👨 爸爸", 'Malay (MS)': "👨 bapa"},
        "jp": ["お父さん"], "romaji": ["Otouasan "],
        "trans": {'English (EN)': "Dad", 'Chinese (ZH)': "爸爸", 'Malay (MS)': "Bapa"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "🙏 please", 'Chinese (ZH)': "🙏 请", 'Malay (MS)': "🙏 sila"},
        "jp": ["お願いします"], "romaji": ["Onegaishimasu "],
        "trans": {'English (EN)': "Please", 'Chinese (ZH)': "请", 'Malay (MS)': "Sila"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "🍎 eat", 'Chinese (ZH)': "🍎 吃", 'Malay (MS)': "🍎 makan"},
        "jp": ["食べる"], "romaji": ["Taberu "],
        "trans": {'English (EN)': "Eat", 'Chinese (ZH)': "吃", 'Malay (MS)': "Makan"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "🥛 drink", 'Chinese (ZH)': "🥛 喝", 'Malay (MS)': "🥛 minum"},
        "jp": ["飲む"], "romaji": ["Nomu "],
        "trans": {'English (EN)': "Drink", 'Chinese (ZH)': "喝", 'Malay (MS)': "Minum"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "😢 sorry", 'Chinese (ZH)': "😢 对不起", 'Malay (MS)': "😢 maaf"},
        "jp": ["ごめんなさい"], "romaji": ["Gomennasai "],
        "trans": {'English (EN)': "Sorry", 'Chinese (ZH)': "对不起", 'Malay (MS)': "Maaf"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "✅ yes", 'Chinese (ZH)': "✅ 是的", 'Malay (MS)': "✅ ya"},
        "jp": ["はい"], "romaji": ["Hai "],
        "trans": {'English (EN)': "Yes", 'Chinese (ZH)': "是的", 'Malay (MS)': "Ya"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "❌ no", 'Chinese (ZH)': "❌ 不要", 'Malay (MS)': "❌ tidak"},
        "jp": ["いいえ"], "romaji": ["Iie "],
        "trans": {'English (EN)': "No", 'Chinese (ZH)': "不要", 'Malay (MS)': "Tidak"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "🚶 go", 'Chinese (ZH)': "🚶 去", 'Malay (MS)': "🚶 pergi"},
        "jp": ["行く"], "romaji": ["Iku "],
        "trans": {'English (EN)': "Go", 'Chinese (ZH)': "去", 'Malay (MS)': "Pergi"}
      },
      {
        "type": "word", 
        "label": {'English (EN)': "🛑 stop", 'Chinese (ZH)': "🛑 停", 'Malay (MS)': "🛑 berhenti"},
        "jp": ["止まって"], "romaji": ["Tomatte "],
        "trans": {'English (EN)': "Stop", 'Chinese (ZH)': "停", 'Malay (MS)': "Berhenti"}
      },

      // —— Sentences ——
      {
        "type": "sentence", 
        "label": {'English (EN)': "❓ how are you", 'Chinese (ZH)': "❓ 你好吗？", 'Malay (MS)': "❓ apa khabar?"},
        "jp": ["お元気ですか"], "romaji": ["Ogenki desu ka "],
        "trans": {'English (EN)': "How are you", 'Chinese (ZH)': "你好吗？", 'Malay (MS)': "Apa khabar?"}
      },
      {
        "type": "sentence", 
        "label": {'English (EN)': "✈️ i love travelling around", 'Chinese (ZH)': "✈️ 我喜欢到处旅游", 'Malay (MS)': "✈️ saya suka melancong"},
        "jp": ["旅行が大好きです"], "romaji": ["Ryokou ga daisuki desu "],
        "trans": {'English (EN)': "I love travelling around", 'Chinese (ZH)': "我喜欢到处旅游", 'Malay (MS)': "Saya suka melancong"}
      },
      {
        "type": "sentence", 
        "label": {'English (EN)': "💰 how much is it", 'Chinese (ZH)': "💰 多少钱？", 'Malay (MS)': "💰 berapakah harganya?"},
        "jp": ["いくらですか"], "romaji": ["Ikura desu ka "],
        "trans": {'English (EN)': "How much is it", 'Chinese (ZH)': "多少钱？", 'Malay (MS)': "Berapakah harganya?"}
      },
      {
        "type": "sentence", 
        "label": {'English (EN)': "🛍️ i am going shopping", 'Chinese (ZH)': "🛍️ 我去购物", 'Malay (MS)': "🛍️ saya pergi membeli-belah"},
        "jp": ["買い物に行きます"], "romaji": ["Kaimono ni ikimasu "],
        "trans": {'English (EN)': "I am going shopping", 'Chinese (ZH)': "我去购物", 'Malay (MS)': "Saya pergi membeli-belah"}
      },
      {
        "type": "sentence", 
        "label": {'English (EN)': "🏠 i have to go home", 'Chinese (ZH)': "🏠 我得回家了", 'Malay (MS)': "🏠 saya mesti pulang"},
        "jp": ["家に帰ります"], "romaji": ["Ie ni kaerimasu "],
        "trans": {'English (EN)': "I have to go home", 'Chinese (ZH)': "我得回家了", 'Malay (MS)': "Saya mesti pulang"}
      },
      {
        "type": "sentence", 
        "label": {'English (EN)': "🍫 i like chocolate", 'Chinese (ZH)': "🍫 我喜欢巧克力", 'Malay (MS)': "🍫 saya suka coklat"},
        "jp": ["チョコレートが好きです"], "romaji": ["Chokore-to ga suki desu "],
        "trans": {'English (EN)': "I like chocolate", 'Chinese (ZH)': "我喜欢巧克力", 'Malay (MS)': "Saya suka coklat"}
      },
      {
        "type": "sentence", 
        "label": {'English (EN)': "❤️ i love you", 'Chinese (ZH)': "❤️ 我爱你", 'Malay (MS)': "❤️ saya cintakan mu"},
        "jp": ["愛しています"], "romaji": ["Aishiteru "],
        "trans": {'English (EN)': "I love you", 'Chinese (ZH)': "我爱你", 'Malay (MS)': "Saya cintakan mu"}
      },
      {
        "type": "sentence", 
        "label": {'English (EN)': "⏰ what time is it", 'Chinese (ZH)': "⏰ 现在几点？", 'Malay (MS)': "⏰ pukul berapakah sekarang?"},
        "jp": ["何時ですか"], "romaji": ["Nanji desu ka "],
        "trans": {'English (EN)': "What time is it", 'Chinese (ZH)': "现在几点？", 'Malay (MS)': "Pukul berapakah sekarang?"}
      },
      {
        "type": "sentence", 
        "label": {'English (EN)': "📚 are you studying or working", 'Chinese (ZH)': "📚 你在读书还是工作？", 'Malay (MS)': "📚 adakah anda belajar atau bekerja?"},
        "jp": ["勉強か工作か"], "romaji": ["Benkyou ka shigoto ka "],
        "trans": {'English (EN)': "Are you studying or working", 'Chinese (ZH)': "你在读书还是工作？", 'Malay (MS)': "Adakah anda belajar or bekerja?"}
      },
      {
        "type": "sentence", 
        "label": {'English (EN)': "🍛 did you eat", 'Chinese (ZH)': "🍛 你吃了吗？", 'Malay (MS)': "🍛 adakah anda sudah makan?"},
        "jp": ["食べましたか"], "romaji": ["Tabemashita ka "],
        "trans": {'English (EN)': "Did you eat", 'Chinese (ZH)': "你吃了吗？", 'Malay (MS)': "Adakah anda sudah makan?"}
      },
      {
        "type": "sentence", 
        "label": {'English (EN)': "🎂 happy birthday", 'Chinese (ZH)': "🎂 生日快乐", 'Malay (MS)': "🎂 selamat hari jadi"},
        "jp": ["お誕生日おめでとう"], "romaji": ["Otandjoubi omedetou "],
        "trans": {'English (EN)': "Happy Birthday", 'Chinese (ZH)': "生日快乐", 'Malay (MS)': "Selamat hari jadi"}
      },
      {
        "type": "sentence", 
        "label": {'English (EN)': "🏁 all done", 'Chinese (ZH)': "🏁 做好啦", 'Malay (MS)': "🏁 selesai"},
        "jp": ["終わり"], "romaji": ["Owari "],
        "trans": {'English (EN)': "All done", 'Chinese (ZH)': "做好啦", 'Malay (MS)': "Selesai"}
      }
    ];

    final List<Map<String, dynamic>> tanjiroLuffyPhrases = [
      {
        "label": {
          'English (EN)': "👋 Greeting: Hello",
          'Chinese (ZH)': "👋 招呼：你好",
          'Malay (MS)': "👋 Salam: Hello"
        },
        "jp": ["こんにちは"], "romaji": ["Konnichiwa"],
        "trans": {'English (EN)': "Hello", 'Chinese (ZH)': "你好", 'Malay (MS)': "Halo"}
      },
      {
        "label": {
          'English (EN)': "🙏 Gratitude: Thank you",
          'Chinese (ZH)': "🙏 感恩：谢谢",
          'Malay (MS)': "🙏 Penghargaan: Terima Kasih"
        },
        "jp": ["ありがとう", "ございます"], "romaji": ["Arigatou ", "gozaimasu"],
        "trans": {'English (EN)': "Thank you very much", 'Chinese (ZH)': "非常感谢", 'Malay (MS)': "Terima kasih banyak"}
      },
      {
        "label": {
          'English (EN)': "✨ Classic: Goodbye",
          'Chinese (ZH)': "✨ 告别：再见",
          'Malay (MS)': "✨ Selamat Tinggal: Goodbye"
        },
        "jp": ["さようなら"], "romaji": ["Sayounara"],
        "trans": {'English (EN)': "Goodbye", 'Chinese (ZH)': "再见", 'Malay (MS)': "Selamat tinggal"}
      },
      {
        "label": {
          'English (EN)': "🌅 Morning: Good Morning",
          'Chinese (ZH)': "🌅 早晨：早安",
          'Malay (MS)': "🌅 Pagi: Selamat Pagi"
        },
        "jp": ["おはよう"], "romaji": ["Ohayou"],
        "trans": {'English (EN)': "Good Morning", 'Chinese (ZH)': "早安", 'Malay (MS)': "Selamat pagi"}
      },
      {
        "label": {
          'English (EN)': "👍 Confirmation: Yes",
          'Chinese (ZH)': "👍 确认：是的",
          'Malay (MS)': "👍 Pengesahan: Ya"
        },
        "jp": ["はい"], "romaji": ["Hai"],
        "trans": {'English (EN)': "Yes", 'Chinese (ZH)': "是的", 'Malay (MS)': "Ya"}
      },
      {
        "label": {
          'English (EN)': "❌ Negation: No",
          'Chinese (ZH)': "❌ 否定：不是",
          'Malay (MS)': "❌ Penafian: Tidak"
        },
        "jp": ["いいえ"], "romaji": ["Iie"],
        "trans": {'English (EN)': "No", 'Chinese (ZH)': "不是", 'Malay (MS)': "Tidak"}
      },
      {
        "label": {
          'English (EN)': "🙇 Apology: Sorry",
          'Chinese (ZH)': "🙇 抱歉：对不起",
          'Malay (MS)': "🙇 Kemaafan: Maaf"
        },
        "jp": ["すみません"], "romaji": ["Sumimasen"],
        "trans": {'English (EN)': "Excuse me / Sorry", 'Chinese (ZH)': "不好意思 / 对不起", 'Malay (MS)': "Maafkan saya"}
      },
      {
        "label": {
          'English (EN)': "🍖 Food: Delicious!",
          'Chinese (ZH)': "🍖 食物：好吃！",
          'Malay (MS)': "🍖 Makanan: Sedap!"
        },
        "jp": ["うまい！"], "romaji": ["Umai!"],
        "trans": {'English (EN)': "Delicious!", 'Chinese (ZH)': "好吃！", 'Malay (MS)': "Sedap!"}
      },
      {
        "label": {
          'English (EN)': "💪 Status: I'm Fine",
          'Chinese (ZH)': "💪 状态：没关系 / 我没事",
          'Malay (MS)': "💪 Status: Saya ok"
        },
        "jp": ["大丈夫"], "romaji": ["Daijoubu"],
        "trans": {'English (EN)': "I'm Fine", 'Chinese (ZH)': "没关系 / 我没事", 'Malay (MS)': "Saya ok"}
      },
      {
        "label": {
          'English (EN)': "🚀 Action: Let's Go!",
          'Chinese (ZH)': "🚀 行动：出发吧！",
          'Malay (MS)': "🚀 Tindakan: Mari pergi!"
        },
        "jp": ["行くぞ"], "romaji": ["Ikuzo"],
        "trans": {'English (EN)': "Let's Go!", 'Chinese (ZH)': "出发吧！", 'Malay (MS)': "Mari pergi!"}
      },
    ];

    final List<Map<String, dynamic>> wordsOnlyList = List<Map<String, dynamic>>.from(
      nezukoPhrases.where((e) => e['type'] == 'word')
    );
    final List<Map<String, dynamic>> sentencesOnlyList = List<Map<String, dynamic>>.from(
      nezukoPhrases.where((e) => e['type'] == 'sentence')
    );

    return Scaffold(
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 100, 
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school_rounded, 
              color: _selectedCharacter == 'Nezuko' ? Colors.amberAccent : Colors.cyanAccent,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              mainTitleText, 
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            _selectedCharacter == 'Nezuko'
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sign_language_rounded, color: Colors.amberAccent, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      '手話の学習', 
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.55),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.translate_rounded, color: Colors.cyanAccent, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      '日本語の学習', 
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.55),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, 
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCharacter,
                        dropdownColor: const Color(0xFF1E1E1E),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        isExpanded: true, 
                        items: [
                          DropdownMenuItem(
                            value: 'Tanjiro Kamado',
                            child: Row(
                              children: [
                                _buildSafeDropdownAvatar('assets/tanjiro.jpg'), 
                                const SizedBox(width: 8), 
                                const Expanded(
                                  child: Text(
                                    'Tanjiro Kamado', 
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Luffy',
                            child: Row(
                              children: [
                                _buildSafeDropdownAvatar('assets/luffy.jpg'),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Monkey D. Luffy', 
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Nezuko',
                            child: Row(
                              children: [
                                _buildSafeDropdownAvatar('assets/nezuko.jpg'),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Nezuko Kamado', 
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _stopPlayback(); 
                            setState(() {
                              _selectedCharacter = value;
                              _isNezukoSigning = false; 

                              if (value == 'Nezuko') {
                                _jpWords = ["こんにちは"];
                                _romajiWords = ["Konnichiwa "];
                                _currentTranslations = {
                                  'English (EN)': "Hello",
                                  'Chinese (ZH)': "你好",
                                  'Malay (MS)': "Halo"
                                };
                              } else {
                                _jpWords = ["全集中！", "今日", "の稽古", "を始め", "ましょう！"];
                                _romajiWords = ["Zen ", "shuu ", "chuu! ", "Kyou ", "no ", "keiko ", "o ", "hajimemashou!"];
                                _currentTranslations = {
                                  'English (EN)': "Total concentration! Let's start today's training!",
                                  'Chinese (ZH)': "全神贯注！开始今天的训练吧！",
                                  'Malay (MS)': "Konsentrasi penuh! Mari mulakan latihan hari ini!"
                                };
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLanguage, 
                        dropdownColor: const Color(0xFF1E1E1E),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'English (EN)', child: Text('🌐 English (EN)', maxLines: 1, overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Chinese (ZH)', child: Text('🌐 Chinese (ZH)', maxLines: 1, overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Malay (MS)', child: Text('🌐 Malay (MS)', maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedLanguage = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity, 
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF161521).withOpacity(0.85), 
                borderRadius: BorderRadius.circular(24), 
                border: Border.all(
                  color: Colors.deepPurpleAccent.withOpacity(0.35), 
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column( 
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center, 
                children: [
                  if (_selectedCharacter != 'Nezuko') ...[
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: List.generate(_jpWords.length, (index) {
                          bool isActive = _isPlaying && (index == currentJpIndex);
                          return TextSpan(
                            text: _jpWords[index],
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.amberAccent : Colors.white.withOpacity(0.9),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(text: "(", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.cyanAccent.withOpacity(0.5))),
                          ...List.generate(_romajiWords.length, (index) {
                            bool isActive = _isPlaying && (index == currentRomajiIndex);
                            return TextSpan(
                              text: _romajiWords[index],
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: isActive ? Colors.cyanAccent : Colors.white38,
                              ),
                            );
                          }),
                          TextSpan(text: ")", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.cyanAccent.withOpacity(0.5))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  if (_selectedCharacter == 'Nezuko') ...[
                    SignLanguageTranslator(
                      text: _currentTranslations['English (EN)'] ?? "",
                      isPlaying: _isNezukoSigning,
                      onComplete: () {
                        _stopPlayback(); 
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text(
                    _currentTranslations[_selectedLanguage] ?? _currentTranslations['English (EN)']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.85), 
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  
                  const SizedBox(height: 18), 
                  
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple.withOpacity(0.15),
                      border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.4), width: 1.5),
                    ),
                    child: IconButton(
                      iconSize: 38, 
                      icon: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.amberAccent, 
                      ),
                      onPressed: _togglePlay,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _selectedCharacter == 'Nezuko'
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent), 
                      child: Card(
                        color: Colors.white.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
                        ),
                        margin: EdgeInsets.zero,
                        child: ExpansionTile(
                          // 🚀【全语言随动】：wordsTitle 完美支持全场景联动响应
                          title: Text(
                            wordsTitle,
                            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          iconColor: Colors.white70,
                          collapsedIconColor: Colors.white70,
                          childrenPadding: const EdgeInsets.all(12),
                          children: [
                            _buildVerticalListRow(wordsOnlyList), 
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: Card(
                        color: Colors.white.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
                        ),
                        margin: EdgeInsets.zero,
                        child: ExpansionTile(
                          // 🚀【全语言随动】：sentencesTitle 完美支持全场景联动响应
                          title: Text(
                            sentencesTitle,
                            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          iconColor: Colors.white70,
                          collapsedIconColor: Colors.white70,
                          childrenPadding: const EdgeInsets.all(12),
                          children: [
                            _buildVerticalListRow(sentencesOnlyList), 
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: Card(
                        color: Colors.white.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
                        ),
                        margin: EdgeInsets.zero,
                        child: ExpansionTile(
                          // 🚀【全语言随动修复】：phrasesTitle 完美支持全场景联动响应，彻底消灭 Recommended Phrases 英文残留！
                          title: Text(
                            phrasesTitle,
                            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          iconColor: Colors.white70,
                          collapsedIconColor: Colors.white70,
                          childrenPadding: const EdgeInsets.all(12),
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: tanjiroLuffyPhrases.length, 
                              itemBuilder: (context, index) {
                                final phrase = tanjiroLuffyPhrases[index];
                                final String localizedLabel = (phrase['label'] as Map<String, String>)[_selectedLanguage] 
                                    ?? (phrase['label'] as Map<String, String>)['English (EN)']!;

                                return Card(
                                  color: Colors.white.withOpacity(0.05),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.35), 
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      localizedLabel, 
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)
                                    ),
                                    subtitle: Text(
                                      phrase['jp'].join(''), 
                                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 12),
                                    onTap: () {
                                      _stopPlayback();
                                      setState(() {
                                        _jpWords = List<String>.from(phrase['jp']);
                                        _romajiWords = List<String>.from(phrase['romaji']);
                                        _currentTranslations = Map<String, String>.from(phrase['trans']);
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            
            if (_selectedCharacter != 'Nezuko') ...[
              const SizedBox(height: 24),
              Text(
                customInputTitle,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _handleTranslate(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.translate, color: Colors.white),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}