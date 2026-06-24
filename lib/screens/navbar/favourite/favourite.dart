import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_themes.dart';

class FavoriteSound {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final IconData fallbackIcon;
  bool isPlaying;

  FavoriteSound({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.fallbackIcon,
    this.isPlaying = false,
  });
}

class TabSwitchNotification extends Notification {
  final int index;
  TabSwitchNotification(this.index);
}

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  final List<FavoriteSound> _favoriteSounds = [
    FavoriteSound(
      id: 'forest_night',
      title: 'Forest Night',
      category: 'Nature',
      imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.terrain,
    ),
    FavoriteSound(
      id: 'window_rain',
      title: 'Window Rain',
      category: 'Rain',
      imageUrl: 'https://images.unsplash.com/photo-1515694346937-94d85e41e6f0?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.umbrella_outlined,
    ),
    FavoriteSound(
      id: 'wind_chimes',
      title: 'Wind Chimes',
      category: 'Meditation',
      imageUrl: 'https://images.unsplash.com/photo-1540206395-68808572332f?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.notifications_active_outlined,
    ),
    FavoriteSound(
      id: 'piano_sleep',
      title: 'Piano Sleep',
      category: 'sleep music',
      imageUrl: 'https://images.unsplash.com/photo-1520523839897-bd0b52f945a0?q=80&w=200&auto=format&fit=crop',
      fallbackIcon: Icons.music_note,
    ),
  ];

  void _togglePlay(FavoriteSound sound) {
    setState(() {
      if (sound.isPlaying) {
        sound.isPlaying = false;
      } else {
        // Pause all other sounds
        for (var s in _favoriteSounds) {
          s.isPlaying = false;
        }
        sound.isPlaying = true;
      }
    });
  }

  void _showClearConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemes.borderRadiusCard),
            side: const BorderSide(color: AppColors.borderLight, width: 1.0),
          ),
          title: const Text(
            'Clear All Favorites?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Are you sure you want to remove all saved sounds from your favorites?',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _favoriteSounds.clear();
                });
                Navigator.of(context).pop();
              },
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _removeSound(FavoriteSound sound) {
    setState(() {
      _favoriteSounds.remove(sound);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = _favoriteSounds.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppThemes.paddingScreen,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Favorites',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEmpty
                              ? 'No Saved Sounds'
                              : '${_favoriteSounds.length} Saved Sound${_favoriteSounds.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Delete Button
                  GestureDetector(
                    onTap: isEmpty ? null : _showClearConfirmDialog,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isEmpty ? 0.4 : 1.0,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.borderLight,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: AppColors.errorRed,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Favorites Sounds Section Title & Clear All
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Favorites Sounds',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (!isEmpty)
                    TextButton(
                      onPressed: _showClearConfirmDialog,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // List of Favorite Sounds or Empty State
              if (isEmpty)
                _buildEmptyState()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _favoriteSounds.length,
                  itemBuilder: (context, index) {
                    final sound = _favoriteSounds[index];
                    return _buildSoundCard(sound, index);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoundCard(FavoriteSound sound, int index) {
    return Dismissible(
      key: Key(sound.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppThemes.borderRadiusCard),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.errorRed, size: 28),
      ),
      onDismissed: (direction) {
        _removeSound(sound);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${sound.title} removed from favorites'),
            backgroundColor: AppColors.cardColor,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: AppColors.primaryCyan,
              onPressed: () {
                setState(() {
                  _favoriteSounds.insert(index, sound);
                });
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(AppThemes.borderRadiusCard),
          border: Border.all(
            color: AppColors.borderLight,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail Image with ClipRRect
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 64,
                height: 64,
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
            const SizedBox(width: 16),

            // Sound Information (Title, Category, Status)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sound.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sound.category,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sound.isPlaying ? 'Now playing' : 'Ready to play',
                    style: TextStyle(
                      fontSize: 12,
                      color: sound.isPlaying
                          ? AppColors.primaryCyan
                          : AppColors.primaryCyan.withValues(alpha: 0.8),
                      fontWeight:
                          sound.isPlaying ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // Play/Pause circular button
            GestureDetector(
              onTap: () => _togglePlay(sound),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sound.isPlaying
                      ? AppColors.primaryCyan.withValues(alpha: 0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: sound.isPlaying
                        ? AppColors.primaryCyan
                        : AppColors.primaryCyan.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  sound.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: AppColors.primaryCyan,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60.0, bottom: 20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.favorite_border,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Favorites Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Explore sounds and save them here to quickly access them anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                // Dispatch notification to parent to switch to Sounds tab (index 1)
                TabSwitchNotification(1).dispatch(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppThemes.borderRadiusButton),
                  gradient: AppColors.primaryButtonGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Explore Sounds',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
