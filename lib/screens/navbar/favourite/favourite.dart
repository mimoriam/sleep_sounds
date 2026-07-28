import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/audio_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_themes.dart';
import '../../../utils/page_transitions.dart';
import '../../../utils/tab_notification.dart';
import '../home/widgets/sound_playing.dart';

class FavouriteScreen extends StatelessWidget {
  const FavouriteScreen({super.key});

  void _showClearAllDialog(BuildContext context, FavoritesProvider favorites) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear All Favorites?',
          style: TextStyle(color: AppColors.text(context)),
        ),
        content: Text(
          'Are you sure you want to remove all sounds from your favorites?',
          style: TextStyle(color: AppColors.textMuted(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              favorites.clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final audio = context.watch<AudioProvider>();
    final favList = favorites.favoriteSounds;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppThemes.paddingScreen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), // Balances the right button
                  Text(
                    'Favorite Sounds',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  if (favList.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear All Favorites',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.errorRed,
                      ),
                      onPressed: () => _showClearAllDialog(context, favorites),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: favList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border_rounded,
                              size: 64,
                              color: AppColors.textMuted(context),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No favorites added yet',
                              style: TextStyle(
                                color: AppColors.text(context),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the heart icon on any sound to save it here for quick access.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textMuted(context),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryCyan,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () {
                                TabSwitchNotification(1).dispatch(context);
                              },
                              child: const Text(
                                'Explore Sounds',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: favList.length,
                        itemBuilder: (context, index) {
                          final sound = favList[index];
                          final isCurrentPlaying =
                              audio.currentSound.id == sound.id && audio.isPlaying;

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
                                          errorBuilder: (c, e, s) => Container(
                                            color: AppColors.card(context),
                                            child: Icon(
                                              sound.icon,
                                              color: AppColors.primaryCyan,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: AppColors.card(context),
                                          child: Icon(
                                            sound.icon,
                                            color: AppColors.primaryCyan,
                                          ),
                                        ),
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
                                sound.category.label,
                                style: TextStyle(
                                  color: AppColors.textMuted(context),
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.favorite,
                                      color: AppColors.primaryCyan,
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
}
