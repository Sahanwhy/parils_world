import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_router.dart';
import '../domain/photo_memory.dart';
import 'widgets/childhood_panel.dart';
import 'widgets/teenage_panel.dart';
import 'widgets/current_panel.dart';
import 'widgets/story_slideshow_dialog.dart';

/// Photo Dump Screen with 3 Panels: Childhood, Teenage, and Current.
class PhotoDumpScreen extends StatefulWidget {
  const PhotoDumpScreen({super.key});

  @override
  State<PhotoDumpScreen> createState() => _PhotoDumpScreenState();
}

class _PhotoDumpScreenState extends State<PhotoDumpScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(context),
            _buildCustomSegmentedTabBar(),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  ChildhoodPanel(),
                  TeenagePanel(),
                  CurrentPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go(AppRoutes.dashboard),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF4081),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4081).withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/photo_dump_cover.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.accentGradient.createShader(bounds),
                  child: Text(
                    'Photo Dump',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  'The 3 Chapters of Paril\'s Journey 💕',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Story play icon button in AppBar
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFF4081).withValues(alpha: 0.2),
              side: BorderSide(
                color: const Color(0xFFFF4081).withValues(alpha: 0.5),
              ),
            ),
            tooltip: 'Play Story',
            icon: const Icon(
              Icons.auto_stories_rounded,
              color: Color(0xFFFF4081),
              size: 20,
            ),
            onPressed: () {
              StorySlideshowDialog.show(
                context,
                memories: PhotoMemory.childhoodMemories,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSegmentedTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF161224),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2442)),
      ),
      child: Row(
        children: [
          _buildTabItem(
            index: 0,
            icon: '🧸',
            label: 'Childhood',
            badgeCount: 14,
            activeColor: const Color(0xFFFF4081),
          ),
          const SizedBox(width: 4),
          _buildTabItem(
            index: 1,
            icon: '🎒',
            label: 'Teenage',
            activeColor: const Color(0xFF9C27B0),
          ),
          const SizedBox(width: 4),
          _buildTabItem(
            index: 2,
            icon: '💫',
            label: 'Current',
            activeColor: const Color(0xFFFFB300),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String icon,
    required String label,
    int? badgeCount,
    required Color activeColor,
  }) {
    final isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() => _selectedTabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: activeColor.withValues(alpha: 0.8), width: 1.5)
                : Border.all(color: Colors.transparent, width: 1.5),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (badgeCount != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
