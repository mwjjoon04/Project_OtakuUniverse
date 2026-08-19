import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'profile_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int? _selectedGameIndex; // null: Hub Menu, 0: Water Slash, 1: Luffy Meat Catcher
  
  String? _userAvatar; 
  int _slashHighScore = 0;
  int _meatHighScore = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _userAvatar = data['avatarUrl'];
          _slashHighScore = data['slashHighScore'] ?? 0;
          _meatHighScore = data['meatHighScore'] ?? 0;
        });
      }
    }
  }

  void _updateSlashHighScore(int newScore) {
    if (newScore > _slashHighScore) {
      setState(() => _slashHighScore = newScore);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'slashHighScore': newScore,
        }, SetOptions(merge: true));
      }
    }
  }

  void _updateMeatHighScore(int newScore) {
    if (newScore > _meatHighScore) {
      setState(() => _meatHighScore = newScore);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'meatHighScore': newScore,
        }, SetOptions(merge: true));
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      
      appBar: AppBar(
        title: Text(
          _selectedGameIndex == null
              ? '🎮 Arcade Hub'
              : (_selectedGameIndex == 0 ? 'Water Breathing: Slash' : 'Luffy: Meat Catcher'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        leading: _selectedGameIndex != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () {
                  setState(() {
                    _selectedGameIndex = null;
                  });
                },
              )
            : null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ).then((_) => _loadUserData()); 
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.deepPurpleAccent,
                backgroundImage: _userAvatar != null && _userAvatar!.isNotEmpty
                    ? AssetImage(_userAvatar!)
                    : null,
                child: (_userAvatar == null || _userAvatar!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
            ),
          ),
        ],
      ),
      
      body: _selectedGameIndex == null
          ? _buildGameSelectionMenu()
          : (_selectedGameIndex == 0
              ? WaterBreathingSlashGame(
                  highScore: _slashHighScore,
                  onScoreUpdate: _updateSlashHighScore,
                  onExit: () => setState(() => _selectedGameIndex = null),
                )
              : LuffyMeatCatcherGame(
                  highScore: _meatHighScore,
                  onScoreUpdate: _updateMeatHighScore,
                  onExit: () => setState(() => _selectedGameIndex = null),
                )),
    );
  }

  Widget _buildGameSelectionMenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select an anime mini-game to play:",
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.65), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 18),

          _buildMenuCard(
            title: "🌊 Water Breathing: Slash",
            subtitle: "Slash flying Kana! Missing a kana costs HP. Beware of demon bombs!",
            badgeText: "Demon Slayer",
            badgeColor: Colors.cyanAccent,
            accentColor: Colors.cyan,
            highScore: _slashHighScore,
            scoreLabel: "Pts",
            icon: "⚔️",
            onTap: () {
              setState(() {
                _selectedGameIndex = 0;
              });
            },
          ),

          const SizedBox(height: 20),

          _buildMenuCard(
            title: "🍖 Luffy: Meat Catcher",
            subtitle: "Catch falling meat & Devil Fruits! Dropping food costs HP. Dodge bombs!",
            badgeText: "One Piece",
            badgeColor: Colors.amberAccent,
            accentColor: Colors.amber,
            highScore: _meatHighScore,
            scoreLabel: "Pts",
            icon: "👒",
            onTap: () {
              setState(() {
                _selectedGameIndex = 1;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required MaterialColor accentColor,
    required int highScore,
    required String scoreLabel,
    required String icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161521).withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Colors.amberAccent, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "Best: $highScore $scoreLabel",
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 40)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withOpacity(0.5)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Play Now",
                          style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.play_arrow_rounded, color: badgeColor, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 🌊 GAME 1: WATER BREATHING: SLASH (自适应高屏)
// ==========================================
class WaterBreathingSlashGame extends StatefulWidget {
  final int highScore;
  final Function(int) onScoreUpdate;
  final VoidCallback onExit;

  const WaterBreathingSlashGame({
    super.key,
    required this.highScore,
    required this.onScoreUpdate,
    required this.onExit,
  });

  @override
  State<WaterBreathingSlashGame> createState() => _WaterBreathingSlashGameState();
}

class SlashTarget {
  final int id;
  final String char;
  final String romaji;
  final bool isBomb;
  double x;
  double y;
  double speedY;
  double speedX;
  bool isSliced = false;

  SlashTarget({
    required this.id,
    required this.char,
    required this.romaji,
    required this.isBomb,
    required this.x,
    required this.y,
    required this.speedY,
    required this.speedX,
  });
}

class _WaterBreathingSlashGameState extends State<WaterBreathingSlashGame> {
  final List<SlashTarget> _targets = [];
  final List<Offset> _slashPoints = [];
  Timer? _gameLoopTimer;
  Timer? _spawnTimer;
  int _score = 0;
  int _combo = 0;
  int _lives = 3;
  bool _isGameOver = false;
  bool _isPaused = false;
  int _nextId = 0;
  double _boardHeight = 600.0;
  double _boardWidth = 350.0;

  final List<Map<String, String>> _kanaPool = [
    {"jp": "あ", "ro": "a"},
    {"jp": "い", "ro": "i"},
    {"jp": "う", "ro": "u"},
    {"jp": "え", "ro": "e"},
    {"jp": "お", "ro": "o"},
    {"jp": "か", "ro": "ka"},
    {"jp": "き", "ro": "ki"},
    {"jp": "く", "ro": "ku"},
    {"jp": "け", "ro": "ke"},
    {"jp": "こ", "ro": "ko"},
    {"jp": "斬", "ro": "SLASH"},
    {"jp": "滅", "ro": "SLAY"},
  ];

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _targets.clear();
    _slashPoints.clear();
    _score = 0;
    _combo = 0;
    _lives = 3;
    _isGameOver = false;
    _isPaused = false;

    _gameLoopTimer?.cancel();
    _spawnTimer?.cancel();

    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!_isGameOver && !_isPaused && mounted) {
        _updatePhysics();
      }
    });

    _spawnTimer = Timer.periodic(const Duration(milliseconds: 950), (timer) {
      if (!_isGameOver && !_isPaused && mounted) {
        _spawnTarget();
      }
    });
  }

  void _spawnTarget() {
    final rand = Random();
    
    double bombProbability = 0.30 + (_score / 500) * 0.38;
    if (bombProbability > 0.68) bombProbability = 0.68;

    final isBomb = rand.nextDouble() < bombProbability;
    final kana = _kanaPool[rand.nextInt(_kanaPool.length)];

    final newTarget = SlashTarget(
      id: _nextId++,
      char: isBomb ? "👹" : kana["jp"]!,
      romaji: isBomb ? "DEMON" : kana["ro"]!,
      isBomb: isBomb,
      x: 40.0 + rand.nextDouble() * (_boardWidth - 80.0).clamp(100.0, 500.0),
      y: _boardHeight - 20, // 从屏幕底部升起
      speedY: -(11.0 + rand.nextDouble() * 4.5),
      speedX: (rand.nextDouble() - 0.5) * 3.5,
    );

    setState(() {
      _targets.add(newTarget);
    });
  }

  void _updatePhysics() {
    setState(() {
      for (var target in _targets) {
        target.x += target.speedX;
        target.y += target.speedY;
        target.speedY += 0.38; 
      }

      _targets.removeWhere((t) {
        if (t.y > _boardHeight + 20 && t.speedY > 0) {
          if (!t.isSliced && !t.isBomb) {
            _combo = 0;
            _lives--;
            HapticFeedback.heavyImpact();
            if (_lives <= 0) {
              _isGameOver = true;
              widget.onScoreUpdate(_score);
            }
          }
          return true;
        }
        return false;
      });
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isGameOver || _isPaused) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPos = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      _slashPoints.add(localPos);
      if (_slashPoints.length > 8) {
        _slashPoints.removeAt(0);
      }

      for (var target in _targets) {
        if (!target.isSliced) {
          final dist = (Offset(target.x, target.y) - localPos).distance;
          if (dist < 45.0) {
            target.isSliced = true;
            HapticFeedback.mediumImpact();

            if (target.isBomb) {
              _lives--;
              _combo = 0;
              if (_lives <= 0) {
                _isGameOver = true;
                widget.onScoreUpdate(_score);
              }
            } else {
              _combo++;
              _score += 10 + (_combo * 2);
              widget.onScoreUpdate(_score);
            }
          }
        }
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _slashPoints.clear();
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      _slashPoints.clear();
    });
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    _spawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isNewRecord = _score > widget.highScore;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF14131F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _boardHeight = constraints.maxHeight;
            _boardWidth = constraints.maxWidth;

            return Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: _handlePanUpdate,
                  onPanEnd: _handlePanEnd,
                  child: Stack(
                    children: [
                      ..._targets.map((t) {
                        return Positioned(
                          left: t.x - 28,
                          top: t.y - 28,
                          child: Opacity(
                            opacity: t.isSliced ? 0.3 : 1.0,
                            child: Transform.scale(
                              scale: t.isSliced ? 1.4 : 1.0,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: t.isBomb
                                        ? [Colors.red.shade400, Colors.red.shade900]
                                        : [Colors.cyan.shade300, Colors.blue.shade800],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (t.isBomb ? Colors.red : Colors.cyan).withOpacity(0.4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        t.char,
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      if (!t.isBomb)
                                        Text(
                                          t.romaji,
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.85)),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      CustomPaint(
                        size: Size.infinite,
                        painter: WaterSlashPainter(points: _slashPoints),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Score: $_score", style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              const Icon(Icons.emoji_events_rounded, color: Colors.amberAccent, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                "Best: ${max(_score, widget.highScore)}",
                                style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              if (_combo > 1) ...[
                                const SizedBox(width: 8),
                                Text("$_combo COMBO!", style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Row(
                            children: List.generate(3, (index) {
                              return Icon(
                                index < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: Colors.redAccent,
                                size: 22,
                              );
                            }),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _togglePause,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Icon(
                                _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (_isPaused && !_isGameOver)
                  Container(
                    color: Colors.black.withOpacity(0.85),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pause_circle_filled_rounded, color: Colors.cyanAccent, size: 54),
                          const SizedBox(height: 12),
                          const Text("Game Paused", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 6),
                          Text("Current Score: $_score", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: 160,
                            child: ElevatedButton.icon(
                              onPressed: _togglePause,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text("Resume"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 160,
                            child: OutlinedButton.icon(
                              onPressed: widget.onExit,
                              icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white70),
                              label: const Text("Quit to Hub", style: TextStyle(color: Colors.white70)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_isGameOver)
                  Container(
                    color: Colors.black87,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("⚔️ Battle Finished", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 10),
                          Text("Final Score: $_score", style: const TextStyle(fontSize: 20, color: Colors.cyanAccent)),
                          const SizedBox(height: 6),
                          if (isNewRecord && _score > 0)
                            const Text("🎉 New High Score!", style: TextStyle(fontSize: 14, color: Colors.amberAccent, fontWeight: FontWeight.bold))
                          else
                            Text("Best Record: ${widget.highScore}", style: const TextStyle(fontSize: 14, color: Colors.white54)),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: widget.onExit,
                                icon: const Icon(Icons.menu_rounded, color: Colors.white70),
                                label: const Text("Main Menu", style: TextStyle(color: Colors.white70)),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                              ),
                              const SizedBox(width: 14),
                              ElevatedButton.icon(
                                onPressed: _startNewGame,
                                icon: const Icon(Icons.replay_rounded),
                                label: const Text("Play Again"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class WaterSlashPainter extends CustomPainter {
  final List<Offset> points;
  WaterSlashPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final outerGlowPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.5)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final coreWaterPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], outerGlowPaint);
      canvas.drawLine(points[i], points[i + 1], coreWaterPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WaterSlashPainter oldDelegate) => true;
}

// ==========================================
// 🍖 GAME 2: LUFFY: MEAT CATCHER (🌟 修复草帽靠底自适应)
// ==========================================
class LuffyMeatCatcherGame extends StatefulWidget {
  final int highScore;
  final Function(int) onScoreUpdate;
  final VoidCallback onExit;

  const LuffyMeatCatcherGame({
    super.key,
    required this.highScore,
    required this.onScoreUpdate,
    required this.onExit,
  });

  @override
  State<LuffyMeatCatcherGame> createState() => _LuffyMeatCatcherGameState();
}

class FallingFood {
  final String icon;
  final int points;
  final bool isBomb;
  double x;
  double y;
  double speed;

  FallingFood({
    required this.icon,
    required this.points,
    required this.isBomb,
    required this.x,
    required this.y,
    required this.speed,
  });
}

class _LuffyMeatCatcherGameState extends State<LuffyMeatCatcherGame> {
  double _luffyX = 150.0;
  final List<FallingFood> _foods = [];
  Timer? _gameLoopTimer;
  Timer? _spawnTimer;
  int _score = 0;
  int _lives = 3;
  bool _isGameOver = false;
  bool _isPaused = false;
  double _boardHeight = 600.0;
  double _boardWidth = 350.0;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _foods.clear();
    _score = 0;
    _lives = 3;
    _isGameOver = false;
    _isPaused = false;
    _luffyX = 150.0;

    _gameLoopTimer?.cancel();
    _spawnTimer?.cancel();

    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!_isGameOver && !_isPaused && mounted) {
        _updateGame();
      }
    });

    _spawnTimer = Timer.periodic(const Duration(milliseconds: 750), (timer) {
      if (!_isGameOver && !_isPaused && mounted) {
        _spawnFood();
      }
    });
  }

  void _spawnFood() {
    final rand = Random();
    
    double bombProbability = 0.35 + (_score / 350) * 0.30;
    if (bombProbability > 0.65) bombProbability = 0.65;

    final roll = rand.nextDouble();

    String icon = "🍖";
    int points = 10;
    bool isBomb = false;

    if (roll < bombProbability) {
      icon = "💣";
      isBomb = true;
    } else if (roll < bombProbability + 0.15) {
      icon = "🍇"; 
      points = 50;
    } else if (roll < bombProbability + 0.35) {
      icon = "🍙"; 
      points = 20;
    }

    setState(() {
      _foods.add(FallingFood(
        icon: icon,
        points: points,
        isBomb: isBomb,
        x: 30.0 + rand.nextDouble() * (_boardWidth - 60.0).clamp(100.0, 500.0),
        y: 0.0,
        speed: 5.0 + rand.nextDouble() * 4.0,
      ));
    });
  }

  void _updateGame() {
    setState(() {
      for (var f in _foods) {
        f.y += f.speed;
      }

      // 🌟 根据当前屏幕高度自适应判定区间
      double catcherTop = _boardHeight - 88.0;

      _foods.removeWhere((f) {
        // 接住判定
        if (f.y >= catcherTop - 25.0 && f.y <= catcherTop + 35.0) {
          if ((f.x - _luffyX).abs() < 45.0) {
            HapticFeedback.lightImpact();
            if (f.isBomb) {
              _lives--;
              if (_lives <= 0) {
                _isGameOver = true;
                widget.onScoreUpdate(_score);
              }
            } else {
              _score += f.points;
              widget.onScoreUpdate(_score);
            }
            return true;
          }
        }

        // 漏接食物扣血判定
        if (f.y > _boardHeight) {
          if (!f.isBomb) {
            _lives--;
            HapticFeedback.heavyImpact();
            if (_lives <= 0) {
              _isGameOver = true;
              widget.onScoreUpdate(_score);
            }
          }
          return true;
        }
        return false;
      });
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    _spawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isNewRecord = _score > widget.highScore;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1612),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _boardHeight = constraints.maxHeight;
            _boardWidth = constraints.maxWidth;

            return Stack(
              children: [
                // 1. 拖动层与下落食物渲染
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    if (_isGameOver || _isPaused) return;
                    setState(() {
                      _luffyX += details.delta.dx;
                      _luffyX = _luffyX.clamp(35.0, _boardWidth - 35.0);
                    });
                  },
                  child: Stack(
                    children: [
                      ..._foods.map((f) {
                        return Positioned(
                          left: f.x - 16,
                          top: f.y,
                          child: Text(
                            f.icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                        );
                      }),

                      // 🌟 核心修改：草帽紧贴底部（自适应任意长屏手机，距底部 14px）
                      Positioned(
                        left: _luffyX - 35,
                        bottom: 14,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("👒", style: TextStyle(fontSize: 48)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade900,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text("Luffy", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. HUD 顶栏
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Score: $_score", style: const TextStyle(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              const Icon(Icons.emoji_events_rounded, color: Colors.amberAccent, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                "Best: ${max(_score, widget.highScore)}",
                                style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Row(
                            children: List.generate(3, (index) {
                              return Icon(
                                index < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: Colors.redAccent,
                                size: 22,
                              );
                            }),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _togglePause,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Icon(
                                _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. 暂停弹窗
                if (_isPaused && !_isGameOver)
                  Container(
                    color: Colors.black.withOpacity(0.85),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pause_circle_filled_rounded, color: Colors.amberAccent, size: 54),
                          const SizedBox(height: 12),
                          const Text("Feast Paused", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 6),
                          Text("Current Score: $_score", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: 160,
                            child: ElevatedButton.icon(
                              onPressed: _togglePause,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text("Resume"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade800,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 160,
                            child: OutlinedButton.icon(
                              onPressed: widget.onExit,
                              icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white70),
                              label: const Text("Quit to Hub", style: TextStyle(color: Colors.white70)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 4. 结算弹层
                if (_isGameOver)
                  Container(
                    color: Colors.black87,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("🍖 Feast Finished!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 10),
                          Text("Final Score: $_score", style: const TextStyle(fontSize: 20, color: Colors.amberAccent)),
                          const SizedBox(height: 6),
                          if (isNewRecord && _score > 0)
                            const Text("🎉 New High Score!", style: TextStyle(fontSize: 14, color: Colors.amberAccent, fontWeight: FontWeight.bold))
                          else
                            Text("Best Record: ${widget.highScore}", style: const TextStyle(fontSize: 14, color: Colors.white54)),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: widget.onExit,
                                icon: const Icon(Icons.menu_rounded, color: Colors.white70),
                                label: const Text("Main Menu", style: TextStyle(color: Colors.white70)),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                              ),
                              const SizedBox(width: 14),
                              ElevatedButton.icon(
                                onPressed: _startNewGame,
                                icon: const Icon(Icons.replay_rounded),
                                label: const Text("Play Again"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}