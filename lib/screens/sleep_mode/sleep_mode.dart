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
  bool _isUltraDim = false;
  double _dimOverlayAlpha = 0.65;
  Timer? _tempBrightenTimer;
  bool _controlsTemporarilyVisible = false;
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
      await ScreenBrightness().setScreenBrightness(target.clamp(0.01, 1.0));
    } catch (e) {
      debugPrint('Error updating brightness: $e');
    } finally {
      _isBrightnessOperationRunning = false;
    }
  }

  Future<void> _enableSleepMode() async {
    if (!_isActive || _isBrightnessOperationRunning) return;
    _isBrightnessOperationRunning = true;
    try {
      await ScreenBrightness().setScreenBrightness(0.01);
    } catch (e) {
      debugPrint('Error setting screen brightness: $e');
    }
    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('Error enabling wakelock: $e');
    } finally {
      _isBrightnessOperationRunning = false;
    }
  }

  Future<void> _disableSleepMode() async {
    if (_isBrightnessOperationRunning) return;
    _isBrightnessOperationRunning = true;
    try {
      await ScreenBrightness().resetScreenBrightness();
    } catch (e) {
      debugPrint('Error resetting screen brightness: $e');
    }
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('Error disabling wakelock: $e');
    } finally {
      _isBrightnessOperationRunning = false;
    }
  }

  void _onScreenTapped() {
    setState(() {
      _controlsTemporarilyVisible = true;
    });
    _tempBrightenTimer?.cancel();
    _tempBrightenTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _controlsTemporarilyVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _isActive = false;
    _tempBrightenTimer?.cancel();
    _glowController.dispose();
    WidgetsBinding.instance.removeObserver(this);
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

    final currentAlpha = _isUltraDim
        ? 0.88
        : (_controlsTemporarilyVisible ? 0.35 : _dimOverlayAlpha);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onScreenTapped,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            // Main Sleep Mode Content
            SafeArea(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
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
                                  alpha: (0.1 + (_glowController.value * 0.2)) *
                                      (_isUltraDim ? 0.3 : 1.0),
                                ),
                                blurRadius: glow,
                                spreadRadius: glow * 0.4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.nights_stay_rounded,
                            color: AppColors.primaryCyan.withValues(
                              alpha: _isUltraDim ? 0.4 : 0.9,
                            ),
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
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: _isUltraDim ? 0.5 : 0.95,
                        ),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (audio.soundLayers.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '+${audio.soundLayers.length} sounds layered',
                        style: TextStyle(
                          color: AppColors.primaryCyan.withValues(
                            alpha: _isUltraDim ? 0.4 : 0.8,
                          ),
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
                                color: AppColors.primaryCyan.withValues(
                                  alpha: _isUltraDim ? 0.4 : 0.9,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _formatTime(audio.timerRemainingSeconds!),
                                  style: TextStyle(
                                    color: AppColors.primaryCyan.withValues(
                                      alpha: _isUltraDim ? 0.5 : 1.0,
                                    ),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'remaining',
                                  style: TextStyle(
                                    color: Colors.white.withValues(
                                      alpha: _isUltraDim ? 0.25 : 0.4,
                                    ),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Playing uninterrupted sound',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(
                            alpha: _isUltraDim ? 0.4 : 0.8,
                          ),
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 36),

                    // Control Play / Pause & Ultra Dim Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 32,
                          tooltip: _isUltraDim ? 'Normal Dim' : 'Ultra Dim',
                          icon: Icon(
                            _isUltraDim
                                ? Icons.brightness_high_rounded
                                : Icons.brightness_2_rounded,
                            color: Colors.white60,
                          ),
                          onPressed: () {
                            setState(() {
                              _isUltraDim = !_isUltraDim;
                            });
                          },
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          iconSize: 64,
                          icon: Icon(
                            audio.isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: AppColors.primaryCyan.withValues(
                              alpha: _isUltraDim ? 0.5 : 1.0,
                            ),
                          ),
                          onPressed: () {
                            audio.togglePlayPause();
                          },
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          iconSize: 32,
                          tooltip: 'Screen Dimmer',
                          icon: Icon(
                            Icons.dark_mode_outlined,
                            color: _dimOverlayAlpha > 0.6
                                ? AppColors.primaryCyan
                                : Colors.white60,
                          ),
                          onPressed: () {
                            setState(() {
                              _dimOverlayAlpha =
                                  _dimOverlayAlpha >= 0.75 ? 0.40 : 0.75;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Exit Sleep Mode Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                          color: Colors.white.withValues(
                            alpha: _isUltraDim ? 0.15 : 0.3,
                          ),
                        ),
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
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap screen to briefly brighten controls',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Dynamic Screen Dimming Black Overlay
            IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: Colors.black.withValues(alpha: currentAlpha),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
