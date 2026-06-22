import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_themes.dart';
import '../auth/login/login.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      // On first page, pop if possible
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back and Skip Navigation
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppThemes.paddingScreen / 2,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: _previousPage,
                  ),
                  if (_currentPage < 3)
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48), // Spacer to balance header
                ],
              ),
            ),

            // Page Contents
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildSleepBetterPage(),
                  _buildDiscoverSoundsPage(),
                  _buildMixerPage(),
                ],
              ),
            ),

            // Footer Section
            Padding(
              padding: const EdgeInsets.all(AppThemes.paddingScreen),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Indicators (only shown on page 1, 2, 3)
                  if (_currentPage > 0) ...[
                    PageIndicator(
                      activeIndex: _currentPage - 1,
                      count: 3,
                    ),
                    const SizedBox(height: 32),
                  ] else ...[
                    const SizedBox(height: 40), // Spacing for welcome page
                  ],

                  // Action Button
                  GradientButton(
                    text: _currentPage == 3 ? 'Get Start' : 'Continue',
                    gradient: (_currentPage == 2 || _currentPage == 3)
                        ? AppColors.activeSliderGradient
                        : AppColors.primaryButtonGradient,
                    onPressed: _nextPage,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WELCOME PAGE (Screen 1) ---
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppThemes.paddingScreen),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing Moon Illustration
          const Center(
            child: GlowingMoonContainer(),
          ),
          const SizedBox(height: 60),

          // Title
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.primaryCyan],
            ).createShader(bounds),
            child: const Text(
              'Sleep Sounds',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle 1
          const Text(
            'Relax. Listen. Sleep.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle 2
          const Text(
            'Your peaceful sleep starts here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // --- SLEEP BETTER PAGE (Screen 2) ---
  Widget _buildSleepBetterPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppThemes.paddingScreen),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Custom Painted Planet Illustration
          SizedBox(
            width: 250,
            height: 250,
            child: CustomPaint(
              painter: PlanetIllustrationPainter(),
            ),
          ),
          const SizedBox(height: 50),

          // Title
          const Text(
            'Sleep Better Every Night',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          const Text(
            'Enjoy relaxing sounds crafted to help you fall asleep naturally.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // --- DISCOVER SOOTHING SOUNDS PAGE (Screen 3) ---
  Widget _buildDiscoverSoundsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppThemes.paddingScreen),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Headphones and Audio visualizer Illustration
          SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(250, 250),
                  painter: HeadphonesPainter(),
                ),
                const Positioned(
                  bottom: 50,
                  child: AudioVisualizer(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),

          // Title
          const Text(
            'Discover Soothing Sounds',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          const Text(
            'Rain, ocean, forest, white noise, and calming melodies.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // --- BUILD PERFECT MIX PAGE (Screen 4) ---
  Widget _buildMixerPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppThemes.paddingScreen),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Interactive Mixer Illustration
          SizedBox(
            width: 280,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Floating cyan background glowing particles
                ..._buildMixerParticles(),
                const MixerBoard(),
                // Glow line under mixer
                Positioned(
                  bottom: 10,
                  child: Container(
                    width: 120,
                    height: 2,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryCyan.withValues(alpha: 0.8),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),

          // Title
          const Text(
            'Build Your Perfect Sleep Mix',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          const Text(
            'Mix multiple sounds and create your own relaxing environment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMixerParticles() {
    return [
      Positioned(
        left: 20,
        top: 30,
        child: _buildParticle(6, AppColors.primaryCyan.withValues(alpha: 0.6)),
      ),
      Positioned(
        right: 15,
        top: 50,
        child: _buildParticle(4, AppColors.primaryCyan.withValues(alpha: 0.4)),
      ),
      Positioned(
        left: 25,
        bottom: 40,
        child: _buildParticle(5, AppColors.primaryCyan.withValues(alpha: 0.3)),
      ),
      Positioned(
        right: 25,
        bottom: 30,
        child: _buildParticle(4, AppColors.primaryCyan.withValues(alpha: 0.5)),
      ),
    ];
  }

  Widget _buildParticle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.8),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: Glowing Moon Container ---
class GlowingMoonContainer extends StatelessWidget {
  const GlowingMoonContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryPurple,
            AppColors.primaryBlue,
            AppColors.primaryCyan,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryCyan.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 70,
          height: 70,
          child: CustomPaint(
            painter: CrescentMoonPainter(),
          ),
        ),
      ),
    );
  }
}

// --- PAINTER: Crescent Moon ---
class CrescentMoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..addOval(Rect.fromLTWH(0, 0, size.width, size.height));

    // Offset the cutting circle to the left to leave a crescent on the right
    final path2 = Path()
      ..addOval(
        Rect.fromLTWH(
          -size.width * 0.35,
          -size.height * 0.05,
          size.width,
          size.height * 1.1,
        ),
      );

    final crescentPath = Path.combine(PathOperation.difference, path1, path2);

    canvas.drawPath(crescentPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- PAINTER: Planet Illustration ---
class PlanetIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final planetRadius = size.width * 0.25;

    // Draw background stars
    final starPaint = Paint()..style = PaintingStyle.fill;

    // Static list of stars (offsets relative to center, radius, opacity, type)
    // type: 1 = dot, 2 = sparkle
    final stars = {
      const Offset(-80, -60): [2.0, 0.8, 1.0],
      const Offset(-45, -75): [1.5, 0.5, 1.0],
      const Offset(50, -80): [2.5, 0.9, 1.0],
      const Offset(90, -50): [1.5, 0.4, 1.0],
      const Offset(-90, 30): [2.0, 0.7, 1.0],
      const Offset(85, 45): [2.2, 0.8, 1.0],
      const Offset(-70, 75): [1.5, 0.6, 1.0],
      const Offset(70, 70): [1.8, 0.5, 1.0],
      // Sparkling stars (4-pointed)
      const Offset(-80, 50): [8.0, 0.9, 2.0],
      const Offset(70, 65): [7.0, 0.8, 2.0],
      const Offset(20, -55): [8.5, 0.9, 2.0],
    };

    stars.forEach((offset, data) {
      final pos = center + offset;
      final rad = data[0];
      final op = data[1];
      final type = data[2];

      if (type == 1.0) {
        starPaint.color = Colors.white.withValues(alpha: op);
        canvas.drawCircle(pos, rad, starPaint);
      } else {
        // Draw 4-pointed sparkle
        starPaint.color = AppColors.primaryCyan.withValues(alpha: op);
        final path = Path();
        path.moveTo(pos.dx, pos.dy - rad);
        path.quadraticBezierTo(pos.dx, pos.dy, pos.dx + rad, pos.dy);
        path.quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy + rad);
        path.quadraticBezierTo(pos.dx, pos.dy, pos.dx - rad, pos.dy);
        path.quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy - rad);
        canvas.drawPath(path, starPaint);
      }
    });

    // Draw Planet
    final planetPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF26C6DA), // Bright cyan center
          Color(0xFF006064), // Muted dark teal edges
        ],
        center: Alignment(-0.2, -0.2),
      ).createShader(Rect.fromCircle(center: center, radius: planetRadius));

    canvas.drawCircle(center, planetRadius, planetPaint);

    // Draw Craters (darker teal overlay)
    final craterPaint = Paint()
      ..color = const Color(0xFF00363A).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center + Offset(planetRadius * 0.3, planetRadius * 0.3),
      planetRadius * 0.18,
      craterPaint,
    );
    canvas.drawCircle(
      center + Offset(planetRadius * 0.4, -planetRadius * 0.2),
      planetRadius * 0.12,
      craterPaint,
    );
    canvas.drawCircle(
      center + Offset(-planetRadius * 0.5, planetRadius * 0.1),
      planetRadius * 0.15,
      craterPaint,
    );

    // Draw glowing line below the planet
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primaryCyan.withValues(alpha: 0.0),
          AppColors.primaryCyan,
          AppColors.primaryCyan.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromLTWH(center.dx - 60, center.dy + planetRadius + 30, 120, 2),
      )
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(center.dx - 60, center.dy + planetRadius + 30),
      Offset(center.dx + 60, center.dy + planetRadius + 30),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- PAINTER: Headphones & Notes ---
class HeadphonesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2 - 10);
    final radius = size.width * 0.22;

    // Draw Headband (arc from 180 to 360 degrees)
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, 3.14, 3.14, false, paint);

    // Draw side extensions
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx - radius, center.dy + 15),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + radius, center.dy),
      Offset(center.dx + radius, center.dy + 15),
      paint,
    );

    // Draw ear cups (rounded rectangles)
    final earCupPaint = Paint()
      ..color = AppColors.primaryCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final leftEarCup = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx - radius, center.dy + 25),
        width: 14,
        height: 35,
      ),
      const Radius.circular(6),
    );
    final rightEarCup = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx + radius, center.dy + 25),
        width: 14,
        height: 35,
      ),
      const Radius.circular(6),
    );

    canvas.drawRRect(leftEarCup, earCupPaint);
    canvas.drawRRect(rightEarCup, earCupPaint);

    // Draw music notes floating around
    final notePaint = Paint()
      ..color = AppColors.primaryCyan.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    // Draw a single note at top-left
    _drawMusicNote(canvas, center + Offset(-radius - 30, -35), notePaint);
    // Draw a single note at top-right
    _drawMusicNote(canvas, center + Offset(radius + 35, -20), notePaint);
    // Draw a single note at bottom-left
    _drawMusicNote(canvas, center + Offset(-radius - 20, 30), notePaint);

    // Draw glowing line below the illustration
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primaryCyan.withValues(alpha: 0.0),
          AppColors.primaryCyan,
          AppColors.primaryCyan.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(center.dx - 60, size.height - 10, 120, 2))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(center.dx - 60, size.height - 10),
      Offset(center.dx + 60, size.height - 10),
      linePaint,
    );
  }

  void _drawMusicNote(Canvas canvas, Offset position, Paint paint) {
    // Simple music note: circle + stem + flag
    canvas.drawCircle(position + const Offset(0, 10), 4, paint);

    final stemPaint = Paint()
      ..color = paint.color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      position + const Offset(4, 10),
      position + const Offset(4, -2),
      stemPaint,
    );

    canvas.drawLine(
      position + const Offset(4, -2),
      position + const Offset(10, 0),
      stemPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- WIDGET: Audio Visualizer Waves ---
class AudioVisualizer extends StatelessWidget {
  const AudioVisualizer({super.key});

  @override
  Widget build(BuildContext context) {
    final heights = [
      12.0,
      16.0,
      10.0,
      14.0,
      24.0,
      16.0,
      20.0,
      36.0,
      18.0,
      28.0,
      44.0,
      30.0,
      26.0,
      40.0,
      32.0,
      22.0,
      28.0,
      18.0,
      14.0,
      20.0,
      12.0,
      16.0,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: heights.map((height) {
        return Container(
          width: 4,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            color: AppColors.primaryCyan,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryCyan.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// --- WIDGET: Interactive Mixer Board ---
class MixerBoard extends StatefulWidget {
  const MixerBoard({super.key});

  @override
  State<MixerBoard> createState() => _MixerBoardState();
}

class _MixerBoardState extends State<MixerBoard> {
  final List<double> _sliderValues = [0.65, 0.45, 0.85, 0.35, 0.75];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(AppThemes.borderRadiusCard),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final trackHeight = constraints.maxHeight;
              return GestureDetector(
                onVerticalDragUpdate: (details) {
                  final localY = details.localPosition.dy;
                  final normalizedValue =
                      1.0 - (localY / trackHeight).clamp(0.0, 1.0);
                  setState(() {
                    _sliderValues[index] = normalizedValue;
                  });
                },
                child: SizedBox(
                  width: 30,
                  height: double.infinity,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Inactive Track
                      Container(
                        width: 4,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Active Track
                      FractionallySizedBox(
                        heightFactor: _sliderValues[index],
                        widthFactor: 1.0,
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primaryCyan,
                                AppColors.primaryBlue,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryCyan.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Thumb
                      Positioned(
                        bottom: (_sliderValues[index] * trackHeight) - 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryCyan.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Dot at bottom of slider track
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryCyan,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// --- WIDGET: Page Indicator (Pill & Dots) ---
class PageIndicator extends StatelessWidget {
  final int activeIndex;
  final int count;

  const PageIndicator({
    super.key,
    required this.activeIndex,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: isActive
                ? const LinearGradient(
                    colors: [
                      AppColors.primaryPurple,
                      AppColors.primaryBlue,
                      AppColors.primaryCyan,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: isActive ? null : AppColors.borderLight,
          ),
        );
      }),
    );
  }
}

// --- WIDGET: Custom Gradient Button ---
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Gradient? gradient;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryButtonGradient,
        borderRadius: BorderRadius.circular(AppThemes.borderRadiusButton),
        boxShadow: [
          BoxShadow(
            color: (gradient ?? AppColors.primaryButtonGradient)
                .colors
                .last
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemes.borderRadiusButton),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// --- PLACEHOLDER HOME SCREEN ---
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.primaryPurple, AppColors.primaryCyan],
              ).createShader(bounds),
              child: const Icon(
                Icons.nightlight_round,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Sleep Sounds!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The onboarding is now complete.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const OnboardingScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Restart Onboarding'),
            ),
          ],
        ),
      ),
    );
  }
}
