import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';

Future<AudioHandler> initAudioHandler() async {
  return await AudioService.init(
    builder: () => SleepAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.sleepsounds.channel.audio',
      androidNotificationChannelName: 'Sleep Sounds Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class SleepAudioHandler extends BaseAudioHandler {
  VoidCallback? onPlayCallback;
  VoidCallback? onPauseCallback;
  VoidCallback? onStopCallback;
  VoidCallback? onSkipToNextCallback;
  VoidCallback? onSkipToPreviousCallback;

  // Simple BaseAudioHandler delegate to update playbackState and mediaItem for background controls
  void updateState({
    required bool playing,
    required String title,
    required String subtitle,
  }) {
    mediaItem.add(
      MediaItem(
        id: 'sleep_sound_main',
        title: title,
        artist: subtitle,
        album: 'Sleep Sounds',
      ),
    );

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
        playing: playing,
      ),
    );
  }

  @override
  Future<void> play() async {
    onPlayCallback?.call();
  }

  @override
  Future<void> pause() async {
    playbackState.add(playbackState.value.copyWith(playing: false));
    onPauseCallback?.call();
  }

  @override
  Future<void> stop() async {
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
    onStopCallback?.call();
  }

  @override
  Future<void> skipToNext() async {
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.buffering,
    ));
    onSkipToNextCallback?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.buffering,
    ));
    onSkipToPreviousCallback?.call();
  }
}
