import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../models/mix_preset.dart';
import '../../../../models/sound_category.dart';
import '../../../../models/sound_model.dart';
import '../../../../providers/audio_provider.dart';
import '../../../../providers/favorites_provider.dart';
import '../../../../providers/presets_provider.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_themes.dart';
import '../../../../utils/page_transitions.dart';
import '../../../breathing/breathing_exercise.dart';
import '../../../sleep_mode/sleep_mode.dart';

class SoundPlaying extends StatefulWidget {
  final SoundType sound;
  final int variantIndex;

  const SoundPlaying({
    super.key,
    required this.sound,
    this.variantIndex = 0,
  });

  @override
  State<SoundPlaying> createState() => _SoundPlayingState();
}

class _SoundPlayingState extends State<SoundPlaying>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimController;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final audio = context.read<AudioProvider>();
      final settings = context.read<SettingsProvider>();

      audio.updateSettings(
        notificationsEnabled: settings.notificationsEnabled,
      );

      if (audio.currentSound.id != widget.sound.id || (!audio.isPlaying && !audio.isBuffering)) {
        audio.selectAndPlay(widget.sound, variantIndex: widget.variantIndex);
      }

      // Bug #3 fix: Only auto-set timer; do NOT auto-navigate to Sleep Mode.
      // Sleep Mode navigation only happens when the user explicitly sets timer
      // via the Timer Bottom Sheet.
      if (audio.timerMinutes == null &&
          !audio.timerExplicitlyCleared &&
          settings.defaultTimerMinutes != null) {
        audio.setTimer(settings.defaultTimerMinutes);
      }

      // Bug #2 fix: Listen for errors on the provider instead of reading in build()
      audio.addListener(_onAudioProviderChanged);
    });
  }

  void _onAudioProviderChanged() {
    if (!mounted) return;
    final audio = context.read<AudioProvider>();
    final err = audio.errorMessage;
    if (err != null) {
      audio.clearErrorMessage();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err, style: TextStyle(color: AppColors.text(context))),
            backgroundColor: AppColors.card(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.primaryCyan, width: 1),
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    // Bug #2 fix: Remove the audio provider error listener
    // We access the provider directly since we still have context at this point
    try {
      context.read<AudioProvider>().removeListener(_onAudioProviderChanged);
    } catch (_) {}
    _bgAnimController.dispose();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showTimerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return const _TimerBottomSheet();
      },
    );
  }

  void _showAddSoundBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return const _AddSoundBottomSheet();
      },
    );
  }

  void _showSaveMixDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _SavePresetDialog(),
    );
  }

  // Generate category-specific gradient colors for dynamic visual theme
  List<Color> _getCategoryColors(SoundCategory cat, double anim) {
    switch (cat) {
      case SoundCategory.nature:
        return [
          Color.lerp(const Color(0xFF0F2027), const Color(0xFF1F4037), anim)!,
          Color.lerp(const Color(0xFF203A43), const Color(0xFF99F2C8), anim * 0.3)!,
          const Color(0xFF0F2027),
        ];
      case SoundCategory.rain:
        return [
          Color.lerp(const Color(0xFF141E30), const Color(0xFF243B55), anim)!,
          Color.lerp(const Color(0xFF243B55), const Color(0xFF005C97), anim * 0.4)!,
          const Color(0xFF141E30),
        ];
      case SoundCategory.whiteNoise:
        return [
          Color.lerp(const Color(0xFF232526), const Color(0xFF414345), anim)!,
          Color.lerp(const Color(0xFF414345), const Color(0xFF232526), anim)!,
          const Color(0xFF1A1A1A),
        ];
      case SoundCategory.sleepMusic:
        return [
          Color.lerp(const Color(0xFF1A0033), const Color(0xFF330066), anim)!,
          Color.lerp(const Color(0xFF330066), const Color(0xFF660066), anim * 0.5)!,
          const Color(0xFF0A0014),
        ];
      case SoundCategory.ambient:
        return [
          Color.lerp(const Color(0xFF311006), const Color(0xFF591D0B), anim)!,
          Color.lerp(const Color(0xFF591D0B), const Color(0xFF802E00), anim * 0.4)!,
          const Color(0xFF1A0903),
        ];
      case SoundCategory.relaxation:
      default:
        return [
          Color.lerp(const Color(0xFF00223E), const Color(0xFF1D976C), anim * 0.3)!,
          Color.lerp(const Color(0xFF1D976C), const Color(0xFF00223E), anim)!,
          const Color(0xFF001122),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final isFav = favorites.isFavorite(audio.currentSound.id);


    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isShortScreen = screenHeight < 760;

    final double artHorizontalPadding = isShortScreen ? 90.0 : 76.0;
    final double spacingBetween = isShortScreen ? 8.0 : 14.0;
    final double spacingControls = isShortScreen ? 12.0 : 16.0;
    final double mainTitleSize = isShortScreen ? 20.0 : 24.0;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgAnimController,
        builder: (context, child) {
          final gradientColors = _getCategoryColors(
            audio.currentSound.category,
            _bgAnimController.value,
          );
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppThemes.paddingScreen,
              vertical: isShortScreen ? 6 : 10,
            ),
            child: Column(
              children: [
                // Custom Navigation Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: IconButton(
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Now Playing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          children: [
                            // Breathing Guide Button
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: IconButton(
                                  tooltip: 'Breathing Guide',
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      FadeRoute(
                                        page: const BreathingExerciseScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.self_improvement_rounded,
                                    color: AppColors.primaryCyan,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Sleep Mode Button
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: IconButton(
                                  tooltip: 'Sleep Mode (Dim Screen)',
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      FadeRoute(
                                        page: const SleepModeScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.bedtime_outlined,
                                    color: AppColors.primaryCyan,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Favorite Button
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: IconButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    favorites.toggleFavorite(audio.currentSound.id);
                                  },
                                  icon: Icon(
                                    isFav ? Icons.favorite : Icons.favorite_border,
                                    color: isFav
                                        ? AppColors.primaryCyan
                                        : Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: audio.timerMinutes != null
                                      ? AppColors.primaryCyan
                                      : Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: IconButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _showTimerBottomSheet();
                                  },
                                  icon: Icon(
                                    Icons.timer_outlined,
                                    color: audio.timerMinutes != null
                                        ? AppColors.primaryCyan
                                        : Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            // UI #4: Timer countdown shown next to timer button
                            if (audio.timerRemainingSeconds != null) ...[  
                              const SizedBox(width: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryCyan.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.primaryCyan.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  _formatTimer(audio.timerRemainingSeconds!),
                                  style: const TextStyle(
                                    color: AppColors.primaryCyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(height: spacingBetween),
                        // Album Art Card
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: artHorizontalPadding,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 25,
                                  spreadRadius: 3,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: audio.currentSound.imagePath != null
                                    ? Image.asset(
                                        audio.currentSound.imagePath!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildImageFallback(
                                                    context,
                                                    audio.currentSound.icon),
                                      )
                                    : _buildImageFallback(
                                        context, audio.currentSound.icon),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: spacingBetween),

                        // Sound Title & Tags
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              audio.currentSound.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: mainTitleSize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              audio.currentSound.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryCyan
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.primaryCyan
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      'Variant ${audio.currentVariantIndex + 1} of ${audio.currentSound.variantCount}',
                                      style: const TextStyle(
                                        color: AppColors.primaryCyan,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (audio.soundLayers.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.amber.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Text(
                                        '+${audio.soundLayers.length} Layers Active',
                                        style: const TextStyle(
                                          color: Colors.amberAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: spacingBetween),

                        // Playback Controls
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Save Mix Preset Button
                              IconButton(
                                tooltip: 'Save Mix as Preset',
                                icon: const Icon(
                                  Icons.bookmark_add_outlined,
                                  color: Colors.white70,
                                  size: 24,
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _showSaveMixDialog();
                                },
                              ),
                              SizedBox(width: spacingControls),

                              // Previous Variant
                              Container(
                                width: isShortScreen ? 48 : 54,
                                height: isShortScreen ? 48 : 54,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    audio.previousVariant();
                                  },
                                  icon: const Icon(
                                    Icons.skip_previous_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: spacingControls),

                              // Play/Pause Button
                              Container(
                                width: isShortScreen ? 64 : 70,
                                height: isShortScreen ? 64 : 70,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryCyan,
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    audio.togglePlayPause();
                                  },
                                  icon: audio.isBuffering
                                      ? const SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            color: Colors.black,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : Icon(
                                          audio.isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: Colors.black,
                                          size: isShortScreen ? 32 : 36,
                                        ),
                                ),
                              ),
                              SizedBox(width: spacingControls),

                              // Next Variant
                              Container(
                                width: isShortScreen ? 48 : 54,
                                height: isShortScreen ? 48 : 54,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    audio.nextVariant();
                                  },
                                  icon: const Icon(
                                    Icons.skip_next_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: spacingControls),

                              // Clear Layers Quick Icon
                              IconButton(
                                tooltip: 'Clear All Layers',
                                icon: Icon(
                                  Icons.layers_clear_outlined,
                                  color: audio.soundLayers.isNotEmpty
                                      ? Colors.amberAccent
                                      : Colors.white30,
                                  size: 24,
                                ),
                                onPressed: audio.soundLayers.isEmpty
                                    ? null
                                    : () {
                                        HapticFeedback.lightImpact();
                                        audio.clearAllLayers();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'Cleared all sound layers',
                                            ),
                                            backgroundColor:
                                                AppColors.card(context),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: spacingBetween),

                        // Master Volume Slider
                        Row(
                          children: [
                            Icon(
                              audio.masterVolume == 0
                                  ? Icons.volume_mute_outlined
                                  : audio.masterVolume < 0.4
                                      ? Icons.volume_down_outlined
                                      : Icons.volume_up_outlined,
                              color: Colors.white70,
                              size: 22,
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: audio.isInFadeOut
                                      ? Colors.white30
                                      : AppColors.primaryCyan,
                                  inactiveTrackColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  trackHeight: 4,
                                  thumbColor: audio.isInFadeOut
                                      ? Colors.white30
                                      : AppColors.primaryCyan,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                ),
                                child: Slider(
                                  value: audio.masterVolume,
                                  // Bug #6: Disable slider during fade-out
                                  onChanged: audio.isInFadeOut
                                      ? null
                                      : (val) => audio.setMasterVolume(val),
                                ),
                              ),
                            ),
                            Text(
                              '${(audio.masterVolume * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        // Bug #6: Fading chip shown during fade-out
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          child: audio.isInFadeOut
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryCyan
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.primaryCyan
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.nights_stay_rounded,
                                          color: AppColors.primaryCyan,
                                          size: 14,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Fading to sleep...',
                                          style: TextStyle(
                                            color: AppColors.primaryCyan,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        SizedBox(height: spacingBetween),

                        // Active Sound Layers List Card
                        if (audio.soundLayers.isNotEmpty) ...[
                          Column(
                            children: List.generate(audio.soundLayers.length,
                                (index) {
                              final layer = audio.soundLayers[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.primaryCyan
                                        .withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      layer.soundType.icon,
                                      color: AppColors.primaryCyan,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            layer.soundType.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          SliderTheme(
                                            data: SliderTheme.of(context)
                                                .copyWith(
                                              activeTrackColor:
                                                  AppColors.primaryCyan,
                                              inactiveTrackColor: Colors.white
                                                  .withValues(alpha: 0.2),
                                              trackHeight: 3,
                                              thumbColor: AppColors.primaryCyan,
                                              thumbShape:
                                                  const RoundSliderThumbShape(
                                                enabledThumbRadius: 4,
                                              ),
                                            ),
                                            child: SizedBox(
                                              height: 20,
                                              child: Slider(
                                                value: layer.volume,
                                                // Bug #6: Also disable layer sliders during fade
                                                onChanged: audio.isInFadeOut
                                                    ? null
                                                    : (val) => audio.setLayerVolume(index, val),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: AppColors.errorRed,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        final soundName = layer.soundType.title;
                                        audio.removeSoundLayer(index);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Removed "$soundName" from layers',
                                            ),
                                            backgroundColor:
                                                AppColors.card(context),
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bottom Add Layer Button with Layer Badge Count
                Container(
                  width: double.infinity,
                  height: isShortScreen ? 48 : 54,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(28),
                    border:
                        Border.all(color: AppColors.primaryCyan, width: 1.5),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showAddSoundBottomSheet();
                      },
                      borderRadius: BorderRadius.circular(28),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, color: AppColors.primaryCyan),
                            const SizedBox(width: 8),
                            Text(
                              audio.soundLayers.isEmpty
                                  ? 'Add Sound Layer'
                                  : 'Manage Sound Layers (${audio.soundLayers.length}/5)',
                              style: const TextStyle(
                                color: AppColors.primaryCyan,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageFallback(BuildContext context, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
      ),
      child: Center(
        child: Icon(
          icon,
          color: AppColors.primaryCyan,
          size: 64,
        ),
      ),
    );
  }
}

// Timer Bottom Sheet
class _TimerBottomSheet extends StatelessWidget {
  const _TimerBottomSheet();

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();

    return Container(
      color: AppColors.card(context),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Set Sleep Timer',
                style: TextStyle(
                  color: AppColors.text(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.textMuted(context)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [null, 15, 30, 45, 60, 90].map((mins) {
              final isSelected = audio.timerMinutes == mins;
              final label = mins == null ? 'Off' : '$mins min';
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                selectedColor: AppColors.primaryCyan,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : AppColors.text(context),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: AppColors.background(context),
                onSelected: (selected) {
                  HapticFeedback.lightImpact();
                  final nav = Navigator.of(context);
                  audio.setTimer(mins);
                  nav.pop();

                  if (mins != null) {
                    nav.push(
                      FadeRoute(page: const SleepModeScreen()),
                    );
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// Add Sound Layer Bottom Sheet grouped by category
class _AddSoundBottomSheet extends StatelessWidget {
  const _AddSoundBottomSheet();

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final categories = SoundCategory.values
        .where((c) => c != SoundCategory.all)
        .toList();

    return Material(
      color: AppColors.card(context),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.70,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Ambient Sound Layer',
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Mix up to 5 sounds together (${audio.soundLayers.length}/5 active)',
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textMuted(context)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: categories.expand((cat) {
                    final categorySounds = SoundRegistry.getByCategory(cat)
                        .where((s) => s.id != audio.currentSound.id)
                        .toList();

                    if (categorySounds.isEmpty) return <Widget>[];

                    return [
                      Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 6),
                        child: Row(
                          children: [
                            Icon(cat.icon, size: 16, color: AppColors.primaryCyan),
                            const SizedBox(width: 8),
                            Text(
                              cat.label.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primaryCyan,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...categorySounds.map((sound) {
                        final layerIdx = audio.soundLayers
                            .indexWhere((l) => l.soundType.id == sound.id);
                        final isLayered = layerIdx >= 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isLayered
                                ? AppColors.primaryCyan.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                dense: true,
                                leading: Icon(sound.icon, color: AppColors.primaryCyan),
                                title: Text(
                                  sound.title,
                                  style: TextStyle(
                                    color: AppColors.text(context),
                                    fontWeight: isLayered
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  sound.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textMuted(context),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Icon(
                                  isLayered
                                      ? Icons.check_circle_rounded
                                      : Icons.add_circle_outline_rounded,
                                  color: isLayered
                                      ? AppColors.primaryCyan
                                      : AppColors.textMuted(context),
                                ),
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  if (isLayered) {
                                    await audio.removeSoundLayer(layerIdx);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Removed "${sound.title}" layer',
                                          ),
                                          backgroundColor: AppColors.card(context),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } else {
                                    final success = await audio.addSoundLayer(sound);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? '🎵 Added "${sound.title}" layer (${audio.soundLayers.length}/5)'
                                                : 'Could not add layer (Limit reached)',
                                          ),
                                          backgroundColor: AppColors.card(context),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              if (isLayered) ...[
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 56,
                                    right: 16,
                                    bottom: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.volume_down,
                                        size: 16,
                                        color: AppColors.primaryCyan,
                                      ),
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            activeTrackColor: AppColors.primaryCyan,
                                            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                                            trackHeight: 3,
                                            thumbColor: AppColors.primaryCyan,
                                            thumbShape: const RoundSliderThumbShape(
                                              enabledThumbRadius: 4,
                                            ),
                                          ),
                                          child: SizedBox(
                                            height: 20,
                                            child: Slider(
                                              value: audio.soundLayers[layerIdx].volume,
                                              onChanged: (val) =>
                                                  audio.setLayerVolume(layerIdx, val),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${(audio.soundLayers[layerIdx].volume * 100).toInt()}%',
                                        style: const TextStyle(
                                          color: AppColors.primaryCyan,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ];
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavePresetDialog extends StatefulWidget {
  const _SavePresetDialog();

  @override
  State<_SavePresetDialog> createState() => _SavePresetDialogState();
}

class _SavePresetDialogState extends State<_SavePresetDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final audio = context.read<AudioProvider>();
    _controller = TextEditingController(
      text: 'My ${audio.currentSound.title} Mix',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.read<AudioProvider>();
    final presets = context.read<PresetsProvider>();

    return AlertDialog(
      backgroundColor: AppColors.card(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Save Mix Preset',
        style: TextStyle(color: AppColors.text(context)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Main sound: ${audio.currentSound.title}',
              style: TextStyle(color: AppColors.textMuted(context), fontSize: 13),
            ),
            if (audio.soundLayers.isNotEmpty)
              Text(
                'Layers: ${audio.soundLayers.map((l) => l.soundType.title).join(", ")}',
                style: const TextStyle(color: AppColors.primaryCyan, fontSize: 13),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(color: AppColors.text(context)),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Preset Name',
                hintText: 'e.g. Cozy Night',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(context))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryCyan,
            foregroundColor: Colors.black,
          ),
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () async {
                  final name = _controller.text.trim();
                  final layers = audio.soundLayers
                      .map((l) => LayerConfig(
                            soundId: l.soundType.id,
                            volume: l.volume,
                          ))
                      .toList();

                  final cardColor = AppColors.card(context);
                  final textColor = AppColors.text(context);

                  final success = await presets.savePreset(
                    name: name,
                    mainSoundId: audio.currentSound.id,
                    layers: layers,
                    masterVolume: audio.masterVolume,
                  );

                  if (context.mounted) Navigator.pop(context);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Saved mix preset "$name"'
                              : 'Limit reached (Max 15 presets)',
                          style: TextStyle(color: textColor),
                        ),
                        backgroundColor: cardColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

