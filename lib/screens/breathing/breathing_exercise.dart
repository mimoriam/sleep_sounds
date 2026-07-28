import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';

enum BreathingPattern {
  sleep478('4-7-8 Sleep', 'Inhale 4s • Hold 7s • Exhale 8s', [
    (phase: 'Breathe In', duration: 4, isExpand: true),
    (phase: 'Hold Breath', duration: 7, isExpand: true),
    (phase: 'Breathe Out', duration: 8, isExpand: false),
  ]),
  box('Box Breathing', 'Inhale 4s • Hold 4s • Exhale 4s • Hold 4s', [
    (phase: 'Breathe In', duration: 4, isExpand: true),
    (phase: 'Hold Breath', duration: 4, isExpand: true),
    (phase: 'Breathe Out', duration: 4, isExpand: false),
    (phase: 'Hold Breath', duration: 4, isExpand: false),
  ]),
  relax('Gentle Calm', 'Inhale 4s • Exhale 6s', [
    (phase: 'Breathe In', duration: 4, isExpand: true),
    (phase: 'Breathe Out', duration: 6, isExpand: false),
  ]);

  final String title;
  final String description;
  final List<({String phase, int duration, bool isExpand})> steps;

  const BreathingPattern(this.title, this.description, this.steps);
}

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  BreathingPattern _currentPattern = BreathingPattern.sleep478;

  int _stepIndex = 0;
  int _secondsRemainingInStep = 4;
  Timer? _stepTimer;

  int _totalSessionSeconds = 180; // 3 min session
  Timer? _sessionTimer;
  bool _isSessionActive = true;
  bool _disposed = false; // Bug #7: disposal guard for timers

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _startPattern();
    _startSessionCountdown();
  }

  void _startSessionCountdown() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_disposed || !mounted) return; // Bug #7: disposal guard
      if (_totalSessionSeconds <= 1) {
        t.cancel();
        setState(() {
          _isSessionActive = false;
        });
        _stepTimer?.cancel();
        _animController.stop();
      } else {
        setState(() {
          _totalSessionSeconds--;
        });
      }
    });
  }

  void _startPattern() {
    _animController.stop();
    _animController.reset();
    _stepIndex = 0;
    _runStep();
  }

  void _runStep() {
    if (_disposed || !mounted || !_isSessionActive) return; // Bug #7: disposal guard

    final currentStep = _currentPattern.steps[_stepIndex];
    _secondsRemainingInStep = currentStep.duration;

    _animController.duration = Duration(seconds: currentStep.duration);
    if (currentStep.phase == 'Breathe In') {
      _animController.forward(from: 0.0);
    } else if (currentStep.phase == 'Breathe Out') {
      _animController.reverse(from: 1.0);
    } // Hold keeps current animation position

    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_disposed || !mounted) return; // Bug #7: disposal guard
      if (_secondsRemainingInStep <= 1) {
        t.cancel();
        _stepIndex = (_stepIndex + 1) % _currentPattern.steps.length;
        _runStep();
      } else {
        setState(() {
          _secondsRemainingInStep--;
        });
      }
    });
  }

  @override
  void dispose() {
    _disposed = true; // Bug #7: set flag before cancelling timers
    _animController.dispose();
    _stepTimer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  String _formatSessionTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _currentPattern.steps[_stepIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Breathing Guide',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryCyan.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      _formatSessionTime(_totalSessionSeconds),
                      style: const TextStyle(
                        color: AppColors.primaryCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pattern Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: BreathingPattern.values.map((p) {
                  final isSelected = p == _currentPattern;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(p.title),
                      selectedColor: AppColors.primaryCyan,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _currentPattern = p;
                            _isSessionActive = true;
                            _totalSessionSeconds = 180;
                          });
                          _startSessionCountdown();
                          _startPattern();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const Spacer(),

            // Animated Breathing Circle Widget
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final scale = 0.65 + (_animController.value * 0.35);
                return Center(
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Glow Ring
                        Container(
                          width: 260 * scale,
                          height: 260 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryCyan
                                .withValues(alpha: 0.12 * scale),
                            border: Border.all(
                              color: AppColors.primaryCyan
                                  .withValues(alpha: 0.3 * scale),
                              width: 2,
                            ),
                          ),
                        ),
                        // Middle Glow Ring
                        Container(
                          width: 200 * scale,
                          height: 200 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryCyan
                                .withValues(alpha: 0.25 * scale),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryCyan
                                    .withValues(alpha: 0.4 * scale),
                                blurRadius: 30 * scale,
                                spreadRadius: 10 * scale,
                              ),
                            ],
                          ),
                        ),
                        // Inner Core Circle
                        Container(
                          width: 140 * scale,
                          height: 140 * scale,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.primaryCyan,
                                Color(0xFF007A87),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$_secondsRemainingInStep',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Current Phase Text Prompt
            if (_isSessionActive) ...[
              Text(
                currentStep.phase,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currentPattern.description,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
            ] else ...[
              const Text(
                'Session Complete! 🎉',
                style: TextStyle(
                  color: AppColors.primaryCyan,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Feel relaxed and ready for deep sleep',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
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
                icon: const Icon(Icons.replay_rounded),
                label: const Text(
                  'Start Again',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  setState(() {
                    _isSessionActive = true;
                    _totalSessionSeconds = 180;
                  });
                  _startSessionCountdown();
                  _startPattern();
                },
              ),
            ],

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
