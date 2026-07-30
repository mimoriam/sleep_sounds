import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/sound_model.dart';
import '../../../providers/audio_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_themes.dart';
import '../../../utils/page_transitions.dart';
import '../../../utils/tab_notification.dart';
import '../../breathing/breathing_exercise.dart';
import '../../../services/subscription_service.dart';
import 'widgets/sound_playing.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentCarouselIndex = 0;
  late List<SoundType> _featuredSounds;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Pick 5 random featured sounds that change on every app/screen visit
    final all = List<SoundType>.from(SoundRegistry.allSounds);
    all.shuffle(Random(DateTime.now().microsecondsSinceEpoch));
    _featuredSounds = all.take(5).toList();

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final nextIndex = (_currentCarouselIndex + 1) % _featuredSounds.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

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

  ({String title, List<SoundType> sounds}) _getContextualPicks() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return (
        title: 'Morning Energy & Focus',
        sounds: [
          SoundRegistry.getById('happy_day'),
          SoundRegistry.getById('wave'),
          SoundRegistry.getById('jogging'),
          SoundRegistry.getById('holiday'),
        ],
      );
    } else if (hour >= 12 && hour < 17) {
      return (
        title: 'Afternoon Focus Sounds',
        sounds: [
          SoundRegistry.getById('fan'),
          SoundRegistry.getById('clock'),
          SoundRegistry.getById('noise'),
          SoundRegistry.getById('machine-fan'),
        ],
      );
    } else if (hour >= 17 && hour < 21) {
      return (
        title: 'Evening Wind-Down',
        sounds: [
          SoundRegistry.getById('fire-sounds'),
          SoundRegistry.getById('rain'),
          SoundRegistry.getById('relaxing_tone'),
          SoundRegistry.getById('cat'),
        ],
      );
    } else {
      return (
        title: 'Bedtime Deep Sleep Picks',
        sounds: [
          SoundRegistry.getById('sleeping_tone'),
          SoundRegistry.getById('midnight'),
          SoundRegistry.getById('heart'),
          SoundRegistry.getById('frog'),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contextual = _getContextualPicks();

    return Selector<AudioProvider, ({Map<String, int> counts, List<String> recent})>(
      selector: (_, a) => (counts: a.playCounts, recent: a.recentSoundIds),
      builder: (context, history, _) {
        List<SoundType> popularSounds;
        if (history.counts.isNotEmpty) {
          final sorted = List<SoundType>.from(SoundRegistry.allSounds)
            ..sort((a, b) =>
                (history.counts[b.id] ?? 0).compareTo(history.counts[a.id] ?? 0));
          popularSounds = sorted.take(6).toList();
        } else {
          popularSounds = [
            SoundRegistry.getById('wave'),
            SoundRegistry.getById('fire-sounds'),
            SoundRegistry.getById('rain'),
            SoundRegistry.getById('sleeping_tone'),
            SoundRegistry.getById('fan'),
            SoundRegistry.getById('cat'),
          ];
        }

        List<SoundType> recentlyPlayed;
        if (history.recent.isNotEmpty) {
          recentlyPlayed = history.recent
              .map((id) => SoundRegistry.getByIdOrNull(id))
              .whereType<SoundType>()
              .take(6)
              .toList();
        } else {
          recentlyPlayed = []; // UI #6: proper empty state instead of fallback
        }

        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                // UI #6: Pull-to-refresh re-randomizes the featured carousel
                setState(() {
                  final all = List<SoundType>.from(SoundRegistry.allSounds);
                  all.shuffle(Random(DateTime.now().microsecondsSinceEpoch));
                  _featuredSounds = all.take(5).toList();
                  _currentCarouselIndex = 0;
                });
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              color: AppColors.primaryCyan,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppThemes.paddingScreen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Header Row
                  Column(
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
                  const SizedBox(height: 20),

                  // Featured Sound Auto-Scrolling Carousel
                  SizedBox(
                    height: 190,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _featuredSounds.length,
                      onPageChanged: (idx) {
                        setState(() {
                          _currentCarouselIndex = idx;
                        });
                      },
                      itemBuilder: (context, index) {
                        final sound = _featuredSounds[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                          onTap: () {
                              Navigator.push(
                                context,
                                SlideUpFadeRoute(page: SoundPlaying(sound: sound)),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    sound.imagePath ??
                                        'assets/images/ocean_waves.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppColors.card(context),
                                        child: Center(
                                          child: Icon(
                                            sound.icon,
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
                                          Colors.black.withValues(alpha: 0.2),
                                          Colors.black.withValues(alpha: 0.75),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryCyan
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppColors.primaryCyan
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                ),
                                                child: Text(
                                                  "FEATURED • ${sound.category.label}",
                                                  style: const TextStyle(
                                                    color: AppColors.primaryCyan,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                sound.title,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                sound.description,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white.withValues(
                                                    alpha: 0.8,
                                                  ),
                                                  fontSize: 12,
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
                                            gradient: AppColors
                                                .activeSliderGradient,
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
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Page Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_featuredSounds.length, (idx) {
                      final isSelected = idx == _currentCarouselIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryCyan
                              : AppColors.textMuted(context).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Breathing Guide Banner Button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        FadeRoute(page: const BreathingExerciseScreen()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F2027), Color(0xFF203A43)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryCyan.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryCyan.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.self_improvement_rounded,
                              color: AppColors.primaryCyan,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '4-7-8 Breathing Guide',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Relax your mind before sleep with guided breathing',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.primaryCyan,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Time-of-Day Contextual Picks Header & Grid
                  Text(
                    contextual.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: contextual.sounds.length,
                      itemBuilder: (context, index) {
                        final sound = contextual.sounds[index];
                        return SoundCardWidget(
                          sound: sound,
                          width: 150,
                          height: 160,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

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
                  const SizedBox(height: 14),

                  // Popular Sounds Horizontal List
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: popularSounds.length,
                      itemBuilder: (context, index) {
                        final sound = popularSounds[index];
                        return SoundCardWidget(
                          sound: sound,
                          width: 150,
                          height: 160,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Recently Played Section Header
                  if (recentlyPlayed.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      'Recently Played',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Recently Played Horizontal List
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: recentlyPlayed.length,
                        itemBuilder: (context, index) {
                          final sound = recentlyPlayed[index];
                          return SoundCardWidget(
                            sound: sound,
                            width: 130,
                            height: 140,
                            titleSize: 14,
                            subtitleSize: 11,
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 28),
                    Text(
                      'Recently Played',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 36,
                            color: AppColors.textMuted(context),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Play a sound to see your history here',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted(context),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
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
    this.titleSize = 15.0,
    this.subtitleSize = 11.0,
  });

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionService>();
    final isLocked = sound.isPremium && !subscription.isPremium;

    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 14),
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
            if (isLocked)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: AppColors.primaryCyan,
                    size: 14,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(10.0),
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
