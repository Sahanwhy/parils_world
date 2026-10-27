import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/photo_memory.dart';
import 'featured_favorite_card.dart';
import 'memory_polaroid_card.dart';
import 'photo_lightbox_viewer.dart';
import 'story_slideshow_dialog.dart';

/// Teenage Memories Panel.
/// Vibrant violet moodboard with Sahan favourite hero card, story mode,
/// and a polaroid grid of all 13 teenage photos.
class TeenagePanel extends StatelessWidget {
  const TeenagePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final allMemories = PhotoMemory.teenageMemories;
    final favMemory   = allMemories.firstWhere((m) => m.isFavorite);
    final others      = allMemories.where((m) => !m.isFavorite).toList();

    return CustomScrollView(
      slivers: [
        // Top banner + Play Story
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
                      'Chapter 2: The Teenage Years',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      '${allMemories.length} Unforgettable Moments 🎒',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Play Story button
                ElevatedButton.icon(
                  onPressed: () => StorySlideshowDialog.show(
                    context,
                    memories: allMemories,
                    audioAsset: 'audio/teenage_song.mp3',
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                  label: Text(
                    'Play Story',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B4FBF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF7B4FBF).withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Teen era quote banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF261838), Color(0xFF1E142B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentViolet.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Text('🎒', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The years that turned a girl into a force of nature 🌙',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Featured Hero: Sahan favourite (7(fav).jpeg)
        SliverToBoxAdapter(
          child: FeaturedFavoriteCard(
            memory: favMemory,
            onTap: () {
              final idx = allMemories.indexOf(favMemory);
              PhotoLightboxViewer.show(context, memories: allMemories, initialIndex: idx);
            },
          ),
        ),

        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B4FBF), Color(0xFFBF4F7B)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Teenage Moodboard 💜',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tap to zoom',
                  style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),

        // Polaroid grid
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
                final memory = others[index];
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
              childCount: others.length,
            ),
          ),
        ),
      ],
    );
  }
}
