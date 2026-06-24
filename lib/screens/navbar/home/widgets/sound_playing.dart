import 'package:flutter/material.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_themes.dart';

class SoundPlaying extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? imagePath;
  final IconData fallbackIcon;

  const SoundPlaying({
    super.key,
    this.title = 'Piano Sleep',
    this.subtitle = 'Soft piano melodies',
    this.imagePath,
    this.fallbackIcon = Icons.music_note,
  });

  @override
  State<SoundPlaying> createState() => _SoundPlayingState();
}

class _SoundPlayingState extends State<SoundPlaying> {
  bool _isPlaying = true;
  double _volume = 0.70;
  bool _isFavorite = false;
  int? _timerMinutes;
  List<Map<String, dynamic>> _soundLayers = [];

  @override
  void initState() {
    super.initState();
    // Default active layers from mockup (always show two layers by default)
    _soundLayers = [
      {
        'title': 'Forest Night',
        'volume': 0.70,
        'imagePath': 'assets/images/forest_night.png',
      },
      {
        'title': 'Ocean Breeze',
        'volume': 0.70,
        'imagePath': 'assets/images/ocean_waves.png',
      },
    ];
  }

  void _showTimerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return _TimerBottomSheet(
          initialMinutes: _timerMinutes,
          onTimerChanged: (minutes) {
            setState(() {
              _timerMinutes = minutes;
            });
          },
        );
      },
    );
  }

  void _showAddSoundBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _AddSoundBottomSheet(
              activeLayers: _soundLayers,
              onToggleLayer: (sound) {
                final title = sound['title'] as String;
                final index = _soundLayers.indexWhere(
                  (l) => l['title'] == title,
                );
                setState(() {
                  if (index >= 0) {
                    _soundLayers.removeAt(index);
                  } else {
                    _soundLayers.add({
                      'title': title,
                      'volume': 0.70,
                      'imagePath': sound['imagePath'],
                    });
                  }
                });
                setModalState(() {});
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    // Check if the screen is short (e.g. smaller Android devices or older iPhones)
    final bool isShortScreen = screenHeight < 760;

    // Adaptive spacing & paddings
    final double artHorizontalPadding = isShortScreen ? 90.0 : 76.0;
    final double spacingBetween = isShortScreen ? 8.0 : 14.0;
    final double spacingControls = isShortScreen ? 12.0 : 16.0;
    final double spacingNavBar = isShortScreen ? 8.0 : 14.0;
    final double mainTitleSize = isShortScreen ? 20.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
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
                  // Back Button
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
                    child: Center(
                      child: IconButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title Text
                  const Expanded(
                    child: Text(
                      'Now Playing',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Action Buttons (Heart and Timer)
                  Row(
                    children: [
                      // Favorite/Heart Button
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
                        child: Center(
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _isFavorite = !_isFavorite;
                              });
                            },
                            icon: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite
                                  ? AppColors.primaryCyan
                                  : AppColors.textPrimary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Timer/Clock Button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _timerMinutes != null
                                ? AppColors.primaryCyan
                                : AppColors.borderLight,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: IconButton(
                            onPressed: _showTimerBottomSheet,
                            icon: Icon(
                              Icons.timer_outlined,
                              color: _timerMinutes != null
                                  ? AppColors.primaryCyan
                                  : AppColors.textPrimary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Expanded Column for content so scrollable but leaves Add Sound Layer pinned
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: spacingBetween),
                      // 1. Album Art Image Card
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: artHorizontalPadding,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
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
                              child: widget.imagePath != null
                                  ? (widget.imagePath!.startsWith('http')
                                        ? Image.network(
                                            widget.imagePath!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    _buildImageFallback(),
                                          )
                                        : Image.asset(
                                            widget.imagePath!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    _buildImageFallback(),
                                          ))
                                  : Image.asset(
                                      'assets/images/forest_night.png',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _buildImageFallback(),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: spacingBetween),

                      // 2. Title & Subtitle Info
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: mainTitleSize,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (_soundLayers.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '+${_soundLayers.length} sounds layered',
                              style: const TextStyle(
                                color: AppColors.primaryCyan,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: spacingNavBar),

                      // 3. Playback Control Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Skip Previous
                          Container(
                            width: isShortScreen ? 48 : 54,
                            height: isShortScreen ? 48 : 54,
                            decoration: BoxDecoration(
                              color: AppColors.cardColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.borderLight,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: IconButton(
                                onPressed: () {
                                  // Handle previous
                                },
                                icon: Icon(
                                  Icons.skip_previous_rounded,
                                  color: AppColors.textPrimary,
                                  size: isShortScreen ? 20 : 22,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: spacingControls),
                          // Play / Pause Button
                          Container(
                            width: isShortScreen ? 64 : 70,
                            height: isShortScreen ? 64 : 70,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryCyan,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _isPlaying = !_isPlaying;
                                  });
                                },
                                customBorder: const CircleBorder(),
                                child: Center(
                                  child: Icon(
                                    _isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: isShortScreen ? 26 : 30,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: spacingControls),
                          // Skip Next
                          Container(
                            width: isShortScreen ? 48 : 54,
                            height: isShortScreen ? 48 : 54,
                            decoration: BoxDecoration(
                              color: AppColors.cardColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.borderLight,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: IconButton(
                                onPressed: () {
                                  // Handle next
                                },
                                icon: Icon(
                                  Icons.skip_next_rounded,
                                  color: AppColors.textPrimary,
                                  size: isShortScreen ? 20 : 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacingNavBar),

                      // 4. Volume Slider Row
                      Row(
                        children: [
                          Icon(
                            _volume == 0
                                ? Icons.volume_mute_outlined
                                : _volume < 0.4
                                ? Icons.volume_down_outlined
                                : Icons.volume_up_outlined,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.primaryCyan,
                                inactiveTrackColor: const Color(0xFF1E283C),
                                trackHeight: 4,
                                thumbColor: AppColors.primaryCyan,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 5,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12,
                                ),
                                overlayColor: AppColors.primaryCyan.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                              child: SizedBox(
                                height: 32,
                                child: Slider(
                                  value: _volume,
                                  onChanged: (value) {
                                    setState(() {
                                      _volume = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: Text(
                              '${(_volume * 100).toInt()}%',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacingBetween),

                      // Sound Layers List Container
                      if (_soundLayers.isNotEmpty) ...[
                        Column(
                          children: List.generate(_soundLayers.length, (index) {
                            final layer = _soundLayers[index];
                            return _buildSoundLayerCard(
                              layer,
                              index,
                              isShortScreen,
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),

              // 5. "+ Add Sounds Layer" Pinned Button at bottom (Cyan Outline)
              Container(
                width: double.infinity,
                height: isShortScreen ? 48 : 56,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.primaryCyan, width: 1.5),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showAddSoundBottomSheet,
                    borderRadius: BorderRadius.circular(28),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            color: AppColors.primaryCyan,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Add Sounds Layer',
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
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoundLayerCard(
    Map<String, dynamic> layer,
    int index,
    bool isShortScreen,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isShortScreen ? 6 : 8),
      padding: EdgeInsets.all(isShortScreen ? 8 : 10),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Album image preview
          ClipOval(
            child: SizedBox(
              width: isShortScreen ? 36 : 42,
              height: isShortScreen ? 36 : 42,
              child: Image.asset(
                layer['imagePath'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.backgroundDark,
                    child: const Icon(
                      Icons.music_note,
                      color: AppColors.primaryCyan,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title + Slider
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        layer['title'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isShortScreen ? 14 : 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(layer['volume'] * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Small Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primaryCyan,
                    inactiveTrackColor: const Color(0xFF0F1524),
                    trackHeight: 3,
                    thumbColor: AppColors.primaryCyan,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 4,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 8,
                    ),
                  ),
                  child: SizedBox(
                    height: 20,
                    child: Slider(
                      value: layer['volume'],
                      onChanged: (value) {
                        setState(() {
                          layer['volume'] = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isShortScreen ? 8 : 12),
          // Action Buttons: Mute and Delete
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mute Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    layer['volume'] = layer['volume'] > 0 ? 0.0 : 0.70;
                  });
                },
                child: Container(
                  width: isShortScreen ? 34 : 36,
                  height: isShortScreen ? 34 : 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E283C),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    layer['volume'] == 0
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: AppColors.textSecondary,
                    size: isShortScreen ? 16 : 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Delete Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _soundLayers.removeAt(index);
                  });
                },
                child: Container(
                  width: isShortScreen ? 34 : 36,
                  height: isShortScreen ? 34 : 36,
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: AppColors.errorRed,
                    size: isShortScreen ? 16 : 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Beautiful placeholder fallback image when local/network fails
  Widget _buildImageFallback() {
    return Image.network(
      'https://images.unsplash.com/photo-1502082553048-f009c37129b9?auto=format&fit=crop&q=80&w=600',
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
              widget.fallbackIcon,
              color: AppColors.primaryCyan,
              size: 64,
            ),
          ),
        );
      },
    );
  }
}

class _TimerBottomSheet extends StatefulWidget {
  final int? initialMinutes;
  final Function(int?) onTimerChanged;

  const _TimerBottomSheet({
    required this.initialMinutes,
    required this.onTimerChanged,
  });

  @override
  State<_TimerBottomSheet> createState() => _TimerBottomSheetState();
}

class _TimerBottomSheetState extends State<_TimerBottomSheet> {
  late TextEditingController _customController;
  late FocusNode _customFocusNode;
  int? _localTimerMinutes;

  @override
  void initState() {
    super.initState();
    _localTimerMinutes = widget.initialMinutes;
    _customController = TextEditingController(
      text:
          _localTimerMinutes != null &&
              _localTimerMinutes != 15 &&
              _localTimerMinutes != 30 &&
              _localTimerMinutes != 45 &&
              _localTimerMinutes != 60
          ? _localTimerMinutes.toString()
          : '',
    );
    _customFocusNode = FocusNode();
    _customFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _customController.dispose();
    _customFocusNode.dispose();
    super.dispose();
  }

  String _formatTimerText(int totalMinutes) {
    if (totalMinutes == 60) return '1h';
    if (totalMinutes % 60 == 0) {
      return '${totalMinutes ~/ 60}h';
    }
    if (totalMinutes > 60) {
      return '${totalMinutes ~/ 60}h ${totalMinutes % 60}m';
    }
    return '${totalMinutes}m';
  }

  Widget _buildPresetButton(int minutes, String label) {
    final isSelected = _localTimerMinutes == minutes;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _localTimerMinutes = minutes;
            _customController.clear();
          });
          _customFocusNode.unfocus();
          widget.onTimerChanged(minutes);
        },
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryCyan
                : AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(23),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomToggle() {
    final isCustomSelected =
        _customFocusNode.hasFocus ||
        (_localTimerMinutes != null &&
            _localTimerMinutes != 15 &&
            _localTimerMinutes != 30 &&
            _localTimerMinutes != 45 &&
            _localTimerMinutes != 60);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _customFocusNode.requestFocus();
          setState(() {});
        },
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: isCustomSelected
                ? AppColors.primaryCyan
                : AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(23),
          ),
          child: Center(
            child: Text(
              'Custom',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: isCustomSelected
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTextFieldFocused = _customFocusNode.hasFocus;
    final isCustomSelected =
        isTextFieldFocused ||
        (_localTimerMinutes != null &&
            _localTimerMinutes != 15 &&
            _localTimerMinutes != 30 &&
            _localTimerMinutes != 45 &&
            _localTimerMinutes != 60);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sleep Timer',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Row 1 presets
          Row(
            children: [
              _buildPresetButton(15, '15 min'),
              const SizedBox(width: 12),
              _buildPresetButton(30, '30 min'),
              const SizedBox(width: 12),
              _buildPresetButton(45, '45 min'),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2 presets
          Row(
            children: [
              _buildPresetButton(60, '1 Hour'),
              const SizedBox(width: 12),
              _buildCustomToggle(),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 24),

          // Custom Input field and Save button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCustomSelected
                          ? AppColors.primaryCyan
                          : AppColors.borderLight,
                      width: isCustomSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      inputDecorationTheme: const InputDecorationTheme(
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                    child: TextField(
                      focusNode: _customFocusNode,
                      controller: _customController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Enter minutes..',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.timer_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      onTap: () {
                        setState(() {});
                      },
                      onChanged: (val) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Save button
              GestureDetector(
                onTap: () {
                  final minutes = int.tryParse(_customController.text);
                  if (minutes != null && minutes > 0) {
                    setState(() {
                      _localTimerMinutes = minutes;
                    });
                    widget.onTimerChanged(minutes);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Timer set for $minutes minutes'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: AppColors.cardColor,
                      ),
                    );
                    _customFocusNode.unfocus();
                  }
                },
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight, width: 1),
                  ),
                  child: const Center(
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Outline bottom active indicator
          if (_localTimerMinutes != null) ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  _localTimerMinutes = null;
                  _customController.clear();
                });
                _customFocusNode.unfocus();
                widget.onTimerChanged(null);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Timer cancelled'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppColors.cardColor,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.primaryCyan, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryCyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stopes in ${_formatTimerText(_localTimerMinutes!)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _AddSoundBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> activeLayers;
  final Function(Map<String, dynamic>) onToggleLayer;

  const _AddSoundBottomSheet({
    required this.activeLayers,
    required this.onToggleLayer,
  });

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    final List<Map<String, dynamic>> availableSounds = [
      {
        'title': 'Forest Night',
        'subtitle': 'Peaceful woodland ambience',
        'imagePath': 'assets/images/forest_night.png',
        'icon': Icons.nights_stay_rounded,
      },
      {
        'title': 'Ocean Breeze',
        'subtitle': 'Gentle waves on shore',
        'imagePath': 'assets/images/ocean_waves.png',
        'icon': Icons.waves_rounded,
      },
      {
        'title': 'River Flow',
        'subtitle': 'Calming stream sounds',
        'imagePath': 'assets/images/river_flow.png',
        'icon': Icons.water_rounded,
      },
      {
        'title': 'Birds Chirping',
        'subtitle': 'Morning bird songs',
        'imagePath': 'assets/images/birds_chirping.png',
        'icon': Icons.flutter_dash_rounded,
      },
      {
        'title': 'Soft Rain',
        'subtitle': 'Gentle rainfall',
        'imagePath': 'assets/images/soft_rain.png',
        'icon': Icons.umbrella_rounded,
      },
      {
        'title': 'Thunderstorm',
        'subtitle': 'Deep thunder & rain',
        'imagePath': 'assets/images/thunders.png',
        'icon': Icons.thunderstorm_rounded,
      },
      {
        'title': 'Window Rain',
        'subtitle': 'Rain on glass',
        'imagePath': 'assets/images/soft_rain.png',
        'icon': Icons.grid_on_rounded,
      },
      {
        'title': 'Heavy Rain',
        'subtitle': 'Intense downpour',
        'imagePath': 'assets/images/soft_rain.png',
        'icon': Icons.grain_rounded,
      },
    ];

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Choose a sound to layer',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // List of sounds
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: availableSounds.length,
              itemBuilder: (context, index) {
                final sound = availableSounds[index];
                final bool isActive = activeLayers.any(
                  (l) => l['title'] == sound['title'],
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primaryCyan.withValues(alpha: 0.5)
                          : AppColors.borderLight.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Sound Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primaryCyan
                              : const Color(0xFF1E283C),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          sound['icon'] as IconData,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sound['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sound['subtitle'] as String,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Toggle action button
                      GestureDetector(
                        onTap: () => onToggleLayer(sound),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primaryCyan
                                : const Color(0xFF1E283C),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isActive ? Icons.check_rounded : Icons.add_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
