import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/sound_category.dart';
import '../../../models/sound_model.dart';
import '../../../providers/audio_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_themes.dart';
import '../../../utils/page_transitions.dart';
import '../home/widgets/sound_playing.dart';

class SoundsScreen extends StatefulWidget {
  const SoundsScreen({super.key});

  @override
  State<SoundsScreen> createState() => _SoundsScreenState();
}

class _SoundsScreenState extends State<SoundsScreen> {
  SoundCategory _selectedCategory = SoundCategory.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final audio = context.watch<AudioProvider>();

    var filteredSounds = SoundRegistry.getByCategory(_selectedCategory);
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filteredSounds = filteredSounds
          .where(
            (s) =>
                s.title.toLowerCase().contains(q) ||
                s.description.toLowerCase().contains(q) ||
                s.category.label.toLowerCase().contains(q),
          )
          .toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppThemes.paddingScreen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header Title
              Center(
                child: Text(
                  'Sounds Library',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Search Bar
              TextField(
                controller: _searchController,
                style: TextStyle(color: AppColors.text(context)),
                decoration: InputDecoration(
                  hintText: 'Search rain, waves, fan...',
                  hintStyle: TextStyle(color: AppColors.textMuted(context)),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textMuted(context),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: AppColors.textMuted(context),
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Category Pills Horizontal List
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: SoundCategory.values.length,
                  itemBuilder: (context, index) {
                    final cat = SoundCategory.values[index];
                    final isSelected = _selectedCategory == cat;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        avatar: Icon(
                          cat.icon,
                          size: 16,
                          color: isSelected
                              ? Colors.black
                              : AppColors.textMuted(context),
                        ),
                        label: Text(
                          cat.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.black
                                : AppColors.textMuted(context),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        backgroundColor: AppColors.card(context),
                        selectedColor: AppColors.primaryCyan,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primaryCyan
                                : AppColors.border(context),
                          ),
                        ),
                        onSelected: (selected) {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Sound List Grid
              Expanded(
                child: filteredSounds.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: AppColors.textMuted(context),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No sounds found matching "$_searchQuery"',
                              style: TextStyle(
                                color: AppColors.textMuted(context),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredSounds.length,
                        itemBuilder: (context, index) {
                          final sound = filteredSounds[index];
                          final isCurrentPlaying =
                              audio.currentSound.id == sound.id &&
                                  audio.isPlaying;
                          final isFav = favorites.isFavorite(sound.id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: AppColors.card(context),
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isCurrentPlaying
                                      ? AppColors.primaryCyan
                                      : AppColors.border(context),
                                  width: isCurrentPlaying ? 1.5 : 1.0,
                                ),
                              ),
                              child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: sound.imagePath != null
                                      ? Image.asset(
                                          sound.imagePath!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) =>
                                              _buildIconPlaceholder(context, sound.icon),
                                        )
                                      : _buildIconPlaceholder(context, sound.icon),
                                ),
                              ),
                              title: Text(
                                sound.title,
                                style: TextStyle(
                                  color: AppColors.text(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                sound.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textMuted(context),
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isFav
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFav
                                          ? AppColors.primaryCyan
                                          : AppColors.textMuted(context),
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      favorites.toggleFavorite(sound.id);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isCurrentPlaying
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_fill_rounded,
                                      color: AppColors.primaryCyan,
                                      size: 32,
                                    ),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      if (isCurrentPlaying) {
                                        audio.pause();
                                      } else {
                                        audio.selectAndPlay(sound);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  SlideUpFadeRoute(
                                    page: SoundPlaying(sound: sound),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconPlaceholder(BuildContext context, IconData icon) {
    return Container(
      color: AppColors.card(context),
      child: Center(
        child: Icon(icon, color: AppColors.primaryCyan, size: 24),
      ),
    );
  }
}
