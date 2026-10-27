import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/photo_memory.dart';

/// Polaroid-style scrapbook memory card with subtle tilt, washi-tape accent,
/// and interactive heart reaction.
class MemoryPolaroidCard extends StatefulWidget {
  const MemoryPolaroidCard({
    super.key,
    required this.memory,
    required this.onTap,
    this.index = 0,
  });

  final PhotoMemory memory;
  final VoidCallback onTap;
  final int index;

  @override
  State<MemoryPolaroidCard> createState() => _MemoryPolaroidCardState();
}

class _MemoryPolaroidCardState extends State<MemoryPolaroidCard> {
  bool _isLiked = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Alternate subtle tilts for an authentic scrapbook photo album feel
    final tilt = widget.memory.rotationAngle;

    return Transform.rotate(
      angle: _isHovered ? 0.0 : tilt,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: _isHovered
            ? Matrix4.translationValues(0.0, -4.0, 0.0)
            : Matrix4.identity(),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E192B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered
                      ? AppTheme.accentRose.withValues(alpha: 0.6)
                      : const Color(0xFF332945),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: _isHovered ? 14 : 8,
                    offset: Offset(0, _isHovered ? 6 : 4),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Photo Image
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: Hero(
                              tag: widget.memory.id,
                              child: Image.asset(
                                widget.memory.assetPath,
                                fit: BoxFit.cover,
                                alignment: widget.memory.alignment,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Colors.white10,
                                  child: const Icon(
                                    Icons.photo_outlined,
                                    color: Colors.white38,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Polaroid Bottom Info
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.memory.title,
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _isLiked = !_isLiked);
                                  },
                                  child: Icon(
                                    _isLiked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 15,
                                    color: _isLiked
                                        ? const Color(0xFFFF4081)
                                        : Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.memory.caption,
                              style: GoogleFonts.outfit(
                                color: AppTheme.textSecondary,
                                fontSize: 10.5,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentViolet.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.memory.tag,
                                style: GoogleFonts.outfit(
                                  color: AppTheme.accentVioletLight,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Top Decorative Washi-Tape Accent
                  Positioned(
                    top: -6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE082).withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
