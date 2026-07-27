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
    with WidgetsBindingObserver {
  bool _isActive = true;
  bool _isBrightnessOperationRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableSleepMode();
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
    WidgetsBinding.instance.removeObserver(this);
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withValues(alpha: 0.92),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.nights_stay_rounded,
                color: AppColors.primaryCyan,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                audio.currentSound.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (audio.timerRemainingSeconds != null) ...[
                Text(
                  'Timer: ${_formatTime(audio.timerRemainingSeconds!)}',
                  style: const TextStyle(
                    color: AppColors.primaryCyan,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
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
              const SizedBox(height: 60),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 56,
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
                ],
              ),
              const SizedBox(height: 40),

              // Exit Sleep Mode Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white60,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: const Icon(Icons.wb_sunny_outlined, size: 20),
                label: const Text('Wake Up / Exit Sleep Mode'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
