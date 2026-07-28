import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sound_model.dart';
import '../services/audio_handler.dart';
import '../services/notification_service.dart';

class SoundLayer {
  final SoundType soundType;
  int variantIndex;
  double volume;
  double preFadeVolume;
  AudioPlayer? player;

  SoundLayer({
    required this.soundType,
    this.variantIndex = 0,
    this.volume = 0.70,
    this.preFadeVolume = 0.70,
    this.player,
  });
}

class AudioProvider extends ChangeNotifier {
  static const int maxLayers = 5;
  static const String _keyPlayCounts = 'sound_play_counts';
  static const String _keyRecentSounds = 'recent_sound_ids';
  static const String _keyTimerEndTime = 'timer_end_time';

  final SleepAudioHandler? _audioHandler;
  SharedPreferences? _prefs;

  late final Future<void> _initFuture;
  bool _isDisposed = false;
  bool _isStopping = false;
  bool _isInFadeOut = false;
  bool _timerExplicitlyCleared = false;
  int _loadGeneration = 0; // Incremented on every new load; stale loads abort when mismatch detected

  SoundType _currentSound = SoundRegistry.allSounds[0]; // Default Ocean Waves
  int _currentVariantIndex = 0;
  bool _isPlaying = false;
  bool _isBuffering = false;
  double _masterVolume = 0.70;
  double _preFadeVolume = 0.70;
  int? _timerMinutes;
  int? _timerRemainingSeconds;
  int? _timerTotalSeconds;
  Timer? _countdownTimer;
  bool _notificationsEnabled = true;

  AudioPlayer? _mainPlayer;
  final List<SoundLayer> _soundLayers = [];
  Map<String, int> _playCounts = {};
  List<String> _recentSoundIds = [];

  String? _errorMessage;

  AudioProvider({SleepAudioHandler? audioHandler})
      : _audioHandler = audioHandler {
    _initAudioHandlerCallbacks();
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    await _initMainPlayer();
    await _loadHistory();
    await _restoreTimerIfNeeded();
  }

