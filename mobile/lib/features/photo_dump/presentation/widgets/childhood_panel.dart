import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/photo_memory.dart';
import 'featured_favorite_card.dart';
import 'memory_polaroid_card.dart';
import 'photo_lightbox_viewer.dart';
import 'story_slideshow_dialog.dart';

/// The Childhood Memories Panel.
/// Uniquely designed with Sahan's favorite hero card, story slideshow mode,
/// and an interactive scrapbook polaroid gallery of all 14 childhood photos.
class ChildhoodPanel extends StatelessWidget {
  const ChildhoodPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final allMemories = PhotoMemory.childhoodMemories;
    // 6(fav).jpeg is the favorite
    final favMemory = allMemories.firstWhere((m) => m.isFavorite);
    final otherMemories = allMemories.where((m) => !m.isFavorite).toList();

    return CustomScrollView(
      slivers: [
        // Top Banner & Story Action
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chapter 1: The Wonder Years',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      '14 Timeless Childhood Moments 🧸',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Play Story Button
                ElevatedButton.icon(
                  onPressed: () {
                    StorySlideshowDialog.show(
                      context,
                      memories: allMemories,
                    );
                  },
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    'Play Story',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4081),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFFFF4081).withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Featured Hero: Sahan's Favorite Photo (6(fav).jpeg)
        SliverToBoxAdapter(
          child: FeaturedFavoriteCard(
            memory: favMemory,
            onTap: () {
              final favIndex = allMemories.indexOf(favMemory);
              PhotoLightboxViewer.show(
                context,
                memories: allMemories,
                initialIndex: favIndex,
              );
            },
          ),
        ),

        // Section Divider Header: "The Scrapbook Album"
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Childhood Scrapbook Album 🌸',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tap any photo to zoom',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Responsive Staggered / Masonry Grid of Memories
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 16,
              crossAxisSpacing: 14,
              childAspectRatio: 0.65,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final memory = otherMemories[index];
                return MemoryPolaroidCard(
                  memory: memory,
                  index: index,
                  onTap: () {
                    final fullIndex = allMemories.indexOf(memory);
                    PhotoLightboxViewer.show(
                      context,
                      memories: allMemories,
                      initialIndex: fullIndex,
                    );
                  },
                );
              },
              childCount: otherMemories.length,
            ),
          ),
        ),
      ],
    );
  }
}
