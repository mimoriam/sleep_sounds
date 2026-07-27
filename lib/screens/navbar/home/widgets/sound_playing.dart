import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../models/sound_model.dart';
import '../../../../providers/audio_provider.dart';
import '../../../../providers/favorites_provider.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_themes.dart';
import '../../../../utils/page_transitions.dart';
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

class _SoundPlayingState extends State<SoundPlaying> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final audio = context.read<AudioProvider>();
      final settings = context.read<SettingsProvider>();

      audio.updateSettings(notificationsEnabled: settings.notificationsEnabled);

      if (audio.currentSound.id != widget.sound.id) {
        audio.selectAndPlay(widget.sound, variantIndex: widget.variantIndex);
      }

      if (audio.timerMinutes == null &&
          !audio.timerExplicitlyCleared &&
          settings.defaultTimerMinutes != null) {
        audio.setTimer(settings.defaultTimerMinutes);
      }
    });
  }

  void _showTimerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return const _AddSoundBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final isFav = favorites.isFavorite(audio.currentSound.id);

    final errorMsg = audio.errorMessage;
    if (errorMsg != null) {
      audio.clearErrorMessage();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg, style: TextStyle(color: AppColors.text(context))),
            backgroundColor: AppColors.card(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.primaryCyan, width: 1),
            ),
            action: SnackBarAction(
              label: 'OK',
              textColor: AppColors.primaryCyan,
              onPressed: () {},
            ),
          ),
        );
      });
    }

    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isShortScreen = screenHeight < 760;

    final double artHorizontalPadding = isShortScreen ? 90.0 : 76.0;
    final double spacingBetween = isShortScreen ? 8.0 : 14.0;
    final double spacingControls = isShortScreen ? 12.0 : 16.0;
    final double mainTitleSize = isShortScreen ? 20.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
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
                    child: Center(
                      child: IconButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.text(context),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Now Playing',
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // Sleep Mode Button
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
                        child: Center(
                          child: IconButton(
                            tooltip: 'Sleep Mode',
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
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Favorite/Heart Button
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
                                  : AppColors.text(context),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Timer Button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: audio.timerMinutes != null
                                ? AppColors.primaryCyan
                                : AppColors.border(context),
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
                                  : AppColors.text(context),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Expanded Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: spacingBetween),
                      // Album Art Image Card
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: artHorizontalPadding,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
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
                                              _buildImageFallback(context, audio.currentSound.icon),
                                    )
                                  : _buildImageFallback(context, audio.currentSound.icon),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: spacingBetween),

                      // Sound Title & Info
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            audio.currentSound.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.text(context),
                              fontSize: mainTitleSize,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            audio.currentSound.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted(context),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Variant ${audio.currentVariantIndex + 1} of ${audio.currentSound.variantCount}',
                            style: const TextStyle(
                              color: AppColors.primaryCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (audio.soundLayers.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '+${audio.soundLayers.length} sounds layered',
                              style: const TextStyle(
                                color: AppColors.primaryCyan,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: spacingBetween),

                      // Playback Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Previous Variant
                          Container(
                            width: isShortScreen ? 48 : 54,
                            height: isShortScreen ? 48 : 54,
                            decoration: BoxDecoration(
                              color: AppColors.card(context),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.border(context),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                audio.previousVariant();
                              },
                              icon: Icon(
                                Icons.skip_previous_rounded,
                                color: AppColors.text(context),
                              ),
                            ),
                          ),
                          SizedBox(width: spacingControls),
                          // Play/Pause Button with Buffering State
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
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Icon(
                                      audio.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
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
                              color: AppColors.card(context),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.border(context),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                audio.nextVariant();
                              },
                              icon: Icon(
                                Icons.skip_next_rounded,
                                color: AppColors.text(context),
                              ),
                            ),
                          ),
                        ],
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
                            color: AppColors.textMuted(context),
                            size: 22,
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.primaryCyan,
                                inactiveTrackColor: AppColors.border(context),
                                trackHeight: 4,
                                thumbColor: AppColors.primaryCyan,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 5,
                                ),
                              ),
                              child: Slider(
                                value: audio.masterVolume,
                                onChanged: (val) => audio.setMasterVolume(val),
                              ),
                            ),
                          ),
                          Text(
                            '${(audio.masterVolume * 100).toInt()}%',
                            style: TextStyle(
                              color: AppColors.textMuted(context),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacingBetween),

                      // Active Sound Layers List
                      if (audio.soundLayers.isNotEmpty) ...[
                        Column(
                          children: List.generate(audio.soundLayers.length, (index) {
                            final layer = audio.soundLayers[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.card(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.border(context),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          layer.soundType.title,
                                          style: TextStyle(
                                            color: AppColors.text(context),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            activeTrackColor: AppColors.primaryCyan,
                                            inactiveTrackColor: AppColors.border(context),
                                            trackHeight: 3,
                                            thumbColor: AppColors.primaryCyan,
                                            thumbShape: const RoundSliderThumbShape(
                                              enabledThumbRadius: 4,
                                            ),
                                          ),
                                          child: SizedBox(
                                            height: 20,
                                            child: Slider(
                                              value: layer.volume,
                                              onChanged: (val) =>
                                                  audio.setLayerVolume(index, val),
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
                                      audio.removeSoundLayer(index);
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

              // Bottom Add Layer Button
              Container(
                width: double.infinity,
                height: isShortScreen ? 48 : 54,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.primaryCyan, width: 1.5),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showAddSoundBottomSheet();
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: AppColors.primaryCyan),
                          SizedBox(width: 8),
                          Text(
                            'Add Sound Layer',
                            style: TextStyle(
                              color: AppColors.primaryCyan,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
                  audio.setTimer(mins);
                  Navigator.pop(context);
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

// Add Sound Layer Bottom Sheet
class _AddSoundBottomSheet extends StatelessWidget {
  const _AddSoundBottomSheet();

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final allSounds = SoundRegistry.allSounds
        .where((s) => s.id != audio.currentSound.id)
        .toList();

    return Material(
      color: AppColors.card(context),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Ambient Sound Layer',
                style: TextStyle(
                  color: AppColors.text(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.textMuted(context)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: allSounds.length,
              itemBuilder: (context, index) {
                final sound = allSounds[index];
                final isLayered =
                    audio.soundLayers.any((l) => l.soundType.id == sound.id);

                return ListTile(
                  leading: Icon(sound.icon, color: AppColors.primaryCyan),
                  title: Text(
                    sound.title,
                    style: TextStyle(color: AppColors.text(context)),
                  ),
                  subtitle: Text(
                    sound.category.label,
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
                  onTap: () {
                    HapticFeedback.lightImpact();
                    audio.toggleSoundLayer(sound);
                  },
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
