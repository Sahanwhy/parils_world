import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Current memories panel.
/// Romantic chapter highlighting the present love story of Paril & Sahan.
class CurrentPanel extends StatelessWidget {
  const CurrentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF331628), Color(0xFF221124)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.accentRose.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentRose.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRose.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('💫', style: TextStyle(fontSize: 40)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chapter 3: Right Here With Sahan',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'From childhood innocence to my forever girl. Every current conversation, phone call, and shared dream with you is my new favorite memory 💖',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Text('💌', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '"You were the cutest child, and now you are the most gorgeous girl in my whole world." — Sahan',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF80AB),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Moments grid
          Row(
            children: [
              Expanded(
                child: _buildMemoryBadge(
                  title: 'Late Night Talks 🌙',
                  subtitle: 'When we are about to sleep',
                  icon: Icons.nightlight_round,
                  color: const Color(0xFF9C27B0),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMemoryBadge(
                  title: 'Inside Jokes 😂',
                  subtitle: 'Carbon monoxide & obstack',
                  icon: Icons.sentiment_very_satisfied_rounded,
                  color: const Color(0xFFFF4081),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildMemoryBadge(
            title: 'Future Together 💍',
            subtitle: 'Hotel dates, lazy Sundays & forever smiles',
            icon: Icons.favorite_rounded,
            color: const Color(0xFFFFD700),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryBadge({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF191224),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
