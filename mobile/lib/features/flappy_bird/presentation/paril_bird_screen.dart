import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:audioplayers/audioplayers.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/mongo_db_service.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/models/game_models.dart';
import 'paril_bird_painter.dart';

enum GameState { ready, playing, paused, gameOver }

/// Main screen for Paril's Flappy Bird game.
class ParilBirdScreen extends StatefulWidget {
  const ParilBirdScreen({super.key});

  @override
  State<ParilBirdScreen> createState() => _ParilBirdScreenState();
}

class _ParilBirdScreenState extends State<ParilBirdScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final math.Random _random = math.Random();

  // Assets
  ui.Image? _birdImage;
  ui.Image? _crashedImage;
  ui.Image? _bgImage;

  // Game state
  GameState _gameState = GameState.ready;
  int _score = 0;
  int _highScore = 0;
  int _iceCreamCount = 0;
  int _lifetimeIceCreams = 0;
  bool _isNewHighScore = false;

  // Physics constants
  static const double _gravity = 920.0;
  static const double _flapImpulse = -350.0;
  static const double _forwardSpeed = 165.0;
  static const double _groundHeight = 75.0;
  static const double _birdX = 85.0;
  static const double _birdRadius = 18.0;
  static const double _obstacleWidth = 66.0;
  static const double _obstacleGap = 180.0;
  static const double _obstacleSpacing = 240.0;

  // Dynamic game world values
  double _birdY = 250.0;
  double _birdVelocity = 0.0;
  double _groundOffset = 0.0;
  double _elapsedTime = 0.0;
  Duration _lastTickDuration = Duration.zero;

  // Obstacles, Items, and Effects
  final List<VegetableObstacle> _obstacles = [];
  final List<IceCreamBonus> _iceCreams = [];
  final List<GameParticle> _particles = [];
  final List<FloatingScoreText> _floatingTexts = [];
  double _trailSpawnTimer = 0.0;

  // Audio
  late final AudioPlayer _bgmPlayer;
  late final AudioPlayer _sfxPlayer;
  bool _isMusicMuted = false;

  @override
  void initState() {
    super.initState();
    _bgmPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();
    _initAudio();
    _loadHighScore();
    _loadAssets();

    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  Future<void> _initAudio() async {
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setSource(
        AssetSource(
          'audio/Subway Surfers_ (Main Theme)_ 2012 Original [OFFICIAL].mp3',
        ),
      );
    } catch (_) {
      // Audio fallback for environments without audio device
    }
  }

  void _startBgm() {
    if (_isMusicMuted) return;
    try {
      _bgmPlayer.resume();
    } catch (_) {}
  }

  void _pauseBgm() {
    try {
      _bgmPlayer.pause();
    } catch (_) {}
  }

  void _stopBgm() {
    try {
      _bgmPlayer.stop();
    } catch (_) {}
  }

  void _playCrashSound() {
    if (_isMusicMuted) return;
    try {
      _sfxPlayer.play(AssetSource('audio/crashed_sound.mp3'));
    } catch (_) {}
  }

  void _toggleMusicMute() {
    setState(() {
      _isMusicMuted = !_isMusicMuted;
    });
    if (_isMusicMuted) {
      _pauseBgm();
    } else {
      if (_gameState == GameState.playing) {
        _startBgm();
      }
    }
  }

  Future<void> _loadHighScore() async {
    final storage = await LocalStorageService.getInstance();
    if (!mounted) return;
    setState(() {
      _highScore = storage.getFlappyHighScore();
      _lifetimeIceCreams = storage.getFlappyIceCreamCount();
    });
  }

  Future<void> _loadAssets() async {
    try {
      final birdData = await rootBundle.load('assets/images/paril_bird.png');
      final birdBytes = birdData.buffer.asUint8List();
      final birdCodec = await ui.instantiateImageCodec(birdBytes);
      final birdFrame = await birdCodec.getNextFrame();
      if (mounted) {
        setState(() {
          _birdImage = birdFrame.image;
        });
      }
    } catch (_) {}

    try {
      final crashData = await rootBundle.load('assets/images/crahsed.jpeg');
      final crashBytes = crashData.buffer.asUint8List();
      final crashCodec = await ui.instantiateImageCodec(crashBytes);
      final crashFrame = await crashCodec.getNextFrame();
      if (mounted) {
        setState(() {
          _crashedImage = crashFrame.image;
        });
      }
    } catch (_) {}

    try {
      final bgData = await rootBundle.load('assets/images/paril_bird_background.webp');
      final bgBytes = bgData.buffer.asUint8List();
      final bgCodec = await ui.instantiateImageCodec(bgBytes);
      final bgFrame = await bgCodec.getNextFrame();
      if (mounted) {
        setState(() {
          _bgImage = bgFrame.image;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stopBgm();
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  void _onTick(Duration currentDuration) {
    if (!mounted) return;

    if (_lastTickDuration == Duration.zero) {
      _lastTickDuration = currentDuration;
      return;
    }

    final double dt =
        ((currentDuration - _lastTickDuration).inMicroseconds / 1000000.0)
            .clamp(0.001, 0.035);
    _lastTickDuration = currentDuration;

    _elapsedTime += dt;

    if (_gameState == GameState.playing) {
      _updatePlaying(dt);
    } else if (_gameState == GameState.ready) {
      _updateReady(dt);
    } else if (_gameState == GameState.gameOver) {
      _updateGameOver(dt);
    }

    setState(() {});
  }

  void _updateReady(double dt) {
    // Gentle bobbing motion
    final size = MediaQuery.maybeOf(context)?.size ?? const Size(400, 700);
    _birdY = (size.height * 0.42) + math.sin(_elapsedTime * 4.0) * 10.0;
    _birdVelocity = 0.0;
    _groundOffset += _forwardSpeed * 0.4 * dt;
  }

  void _updateGameOver(double dt) {
    final size = MediaQuery.maybeOf(context)?.size ?? const Size(400, 700);
    final maxGround = size.height - _groundHeight - _birdRadius;

    // Bird continues falling until it rests on ground
    if (_birdY < maxGround) {
      _birdVelocity += _gravity * dt;
      _birdY += _birdVelocity * dt;
      if (_birdY > maxGround) {
        _birdY = maxGround;
        _birdVelocity = 0.0;
      }
    }

    // Update remaining particles
    _updateEffects(dt);
  }

  void _updatePlaying(double dt) {
    final size = MediaQuery.maybeOf(context)?.size ?? const Size(400, 700);
    final groundLimit = size.height - _groundHeight - _birdRadius;

    // Apply gravity
    _birdVelocity += _gravity * dt;
    _birdY += _birdVelocity * dt;

    // Sky ceiling clamp
    if (_birdY < _birdRadius) {
      _birdY = _birdRadius;
      _birdVelocity = 0.0;
    }

    // Ground collision
    if (_birdY >= groundLimit) {
      _birdY = groundLimit;
      _triggerGameOver();
      return;
    }

    // Ground scroll
    _groundOffset += _forwardSpeed * dt;

    // Move obstacles & ice creams
    _updateObstacles(dt, size);
    _updateIceCreams(dt);

    // Trail particles
    _trailSpawnTimer += dt;
    if (_trailSpawnTimer > 0.08) {
      _trailSpawnTimer = 0.0;
      _spawnTrailParticle();
    }

    _updateEffects(dt);

    // Check collisions
    _checkCollisions(size);
  }

  void _spawnTrailParticle() {
    final isHeart = _random.nextDouble() > 0.4;
    _particles.add(
      GameParticle(
        x: _birdX - 22,
        y: _birdY + (_random.nextDouble() * 12 - 6),
        vx: -_forwardSpeed * 0.5 + (_random.nextDouble() * 20 - 10),
        vy: (_random.nextDouble() * 30 - 15),
        size: isHeart ? 7.0 : 4.0,
        color: isHeart
            ? const Color(0xFFFF4081)
            : const Color(0xFFE040FB),
        decay: 0.045,
        isHeart: isHeart,
      ),
    );
  }

  void _updateObstacles(double dt, Size size) {
    // Move existing obstacles
    for (final obs in _obstacles) {
      obs.x -= _forwardSpeed * dt;

      // Score when passing obstacle
      if (!obs.passed && obs.x + obs.width < _birdX) {
        obs.passed = true;
        _score++;
        _onScorePoint();
      }
    }

    // Remove off-screen obstacles
    _obstacles.removeWhere((obs) => obs.x + obs.width < -20);

    // Spawn new obstacles
    if (_obstacles.isEmpty) {
      _spawnObstacle(size.width + 100, size);
    } else {
      final lastObs = _obstacles.last;
      if (lastObs.x < size.width - _obstacleSpacing) {
        _spawnObstacle(size.width, size);
      }
    }
  }

  void _spawnObstacle(double spawnX, Size size) {
    final playableHeight = size.height - _groundHeight - _obstacleGap;
    const minHeight = 60.0;
    final maxHeight = playableHeight - minHeight;

    final topHeight = (minHeight + _random.nextDouble() * (maxHeight - minHeight))
        .clamp(minHeight, maxHeight > minHeight ? maxHeight : minHeight + 10);

    // Pick random vegetable type
    final types = VegetableType.values;
    final type = types[_random.nextInt(types.length)];

    final obs = VegetableObstacle(
      x: spawnX,
      width: _obstacleWidth,
      topHeight: topHeight,
      gap: _obstacleGap,
      type: type,
    );
    _obstacles.add(obs);

    // 70% chance to spawn an ice cream bonus in the gap
    if (_random.nextDouble() < 0.70) {
      final iceY = topHeight + (_obstacleGap * (0.35 + _random.nextDouble() * 0.3));
      final flavor = _random.nextInt(3);
      _iceCreams.add(
        IceCreamBonus(
          x: spawnX + _obstacleWidth / 2,
          y: iceY,
          flavorIndex: flavor,
        ),
      );
    }
  }

  void _updateIceCreams(double dt) {
    for (final ice in _iceCreams) {
      ice.x -= _forwardSpeed * dt;
    }
    _iceCreams.removeWhere((ice) => ice.x < -40 || (ice.collected && ice.x < _birdX));
  }

  void _updateEffects(double dt) {
    for (final p in _particles) {
      p.update(dt);
    }
    _particles.removeWhere((p) => p.isDead);

    for (final ft in _floatingTexts) {
      ft.update(dt);
    }
    _floatingTexts.removeWhere((ft) => ft.isDead);
  }

  void _checkCollisions(Size size) {
    final birdCenter = Offset(_birdX, _birdY);

    // 1. Check Ice Cream bonus pickups
    for (final ice in _iceCreams) {
      if (ice.collected) continue;
      final dist = (birdCenter - Offset(ice.x, ice.y)).distance;
      if (dist < _birdRadius + ice.radius) {
        ice.collected = true;
        _collectIceCream(ice);
      }
    }

    // 2. Check Vegetable Obstacle collisions
    const gracePadding = 5.0; // Grace margin for player comfort
    final birdHitbox = Rect.fromCircle(
      center: birdCenter,
      radius: _birdRadius - gracePadding,
    );

    for (final obs in _obstacles) {
      final topRect = obs.topRect;
      final bottomRect = obs.bottomRect(size.height, _groundHeight);

      if (birdHitbox.overlaps(topRect) || birdHitbox.overlaps(bottomRect)) {
        _triggerGameOver();
        return;
      }
    }
  }

  void _collectIceCream(IceCreamBonus ice) {
    _score += 5;
    _iceCreamCount++;
    _lifetimeIceCreams++;

    // Save lifetime ice creams
    LocalStorageService.getInstance().then((s) {
      s.setFlappyIceCreamCount(_lifetimeIceCreams);
    });

    HapticFeedback.lightImpact();

    // Spawn bonus particles
    for (int i = 0; i < 12; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 40.0 + _random.nextDouble() * 80.0;
      _particles.add(
        GameParticle(
          x: ice.x,
          y: ice.y,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: 5.0 + _random.nextDouble() * 3.0,
          color: i % 2 == 0 ? const Color(0xFFFF4081) : const Color(0xFFFFD54F),
          decay: 0.035,
          isHeart: i % 3 == 0,
        ),
      );
    }

    // Floating text
    _floatingTexts.add(
      FloatingScoreText(
        x: ice.x,
        y: ice.y - 10,
        text: '+5 🍦 Sweet!',
      ),
    );

    _checkHighScore();
  }

  void _onScorePoint() {
    HapticFeedback.selectionClick();
    _checkHighScore();

    // Gentle star burst on passing
    for (int i = 0; i < 4; i++) {
      _particles.add(
        GameParticle(
          x: _birdX,
          y: _birdY,
          vx: -30.0 + _random.nextDouble() * 60.0,
          vy: -20.0 - _random.nextDouble() * 40.0,
          size: 4.0,
          color: const Color(0xFFFFD700),
          decay: 0.05,
        ),
      );
    }
  }

  void _checkHighScore() {
    if (_score > _highScore) {
      _highScore = _score;
      _isNewHighScore = true;
      LocalStorageService.getInstance().then((s) {
        s.setFlappyHighScore(_highScore);
      });
    }
  }

  void _triggerGameOver() {
    _stopBgm(); // Stop music upon crash
    _playCrashSound(); // Play hilarious crash sound effect!
    HapticFeedback.heavyImpact();
    setState(() {
      _gameState = GameState.gameOver;
    });

    // Crash explosion particles
    for (int i = 0; i < 20; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 60.0 + _random.nextDouble() * 120.0;
      _particles.add(
        GameParticle(
          x: _birdX,
          y: _birdY,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: 6.0,
          color: i % 2 == 0 ? const Color(0xFFFF5252) : const Color(0xFFFF4081),
          decay: 0.03,
          isHeart: i % 2 == 0,
        ),
      );
    }

    // Persist final scores locally
    LocalStorageService.getInstance().then((s) {
      if (_score > s.getFlappyHighScore()) {
        s.setFlappyHighScore(_score);
      }
      s.setFlappyIceCreamCount(_lifetimeIceCreams);

      // Submit to MongoDB leaderboard (fire and forget)
      final playerName = s.getPlayerName() ?? 'Paril 💜';
      final role = s.getRole().name;
      MongoDbService().submitScore(
        playerName: playerName,
        role: role,
        score: _score,
        iceCreamCount: _iceCreamCount,
      );
    });
  }

  void _onTap() {
    if (_gameState == GameState.ready) {
      setState(() {
        _gameState = GameState.playing;
        _birdVelocity = _flapImpulse;
      });
      _startBgm(); // Keep replaying background music while playing
      HapticFeedback.lightImpact();
    } else if (_gameState == GameState.playing) {
      setState(() {
        _birdVelocity = _flapImpulse;
      });
      HapticFeedback.lightImpact();

      // Wing flap sparkle
      _particles.add(
        GameParticle(
          x: _birdX - 10,
          y: _birdY + 12,
          vx: -40.0,
          vy: 20.0,
          size: 5.0,
          color: const Color(0xFFE040FB),
          decay: 0.06,
          isHeart: true,
        ),
      );
    }
  }

  void _restartGame() {
    _stopBgm();
    final size = MediaQuery.maybeOf(context)?.size ?? const Size(400, 700);
    setState(() {
      _gameState = GameState.ready;
      _score = 0;
      _iceCreamCount = 0;
      _isNewHighScore = false;
      _birdY = size.height * 0.42;
      _birdVelocity = 0.0;
      _obstacles.clear();
      _iceCreams.clear();
      _particles.clear();
      _floatingTexts.clear();
    });
  }

  void _togglePause() {
    if (_gameState == GameState.playing) {
      _pauseBgm();
      setState(() {
        _gameState = GameState.paused;
      });
    } else if (_gameState == GameState.paused) {
      _startBgm();
      setState(() {
        _gameState = GameState.playing;
      });
    }
  }

  String _getPraiseMessage(int score) {
    if (score >= 35) return '👑 UNSTOPPABLE QUEEN PARIL! Absolute Legend! 💖';
    if (score >= 20) return '🚀 Super Paril! You flew so high! ✨';
    if (score >= 10) return '🍦 Ice cream powerhouse! So proud of you! 🥰';
    if (score >= 5) return '✨ Beautiful flight, my sweet Paril! Keep going! ❤️';
    return '❤️ Great try, Paril! Tap to fly even further! 💕';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: Stack(
          children: [
            // Game Scene Canvas
            CustomPaint(
              size: size,
              painter: ParilBirdPainter(
                birdY: _birdY,
                birdVelocity: _birdVelocity,
                birdX: _birdX,
                birdImage: _birdImage,
                crashedImage: _crashedImage,
                bgImage: _bgImage,
                obstacles: _obstacles,
                iceCreams: _iceCreams,
                particles: _particles,
                floatingTexts: _floatingTexts,
                groundOffset: _groundOffset,
                groundHeight: _groundHeight,
                elapsedTime: _elapsedTime,
                isPlaying: _gameState == GameState.playing,
                isGameOver: _gameState == GameState.gameOver,
              ),
            ),

            // Top HUD Overlay
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Ice Cream Counter
                    _buildHUDChip(
                      icon: '🍦',
                      label: '$_iceCreamCount',
                      color: const Color(0xFFFF80AB),
                    ),

                    // Current Score
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        '$_score',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: [
                            const Shadow(
                              color: Color(0xFF7B4FBF),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Best Score, Sound & Pause
                    Row(
                      children: [
                        _buildHUDChip(
                          icon: '🏆',
                          label: '$_highScore',
                          color: const Color(0xFFFFD54F),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: _isMusicMuted ? 'Unmute music' : 'Mute music',
                          onPressed: _toggleMusicMute,
                          icon: Icon(
                            _isMusicMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: _gameState == GameState.playing ||
                                  _gameState == GameState.paused
                              ? _togglePause
                              : () => context.go(AppRoutes.dashboard),
                          icon: Icon(
                            _gameState == GameState.paused
                                ? Icons.play_arrow_rounded
                                : (_gameState == GameState.playing
                                    ? Icons.pause_rounded
                                    : Icons.arrow_back_rounded),
                            color: Colors.white,
                            size: 26,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Ready Banner Overlay
            if (_gameState == GameState.ready) _buildReadyOverlay(),

            // Paused Menu Overlay
            if (_gameState == GameState.paused) _buildPausedOverlay(),

            // Game Over Dialog Overlay
            if (_gameState == GameState.gameOver) _buildGameOverOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHUDChip({
    required String icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyOverlay() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppTheme.accentViolet.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentViolet.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.accentGradient.createShader(bounds),
              child: Text(
                'Paril Bird',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Flappy flight adventure!',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _buildRuleItem('🥦', 'Avoid vegetable walls'),
            const SizedBox(height: 10),
            _buildRuleItem('🍦', 'Collect ice cream bonuses (+5 pts)'),
            const SizedBox(height: 10),
            _buildRuleItem('👆', 'Tap anywhere to flap & fly'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentRose.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Tap Screen to Start!',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPausedOverlay() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Game Paused',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _togglePause,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Resume Flight'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _restartGame,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Restart'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => context.go(AppRoutes.dashboard),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _isNewHighScore
                ? const Color(0xFFFFD700)
                : AppTheme.accentRose.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (_isNewHighScore
                      ? const Color(0xFFFFD700)
                      : AppTheme.accentRose)
                  .withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isNewHighScore) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      'NEW BEST SCORE!',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFFD700),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Hilarious Crashed Paril Avatar
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF4081),
                        width: 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4081).withValues(alpha: 0.4),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/crahsed.jpeg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF1744),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        '💥 BONK!',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              'Paril Crashed!',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Scores grid
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDeep.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Score', '$_score'),
                  Container(
                    width: 1,
                    height: 36,
                    color: AppTheme.dividerColor,
                  ),
                  _buildStatColumn('Ice Creams', '$_iceCreamCount 🍦'),
                  Container(
                    width: 1,
                    height: 36,
                    color: AppTheme.dividerColor,
                  ),
                  _buildStatColumn('Best', '$_highScore 🏆'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Romantic encouragement message for Paril
            Text(
              _getPraiseMessage(_score),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.accentRoseLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _restartGame,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Fly Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentViolet,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.dashboard),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to Dashboard'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _showLeaderboard,
              icon: const Icon(Icons.leaderboard_rounded, color: Color(0xFFFFD700)),
              label: const Text(
                '🏆 Leaderboard',
                style: TextStyle(color: Color(0xFFFFD700)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaderboard() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.sizeOf(context).height * 0.75,
              decoration: BoxDecoration(
                color: const Color(0xFF161226),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: AppTheme.accentViolet.withAlpha(60), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(150),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.emoji_events_rounded, color: Colors.black87, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ParilBird Leaderboard',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Top Scores in Paril\'s World 🌍',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white12, height: 1),

                  // Leaderboard List
                  Expanded(
                    child: FutureBuilder<List<LeaderboardEntry>>(
                      future: MongoDbService().fetchLeaderboard(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(Color(0xFFFFD700)),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading high scores…',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final list = snapshot.data ?? [];
                        if (list.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🍦', style: TextStyle(fontSize: 48)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No high scores recorded yet!',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Play a round and crash to save your high score to MongoDB.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => setModalState(() {}),
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Refresh'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentViolet,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final entry = list[index];
                            final rank = index + 1;

                            Color rankColor;
                            Widget rankBadge;
                            if (rank == 1) {
                              rankColor = const Color(0xFFFFD700);
                              rankBadge = const Text('🥇', style: TextStyle(fontSize: 22));
                            } else if (rank == 2) {
                              rankColor = const Color(0xFFE0E0E0);
                              rankBadge = const Text('🥈', style: TextStyle(fontSize: 22));
                            } else if (rank == 3) {
                              rankColor = const Color(0xFFCD7F32);
                              rankBadge = const Text('🥉', style: TextStyle(fontSize: 22));
                            } else {
                              rankColor = AppTheme.textSecondary;
                              rankBadge = Text(
                                '#$rank',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              );
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: rank <= 3
                                    ? rankColor.withAlpha(20)
                                    : const Color(0xFF1E1A33),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: rank <= 3
                                      ? rankColor.withAlpha(120)
                                      : Colors.white10,
                                  width: rank <= 3 ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 36,
                                    child: Center(child: rankBadge),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.playerName,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentViolet.withAlpha(60),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                entry.role.toUpperCase(),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.accentVioletLight,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            if (entry.iceCreamCount > 0) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                '🍦 ${entry.iceCreamCount}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${entry.score}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: rank <= 3 ? rankColor : Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'pts',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
