import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';
import '../../services/subscription_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/page_transitions.dart';
import '../../utils/tab_notification.dart';
import 'favourite/favourite.dart';
import 'home/home.dart';
import 'home/widgets/sound_playing.dart';
import 'presets/presets_screen.dart';
import 'settings/settings.dart';
import 'sounds/sounds.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _currentIndex = 0;
  SubscriptionService? _subscriptionService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _subscriptionService = context.read<SubscriptionService>();
      _subscriptionService?.addListener(_onSubscriptionChanged);
    });
  }

  void _onSubscriptionChanged() {
    if (!mounted || _subscriptionService == null) return;
    context.read<AudioProvider>().enforceSubscriptionStatus(_subscriptionService!.isPremium);
  }

  @override
  void dispose() {
    _subscriptionService?.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const SoundsScreen(),
    const PresetsScreen(),
    const FavouriteScreen(),
    const SettingsScreen(),
  ];

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border(context), width: 1),
        ),
        title: Text(
          'Exit App?',
          style: TextStyle(
            color: AppColors.text(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to exit Sleep Sounds?',
          style: TextStyle(color: AppColors.textMuted(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Exit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        } else {
          final shouldExit = await _showExitConfirmationDialog(context);
          if (shouldExit && context.mounted) {
            context.read<AudioProvider>().stop();
            SystemNavigator.pop();
          }
        }
      },
      child: NotificationListener<TabSwitchNotification>(
        onNotification: (notification) {
          setState(() {
            _currentIndex = notification.index;
          });
          return true;
        },
        child: Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: IndexedStack(index: _currentIndex, children: _screens),
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Selector<AudioProvider, bool>(
                selector: (_, audio) =>
                    audio.isPlaying || audio.timerRemainingSeconds != null,
                builder: (context, showMiniPlayer, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: showMiniPlayer
                        ? const _MiniPlayerBar(key: ValueKey('mini_player'))
                        : const SizedBox.shrink(key: ValueKey('no_mini_player')),
                  );
                },
              ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: AppColors.border(context),
                    width: 1.0,
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    backgroundColor: Colors.transparent,
                    selectedItemColor: AppColors.primaryCyan,
                    unselectedItemColor: AppColors.textMuted(context),
                    selectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                    ),
                    type: BottomNavigationBarType.fixed,
                    elevation: 0,
                    items: const [
                      BottomNavigationBarItem(
                        icon: Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.home_outlined, size: 22),
                        ),
                        activeIcon: Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.home, size: 22),
                        ),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.music_note_outlined, size: 22),
                        ),
                        activeIcon: Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.music_note, size: 22),
                        ),
                        label: 'Sounds',
                      ),
                      BottomNavigationBarItem(
                        icon: Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.tune_outlined, size: 22),
                        ),
                        activeIcon: Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.tune, size: 22),
                        ),
                        label: 'Mixes',
                      ),
                      BottomNavigationBarItem(
                        icon: Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.favorite_border, size: 22),
                        ),
                        activeIcon: Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.favorite, size: 22),
                        ),
                        label: 'Favorites',
                      ),
                      BottomNavigationBarItem(
                        icon: Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.settings_outlined, size: 22),
                        ),
                        activeIcon: Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.settings, size: 22),
                        ),
                        label: 'Settings',
                      ),
                    ],
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
}

class _MiniPlayerBar extends StatelessWidget {
  const _MiniPlayerBar({super.key});

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final sound = audio.currentSound;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryCyan, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              SlideUpFadeRoute(page: SoundPlaying(sound: sound)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: sound.imagePath != null
                        ? Image.asset(
                            sound.imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: AppColors.card(context),
                              child: Icon(sound.icon, color: AppColors.primaryCyan, size: 20),
                            ),
                          )
                        : Container(
                            color: AppColors.card(context),
                            child: Icon(sound.icon, color: AppColors.primaryCyan, size: 20),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sound.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                          Row(
                            children: [
                              if (audio.timerRemainingSeconds != null) ...[
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 12,
                                  color: AppColors.primaryCyan,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTimer(audio.timerRemainingSeconds!),
                                  style: const TextStyle(
                                    color: AppColors.primaryCyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              _EqualizerBars(isPlaying: audio.isPlaying),
                              const SizedBox(width: 6),
                              Text(
                                audio.isPlaying ? 'Playing' : 'Paused',
                                style: TextStyle(
                                  color: AppColors.textMuted(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    audio.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: AppColors.primaryCyan,
                    size: 32,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    audio.togglePlayPause();
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted(context),
                    size: 20,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    audio.stop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EqualizerBars extends StatefulWidget {
  final bool isPlaying;
  const _EqualizerBars({required this.isPlaying});

  @override
  State<_EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<_EqualizerBars>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 350 + i * 120),
      ),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 3, end: 12).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    if (widget.isPlaying) {
      _startAnim();
    }
  }

  void _startAnim() {
    for (var c in _controllers) {
      c.repeat(reverse: true);
    }
  }

  void _stopAnim() {
    for (var c in _controllers) {
      c.stop();
    }
  }

  @override
  void didUpdateWidget(covariant _EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnim();
      } else {
        _stopAnim();
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Container(
              width: 2.5,
              height: widget.isPlaying ? _animations[i].value : 3,
              margin: const EdgeInsets.symmetric(horizontal: 1.0),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}

