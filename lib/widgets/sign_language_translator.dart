import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart'; 

class SignLanguageTranslator extends StatefulWidget {
  final String text;          
  final bool isPlaying;       
  final VoidCallback? onComplete; 

  const SignLanguageTranslator({
    Key? key,
    required this.text,
    required this.isPlaying,
    this.onComplete,
  }) : super(key: key);

  @override
  State<SignLanguageTranslator> createState() => _SignLanguageTranslatorState();
}

class _SignLanguageTranslatorState extends State<SignLanguageTranslator> {
  VideoPlayerController? _videoController;
  String _currentConcept = 'HELLO';
  bool _isInitialized = false;

  // 🚀【全网净化资产字典】：已彻底删去 FUCK 核心物理路径映射
  final Map<String, String> _signVideoAssets = {
    'HELLO': 'assets/videos/hello.mp4',       
    'GOODBYE': 'assets/videos/goodbye.mp4',   
    'FINE': 'assets/videos/fine.mp4',       
    'HELP': 'assets/videos/help.mp4',       
    'MOM': 'assets/videos/mom.mp4',         
    'DAD': 'assets/videos/dad.mp4',         
    'PLEASE': 'assets/videos/please.mp4',   
    'EAT': 'assets/videos/eat.mp4',         
    'DRINK': 'assets/videos/drink.mp4',     
    'SORRY': 'assets/videos/sorry.mp4',     
    'YES': 'assets/videos/yes.mp4',         
    'NO': 'assets/videos/no.mp4',           
    'GO': 'assets/videos/go.mp4',           
    'STOP': 'assets/videos/stop.mp4',       
    
    'HOW_ARE_YOU': 'assets/videos/how_are_you.mp4',
    'HOW_MUCH_IS_IT': 'assets/videos/how_much_is_it.mp4',
    'GOING_SHOPPING': 'assets/videos/i_am_going_shopping.mp4',
    'GO_HOME': 'assets/videos/i_have_to_go_home.mp4',
    'LIKE_CHOCOLATE': 'assets/videos/i_like_chocolate.mp4',
    'I_LOVE_YOU': 'assets/videos/i_love_you.mp4',
    'WHAT_TIME': 'assets/videos/what_time_is_it.mp4',
    'STUDY_OR_WORK': 'assets/videos/are_you_studying_or_are_you_working.mp4',
    'DID_YOU_EAT': 'assets/videos/did_you_eat.mp4',
    'HAPPY_BIRTHDAY': 'assets/videos/happy_birthday.mp4',
    'ALL_DONE': 'assets/videos/all_done.mp4',

    'ANGRY': 'assets/videos/angry.mp4',
    'CALL': 'assets/videos/call.mp4',
    'CRY': 'assets/videos/cry.mp4',
    // 🛑【已安全斩断底层的 FUCK 映射线】
    'HAPPY': 'assets/videos/happy.mp4',
    'TRAVELING': 'assets/videos/i_love_travelling_around.mp4',
    'MONEY': 'assets/videos/money.mp4',
    'SAD': 'assets/videos/sad.mp4',
    'TOILET': 'assets/videos/toilet.mp4',
  };

  @override
  void initState() {
    super.initState();
    _parseConcept();
    _initializeSelectedVideo();
  }

