import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/photo_memory.dart';

/// Fullscreen interactive Lightbox with pinch-to-zoom, swipe carousel,
/// and special highlight for Sahan's favorite photo.
class PhotoLightboxViewer extends StatefulWidget {
  const PhotoLightboxViewer({
    super.key,
    required this.memories,
    required this.initialIndex,
  });

  final List<PhotoMemory> memories;
  final int initialIndex;

  static void show(
    BuildContext context, {
    required List<PhotoMemory> memories,
    required int initialIndex,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close Photo',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return PhotoLightboxViewer(
          memories: memories,
          initialIndex: initialIndex,
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  @override
  State<PhotoLightboxViewer> createState() => _PhotoLightboxViewerState();
}

class _PhotoLightboxViewerState extends State<PhotoLightboxViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    if (_transformController.value != Matrix4.identity()) {
      _transformController.value = Matrix4.identity();
    } else {
      _transformController.value = Matrix4.diagonal3Values(2.2, 2.2, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMemory = widget.memories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(color: Colors.black.withValues(alpha: 0.85)),
          ),

          // Main Carousel
          PageView.builder(
            controller: _pageController,
            itemCount: widget.memories.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _transformController.value = Matrix4.identity();
              });
            },
            itemBuilder: (context, index) {
              final memory = widget.memories[index];
              return Center(
                child: GestureDetector(
                  onDoubleTap: _onDoubleTap,
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Hero(
                      tag: memory.id,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 520),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: memory.isFavorite
                              ? Border.all(
                                  color: const Color(0xFFFFD700),
                                  width: 2.5,
                                )
                              : Border.all(color: Colors.white24),
                          boxShadow: [
                            BoxShadow(
                              color: memory.isFavorite
                                  ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                                  : Colors.black54,
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          memory.assetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: Colors.white54,
                              size: 64,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Top Header Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close Button
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                  ),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),

                // Counter indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.memories.length}',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Favorite icon indicator
                if (currentMemory.isFavorite)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4081),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  )
                else
                  const SizedBox(width: 44),
              ],
            ),
          ),

          // Bottom Caption & Info Panel
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161224).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: currentMemory.isFavorite
                      ? const Color(0xFFFFD700).withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.15),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentMemory.isFavorite) ...[
                    Row(
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          "Sahan's Absolute Favorite Photo 💖",
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFFD700),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    currentMemory.title,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentMemory.caption,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  if (currentMemory.favoriteNote != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '💌 "${currentMemory.favoriteNote}"',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF80AB),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Left Navigation Arrow (desktop/tablet/convenience)
          if (_currentIndex > 0)
            Positioned(
              left: 12,
              top: MediaQuery.of(context).size.height / 2 - 24,
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                ),
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),

          // Right Navigation Arrow
          if (_currentIndex < widget.memories.length - 1)
            Positioned(
              right: 12,
              top: MediaQuery.of(context).size.height / 2 - 24,
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                ),
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
