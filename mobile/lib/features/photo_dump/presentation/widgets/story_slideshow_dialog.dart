import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../domain/photo_memory.dart';

/// Immersive Instagram/Snapchat-style Story Player that automatically
/// plays through memories in sync with the background soundtrack.
class StorySlideshowDialog extends StatefulWidget {
  const StorySlideshowDialog({
    super.key,
    required this.memories,
    this.audioAsset = 'audio/childhood_background.mp3',
  });

  final List<PhotoMemory> memories;
  final String audioAsset;

  static void show(
    BuildContext context, {
    required List<PhotoMemory> memories,
    String audioAsset = 'audio/childhood_background.mp3',
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close Story',
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return StorySlideshowDialog(
          memories: memories,
          audioAsset: audioAsset,
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    );
  }

  @override
  State<StorySlideshowDialog> createState() => _StorySlideshowDialogState();
}

class _StorySlideshowDialogState extends State<StorySlideshowDialog>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final AnimationController _animController;
  StreamSubscription<Duration>? _durationSub;
  Duration? _totalDuration;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Default initial slide duration (fallback ~3s each)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _animController.forward();
    _playBackgroundMusic();
  }

  Future<void> _playBackgroundMusic() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource(widget.audioAsset));

    // Listen for duration updates from audioplayer to sync slide timer
    _durationSub = _audioPlayer.onDurationChanged.listen((dur) {
      if (!mounted) return;
      if (dur.inMilliseconds > 0 && widget.memories.isNotEmpty) {
        _updateSlideDuration(dur);
      }
    });

    final initialDur = await _audioPlayer.getDuration();
    if (initialDur != null && initialDur.inMilliseconds > 0 && widget.memories.isNotEmpty) {
      _updateSlideDuration(initialDur);
    }
  }

  void _updateSlideDuration(Duration totalDur) {
    _totalDuration = totalDur;
    final perSlideMs = (totalDur.inMilliseconds / widget.memories.length).round();
    if (perSlideMs > 400 && _animController.duration?.inMilliseconds != perSlideMs) {
      final oldVal = _animController.value;
      _animController.duration = Duration(milliseconds: perSlideMs);
      if (_animController.isAnimating) {
        _animController.forward(from: oldVal);
      }
    }
  }

  void _seekAudioToSlide(int index) {
    if (_totalDuration != null && widget.memories.isNotEmpty) {
      final targetMs = (index * _totalDuration!.inMilliseconds / widget.memories.length).round();
      _audioPlayer.seek(Duration(milliseconds: targetMs));
    }
  }

  Future<void> _closeStory() async {
    await _audioPlayer.stop();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _animController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _nextStory() {
    if (_currentIndex < widget.memories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _seekAudioToSlide(_currentIndex);
      _animController.reset();
      _animController.forward();
    } else {
      _closeStory();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _seekAudioToSlide(_currentIndex);
      _animController.reset();
      _animController.forward();
    } else {
      _animController.reset();
      _animController.forward();
    }
  }

  void _onTapDown(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx;
    if (dx < screenWidth * 0.35) {
      _previousStory();
    } else {
      _nextStory();
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _animController.stop();
    _audioPlayer.pause();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _animController.forward();
    _audioPlayer.resume();
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTapDown,
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image (Blurred)
            Image.asset(
              memory.assetPath,
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.65),
              colorBlendMode: BlendMode.darken,
            ),

            // Main Foreground Image
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Container(
                  key: ValueKey(memory.id),
                  constraints: const BoxConstraints(maxHeight: 560),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: memory.isFavorite
                        ? Border.all(color: const Color(0xFFFFD700), width: 3)
                        : Border.all(color: Colors.white24, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: memory.isFavorite
                            ? const Color(0xFFFFD700).withValues(alpha: 0.4)
                            : Colors.black87,
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    memory.assetPath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Top Story Indicators
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 10,
              right: 10,
              child: Column(
                children: [
                  Row(
                    children: List.generate(widget.memories.length, (idx) {
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: idx < _currentIndex
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                )
                              : idx == _currentIndex
                                  ? AnimatedBuilder(
                                      animation: _animController,
                                      builder: (context, child) {
                                        return FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: _animController.value,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: memory.isFavorite
                                                  ? const Color(0xFFFFD700)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : const SizedBox(),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Header with Title & Close
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFFF4081),
                        child: Text(
                          memory.isFavorite ? '👑' : '🌸',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              memory.title,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              memory.isFavorite
                                  ? "Sahan's Favorite Memory 💖"
                                  : 'Childhood Memory #${_currentIndex + 1}',
                              style: GoogleFonts.outfit(
                                color: memory.isFavorite
                                    ? const Color(0xFFFFD700)
                                    : Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _closeStory,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Caption & Love Note
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: memory.isFavorite
                        ? const Color(0xFFFFD700)
                        : Colors.white12,
                  ),
                ),
                child: Text(
                  memory.isFavorite
                      ? "👑 \"${memory.caption} — Sahan's Favorite forever!\""
                      : memory.caption,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
