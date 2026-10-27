import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

/// Screen dedicated to the song "Can't Falling in Love".
/// Displays a rotating vinyl album photo of the couple/song.
/// Requires the song to finish playing before allowing progression to Dashboard.
class SongDedicationScreen extends StatefulWidget {
  const SongDedicationScreen({super.key});

  @override
  State<SongDedicationScreen> createState() => _SongDedicationScreenState();
}

class _SongDedicationScreenState extends State<SongDedicationScreen>
    with SingleTickerProviderStateMixin {
  late final AudioPlayer _player;
  late final AnimationController _rotationController;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<void>? _completeSub;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  PlayerState _playerState = PlayerState.stopped;

  bool _isCompleted = false;
  bool _isLoadingAudio = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      _positionSub = _player.onPositionChanged.listen((pos) {
        if (!mounted) return;
        setState(() {
          _currentPosition = pos;
          if (_totalDuration.inSeconds > 0 &&
              pos.inSeconds >= _totalDuration.inSeconds - 1) {
            _isCompleted = true;
          }
        });
      });

      _durationSub = _player.onDurationChanged.listen((dur) {
        if (!mounted) return;
        setState(() {
          _totalDuration = dur;
        });
      });

      _stateSub = _player.onPlayerStateChanged.listen((state) {
        if (!mounted) return;
        setState(() {
          _playerState = state;
        });

        if (state == PlayerState.playing) {
          if (!_rotationController.isAnimating) {
            _rotationController.repeat();
          }
        } else {
          if (_rotationController.isAnimating) {
            _rotationController.stop();
          }
        }
      });

      _completeSub = _player.onPlayerComplete.listen((_) {
        if (!mounted) return;
        setState(() {
          _isCompleted = true;
          _currentPosition = _totalDuration;
          _playerState = PlayerState.completed;
        });
        _rotationController.stop();
      });

      // Prepare audio source
      await _player.setSource(AssetSource('audio/cant_help_falling_in_love.mp3'));

      // Attempt initial play
      await _player.resume();

      if (mounted) {
        setState(() {
          _isLoadingAudio = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAudio = false;
          _errorMessage = 'Tap play to start the music';
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else {
      if (_playerState == PlayerState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.resume();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _progress {
    if (_totalDuration.inMilliseconds == 0) return 0.0;
    final val =
        _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
    return val.clamp(0.0, 1.0);
  }

  Future<void> _skipToDashboard() async {
    try {
      await _player.stop();
    } catch (_) {}
    if (mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _rotationController.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                    vertical: AppTheme.spacingS,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppTheme.spacingM),
                      _buildHeader(),
                      const SizedBox(height: AppTheme.spacingXL),
                      _buildVinylArtwork(),
                      const SizedBox(height: AppTheme.spacingXL),
                      _buildSongDetails(),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildProgressBar(),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildPlaybackControls(),
                      const SizedBox(height: AppTheme.spacingXL),
                      _buildProceedSection(),
                      const SizedBox(height: AppTheme.spacingL),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppTheme.textSecondary,
            onPressed: () => context.go(AppRoutes.developerMessage),
          ),
          TextButton.icon(
            onPressed: _skipToDashboard,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentVioletLight,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              backgroundColor: AppTheme.accentViolet.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: AppTheme.accentViolet.withValues(alpha: 0.35),
                ),
              ),
            ),
            icon: const Icon(Icons.skip_next_rounded, size: 18),
            label: const Text(
              'Skip Song',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.accentVioletLight, AppTheme.accentRoseLight],
          ).createShader(bounds),
          child: Text(
            'A song dedicated to my love',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          'Listen with all your heart to continue',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                letterSpacing: 0.3,
              ),
        ),
      ],
    );
  }

  Widget _buildVinylArtwork() {
    final isPlaying = _playerState == PlayerState.playing;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer subtle glowing aura
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            width: 270,
            height: 270,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isPlaying ? AppTheme.accentViolet : Colors.transparent)
                      .withAlpha(80),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: (isPlaying ? AppTheme.accentRose : Colors.transparent)
                      .withAlpha(50),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // Vinyl record body
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F0B17),
              border: Border.all(
                color: AppTheme.accentViolet.withAlpha(80),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(180),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Concentric vinyl grooves
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(12),
                      width: 1,
                    ),
                  ),
                ),
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(15),
                      width: 1,
                    ),
                  ),
                ),

                // Rotating center photo
                RotationTransition(
                  turns: _rotationController,
                  child: Container(
                    width: 155,
                    height: 155,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accentRoseLight.withAlpha(180),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentRose.withAlpha(90),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/song_image.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, error, stackTrace) {
                          return Container(
                            color: AppTheme.cardColor,
                            child: const Center(
                              child: Icon(
                                Icons.music_note_rounded,
                                size: 50,
                                color: AppTheme.accentVioletLight,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongDetails() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.music_note_rounded,
              size: 20,
              color: AppTheme.accentVioletLight,
            ),
            const SizedBox(width: 8),
            Text(
              "Can't Falling in Love",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(width: 8),
            const FloatingHeart(size: 14),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Forever & Always Dedicated to You',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 6,
            backgroundColor: AppTheme.cardColor,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.accentVioletLight,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(_currentPosition),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            Text(
              _totalDuration == Duration.zero
                  ? '--:--'
                  : _formatDuration(_totalDuration),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    final isPlaying = _playerState == PlayerState.playing;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Replay button
        IconButton(
          icon: const Icon(Icons.replay_10_rounded),
          color: AppTheme.textSecondary,
          iconSize: 28,
          onPressed: () async {
            final newPos = _currentPosition - const Duration(seconds: 10);
            await _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
          },
        ),
        const SizedBox(width: AppTheme.spacingL),

        // Big play / pause button
        GestureDetector(
          onTap: _isLoadingAudio ? null : _togglePlayPause,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.accentGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentViolet.withAlpha(140),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: _isLoadingAudio
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingL),

        // Forward button (allowed only up to 10s if already listened)
        IconButton(
          icon: const Icon(Icons.forward_10_rounded),
          color: _isCompleted ? AppTheme.textSecondary : AppTheme.textMuted,
          iconSize: 28,
          onPressed: _isCompleted
              ? () async {
                  final newPos = _currentPosition + const Duration(seconds: 10);
                  if (newPos <= _totalDuration) {
                    await _player.seek(newPos);
                  }
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildProceedSection() {
    final percentage = (_progress * 100).toInt();

    return Column(
      children: [
        if (!_isCompleted) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentViolet.withAlpha(40),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.music_note_rounded,
                  size: 16,
                  color: AppTheme.accentRoseLight,
                ),
                const SizedBox(width: 8),
                Text(
                  'Playing dedicated song ($percentage% completed)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          GradientButton(
            label: 'Skip & Enter App Paril',
            icon: Icons.skip_next_rounded,
            onPressed: _skipToDashboard,
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppTheme.accentViolet.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentViolet.withAlpha(120),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: AppTheme.accentRoseLight,
                ),
                const SizedBox(width: 8),
                Text(
                  'Song completed! You can now proceed ❤️',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          GradientButton(
            label: 'Enter App Paril',
            icon: Icons.arrow_forward_rounded,
            onPressed: _skipToDashboard,
          ),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: AppTheme.spacingS),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
          ),
        ],
      ],
    );
  }
}