  @override
  void didUpdateWidget(covariant SignLanguageTranslator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.text != oldWidget.text) {
      _parseConcept();
      _initializeSelectedVideo();
    } else if (widget.isPlaying != oldWidget.isPlaying) {
      _handleVideoPlayback();
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener); 
    _videoController?.dispose(); 
    super.dispose();
  }

  void _videoListener() {
    if (!mounted || _videoController == null || !_isInitialized) return;
    
    if (_videoController!.value.position >= _videoController!.value.duration && widget.isPlaying) {
      widget.onComplete?.call(); 
    }
  }

  // 🚀【长句拦截器优先解析网关】
  void _parseConcept() {
    final String upper = widget.text.toUpperCase();
    setState(() {
      if (upper.contains('HOW ARE YOU')) { _currentConcept = 'HOW_ARE_YOU'; }
      else if (upper.contains('HOW MUCH')) { _currentConcept = 'HOW_MUCH_IS_IT'; }
      else if (upper.contains('SHOPPING')) { _currentConcept = 'GOING_SHOPPING'; }
      else if (upper.contains('GO HOME') || upper.contains('TO GO HOME')) { _currentConcept = 'GO_HOME'; }
      else if (upper.contains('CHOCOLATE')) { _currentConcept = 'LIKE_CHOCOLATE'; }
      else if (upper.contains('I LOVE YOU')) { _currentConcept = 'I_LOVE_YOU'; }
      else if (upper.contains('WHAT TIME') || upper.contains('TIME IS IT')) { _currentConcept = 'WHAT_TIME'; }
      else if (upper.contains('STUDYING') || upper.contains('WORKING') || upper.contains('STUDY OR WORK')) { _currentConcept = 'STUDY_OR_WORK'; }
      else if (upper.contains('DID YOU EAT') || (upper.contains('EAT') && upper.contains('DID'))) { _currentConcept = 'DID_YOU_EAT'; }
      else if (upper.contains('HAPPY BIRTHDAY') || upper.contains('BIRTHDAY')) { _currentConcept = 'HAPPY_BIRTHDAY'; }
      else if (upper.contains('ALL DONE') || upper.contains('DONE')) { _currentConcept = 'ALL_DONE'; }
      else if (upper.contains('GOODBYE') || upper.contains('GOOD BYE')) { _currentConcept = 'GOODBYE'; }
      
      else if (upper.contains('ANGRY')) { _currentConcept = 'ANGRY'; }
      else if (upper.contains('CALL')) { _currentConcept = 'CALL'; }
      else if (upper.contains('CRY')) { _currentConcept = 'CRY'; }
      // 🛑【已全面抹除 FUCK 解析分支，拒绝中途拦截】
      else if (upper.contains('HAPPY')) { _currentConcept = 'HAPPY'; }
      else if (upper.contains('TRAVELLING') || upper.contains('TRAVEL') || upper.contains('AROUND')) { _currentConcept = 'TRAVELING'; }
      else if (upper.contains('MONEY')) { _currentConcept = 'MONEY'; }
      else if (upper.contains('SAD')) { _currentConcept = 'SAD'; }
      else if (upper.contains('TOILET')) { _currentConcept = 'TOILET'; }

      else if (upper.contains('HELLO')) { _currentConcept = 'HELLO'; } 
      else if (upper.contains('FINE') || upper.contains('OKAY')) { _currentConcept = 'FINE'; }
      else if (upper.contains('HELP')) { _currentConcept = 'HELP'; }
      else if (upper.contains('MOM') || upper.contains('MOTHER')) { _currentConcept = 'MOM'; }
      else if (upper.contains('DAD') || upper.contains('FATHER')) { _currentConcept = 'DAD'; }
      else if (upper.contains('PLEASE')) { _currentConcept = 'PLEASE'; }
      else if (upper.contains('EAT')) { _currentConcept = 'EAT'; }
      else if (upper.contains('DRINK')) { _currentConcept = 'DRINK'; }
      else if (upper.contains('SORRY')) { _currentConcept = 'SORRY'; }
      else if (upper.contains('YES')) { _currentConcept = 'YES'; }
      else if (upper.contains('NO')) { _currentConcept = 'NO'; }
      else if (upper.contains('GO')) { _currentConcept = 'GO'; }
      else if (upper.contains('STOP')) { _currentConcept = 'STOP'; }
      else { _currentConcept = 'HELLO'; } 
    });
  }

  Future<void> _initializeSelectedVideo() async {
    setState(() {
      _isInitialized = false;
    });
    
    if (_videoController != null) {
      _videoController!.removeListener(_videoListener); 
      await _videoController!.dispose();
    }

    String assetPath = _signVideoAssets[_currentConcept] ?? 'assets/videos/hello.mp4';
    _videoController = VideoPlayerController.asset(assetPath);

    try {
      await _videoController!.initialize();
      _videoController!.setLooping(false); 
      _videoController!.addListener(_videoListener); 
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _handleVideoPlayback();
      }
    } catch (e) {
      debugPrint("❌ 本地手语视频初始化挂载异常: $e");
    }
  }

  void _handleVideoPlayback() {
    if (_videoController == null || !_isInitialized) return;
    
    if (widget.isPlaying) {
      _videoController!.play(); 
    } else {
      _videoController!.pause(); 
      _videoController!.seekTo(Duration.zero); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250, 
      height: 280, 
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05), 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFB3C1), width: 3.5),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20), 
        child: _isInitialized
            ? Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: 15, 
                    top: 0,
                    child: SizedBox(
                      width: 280, 
                      height: 280,
                      child: Center(
                        child: Transform.scale(
                          scale: 1.45, 
                          alignment: const Alignment(0.45, 0.0), 
                          child: AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio, 
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4D6D)),
                  strokeWidth: 3,
                ),
              ),
      ),
    );
  }
}