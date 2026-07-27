import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/sound_model.dart';
import '../../../providers/audio_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_themes.dart';
import '../../../utils/page_transitions.dart';
import '../../../utils/tab_notification.dart';
import 'widgets/sound_playing.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning ☀️';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon 🌤️';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening 🌅';
    } else {
      return 'Good Night 🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSounds = SoundRegistry.allSounds;

    // Daily Featured Sound
    final dailyIndex = DateTime.now().day % allSounds.length;
    final featuredSound = allSounds[dailyIndex];

    return Selector<AudioProvider, ({Map<String, int> counts, List<String> recent})>(
      selector: (_, a) => (counts: a.playCounts, recent: a.recentSoundIds),
      builder: (context, history, _) {
        List<SoundType> popularSounds;
        if (history.counts.isNotEmpty) {
          final sorted = List<SoundType>.from(allSounds)
            ..sort((a, b) => (history.counts[b.id] ?? 0).compareTo(history.counts[a.id] ?? 0));
          popularSounds = sorted.take(4).toList();
        } else {
          popularSounds = [
            SoundRegistry.getById('wave'),
            SoundRegistry.getById('fire-sounds'),
            SoundRegistry.getById('rain'),
            SoundRegistry.getById('sleeping_tone'),
          ];
        }

        List<SoundType> recentlyPlayed;
        if (history.recent.isNotEmpty) {
          recentlyPlayed = history.recent
              .map((id) => SoundRegistry.getByIdOrNull(id))
              .whereType<SoundType>()
              .take(4)
              .toList();
        } else {
          recentlyPlayed = [
            SoundRegistry.getById('fan'),
            SoundRegistry.getById('clock'),
            SoundRegistry.getById('cat'),
            SoundRegistry.getById('midnight'),
          ];
        }

        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppThemes.paddingScreen),
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
                            Text(
                              'Sleep peacefully tonight',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getTimeGreeting(),
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textMuted(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border(context),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.notifications_none_outlined,
                          color: AppColors.text(context),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Featured Card ("Tonight's Best Sleep Sound")
                  GestureDetector(
                    onTap: () {
                      context.read<AudioProvider>().selectAndPlay(featuredSound);
                      Navigator.push(
                        context,
                        SlideUpFadeRoute(page: SoundPlaying(sound: featuredSound)),
                      );
                    },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          featuredSound.imagePath ?? 'assets/images/ocean_waves.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.card(context),
                              child: Center(
                                child: Icon(
                                  featuredSound.icon,
                                  color: AppColors.primaryCyan,
                                  size: 48,
                                ),
                              ),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text(
                                      "Tonight's Best Sleep Sound",
                                      style: TextStyle(
                                        color: AppColors.primaryCyan,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      featuredSound.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      featuredSound.description,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.activeSliderGradient,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Popular Sounds Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Popular Sounds',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      TabSwitchNotification(1).dispatch(context);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        color: AppColors.primaryCyan,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Popular Sounds Horizontal List
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: popularSounds.length,
                  itemBuilder: (context, index) {
                    final sound = popularSounds[index];
                    return SoundCardWidget(
                      sound: sound,
                      width: 170,
                      height: 200,
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Recently Played Section Header
              Text(
                'Recently Played',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text(context),
                ),
              ),
              const SizedBox(height: 16),

              // Recently Played Horizontal List
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: recentlyPlayed.length,
                  itemBuilder: (context, index) {
                    final sound = recentlyPlayed[index];
                    return SoundCardWidget(
                      sound: sound,
                      width: 130,
                      height: 150,
                      titleSize: 14,
                      subtitleSize: 11,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// SoundCardWidget using SoundType
class SoundCardWidget extends StatelessWidget {
  final SoundType sound;
  final double width;
  final double height;
  final double titleSize;
  final double subtitleSize;

  const SoundCardWidget({
    super.key,
    required this.sound,
    required this.width,
    required this.height,
    this.titleSize = 16.0,
    this.subtitleSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              sound.imagePath ?? 'assets/images/forest_night.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                  ),
                  child: Center(
                    child: Icon(
                      sound.icon,
                      color: AppColors.primaryCyan,
                      size: width * 0.28,
                    ),
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    sound.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sound.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: subtitleSize,
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    context.read<AudioProvider>().selectAndPlay(sound);
                    Navigator.push(
                      context,
                      SlideUpFadeRoute(page: SoundPlaying(sound: sound)),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
