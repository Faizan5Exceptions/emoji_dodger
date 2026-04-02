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

// ── Enums ─────────────────────────────────────────────────────────────────────
enum GameState { menu, playing, gameOver }

// ── Falling object (enemy or 1-UP) ────────────────────────────────────────────
class FallingObject {
  double x, y, speed, size, scale, rotation;
  String emoji;
  bool isOneUp;
  FallingObject({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.emoji,
    this.isOneUp = false,
    this.scale = 0.0,
    this.rotation = 0.0,
  });
}

// ── Floating popup text ────────────────────────────────────────────────────────
class FloatingText {
  double x, y, opacity;
  String text;
  Color color;
  FloatingText({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    this.opacity = 1.0,
  });
}

// ── Explosion particle ─────────────────────────────────────────────────────────
class Particle {
  double x, y, vx, vy, opacity, size;
  String emoji;
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.emoji,
    this.opacity = 1.0,
    this.size = 18,
  });
}

// ── Main game screen ───────────────────────────────────────────────────────────
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // ── Constants ─────────────────────────────────────────────────────────────────
  static const double playerSize   = 54;
  static const double playerBottom = 32;
  static const int    maxLives     = 5;
  static const int    startLives   = 3;

  static const List<String> dangerEmojis = [
    '💣','☄️','🪨','⚡','🔥','🌪️','💀','🦠','🧨','🪤','💢','🌑',
  ];
  static const List<String> bgStars = ['⭐','✨','🌟','💫','🌠'];
  static const List<String> burstEmojis = ['💥','✨','⭐','🔥','💫'];

  // ── Game state ────────────────────────────────────────────────────────────────
  GameState            _state           = GameState.menu;
  double               _playerX         = 0.5;
  double               _targetX         = 0.5;
  List<FallingObject>  _objects         = [];
  List<FloatingText>   _floatingTexts   = [];
  List<Particle>       _particles       = [];
  List<FallingObject>  _bgObjects       = [];
  int                  _score           = 0;
  int                  _highScore       = 0;
  int                  _lives           = startLives;
  bool                 _invincible      = false;
  bool                 _playerVisible   = true;
  int                  _invincibleTicks = 0;
  int                  _nextOneUpTicks  = 0;

  // difficulty
  double _spawnInterval = 1000;
  double _baseSpeed     = 0.0042;

  // ── Timers ────────────────────────────────────────────────────────────────────
  Timer? _gameLoop, _spawnTimer, _diffTimer, _bgLoop, _bgSpawn;

  // ── Animation controllers ─────────────────────────────────────────────────────
  late AnimationController _globalCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _flashCtrl;
  late AnimationController _oneUpCtrl;
  late AnimationController _titleCtrl;

  late Animation<double> _globalAnim;
  late Animation<double> _shakeAnim;
  late Animation<double> _flashAnim;
  late Animation<double> _oneUpAnim;
  late Animation<double> _titleAnim;

  Size   _screen = Size.zero;
  final  Random _rng = Random();

  // ── Init ──────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _globalCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 3),
    )..repeat();
    _globalAnim = Tween<double>(begin: 0, end: 1).animate(_globalCtrl);

    _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    _flashCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350),
    );
    _flashAnim = Tween<double>(begin: 0, end: 1).animate(_flashCtrl);

    _oneUpCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    );
    _oneUpAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _oneUpCtrl, curve: Curves.elasticOut),
    );

    _titleCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _titleAnim = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _titleCtrl, curve: Curves.easeInOut),
    );

    _startBgAnimation();
  }

  @override
  void dispose() {
    _stopAll();
    _globalCtrl.dispose();
    _shakeCtrl.dispose();
    _flashCtrl.dispose();
    _oneUpCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  // ── Background animation (menu & game-over) ───────────────────────────────────
  void _startBgAnimation() {
    _bgObjects.clear();
    _bgLoop = Timer.periodic(const Duration(milliseconds: 32), (_) {
      if (!mounted) return;
      setState(() {
        for (final o in _bgObjects) {
          o.y        += o.speed * 0.45;
          o.rotation += 0.012;
        }
        _bgObjects.removeWhere((o) => o.y > 1.12);
      });
    });
    _bgSpawn = Timer.periodic(const Duration(milliseconds: 620), (_) {
      if (!mounted) return;
      _bgObjects.add(FallingObject(
        x:        0.04 + _rng.nextDouble() * 0.92,
        y:        -0.06,
        speed:    0.0016 + _rng.nextDouble() * 0.0022,
        size:     20 + _rng.nextDouble() * 20,
        emoji:    dangerEmojis[_rng.nextInt(dangerEmojis.length)],
        scale:    1.0,
        rotation: _rng.nextDouble() * 2 * pi,
      ));
    });
  }

  void _stopBgAnimation() {
    _bgLoop?.cancel();
    _bgSpawn?.cancel();
  }

  // ── Game control ──────────────────────────────────────────────────────────────
  void _startGame() {
    _stopAll();
    setState(() {
      _state           = GameState.playing;
      _objects         = [];
      _floatingTexts   = [];
      _particles       = [];
      _bgObjects       = [];
      _score           = 0;
      _lives           = startLives;
      _playerX         = 0.5;
      _targetX         = 0.5;
      _invincible      = false;
      _playerVisible   = true;
      _invincibleTicks = 0;
      _spawnInterval   = 1000;
      _baseSpeed       = 0.0042;
      _nextOneUpTicks  = _rng.nextInt(350) + 350;
    });

    _gameLoop  = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
    _scheduleSpawn();
    // Difficulty ramps every 3 s
    _diffTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _spawnInterval = (_spawnInterval - 65).clamp(220, 1000);
      _baseSpeed     = (_baseSpeed + 0.0007).clamp(0.0042, 0.022);
    });
  }

  void _scheduleSpawn() {
    if (_state != GameState.playing) return;
    _spawnTimer = Timer(Duration(milliseconds: _spawnInterval.toInt()), () {
      _spawnEnemy();
      _scheduleSpawn();
    });
  }

  void _spawnEnemy() {
    if (_state != GameState.playing) return;
    final variance = 0.65 + _rng.nextDouble() * 0.75;
    setState(() {
      _objects.add(FallingObject(
        x:        0.06 + _rng.nextDouble() * 0.88,
        y:        -0.06,
        speed:    _baseSpeed * variance,
        size:     34 + _rng.nextDouble() * 20,
        emoji:    dangerEmojis[_rng.nextInt(dangerEmojis.length)],
        scale:    0.0,
        rotation: (_rng.nextDouble() - 0.5) * 0.5,
      ));
    });
  }

  void _spawnOneUp() {
    setState(() {
      _objects.add(FallingObject(
        x:       0.1 + _rng.nextDouble() * 0.8,
        y:       -0.06,
        speed:   _baseSpeed * 0.52,
        size:    46,
        emoji:   '🆙',
        isOneUp: true,
        scale:   0.0,
      ));
    });
  }

  // ── Tick (~60 fps) ────────────────────────────────────────────────────────────
  void _tick() {
    if (_state != GameState.playing) return;
    setState(() {
      _score++;
      _playerX += (_targetX - _playerX) * 0.2; // smooth lerp

      // Move objects
      for (final o in _objects) {
        if (o.scale < 1.0) o.scale = (o.scale + 0.14).clamp(0, 1);
        o.y        += o.speed;
        o.rotation += o.isOneUp ? 0 : 0.02;
      }
      _objects.removeWhere((o) => o.y > 1.1);

      // Float texts
      for (final t in _floatingTexts) {
        t.y       -= 0.007;
        t.opacity -= 0.016;
      }
      _floatingTexts.removeWhere((t) => t.opacity <= 0);

      // Particles
      for (final p in _particles) {
        p.x       += p.vx;
        p.y       += p.vy;
        p.vy      += 0.001; // gravity
        p.opacity -= 0.022;
      }
      _particles.removeWhere((p) => p.opacity <= 0);

      // Invincibility blink
      if (_invincible) {
        _invincibleTicks--;
        _playerVisible = (_invincibleTicks % 8) < 4;
        if (_invincibleTicks <= 0) {
          _invincible    = false;
          _playerVisible = true;
        }
      }

      // 1-UP spawn countdown
      _nextOneUpTicks--;
      if (_nextOneUpTicks <= 0) {
        _spawnOneUp();
        _nextOneUpTicks = _rng.nextInt(480) + 360;
      }

      _checkCollision();
    });
  }

  // ── Collision detection ────────────────────────────────────────────────────────
  void _checkCollision() {
    if (_screen == Size.zero) return;
    final sw = _screen.width, sh = _screen.height;
    final px = _playerX * sw;
    final py = sh - playerBottom - playerSize / 2;
    const pR = playerSize * 0.44;

    for (final o in List<FallingObject>.from(_objects)) {
      if (o.scale < 0.6) continue;
      final dist = sqrt(pow(px - o.x * sw, 2) + pow(py - o.y * sh, 2));
      if (dist < pR + o.size * 0.5 * 0.58) {
        if (o.isOneUp) {
          _collectOneUp(o);
        } else if (!_invincible) {
          _takeDamage(o);
          if (_state == GameState.gameOver) return;
        }
      }
    }
  }

  void _collectOneUp(FallingObject o) {
    _objects.remove(o);
    HapticFeedback.lightImpact();
    _oneUpCtrl.forward(from: 0);
    _burst(o.x, o.y, ['💚', '✨', '⭐', '🌟']);
    if (_lives < maxLives) {
      _lives++;
      _addFloat(o.x, o.y, '+1 UP! ❤️', Colors.greenAccent);
    } else {
      _addFloat(o.x, o.y, '💛 MAX LIVES!', Colors.amber);
    }
  }

  void _takeDamage(FallingObject o) {
    _objects.remove(o);
    _lives--;
    HapticFeedback.heavyImpact();
    _flashCtrl.forward(from: 0);
    _shakeCtrl.forward(from: 0);
    _burst(_playerX, 0.85, burstEmojis);
    if (_lives <= 0) {
      _triggerGameOver();
    } else {
      _addFloat(_playerX, 0.82, '-1 ❤️', Colors.redAccent);
      _invincible      = true;
      _invincibleTicks = 130;
    }
  }

  void _addFloat(double x, double y, String text, Color color) =>
      _floatingTexts.add(FloatingText(x: x, y: y, text: text, color: color));

  void _burst(double x, double y, List<String> emojis) {
    for (int i = 0; i < 9; i++) {
      final angle = i * 2 * pi / 9 + _rng.nextDouble() * 0.5;
      final spd   = 0.008 + _rng.nextDouble() * 0.013;
      _particles.add(Particle(
        x:     x,
        y:     y,
        vx:    cos(angle) * spd,
        vy:    sin(angle) * spd - 0.012,
        emoji: emojis[_rng.nextInt(emojis.length)],
        size:  13 + _rng.nextDouble() * 14,
      ));
    }
  }

  void _triggerGameOver() {
    _gameLoop?.cancel();
    _spawnTimer?.cancel();
    _diffTimer?.cancel();
    if (_score > _highScore) _highScore = _score;
    setState(() => _state = GameState.gameOver);
    _startBgAnimation();
  }

  void _stopAll() {
    _gameLoop?.cancel();
    _spawnTimer?.cancel();
    _diffTimer?.cancel();
    _stopBgAnimation();
  }

  void _goToMenu() {
    _stopAll();
    setState(() {
      _state         = GameState.menu;
      _objects       = [];
      _floatingTexts = [];
      _particles     = [];
    });
    _startBgAnimation();
  }

  // ── Input ─────────────────────────────────────────────────────────────────────
  void _onDrag(DragUpdateDetails d) {
    if (_state != GameState.playing) return;
    setState(() => _targetX = (_targetX + d.delta.dx / _screen.width).clamp(0.05, 0.95));
  }

  void _onTap(TapDownDetails d) {
    if (_state != GameState.playing) return;
    setState(() => _targetX = (d.localPosition.dx / _screen.width).clamp(0.05, 0.95));
  }

  // ── Build ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (ctx, c) {
        _screen = Size(c.maxWidth, c.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: _onDrag,
          onTapDown: _onTap,
          child: AnimatedBuilder(
            animation: Listenable.merge([_shakeAnim, _flashAnim, _oneUpAnim, _globalAnim]),
            builder: (_, child) {
              final shake = sin(_shakeAnim.value * pi * 12) * 18 * (1 - _shakeAnim.value);
              return Stack(children: [
                Transform.translate(offset: Offset(shake, 0), child: child),
                // Red damage flash
                if (_flashAnim.value > 0.01)
                  IgnorePointer(
                    child: Container(
                      color: Colors.red.withOpacity(
                        _flashAnim.value * (1 - _flashAnim.value) * 4 * 0.38,
                      ),
                    ),
                  ),
                // Green 1-UP flash
                if (_oneUpAnim.value > 0.01 && _oneUpAnim.value < 0.99)
                  IgnorePointer(
                    child: Container(
                      color: Colors.greenAccent.withOpacity(
                        sin(_oneUpAnim.value * pi) * 0.22,
                      ),
                    ),
                  ),
              ]);
            },
            child: _buildScene(),
          ),
        );
      }),
    );
  }

  Widget _buildScene() {
    return Stack(children: [
      _buildBackground(),
      if (_state == GameState.menu)     _buildMenuScreen(),
      if (_state == GameState.playing)  _buildGameplay(),
      if (_state == GameState.gameOver) _buildGameOverScreen(),
    ]);
  }

  // ── Background ────────────────────────────────────────────────────────────────
  Widget _buildBackground() {
    final sw = _screen.width, sh = _screen.height;
    return SizedBox.expand(
      child: Stack(children: [
        // Deep space gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF04040F), Color(0xFF0B0B25), Color(0xFF07101E)],
            ),
          ),
        ),
        // Twinkling stars
        ...List.generate(48, (i) {
          final rx = (i * 131.7 % 100) / 100;
          final ry = (i * 83.1 % 100) / 100;
          return Positioned(
            left: rx * sw,
            top:  ry * sh * 0.8,
            child: AnimatedBuilder(
              animation: _globalAnim,
              builder: (_, __) => Opacity(
                opacity: (0.1 + 0.7 * sin(_globalAnim.value * 2 * pi + i * 1.1).abs())
                    .clamp(0.0, 1.0),
                child: Text(
                  bgStars[i % bgStars.length],
                  style: TextStyle(fontSize: 7.0 + (i % 5) * 2.5),
                ),
              ),
            ),
          );
        }),
        // Decorative bg falling emojis (menu / game-over)
        if (_state != GameState.playing)
          ..._bgObjects.map((o) => Positioned(
            left: o.x * sw - o.size / 2,
            top:  o.y * sh - o.size / 2,
            child: Transform.rotate(
              angle: o.rotation,
              child: Opacity(
                opacity: 0.15,
                child: Text(o.emoji, style: TextStyle(fontSize: o.size)),
              ),
            ),
          )),
      ]),
    );
  }

  // ── MENU SCREEN ───────────────────────────────────────────────────────────────
  Widget _buildMenuScreen() {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Animated title block
          AnimatedBuilder(
            animation: Listenable.merge([_globalAnim, _titleAnim]),
            builder: (_, __) {
              final wave = _globalAnim.value * 2 * pi;
              return Column(children: [
                Transform.translate(
                  offset: Offset(sin(wave * 0.7) * 5, sin(wave) * 9),
                  child: const Text('🧑', style: TextStyle(fontSize: 80)),
                ),
                const SizedBox(height: 20),
                Transform.scale(
                  scale: _titleAnim.value,
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: const [
                        Color(0xFF00F5FF), Color(0xFF8B5CF6),
                        Color(0xFFFF0080), Color(0xFF00F5FF),
                      ],
                      stops: const [0, 0.33, 0.66, 1],
                      transform: GradientRotation(_globalAnim.value * 2 * pi),
                    ).createShader(bounds),
                    child: const Text(
                      'EMOJI\nDODGER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 7,
                        height: 1.05,
                      ),
                    ),
                  ),
                ),
              ]);
            },
          ),

          const SizedBox(height: 10),
          Text(
            'Survive the emoji storm!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.48),
              fontSize: 14,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 20),

          // Waving danger emojis row
          AnimatedBuilder(
            animation: _globalAnim,
            builder: (_, __) => SizedBox(
              height: 46,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(7, (i) {
                  final dy = sin(_globalAnim.value * 2 * pi + i * 0.95) * 10;
                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(dangerEmojis[i], style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }),
              ),
            ),
          ),

          const Spacer(flex: 1),

          // High score badge
          if (_highScore > 0) ...[
            _glassCard(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(
                    'BEST  ${_formatScore(_highScore)}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      shadows: [Shadow(color: Colors.amber, blurRadius: 10)],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ] else
            const SizedBox(height: 10),

          // Play button
          _glowButton('▶  PLAY', const Color(0xFF00F5FF), _startGame),

          const SizedBox(height: 22),

          // Info pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoPill('❤️ × $startLives  Start Lives'),
              const SizedBox(width: 10),
              _infoPill('🆙  = +1 Life'),
            ],
          ),

          const Spacer(flex: 2),

          Text(
            'Drag or tap to move',
            style: TextStyle(
              color: Colors.white.withOpacity(0.22),
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── GAMEPLAY ──────────────────────────────────────────────────────────────────
  Widget _buildGameplay() {
    final sw = _screen.width, sh = _screen.height;
    return Stack(children: [

      // Ground glow
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: Container(
          height: playerBottom + playerSize + 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, const Color(0xFF0D47A1).withOpacity(0.4)],
            ),
          ),
        ),
      ),

      // Particles
      ..._particles.map((p) => Positioned(
        left: p.x * sw - p.size / 2,
        top:  p.y * sh - p.size / 2,
        child: Opacity(
          opacity: p.opacity.clamp(0.0, 1.0),
          child: Text(p.emoji, style: TextStyle(fontSize: p.size)),
        ),
      )),

      // Falling objects
      ..._objects.map((o) => Positioned(
        left: o.x * sw - o.size / 2,
        top:  o.y * sh - o.size / 2,
        child: Transform.scale(
          scale: o.scale,
          child: o.isOneUp
              ? _buildOneUpWidget(o)
              : Transform.rotate(
            angle: o.rotation,
            child: Text(o.emoji, style: TextStyle(fontSize: o.size, height: 1)),
          ),
        ),
      )),

      // Floating texts
      ..._floatingTexts.map((t) => Positioned(
        left: t.x * sw - 60,
        top:  t.y * sh,
        child: Opacity(
          opacity: t.opacity.clamp(0.0, 1.0),
          child: Text(
            t.text,
            style: TextStyle(
              color: t.color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: t.color, blurRadius: 12)],
            ),
          ),
        ),
      )),

      // Player
      if (_playerVisible)
        Positioned(
          left:   _playerX * sw - playerSize / 2,
          bottom: playerBottom,
          child:  _buildPlayerWidget(),
        ),

      // HUD
      Positioned(
        top:  MediaQuery.of(context).padding.top + 14,
        left: 0, right: 0,
        child: _buildHUD(),
      ),
    ]);
  }

  Widget _buildOneUpWidget(FallingObject o) {
    return AnimatedBuilder(
      animation: _globalAnim,
      builder: (_, __) {
        final pulse = 0.88 + sin(_globalAnim.value * 2 * pi * 2) * 0.12;
        return Transform.scale(
          scale: pulse,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width:  o.size + 20,
              height: o.size + 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.6),
                    blurRadius: 24,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
            Text('🆙', style: TextStyle(fontSize: o.size, height: 1)),
          ]),
        );
      },
    );
  }

  Widget _buildPlayerWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: playerSize + 10,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.75),
                blurRadius: 24,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        const Text('🧑', style: TextStyle(fontSize: playerSize, height: 1)),
      ],
    );
  }

  Widget _buildHUD() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Hearts
          Row(
            children: List.generate(maxLives, (i) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Text(
                i < _lives ? '❤️' : '🖤',
                style: TextStyle(
                  fontSize: 22,
                  shadows: i < _lives
                      ? [const Shadow(color: Colors.redAccent, blurRadius: 8)]
                      : null,
                ),
              ),
            )),
          ),
          // Score
          _hudChip('⭐  ${_formatScore(_score)}', Colors.amber),
        ],
      ),
    );
  }

  // ── GAME OVER ─────────────────────────────────────────────────────────────────
  Widget _buildGameOverScreen() {
    final isNewHigh = _score > 0 && _score >= _highScore;
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _globalAnim,
              builder: (_, __) => Transform.rotate(
                angle: sin(_globalAnim.value * 2 * pi * 1.5) * 0.12,
                child: const Text('💥', style: TextStyle(fontSize: 90)),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Color(0xFFFF2D55),
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                shadows: [Shadow(color: Color(0xFFFF2D55), blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 30),

            // Score card
            _glassCard(
              wide: true,
              child: Column(children: [
                _statRow('⭐  Score', _formatScore(_score), Colors.amber),
                const SizedBox(height: 4),
                Divider(color: Colors.white.withOpacity(0.1), height: 26),
                _statRow('🏆  Best', _formatScore(_highScore), Colors.cyanAccent),
                if (isNewHigh) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.45), width: 1.5,
                      ),
                    ),
                    child: const Text(
                      '🎉  New High Score!',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ]),
            ),

            const SizedBox(height: 32),
            _glowButton('🔄  PLAY AGAIN', Colors.greenAccent, _startGame),
            const SizedBox(height: 14),
            TextButton(
              onPressed: _goToMenu,
              child: Text(
                '← Main Menu',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 15,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared UI helpers ─────────────────────────────────────────────────────────

  Widget _glowButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _titleAnim,
        builder: (_, __) => Transform.scale(
          scale: _titleAnim.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 17),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.55)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.55), blurRadius: 32, spreadRadius: 2),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child, bool wide = false}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: wide ? 30 : 52),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.13), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24)],
      ),
      child: child,
    );
  }

  Widget _infoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, letterSpacing: 0.8),
      ),
    );
  }

  Widget _hudChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.55), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.22), blurRadius: 10)],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          shadows: [Shadow(color: color, blurRadius: 6)],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 16)),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: color, blurRadius: 10)],
          ),
        ),
      ],
    );
  }

  // ── Utils ─────────────────────────────────────────────────────────────────────
  String _formatScore(int s) =>
      s >= 1000 ? '${(s / 1000).toStringAsFixed(1)}k' : '$s';
}