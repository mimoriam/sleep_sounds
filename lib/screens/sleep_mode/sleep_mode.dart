import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../providers/audio_provider.dart';
import '../../utils/app_colors.dart';

class SleepModeScreen extends StatefulWidget {
  const SleepModeScreen({super.key});

  @override
  State<SleepModeScreen> createState() => _SleepModeScreenState();
}

class _SleepModeScreenState extends State<SleepModeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _isActive = true;
  bool _isBrightnessOperationRunning = false;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _enableSleepMode();

    // Bug #9: Listen to provider changes to update brightness outside build()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AudioProvider>().addListener(_onAudioChanged);
    });
  }

  void _onAudioChanged() {
    if (!mounted) return;
    final audio = context.read<AudioProvider>();
    final fade = audio.fadeProgress;
    if (fade != null) {
      final targetBrightness = (0.01 + (0.04 * fade)).clamp(0.01, 0.05);
      _updateBrightness(targetBrightness);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isActive) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _disableSleepMode();
    } else if (state == AppLifecycleState.resumed) {
      _enableSleepMode();
    }
  }

  Future<void> _updateBrightness(double target) async {
    if (!_isActive || _isBrightnessOperationRunning) return;
    _isBrightnessOperationRunning = true;
    try {
      await ScreenBrightness().setScreenBrightness(target);
    } catch (_) {
    } finally {
      _isBrightnessOperationRunning = false;
    }
  }

  Future<void> _enableSleepMode() async {
    if (!_isActive || _isBrightnessOperationRunning) return;
    _isBrightnessOperationRunning = true;
    try {
      await ScreenBrightness().setScreenBrightness(0.05);
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('Brightness error: $e');
    } finally {
      _isBrightnessOperationRunning = false;
    }
  }

  Future<void> _disableSleepMode() async {
    if (_isBrightnessOperationRunning) return;
    _isBrightnessOperationRunning = true;
    try {
      await ScreenBrightness().resetScreenBrightness();
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('Brightness reset error: $e');
    } finally {
      _isBrightnessOperationRunning = false;
    }
  }

  @override
  void dispose() {
    _isActive = false;
    _glowController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    // Bug #9: Remove the provider listener
    try {
      context.read<AudioProvider>().removeListener(_onAudioChanged);
    } catch (_) {}
    _disableSleepMode();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final totalSecs = audio.timerTotalSeconds ?? 1;
    final remaining = audio.timerRemainingSeconds ?? 0;
    final progress = (remaining / totalSecs).clamp(0.0, 1.0);
    // Bug #9: Brightness is now updated from _onAudioChanged listener, not here.

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
            Navigator.pop(context);
          }
        },
        child: SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withValues(alpha: 0.95),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Glowing Animated Moon Icon
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    final glow = 15.0 + (_glowController.value * 25.0);
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryCyan.withValues(
                              alpha: 0.2 + (_glowController.value * 0.3),
                            ),
                            blurRadius: glow,
                            spreadRadius: glow * 0.4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.nights_stay_rounded,
                        color: AppColors.primaryCyan,
                        size: 84,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Sound Title & Layers Info
                Text(
                  audio.currentSound.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (audio.soundLayers.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '+${audio.soundLayers.length} sounds layered',
                    style: const TextStyle(
                      color: AppColors.primaryCyan,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Timer Circular Progress or Status
                if (audio.timerRemainingSeconds != null) ...[
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 130,
                          height: 130,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6,
                            backgroundColor: Colors.white10,
                            color: AppColors.primaryCyan,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(audio.timerRemainingSeconds!),
                              style: const TextStyle(
                                color: AppColors.primaryCyan,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'remaining',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Playing uninterrupted sound',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 50),

                // Control Play / Pause
                IconButton(
                  iconSize: 64,
                  icon: Icon(
                    audio.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: AppColors.primaryCyan,
                  ),
                  onPressed: () {
                    audio.togglePlayPause();
                  },
                ),
                const SizedBox(height: 40),

                // Exit Sleep Mode Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  icon: const Icon(Icons.wb_sunny_outlined, size: 20),
                  label: const Text(
                    'Wake Up / Exit Sleep Mode',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Swipe down to exit anytime',
                  style: TextStyle(color: Colors.white24, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
