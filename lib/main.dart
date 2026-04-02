import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const EmojiDodgerApp());
}

class EmojiDodgerApp extends StatelessWidget {
  const EmojiDodgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emoji Dodger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'monospace'),
      home: const GameScreen(),
    );
  }
}

// ── Data model for a falling emoji ────────────────────────────────────────────
class FallingEmoji {
  double x;
  double y;
  double speed;
  String emoji;
  double size;

  FallingEmoji({
    required this.x,
    required this.y,
    required this.speed,
    required this.emoji,
    required this.size,
  });
}

// ── Game states ────────────────────────────────────────────────────────────────
enum GameState { idle, playing, gameOver }

// ── Main game screen ───────────────────────────────────────────────────────────
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // ── Constants ────────────────────────────────────────────────────────────────
  static const double playerSize = 52;
  static const double playerBottomPadding = 28;
  static const List<String> fallingEmojis = [
    '💣', '☄️', '🪨', '⚡', '🔥', '🌪️', '💀', '🦠', '🧨', '🪤',
  ];
  static const List<String> bgEmojis = ['⭐', '✨', '🌟', '💫'];

  // ── Game state ────────────────────────────────────────────────────────────────
  GameState _gameState = GameState.idle;
  double _playerX = 0.5; // 0..1 normalised
  final List<FallingEmoji> _enemies = [];
  int _score = 0;
  int _highScore = 0;
  double _spawnInterval = 1200; // ms
  double _baseSpeed = 0.003;    // screen-fraction per tick
  final Random _rng = Random();

  // ── Timers / animation ────────────────────────────────────────────────────────
  Timer? _gameLoop;
  Timer? _spawnTimer;
  Timer? _difficultyTimer;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // screen size cache
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _stopGame();
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Game control ──────────────────────────────────────────────────────────────
  void _startGame() {
    setState(() {
      _gameState = GameState.playing;
      _enemies.clear();
      _score = 0;
      _playerX = 0.5;
      _spawnInterval = 1200;
      _baseSpeed = 0.003;
    });

    // ~60 fps game loop
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());

    // Spawn enemies
    _scheduleSpawn();

    // Gradually increase difficulty
    _difficultyTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _spawnInterval = (_spawnInterval - 60).clamp(300, 1200);
      _baseSpeed = (_baseSpeed + 0.0003).clamp(0.003, 0.012);
    });
  }

  void _scheduleSpawn() {
    if (_gameState != GameState.playing) return;
    _spawnTimer = Timer(Duration(milliseconds: _spawnInterval.toInt()), () {
      _spawnEnemy();
      _scheduleSpawn();
    });
  }

  void _spawnEnemy() {
    if (_gameState != GameState.playing) return;
    final emoji = fallingEmojis[_rng.nextInt(fallingEmojis.length)];
    final speedVariance = 0.8 + _rng.nextDouble() * 0.7;
    setState(() {
      _enemies.add(FallingEmoji(
        x: 0.05 + _rng.nextDouble() * 0.90,
        y: -0.05,
        speed: _baseSpeed * speedVariance,
        emoji: emoji,
        size: 36 + _rng.nextDouble() * 16,
      ));
    });
  }

  void _tick() {
    if (_gameState != GameState.playing) return;
    setState(() {
      // Move enemies down
      for (final e in _enemies) {
        e.y += e.speed;
      }
      // Remove off-screen
      _enemies.removeWhere((e) => e.y > 1.08);

      // Increment score
      _score++;

      // Collision detection
      _checkCollision();
    });
  }

  void _checkCollision() {
    final sw = _screenSize.width;
    final sh = _screenSize.height;
    if (sw == 0 || sh == 0) return;

    final px = _playerX * sw;
    final py = sh - playerBottomPadding - playerSize / 2;
    const hitRadius = playerSize * 0.45;

    for (final e in _enemies) {
      final ex = e.x * sw;
      final ey = e.y * sh;
      final er = e.size * 0.5;
      final dist = sqrt(pow(px - ex, 2) + pow(py - ey, 2));
      if (dist < hitRadius + er * 0.55) {
        _triggerGameOver();
        return;
      }
    }
  }

  void _triggerGameOver() {
    _stopGame();
    HapticFeedback.heavyImpact();
    if (_score > _highScore) _highScore = _score;
    _shakeController.forward(from: 0);
    setState(() => _gameState = GameState.gameOver);
  }

  void _stopGame() {
    _gameLoop?.cancel();
    _spawnTimer?.cancel();
    _difficultyTimer?.cancel();
  }

  // ── Input ─────────────────────────────────────────────────────────────────────
  void _onHorizontalDrag(double dx) {
    if (_gameState != GameState.playing) return;
    setState(() {
      _playerX = (_playerX + dx / _screenSize.width).clamp(0.05, 0.95);
    });
  }

  void _onTapDown(TapDownDetails d) {
    if (_gameState != GameState.playing) return;
    setState(() {
      _playerX = (d.localPosition.dx / _screenSize.width).clamp(0.05, 0.95);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) => _onHorizontalDrag(d.delta.dx),
            onTapDown: _onTapDown,
            child: AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) {
                final shake = sin(_shakeAnim.value * pi * 8) * 14 *
                    (1 - _shakeAnim.value);
                return Transform.translate(
                  offset: Offset(shake, 0),
                  child: child,
                );
              },
              child: _buildGame(constraints),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGame(BoxConstraints constraints) {
    final sw = constraints.maxWidth;
    final sh = constraints.maxHeight;

    return Stack(
      children: [
        // ── Background ──────────────────────────────────────────────────────────
        _buildBackground(sw, sh),

        // ── Falling enemies ────────────────────────────────────────────────────
        ..._enemies.map((e) => Positioned(
          left: e.x * sw - e.size / 2,
          top: e.y * sh - e.size / 2,
          child: Text(e.emoji,
              style: TextStyle(fontSize: e.size, height: 1)),
        )),

        // ── Player ─────────────────────────────────────────────────────────────
        if (_gameState == GameState.playing)
          Positioned(
            left: _playerX * sw - playerSize / 2,
            bottom: playerBottomPadding,
            child: _buildPlayer(),
          ),

        // ── Score ───────────────────────────────────────────────────────────────
        if (_gameState == GameState.playing)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: _buildHUD(),
          ),

        // ── Overlays ────────────────────────────────────────────────────────────
        if (_gameState == GameState.idle) _buildStartOverlay(sw, sh),
        if (_gameState == GameState.gameOver) _buildGameOverOverlay(sw, sh),
      ],
    );
  }

  // ── Background ────────────────────────────────────────────────────────────────
  Widget _buildBackground(double sw, double sh) {
    return Container(
      width: sw,
      height: sh,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D0D2B), Color(0xFF1A1A4E), Color(0xFF0D1B3E)],
        ),
      ),
      child: Stack(
        children: [
          // Static star field
          ...List.generate(35, (i) {
            final rx = (i * 137.5 % 100) / 100;
            final ry = (i * 97.3 % 100) / 100;
            return Positioned(
              left: rx * sw,
              top: ry * sh * 0.7,
              child: Opacity(
                opacity: 0.3 + (i % 5) * 0.14,
                child: Text(
                  bgEmojis[i % bgEmojis.length],
                  style: TextStyle(fontSize: 10 + (i % 4) * 4.0),
                ),
              ),
            );
          }),
          // Ground strip
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: playerBottomPadding + playerSize + 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF1565C0).withOpacity(0.35),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Player widget ─────────────────────────────────────────────────────────────
  Widget _buildPlayer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Shadow glow beneath
        Container(
          width: playerSize,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.6),
                blurRadius: 18,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        const Text('🧑', style: TextStyle(fontSize: playerSize, height: 1)),
      ],
    );
  }

  // ── HUD ───────────────────────────────────────────────────────────────────────
  Widget _buildHUD() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _scoreChip('⭐ ${_formatScore(_score)}', Colors.amber),
          _scoreChip('🏆 ${_formatScore(_highScore)}', Colors.cyanAccent),
        ],
      ),
    );
  }

  Widget _scoreChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ── Start overlay ─────────────────────────────────────────────────────────────
  Widget _buildStartOverlay(double sw, double sh) {
    return Container(
      color: Colors.black.withOpacity(0.55),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Transform.scale(
          scale: _pulseAnim.value,
          child: child,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧑', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            const Text(
              'EMOJI DODGER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dodge the falling chaos!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '💣 ☄️ 🪨 ⚡ 🔥',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 36),
            _buildStartButton('TAP TO START 🚀', Colors.cyanAccent, _startGame),
            const SizedBox(height: 16),
            Text(
              'Drag or tap to move',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Game Over overlay ─────────────────────────────────────────────────────────
  Widget _buildGameOverOverlay(double sw, double sh) {
    final isNewHigh = _score >= _highScore;
    return Container(
      color: Colors.black.withOpacity(0.72),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💥', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 12),
          const Text(
            'GAME OVER',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 24),
          _overlayCard(
            Column(
              children: [
                _statRow('⭐ Score', _formatScore(_score), Colors.amber),
                const SizedBox(height: 10),
                _statRow('🏆 Best', _formatScore(_highScore), Colors.cyanAccent),
                if (isNewHigh) ...[
                  const SizedBox(height: 10),
                  const Text(
                    '🎉 New High Score!',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          _buildStartButton('PLAY AGAIN 🔄', Colors.greenAccent, _startGame),
        ],
      ),
    );
  }

  Widget _overlayCard(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: child,
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 16)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStartButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.85), color.withOpacity(0.5)],
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.45),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  String _formatScore(int s) {
    if (s >= 1000) return '${(s / 1000).toStringAsFixed(1)}k';
    return '$s';
  }
}