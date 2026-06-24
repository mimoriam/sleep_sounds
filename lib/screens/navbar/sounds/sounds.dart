import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_themes.dart';
import '../home/widgets/sound_playing.dart';

class SleepSound {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final IconData fallbackIcon;
  final bool isPro;
  bool isPlaying;
  bool isFavorite;

  SleepSound({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.fallbackIcon,
    this.isPro = false,
    this.isPlaying = false,
    this.isFavorite = false,
  });
}

class SoundsScreen extends StatefulWidget {
  const SoundsScreen({super.key});

  @override
  State<SoundsScreen> createState() => _SoundsScreenState();
}

class _SoundsScreenState extends State<SoundsScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Nature',
    'Rain',
    'White noise',
    'Sleep music',
    'Meditation',
  ];

  final Map<String, IconData> _categoryIcons = {
    'Nature': Icons.eco_outlined,
    'Rain': Icons.umbrella_outlined,
    'White noise': Icons.graphic_eq_rounded,
    'Sleep music': Icons.bedtime_outlined,
    'Meditation': Icons.self_improvement_rounded,
  };

  final List<SleepSound> _sounds = [
    // Nature
    SleepSound(
      id: 'forest_night',
      title: 'Forest Night',
      description: 'Peaceful woodland ambience',
      category: 'Nature',
      imageUrl: 'https://images.unsplash.com/photo-1502082553048-f009c37129b9?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.terrain,
      isPlaying: true, // Forest Night is active by default in the screenshot
      isFavorite: true, // Highlighted with active favorite
    ),
    SleepSound(
      id: 'ocean_breeze',
      title: 'Ocean Breeze',
      description: 'Gentle waves on shore',
      category: 'Nature',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.waves,
    ),
    SleepSound(
      id: 'river_flow',
      title: 'River Flow',
      description: 'Calming stream sounds',
      category: 'Nature',
      imageUrl: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.water,
    ),
    SleepSound(
      id: 'birds_chirping',
      title: 'Birds Chirping',
      description: 'Morning bird songs',
      category: 'Nature',
      imageUrl: 'https://images.unsplash.com/photo-1470240731273-7821a6eeb6bd?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.flutter_dash,
    ),
    SleepSound(
      id: 'rainy_forest',
      title: 'Rainy Forest',
      description: 'Rain in the woods',
      category: 'Nature',
      imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.forest,
    ),

    // Rain
    SleepSound(
      id: 'soft_rain',
      title: 'Soft Rain',
      description: 'Gentle rainfall',
      category: 'Rain',
      imageUrl: 'https://images.unsplash.com/photo-1534274988757-a28bf1a57c17?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.umbrella,
    ),
    SleepSound(
      id: 'thunderstorm',
      title: 'Thunderstorm',
      description: 'Deep thunder & rain',
      category: 'Rain',
      imageUrl: 'https://images.unsplash.com/photo-1492011221367-f47e3ccd77a0?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.flash_on,
    ),
    SleepSound(
      id: 'window_rain',
      title: 'Window Rain',
      description: 'Rain on glass',
      category: 'Rain',
      imageUrl: 'https://images.unsplash.com/photo-1428908728789-d2de25dbd4e2?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.wb_sunny,
    ),
    SleepSound(
      id: 'heavy_rain',
      title: 'Heavy Rain',
      description: 'Intense downpour',
      category: 'Rain',
      imageUrl: 'https://images.unsplash.com/photo-1515694346937-94d85e41e6f0?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.grain,
      isPro: true,
    ),

    // White noise
    SleepSound(
      id: 'fan_sound',
      title: 'Fan Sound',
      description: 'Steady white noise',
      category: 'White noise',
      imageUrl: 'https://images.unsplash.com/photo-1618944847828-82e943c3dba7?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.air,
    ),
    SleepSound(
      id: 'brown_noise',
      title: 'Brown Noise',
      description: 'Deep frequency noise',
      category: 'White noise',
      imageUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.waves,
    ),
    SleepSound(
      id: 'pink_noise',
      title: 'Pink Noise',
      description: 'Balanced frequency',
      category: 'White noise',
      imageUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.blur_on,
      isPro: true,
    ),

    // Sleep music
    SleepSound(
      id: 'piano_sleep',
      title: 'Piano Sleep',
      description: 'Soft piano melodies',
      category: 'Sleep music',
      imageUrl: 'https://images.unsplash.com/photo-1520523839897-bd0b52f945a0?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.music_note,
    ),
    SleepSound(
      id: 'fireplace_crackle',
      title: 'Fireplace Crackle',
      description: 'Cozy fire sounds',
      category: 'Sleep music',
      imageUrl: 'https://images.unsplash.com/photo-1545048702-79362596cdc9?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.fireplace,
    ),

    // Meditation
    SleepSound(
      id: 'wind_chimes',
      title: 'Wind Chimes',
      description: 'Gentle bell tones',
      category: 'Meditation',
      imageUrl: 'https://images.unsplash.com/photo-1540206395-68808572332f?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.notifications,
    ),
    SleepSound(
      id: 'deep_meditation',
      title: 'Deep Meditation',
      description: 'Tibetan bowls & pads',
      category: 'Meditation',
      imageUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.self_improvement,
    ),
  ];

  void _togglePlay(SleepSound sound) {
    setState(() {
      if (sound.isPlaying) {
        sound.isPlaying = false;
      } else {
        // Pause all other playing sounds
        for (var s in _sounds) {
          s.isPlaying = false;
        }
        sound.isPlaying = true;
      }
    });
  }

  void _toggleFavorite(SleepSound sound) {
    setState(() {
      sound.isFavorite = !sound.isFavorite;
    });
  }

  List<SleepSound> _getSoundsByCategory(String categoryName) {
    return _sounds.where((sound) => sound.category == categoryName).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Get unique categories present in sounds, preserving initial order (excluding 'All')
    final List<String> activeCategories = _selectedCategory == 'All'
        ? _categories.sublist(1)
        : [_selectedCategory];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.only(
                left: AppThemes.paddingScreen,
                right: AppThemes.paddingScreen,
                top: 16,
                bottom: 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All Sleep Sounds',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Find your perfect tone for tonight.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Horizontal Categories List
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppThemes.paddingScreen - 8),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryCyan
                              : AppColors.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: isSelected
                              ? null
                              : Border.all(color: AppColors.borderLight, width: 1.0),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.backgroundDark
                                : AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // Vertical list of sounds
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppThemes.paddingScreen),
                child: Column(
                  children: [
                    ...activeCategories.map((category) {
                      final categorySounds = _getSoundsByCategory(category);
                      if (categorySounds.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Header
                          _buildCategoryHeader(category, categorySounds.length),
                          const SizedBox(height: 10),

                          // Sounds in Category
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: categorySounds.length,
                            itemBuilder: (context, index) {
                              final sound = categorySounds[index];
                              return _buildSoundCard(sound);
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String categoryName, int count) {
    final icon = _categoryIcons[categoryName] ?? Icons.music_note_outlined;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              categoryName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.borderLight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSoundCard(SleepSound sound) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SoundPlaying(
              title: sound.title,
              subtitle: sound.description,
              imagePath: sound.imageUrl,
              fallbackIcon: sound.fallbackIcon,
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(AppThemes.borderRadiusCard),
          border: Border.all(
            color: sound.isPlaying ? AppColors.primaryCyan : AppColors.borderLight,
            width: sound.isPlaying ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Sound Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Image.network(
                  sound.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.backgroundDark,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryCyan,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E2738), Color(0xFF0F1524)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          sound.fallbackIcon,
                          color: AppColors.primaryCyan,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
  
            const SizedBox(width: 12),
  
            // Title & Subtitle Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sound.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sound.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (sound.isPro) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Color(0xFFFFD54F),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
  
            const SizedBox(width: 8),
  
            // Favorite Button
            GestureDetector(
              onTap: () => _toggleFavorite(sound),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: sound.isFavorite
                      ? const Color(0xFFFF5252).withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: sound.isFavorite
                      ? Colors.transparent
                      : AppColors.borderLight,
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  sound.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: sound.isFavorite ? const Color(0xFFFF5252) : AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
  
            const SizedBox(width: 10),
  
            // Play Button
            GestureDetector(
              onTap: () => _togglePlay(sound),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: sound.isPlaying ? AppColors.primaryCyan : Colors.transparent,
                  border: Border.all(
                    color: sound.isPlaying ? Colors.transparent : AppColors.borderLight,
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  sound.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: sound.isPlaying ? AppColors.backgroundDark : AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
