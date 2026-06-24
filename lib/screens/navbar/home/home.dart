import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_themes.dart';
import '../favourite/favourite.dart';
import 'widgets/sound_playing.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sleep peacefully tonight',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Good Night 🌙',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Notification Bell Container
                  Container(
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
                      Icons.notifications_none_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Featured Card ("Tonight's Best Sleep Sound")
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SoundPlaying(
                        title: 'Forest Night',
                        subtitle: 'Peaceful woodland ambience',
                        imagePath: 'assets/images/forest_night.png',
                        fallbackIcon: Icons.nights_stay_outlined,
                      ),
                    ),
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
                        // Image with fallback
                        Image.asset(
                          'assets/images/forest_night.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF151C2C),
                                    Color(0xFF0B101E),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.nights_stay_outlined,
                                  color: AppColors.primaryCyan,
                                  size: 48,
                                ),
                              ),
                            );
                          },
                        ),
                        // Gradient Overlay for Readability
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
                        // Content
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
                                    const Text(
                                      "Forest Night",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Peaceful woodland ambience",
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
                              // Play Button
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
                  const Text(
                    'Popular Sounds',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    SoundCard(
                      title: 'Forest Night',
                      subtitle: 'Peaceful woodland ambi...',
                      imagePath: 'assets/images/forest_night.png',
                      width: 170,
                      height: 200,
                      fallbackIcon: Icons.terrain,
                    ),
                    SoundCard(
                      title: 'Fireplace crackle',
                      subtitle: 'Cozy fire sounds',
                      imagePath: 'assets/images/fireplace.png',
                      width: 170,
                      height: 200,
                      fallbackIcon: Icons.local_fire_department_outlined,
                    ),
                    SoundCard(
                      title: 'Ocean Waves',
                      subtitle: 'Soothing beach waves',
                      imagePath: 'assets/images/ocean_waves.png',
                      width: 170,
                      height: 200,
                      fallbackIcon: Icons.waves_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Recently Added Section Header
              const Text(
                'Recently Added',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Recently Added Horizontal List
              SizedBox(
                height: 150,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    SoundCard(
                      title: 'Soft Rain',
                      subtitle: 'Gentle rainfall',
                      imagePath: 'assets/images/soft_rain.png',
                      width: 130,
                      height: 150,
                      titleSize: 14,
                      subtitleSize: 11,
                      fallbackIcon: Icons.umbrella_outlined,
                    ),
                    SoundCard(
                      title: 'Birds Chirping',
                      subtitle: 'Morning bird songs',
                      imagePath: 'assets/images/birds_chirping.png',
                      width: 130,
                      height: 150,
                      titleSize: 14,
                      subtitleSize: 11,
                      fallbackIcon: Icons.flutter_dash_outlined,
                    ),
                    SoundCard(
                      title: 'Thunders',
                      subtitle: 'Deep thunder rumbles',
                      imagePath: 'assets/images/thunder.png',
                      width: 130,
                      height: 150,
                      titleSize: 14,
                      subtitleSize: 11,
                      fallbackIcon: Icons.flash_on_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SHARED COMPONENT: SoundCard ---
class SoundCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final double width;
  final double height;
  final double titleSize;
  final double subtitleSize;
  final IconData fallbackIcon;

  const SoundCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.width,
    required this.height,
    this.titleSize = 16.0,
    this.subtitleSize = 12.0,
    this.fallbackIcon = Icons.music_note,
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
            // Background Image
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF151C2C), Color(0xFF0B101E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      fallbackIcon,
                      color: AppColors.primaryCyan,
                      size: width * 0.28,
                    ),
                  ),
                );
              },
            ),
            // Gradient Overlay
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
            // Text Content
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
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
                    subtitle,
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
            // Material Splash Inkwell
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SoundPlaying(
                          title: title,
                          subtitle: subtitle,
                          imagePath: imagePath,
                          fallbackIcon: fallbackIcon,
                        ),
                      ),
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