  Future<void> _restoreTimerIfNeeded() async {
    try {
      final endTimeStr = _prefs?.getString(_keyTimerEndTime);
      if (endTimeStr == null) return;
      final endTime = DateTime.parse(endTimeStr);
      final remaining = endTime.difference(DateTime.now());
      if (remaining.inSeconds > 0) {
        final remainingMinutes = (remaining.inSeconds / 60.0).ceil();
        // Restore by setting timerTotalSeconds directly then starting countdown
        _timerTotalSeconds = remaining.inSeconds;
        _timerRemainingSeconds = remaining.inSeconds;
        _timerMinutes = remainingMinutes;
        _preFadeVolume = _masterVolume;
        _isInFadeOut = false;
        _safeNotify();
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
          if (_isDisposed) { timer.cancel(); return; }
          if (_timerRemainingSeconds == null || _timerRemainingSeconds! <= 0) {
            timer.cancel();
            _timerMinutes = null;
            _timerRemainingSeconds = null;
            _timerTotalSeconds = null;
            _isInFadeOut = false;
            _prefs?.remove(_keyTimerEndTime);
            await pause();
            _masterVolume = _preFadeVolume;
            if (_mainPlayer != null) {
              try { await _mainPlayer!.setVolume(_masterVolume); } catch (_) {}
            }
            for (final layer in _soundLayers) {
              layer.volume = layer.preFadeVolume;
              if (layer.player != null) {
                try { await layer.player!.setVolume(layer.preFadeVolume); } catch (_) {}
              }
            }
            if (_notificationsEnabled) {
              await NotificationService.showTimerEndedNotification();
            }
            _safeNotify();
          } else {
            _timerRemainingSeconds = _timerRemainingSeconds! - 1;
            if (_timerRemainingSeconds! <= 30 && _preFadeVolume > 0) {
              _isInFadeOut = true;
              final fadeFactor = _timerRemainingSeconds! / 30.0;
              final targetVolume = (_preFadeVolume * fadeFactor).clamp(0.0, 1.0);
              _masterVolume = targetVolume;
              if (_mainPlayer != null) {
                try { await _mainPlayer!.setVolume(targetVolume); } catch (_) {}
              }
              for (final layer in _soundLayers) {
                if (layer.player != null) {
                  final layerTarget = (layer.preFadeVolume * fadeFactor).clamp(0.0, 1.0);
                  layer.volume = layerTarget;
                  try { await layer.player!.setVolume(layerTarget); } catch (_) {}
                }
              }
            }
            _safeNotify();
          }
        });
      } else {
        _prefs?.remove(_keyTimerEndTime);
      }
    } catch (e) {
      debugPrint('Timer restore error: $e');
    }
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void updateSettings({required bool notificationsEnabled}) {
    _notificationsEnabled = notificationsEnabled;
  }

  void _initAudioHandlerCallbacks() {
    final handler = _audioHandler;
    if (handler != null) {
      handler.onPlayCallback = () => play();
      handler.onPauseCallback = () => pause();
      handler.onStopCallback = () => stop();
      handler.onSkipToNextCallback = () => nextVariant();
      handler.onSkipToPreviousCallback = () => previousVariant();
    }
  }

  Future<void> _loadHistory() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final countsJson = _prefs?.getString(_keyPlayCounts);
      if (countsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(countsJson);
        _playCounts = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
      }
      _recentSoundIds = _prefs?.getStringList(_keyRecentSounds) ?? [];
      _safeNotify();
    } catch (_) {}
  }

  Future<void> _recordPlay(String soundId) async {
    _playCounts[soundId] = (_playCounts[soundId] ?? 0) + 1;
    _recentSoundIds.remove(soundId);
    _recentSoundIds.insert(0, soundId);
    if (_recentSoundIds.length > 10) {
      _recentSoundIds = _recentSoundIds.sublist(0, 10);
    }
    _safeNotify();

    if (_prefs != null) {
      await _prefs!.setString(_keyPlayCounts, jsonEncode(_playCounts));
      await _prefs!.setStringList(_keyRecentSounds, _recentSoundIds);
    }
  }

  SoundType get currentSound => _currentSound;
  int get currentVariantIndex => _currentVariantIndex;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  double get masterVolume => _masterVolume;
  int? get timerMinutes => _timerMinutes;
  int? get timerRemainingSeconds => _timerRemainingSeconds;
  int? get timerTotalSeconds => _timerTotalSeconds;
  double? get fadeProgress {
    if (_isInFadeOut && _timerRemainingSeconds != null) {
      return (_timerRemainingSeconds! / 30.0).clamp(0.0, 1.0);
    }
    return null;
  }
  bool get isInFadeOut => _isInFadeOut;
  bool get timerExplicitlyCleared => _timerExplicitlyCleared;
  int get layerCount => _soundLayers.length;
  List<SoundLayer> get soundLayers => List.unmodifiable(_soundLayers);
  String? get errorMessage => _errorMessage;
  Map<String, int> get playCounts => Map.unmodifiable(_playCounts);
  List<String> get recentSoundIds => List.unmodifiable(_recentSoundIds);

  void clearErrorMessage() {
    _errorMessage = null;
    _safeNotify();
  }

  Future<void> _initMainPlayer() async {
    try {
      _mainPlayer = AudioPlayer();
      await _mainPlayer!.setLoopMode(LoopMode.one);
      _mainPlayer!.playerStateStream.listen((state) {
        if (_isDisposed) return;
        final isBufferingNow = state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
        final isPlayingNow = state.playing &&
            state.processingState != ProcessingState.completed;

        bool changed = false;
        if (_isBuffering != isBufferingNow) {
          _isBuffering = isBufferingNow;
          changed = true;
        }
        // Only update _isPlaying from the stream when not actively buffering
        // to avoid fighting with the explicit state set in _playMainSound().
        if (_isPlaying != isPlayingNow && !_isBuffering) {
          _isPlaying = isPlayingNow;
          changed = true;
        }
        if (changed) {
          _safeNotify();
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize main player: $e');
    }
  }

  Future<void> selectSound(SoundType sound, {int variantIndex = 0}) async {
    _currentSound = sound;
    _currentVariantIndex = variantIndex.clamp(0, sound.variantCount - 1);
    _safeNotify();

    if (_isPlaying) {
      await _playMainSound();
    }
  }

  Future<void> selectAndPlay(SoundType sound, {int variantIndex = 0}) async {
    await _initFuture;
    _currentSound = sound;
    _currentVariantIndex = variantIndex.clamp(0, sound.variantCount - 1);
    await _playMainSound();
    for (final layer in _soundLayers) {
      if (layer.player != null) {
        try {
          await layer.player!.play();
        } catch (_) {}
      }
    }
  }

  Future<void> loadPreset({
    required SoundType mainSound,
    required List<({SoundType sound, double volume})> layers,
    double masterVolume = 0.70,
  }) async {
    await _initFuture;
    for (final layer in _soundLayers) {
      if (layer.player != null) {
        try {
          await layer.player!.stop();
          await layer.player!.dispose();
        } catch (_) {}
      }
    }
    _soundLayers.clear();
    if (_mainPlayer != null) {
      try {
        await _mainPlayer!.stop();
      } catch (_) {}
    }

    _masterVolume = masterVolume;
    _currentSound = mainSound;
    _currentVariantIndex = 0;

    for (final l in layers) {
      await addSoundLayer(l.sound);
      if (_soundLayers.isNotEmpty) {
        setLayerVolume(_soundLayers.length - 1, l.volume);
      }
    }
    // Do NOT call play() here — the caller pushes SoundPlaying which
    // calls selectAndPlay() on mount, preventing double play-count.
    _safeNotify();
  }

  Future<void> _playMainSound() async {
    await _initFuture;
    if (_mainPlayer == null) return;

    // Increment generation so any concurrent in-progress load sees a mismatch
    // and aborts at the next await point — the newest call always wins.
    final int thisGeneration = ++_loadGeneration;

    _isBuffering = true;
    _safeNotify();

    final bool wasPlaying = _isPlaying;
    int retryCount = 0;
    try {
      while (retryCount < _currentSound.variantCount) {
        if (_loadGeneration != thisGeneration) return; // Abort: newer call won
        try {
          _errorMessage = null;
          final assetPath = _currentSound.audioAssetPaths[_currentVariantIndex];

          // Cleanly stop previous player session to flush buffers & avoid Android Opus decoder collisions
          try { await _mainPlayer!.stop(); } catch (_) {}
          if (_loadGeneration != thisGeneration) return; // Abort check after await

          await _mainPlayer!.setAsset(assetPath);
          if (_loadGeneration != thisGeneration) return; // Abort check after await

          await _mainPlayer!.setVolume(_masterVolume);
          if (_loadGeneration != thisGeneration) return; // Abort check after await

          await _mainPlayer!.play();
          if (_loadGeneration != thisGeneration) return; // Abort check after await

          _isPlaying = true;
          _isBuffering = false;
          if (!wasPlaying) {
            await _recordPlay(_currentSound.id);
          }
          _audioHandler?.updateState(
            playing: true,
            title: _currentSound.title,
            subtitle: _currentSound.description,
          );
          _safeNotify();
          return;
        } catch (e) {
          if (_loadGeneration != thisGeneration) return; // Abort on error too
          retryCount++;
          if (retryCount < _currentSound.variantCount) {
            _currentVariantIndex =
                (_currentVariantIndex + 1) % _currentSound.variantCount;
          } else {
            _errorMessage = "Couldn't load sound file after trying variants: $e";
            _isPlaying = false;
            _isBuffering = false;
            _safeNotify();
            return;
          }
        }
      }
    } finally {
      // Only clean up if this generation is still current — a newer call
      // will manage its own state.
      if (_loadGeneration == thisGeneration) {
        _isBuffering = false;
        _safeNotify();
      }
    }
  }

  Future<void> togglePlayPause() async {
    if (_isBuffering) {
      // Cancel the in-progress load and pause cleanly
      _loadGeneration++;
      _isBuffering = false;
      await pause();
      return;
    }
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> play() async {
    await _playMainSound();
    for (final layer in _soundLayers) {
      if (layer.player != null) {
        try {
          await layer.player!.play();
        } catch (_) {}
      }
    }
  }

  Future<void> pause() async {
    try {
      if (_mainPlayer != null) {
        await _mainPlayer!.pause();
      }
    } catch (e) {
      debugPrint('Error pausing main player: $e');
    }
    for (final layer in _soundLayers) {
      if (layer.player != null) {
        try {
          await layer.player!.pause();
        } catch (e) {
          debugPrint('Error pausing layer player: $e');
        }
      }
    }
    _isPlaying = false;
    _audioHandler?.updateState(
      playing: false,
      title: _currentSound.title,
      subtitle: 'Paused',
    );
    _safeNotify();
  }

  Future<void> stop() async {
    if (_isStopping) return;
    _isStopping = true;
    try {
      if (_mainPlayer != null) {
        try {
          await _mainPlayer!.stop();
        } catch (_) {}
      }
      for (final layer in _soundLayers) {
        if (layer.player != null) {
          try {
            await layer.player!.stop();
            await layer.player!.dispose();
          } catch (_) {}
        }
      }
      _soundLayers.clear();
      _isPlaying = false;
      _cancelTimer();
      _audioHandler?.updateState(
        playing: false,
        title: _currentSound.title,
        subtitle: 'Stopped',
      );
      _safeNotify();
    } finally {
      _isStopping = false;
    }
  }

  Future<void> nextVariant() async {
    _currentVariantIndex =
        (_currentVariantIndex + 1) % _currentSound.variantCount;
    if (_isPlaying) {
      await _playMainSound();
    } else {
      _safeNotify();
    }
  }

  Future<void> previousVariant() async {
    _currentVariantIndex =
        (_currentVariantIndex - 1 + _currentSound.variantCount) %
            _currentSound.variantCount;
    if (_isPlaying) {
      await _playMainSound();
    } else {
      _safeNotify();
    }
  }

  Future<void> setMasterVolume(double vol) async {
    if (_isInFadeOut) return; // Block volume adjustments during timer fade-out
    _masterVolume = vol.clamp(0.0, 1.0);
    if (_mainPlayer != null) {
      try {
        await _mainPlayer!.setVolume(_masterVolume);
      } catch (_) {}
    }
    _safeNotify();
  }

  // --- Sound Layering / Mixing ---
  Future<bool> addSoundLayer(SoundType sound) async {
    if (_soundLayers.any((l) => l.soundType.id == sound.id)) {
      return true; // Already added
    }

    if (_soundLayers.length >= maxLayers) {
      _errorMessage = "Maximum of $maxLayers sound layers allowed";
      _safeNotify();
      return false;
    }

    final player = AudioPlayer();
    try {
      await player.setLoopMode(LoopMode.one);
      final layer = SoundLayer(
        soundType: sound,
        volume: 0.70,
        preFadeVolume: 0.70,
        player: player,
      );

      final assetPath = sound.audioAssetPaths[0];
      await player.setAsset(assetPath);
      await player.setVolume(layer.volume);
      if (_isPlaying) {
        await player.play();
      }
      _soundLayers.add(layer);
      _errorMessage = null;
      _safeNotify();
      return true;
    } catch (e) {
      player.dispose();
      _errorMessage = "Couldn't load layer sound";
      _safeNotify();
      return false;
    }
  }

  Future<void> removeSoundLayer(int index) async {
    if (index >= 0 && index < _soundLayers.length) {
      final layer = _soundLayers.removeAt(index);
      if (layer.player != null) {
        try {
          await layer.player!.stop();
          await layer.player!.dispose();
        } catch (_) {}
      }
      _safeNotify();
    }
  }

  Future<void> clearAllLayers() async {
    for (final layer in _soundLayers) {
      if (layer.player != null) {
        try {
          await layer.player!.stop();
          await layer.player!.dispose();
        } catch (_) {}
      }
    }
    _soundLayers.clear();
    _safeNotify();
  }

  Future<void> toggleSoundLayer(SoundType sound) async {
    final index = _soundLayers.indexWhere((l) => l.soundType.id == sound.id);
    if (index >= 0) {
      await removeSoundLayer(index);
    } else {
      await addSoundLayer(sound);
    }
  }

  Future<void> setLayerVolume(int index, double vol) async {
    if (index >= 0 && index < _soundLayers.length) {
      _soundLayers[index].volume = vol.clamp(0.0, 1.0);
      if (!_isInFadeOut) {
        _soundLayers[index].preFadeVolume = _soundLayers[index].volume;
      }
      if (_soundLayers[index].player != null) {
        try {
          await _soundLayers[index].player!.setVolume(_soundLayers[index].volume);
        } catch (_) {}
      }
      _safeNotify();
    }
  }

  // --- Sleep Timer ---
  void setTimer(int? minutes) {
    _cancelTimer();
    _timerExplicitlyCleared = (minutes == null);
    _timerMinutes = minutes;
    if (minutes == null) {
      // Bug #4: Restore volumes if timer was cleared during fade-out
      if (_isInFadeOut) {
        _masterVolume = _preFadeVolume;
        if (_mainPlayer != null) {
          try { _mainPlayer!.setVolume(_masterVolume); } catch (_) {}
        }
        for (final layer in _soundLayers) {
          layer.volume = layer.preFadeVolume;
          if (layer.player != null) {
            try { layer.player!.setVolume(layer.preFadeVolume); } catch (_) {}
          }
        }
      }
      _timerRemainingSeconds = null;
      _timerTotalSeconds = null;
      _isInFadeOut = false;
      _prefs?.remove(_keyTimerEndTime);
      _safeNotify();
      return;
    }

    _preFadeVolume = _masterVolume;
    for (final layer in _soundLayers) {
      layer.preFadeVolume = layer.volume;
    }
    _timerRemainingSeconds = minutes * 60;
    _timerTotalSeconds = minutes * 60;
    _isInFadeOut = false;
    
    final endTime = DateTime.now().add(Duration(minutes: minutes));
    _prefs?.setString(_keyTimerEndTime, endTime.toIso8601String());

    _safeNotify();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      if (_timerRemainingSeconds == null || _timerRemainingSeconds! <= 0) {
        timer.cancel();
        _timerMinutes = null;
        _timerRemainingSeconds = null;
        _timerTotalSeconds = null;
        _isInFadeOut = false;
        _prefs?.remove(_keyTimerEndTime);
        
        await pause();
        _masterVolume = _preFadeVolume;
        if (_mainPlayer != null) {
          try {
            await _mainPlayer!.setVolume(_masterVolume);
          } catch (_) {}
        }
        for (final layer in _soundLayers) {
          layer.volume = layer.preFadeVolume;
          if (layer.player != null) {
            try {
              await layer.player!.setVolume(layer.preFadeVolume);
            } catch (_) {}
          }
        }

        if (_notificationsEnabled) {
          await NotificationService.showTimerEndedNotification();
        }
        _safeNotify();
      } else {
        _timerRemainingSeconds = _timerRemainingSeconds! - 1;

        // Gradual 30-second volume fade out before ending
        if (_timerRemainingSeconds! <= 30 && _preFadeVolume > 0) {
          _isInFadeOut = true;
          final fadeFactor = _timerRemainingSeconds! / 30.0;
          final targetVolume = (_preFadeVolume * fadeFactor).clamp(0.0, 1.0);
          _masterVolume = targetVolume;
          if (_mainPlayer != null) {
            try {
              await _mainPlayer!.setVolume(targetVolume);
            } catch (_) {}
          }
          for (final layer in _soundLayers) {
            if (layer.player != null) {
              final layerTarget = (layer.preFadeVolume * fadeFactor).clamp(0.0, 1.0);
              layer.volume = layerTarget;
              try {
                await layer.player!.setVolume(layerTarget);
              } catch (_) {}
            }
          }
        }
        _safeNotify();
      }
    });
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _timerMinutes = null;
    _timerRemainingSeconds = null;
    _timerTotalSeconds = null;
    _isInFadeOut = false;
    _prefs?.remove(_keyTimerEndTime);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelTimer();
    _mainPlayer?.dispose();
    for (final layer in _soundLayers) {
      layer.player?.dispose();
    }
    super.dispose();
  }
}
