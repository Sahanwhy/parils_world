import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_router.dart';

class SongItem {
  const SongItem({
    required this.title,
    required this.artist,
    required this.audioAsset,
    required this.coverAsset,
    required this.note,
    required this.badge,
    required this.accentColor,
  });

  final String title;
  final String artist;
  final String audioAsset;
  final String coverAsset;
  final String note;
  final String badge;
  final Color accentColor;
}

class RemindingSongsScreen extends StatefulWidget {
  const RemindingSongsScreen({super.key});

  @override
  State<RemindingSongsScreen> createState() => _RemindingSongsScreenState();
}

class _RemindingSongsScreenState extends State<RemindingSongsScreen>
    with TickerProviderStateMixin {
  late final AudioPlayer _player;
  late final AnimationController _vinylAnim;
  late final AnimationController _pulseAnim;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<void>? _completeSub;

  static const List<SongItem> _songs = [
    SongItem(
      title: 'Sajde',
      artist: 'Arijit Singh, Nihira Joshi',
      audioAsset: 'audio/SAJDE.mp3',
      coverAsset: 'assets/images/sajde_song_cover.jpg',
      note: 'The sacred melody of falling in love and devoting my whole heart to you.',
      badge: "Sahan's Heart 💖",
      accentColor: Color(0xFFFF4081),
    ),
    SongItem(
      title: 'Every Breath You Take',
      artist: 'The Police',
      audioAsset: 'audio/Every Breath You Take.mp3',
      coverAsset: 'assets/images/every_breath_you_take_cover.jpg',
      note: 'Every breath, every move, every smile... I will always be right beside you.',
      badge: 'Forever With You 🌙',
      accentColor: Color(0xFF7C4DFF),
    ),
  ];

  int _currentIndex = 0;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = false;

  bool get _isPlaying => _playerState == PlayerState.playing;

  @override
  void initState() {
    super.initState();
    _vinylAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    _posSub = _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });

    _durSub = _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });

    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _playerState = s);
      if (s == PlayerState.playing) {
        if (!_vinylAnim.isAnimating) _vinylAnim.repeat();
      } else {
        _vinylAnim.stop();
      }
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      _playNext();
    });
  }

  Future<void> _playSong(int index) async {
    setState(() {
      _currentIndex = index;
      _isLoading = true;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    try {
      await _player.stop();
      await _player.play(AssetSource(_songs[index].audioAsset));
    } catch (_) {
      // Audio error handling
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_playerState == PlayerState.paused) {
        await _player.resume();
      } else {
        await _playSong(_currentIndex);
      }
    }
  }

  void _playNext() {
    final nextIndex = (_currentIndex + 1) % _songs.length;
    _playSong(nextIndex);
  }

  void _playPrevious() {
    final prevIndex = (_currentIndex - 1 + _songs.length) % _songs.length;
    _playSong(prevIndex);
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _vinylAnim.dispose();
    _pulseAnim.dispose();
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = _songs[_currentIndex];

    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: Stack(
        children: [
          // Ambient dynamic background
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    Color.lerp(
                      currentSong.accentColor.withValues(alpha: 0.28),
                      const Color(0xFF1E0A32),
                      _pulseAnim.value,
                    )!,
                    AppTheme.backgroundDeep,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // Title & Subtitle
                        ShaderMask(
                          shaderCallback: (b) => LinearGradient(
                            colors: [
                              Colors.white,
                              currentSong.accentColor,
                              const Color(0xFFFF80AB),
                            ],
                          ).createShader(b),
                          child: Text(
                            'Songs That Remind Us',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'The melodies where our memories live 🎵',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Spinning Vinyl Hero Display
                        _buildVinylHero(currentSong),

                        const SizedBox(height: 24),

                        // Current Song Info
                        Text(
                          currentSong.title,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentSong.artist,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 14),

                        // Song dedicated love note
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: currentSong.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: currentSong.accentColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            '“${currentSong.note}”',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.92),
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Slider & Times
                        _buildProgressBar(currentSong),

                        const SizedBox(height: 16),

                        // Audio Controls
                        _buildControls(currentSong),

                        const SizedBox(height: 32),

                        // Playlist section
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Our Playlist',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Song list cards
                        ...List.generate(_songs.length, (idx) {
                          return _buildSongCard(idx, _songs[idx]);
                        }),

                        const SizedBox(height: 40),
                      ],
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

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textSecondary),
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF28103A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF4081).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💕', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Text(
                  'Shared Beats',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF80AB),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVinylHero(SongItem song) {
    return AnimatedBuilder(
      animation: _vinylAnim,
      builder: (_, __) => Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: song.accentColor.withValues(
                alpha: _isPlaying ? 0.45 : 0.20,
              ),
              blurRadius: _isPlaying ? 40 : 25,
              spreadRadius: _isPlaying ? 6 : 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Vinyl Record Ring
            Transform.rotate(
              angle: _vinylAnim.value * 2 * math.pi,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF111116),
                  border: Border.all(color: const Color(0xFF2A2A38), width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  // Inner Vinyl Grooves
                  child: Container(
                    width: 175,
                    height: 175,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF222230), width: 3),
                    ),
                  ),
                ),
              ),
            ),

            // Album Cover in Center
            Transform.rotate(
              angle: _vinylAnim.value * 2 * math.pi,
              child: Container(
                width: 125,
                height: 125,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: song.accentColor,
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    song.coverAsset,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Center Spindle Hole
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A0714),
                border: Border.all(color: Colors.white54, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(SongItem song) {
    final maxSec = _duration.inSeconds.toDouble();
    final curSec = _position.inSeconds.toDouble().clamp(0.0, maxSec > 0 ? maxSec : 1.0);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: song.accentColor,
            inactiveTrackColor: Colors.white12,
            thumbColor: Colors.white,
            overlayColor: song.accentColor.withValues(alpha: 0.25),
          ),
          child: Slider(
            value: curSec,
            min: 0.0,
            max: maxSec > 0 ? maxSec : 1.0,
            onChanged: (val) {
              _player.seek(Duration(seconds: val.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
              ),
              Text(
                _formatDuration(_duration),
                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(SongItem song) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Prev button
        IconButton(
          iconSize: 34,
          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
          onPressed: _playPrevious,
        ),
        const SizedBox(width: 16),

        // Play/Pause button
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [song.accentColor, song.accentColor.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: song.accentColor.withValues(alpha: 0.45),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Next button
        IconButton(
          iconSize: 34,
          icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
          onPressed: _playNext,
        ),
      ],
    );
  }

  Widget _buildSongCard(int index, SongItem song) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _playSong(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? song.accentColor.withValues(alpha: 0.16)
              : const Color(0xFF181024),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? song.accentColor
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: song.accentColor.withValues(alpha: 0.20),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Album art thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                song.coverAsset,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),

            // Song details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          song.title,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: song.accentColor.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          song.badge,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: song.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artist,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Indicator or play button
            Icon(
              isSelected && _isPlaying
                  ? Icons.graphic_eq_rounded
                  : isSelected
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_filled_rounded,
              color: isSelected ? song.accentColor : Colors.white38,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
