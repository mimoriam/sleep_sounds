# 🔴 Production-Grade Code Review — Sleep Sounds App

> **Reviewer posture:** Adversarial. Assumes 100k users, poor network, low-end devices, and hostile OS behavior (force-kills, rapid lifecycle events).
> **Files reviewed:** 20 source files, 6 plan/walkthrough documents.
> **Scope:** Bugs fixable within the current architecture — no major refactoring proposals.

---

## Summary of Findings

| Severity | Count |
|----------|-------|
| 🔴 Critical | 3 |
| 🟠 High | 8 |
| 🟡 Medium | 10 |
| 🔵 Low | 6 |
| **Total** | **27** |

---

## File 1: `audio_provider.dart` — The Most Dangerous File

> This file owns audio playback, timer logic, history tracking, notification delegation, AND layer management. Every bug here affects the entire app.

---

### ISSUE #1 — Infinite Recursion: `stop()` ↔ `SleepAudioHandler.stop()`

**Category:** Correctness & Logic, Concurrency
**Severity:** 🔴 Critical

[audio_provider.dart L66-70](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart#L63-L71) wires up callbacks:

```dart
handler.onStopCallback = () => stop();
```

[audio_provider.dart L226](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart#L213-L228) calls the handler:

```dart
Future<void> stop() async {
  // ...
  _audioHandler?.stop();  // ← calls SleepAudioHandler.stop()
  // ...
}
```

[audio_handler.dart L71-77](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/services/audio_handler.dart#L71-L77):

```dart
@override
Future<void> stop() async {
  playbackState.add(playbackState.value.copyWith(...));
  onStopCallback?.call();  // ← calls AudioProvider.stop()
}
```

**Call chain:** `AudioProvider.stop()` → `_audioHandler.stop()` → `onStopCallback()` → `AudioProvider.stop()` → `_audioHandler.stop()` → ∞

**Production failure:** Stack overflow crash. Every user who presses stop, or whose timer expires (timer calls `pause()` → user later calls `stop()`), or who presses stop from the mini-player — **app crashes**.

**Fix:**

```dart
// audio_provider.dart — add a guard flag
bool _isStopping = false;

Future<void> stop() async {
  if (_isStopping) return;
  _isStopping = true;
  try {
    if (_mainPlayer != null) {
      await _mainPlayer!.stop();
    }
    for (final layer in _soundLayers) {
      if (layer.player != null) {
        await layer.player!.stop();
        await layer.player!.dispose();
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
    // Do NOT call _audioHandler?.stop() — use updateState instead
    notifyListeners();
  } finally {
    _isStopping = false;
  }
}
```

**The same recursion pattern exists for `play()`:**

[audio_handler.dart L59-62](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/services/audio_handler.dart#L58-L62): `SleepAudioHandler.play()` calls `onPlayCallback` → `AudioProvider.play()` → `_playMainSound()` → `_audioHandler.updateState()`. This one doesn't recurse because `play()` doesn't call `_audioHandler.play()`, but the asymmetry is confusing and fragile.

---

### ISSUE #2 — Double Playback Race Condition: `selectSound()` + `play()` called without sequential awaiting

**Category:** Concurrency & Async Safety
**Severity:** 🔴 Critical

Multiple call sites fire `selectSound()` and `play()` back-to-back without awaiting:

- [home.dart L128-129](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart#L128-L129): `context.read<AudioProvider>().selectSound(...)` then `context.read<AudioProvider>().play()`
- [home.dart L418-419](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart#L418-L419): Same pattern in `SoundCardWidget`
- [sounds.dart L274-275](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/sounds/sounds.dart#L274-L275)
- [favourite.dart L257-258](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/favourite/favourite.dart#L256-L258)
- [sound_playing.dart L38-39](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart#L38-L39)

**Why this is dangerous:**

`selectSound()` checks `if (_isPlaying)` and calls `_playMainSound()`. Then `play()` ALSO calls `_playMainSound()`. Neither is awaited. Two concurrent calls to `_playMainSound()` race each other:
- Both set `_isBuffering = true`
- Both call `_mainPlayer!.setAsset()` — second call interrupts first
- Both call `_mainPlayer!.play()` — double play on same player
- Both call `_recordPlay()` — double play count increment
- Both call `notifyListeners()` — unpredictable UI state

**Production failure:** Sound starts, stops, restarts. Play count inflated. With 100k users tapping rapidly, this is guaranteed to hit.

**Fix — Centralize into a single method:**

```dart
// In AudioProvider:
Future<void> selectAndPlay(SoundType sound, {int variantIndex = 0}) async {
  _currentSound = sound;
  _currentVariantIndex = variantIndex.clamp(0, sound.variantCount - 1);
  await _playMainSound();
  for (final layer in _soundLayers) {
    if (layer.player != null) {
      try { await layer.player!.play(); } catch (_) {}
    }
  }
}
```

Then replace all `selectSound(); play();` call sites with `selectAndPlay(sound)`.

---

### ISSUE #3 — Timer Callback Executes After Dispose → Crash

**Category:** Concurrency, Flutter-Specific
**Severity:** 🔴 Critical

[audio_provider.dart L347-383](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart#L347-L383):

```dart
_countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
  // ...
  await pause();              // calls notifyListeners()
  await setMasterVolume(...); // calls notifyListeners()
  NotificationService.showTimerEndedNotification();
  notifyListeners();
  // ...
});
```

[audio_provider.dart L393-401](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart#L393-L401):

```dart
@override
void dispose() {
  _mainPlayer?.dispose();
  for (final layer in _soundLayers) {
    layer.player?.dispose();
  }
  _cancelTimer();  // cancels timer, but callback may already be mid-execution
  super.dispose();
}
```

**Why:** `Timer.periodic` fires its callback, which starts an async operation (`await pause()`). Before the await completes, `dispose()` is called on a hot-restart, navigation, or widget tree rebuild. The callback resumes after dispose and calls `notifyListeners()` on a disposed ChangeNotifier.

**Production failure:** `FlutterError: A ChangeNotifier was used after being disposed.` — crash in production.

**Fix:**

```dart
bool _isDisposed = false;

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

// Add to the timer callback and all methods that call notifyListeners:
void _safeNotify() {
  if (!_isDisposed) notifyListeners();
}
```

Replace all `notifyListeners()` calls with `_safeNotify()`.

---

### ISSUE #4 — Constructor Fires Async Methods Without Awaiting → Null Player on First Play

**Category:** Concurrency & Async Safety
**Severity:** 🟠 High

[audio_provider.dart L52-57](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart#L52-L57):

```dart
AudioProvider({SleepAudioHandler? audioHandler})
    : _audioHandler = audioHandler {
  _initMainPlayer();       // async, not awaited
  _initAudioHandlerCallbacks();
  _loadHistory();          // async, not awaited
}
```

`_initMainPlayer()` creates the `AudioPlayer` and sets loop mode. If `play()` is called immediately (e.g., from `initState` → `addPostFrameCallback`), `_mainPlayer` may still be null.

[audio_provider.dart L134-135](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart#L134-L135):

```dart
Future<void> _playMainSound() async {
  if (_mainPlayer == null) return;  // Silent failure!
```

**Production failure:** User taps a sound immediately after app launch → nothing happens. No error, no feedback. Silent failure.

**Fix:**

```dart
late final Future<void> _initFuture;

AudioProvider({SleepAudioHandler? audioHandler})
    : _audioHandler = audioHandler {
  _initAudioHandlerCallbacks();
  _initFuture = _initialize();
}

Future<void> _initialize() async {
  await _initMainPlayer();
  await _loadHistory();
}

Future<void> _playMainSound() async {
  await _initFuture; // Wait for initialization
  if (_mainPlayer == null) return;
  // ...
}
```

---

### ISSUE #5 — Timer Fade-Out and User Volume Slider Fight Each Other

**Category:** Concurrency, UX
**Severity:** 🟠 High

During the last 30 seconds of the timer, [audio_provider.dart L367-380](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart#L367-L380) overwrites the volume every second:

```dart
if (_timerRemainingSeconds! <= 30 && _preFadeVolume > 0) {
  final fadeFactor = _timerRemainingSeconds! / 30.0;
  final targetVolume = _preFadeVolume * fadeFactor;
  await _mainPlayer!.setVolume(targetVolume.clamp(0.0, 1.0));
```

Simultaneously, the user can drag the master volume slider, which calls `setMasterVolume()`. The slider sets volume → 1 second later the timer overwrites it back to the fade curve. The slider visually jumps.

**Production failure:** User tries to adjust volume during fade-out → slider fights them, volume jumps, confusing UX. User thinks the app is broken.

**Fix:**

```dart
Future<void> setMasterVolume(double vol) async {
  _masterVolume = vol.clamp(0.0, 1.0);
  if (_isInFadeOut) {
    // User manually adjusted during fade — cancel the fade
    _preFadeVolume = _masterVolume;
    // Restore layer volumes too
    for (final layer in _soundLayers) {
      layer.preFadeVolume = layer.volume;
    }
  }
  if (_mainPlayer != null) {
    await _mainPlayer!.setVolume(_masterVolume);
  }
  notifyListeners();
}
```

Add `bool _isInFadeOut = false;` flag, set to `true` when fade begins, `false` when timer ends.

---

### ISSUE #6 — `setLayerVolume` Corrupts `preFadeVolume` During Active Fade

**Category:** Data Consistency
**Severity:** 🟡 Medium

[audio_provider.dart L321-322](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart#L319-L328):

```dart
_soundLayers[index].volume = vol.clamp(0.0, 1.0);
_soundLayers[index].preFadeVolume = _soundLayers[index].volume;
```

`preFadeVolume` is always overwritten to match the current volume. If the timer is mid-fade, the fade calculation uses `preFadeVolume` as the baseline. Adjusting a layer slider during fade corrupts the baseline, causing the fade to suddenly jump.

**Fix:** Same pattern as Issue #5 — only update `preFadeVolume` when NOT in fade-out.

---

### ISSUE #7 — `_recordPlay()` Not Awaited → Double Counting

**Category:** Data Consistency, Concurrency
**Severity:** 🟡 Medium

[audio_provider.dart L150](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart#L150):

```dart
_recordPlay(_currentSound.id);  // fire-and-forget
```

`_recordPlay` modifies `_playCounts`, calls `notifyListeners()`, and writes to SharedPreferences. Since it's not awaited, if `_playMainSound` is called again rapidly, the second call reads stale `_playCounts`.

Also: `_recordPlay` is called every time `_playMainSound` succeeds, including on `resume` after pause (`play()` → `_playMainSound()`). This inflates play counts.

**Fix:**

```dart
// Only record on initial sound selection, not on resume
if (!_isPlaying) { // was not already playing this sound
  await _recordPlay(_currentSound.id);
}
_isPlaying = true;
```

---

### ISSUE #8 — `pause()` Layer Errors Swallowed, But Main Player Error Crashes

**Category:** Error Handling
**Severity:** 🟡 Medium

[audio_provider.dart L195-210](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart#L195-L211):

```dart
Future<void> pause() async {
  if (_mainPlayer != null) {
    await _mainPlayer!.pause();  // NO try/catch — crashes on disposed player
  }
  for (final layer in _soundLayers) {
    if (layer.player != null) {
      await layer.player!.pause();  // ALSO no try/catch
    }
  }
```

Compare to `play()` where layers have `try {} catch (_) {}`. The inconsistency means a disposed or errored player in `pause()` crashes the app.

**Fix:** Wrap all player operations in try/catch:

```dart
Future<void> pause() async {
  try {
    await _mainPlayer?.pause();
  } catch (e) {
    debugPrint('Main player pause error: $e');
  }
  for (final layer in _soundLayers) {
    try {
      await layer.player?.pause();
    } catch (e) {
      debugPrint('Layer pause error: $e');
    }
  }
  _isPlaying = false;
  // ...
}
```

---

## File 2: `sound_playing.dart` — UI/State Sync Issues

---

### ISSUE #9 — SnackBar Spam: Error Message Triggers Duplicate SnackBars on Every Rebuild

**Category:** Flutter-Specific, Correctness
**Severity:** 🟠 High

[sound_playing.dart L88-110](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart#L88-L111):

```dart
if (audio.errorMessage != null) {
  final msg = audio.errorMessage!;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ScaffoldMessenger.of(context).showSnackBar(...);
    audio.clearErrorMessage();  // line 109
  });
}
```

**Problem:** `build()` runs, schedules a post-frame callback, then `clearErrorMessage()` triggers `notifyListeners()`, which triggers another `build()`. If the callback hasn't fired yet, `audio.errorMessage` might still be non-null (race between build and callback), scheduling ANOTHER SnackBar.

Even if it is cleared, the SnackBar action handler at line 104 ALSO calls `clearErrorMessage()`. So `clearErrorMessage` is called twice — once at line 109 unconditionally, once from the action button. The action button's `clearErrorMessage` is redundant but also calls `notifyListeners()` again → another rebuild.

**Production failure:** Multiple stacked SnackBars for the same error. Confusing UX.

**Fix:**

```dart
// Use a local flag to prevent re-scheduling
@override
Widget build(BuildContext context) {
  final audio = context.watch<AudioProvider>();
  
  // Handle error ONCE
  final errorMsg = audio.errorMessage;
  if (errorMsg != null) {
    // Clear immediately to prevent re-triggering on rebuild
    audio.clearErrorMessage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), /* ... */),
      );
    });
  }
  // ... rest of build
}
```

---

### ISSUE #10 — `initState` Post-Frame Callback Missing `mounted` Check

**Category:** Flutter-Specific
**Severity:** 🟠 High

[sound_playing.dart L31-45](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart#L29-L46):

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final audio = context.read<AudioProvider>();  // context used after potential dispose
    final settings = context.read<SettingsProvider>();
    // ...
  });
}
```

If the user navigates away before the post-frame callback fires (e.g., rapid back-press), `context` is invalid and `context.read` throws.

**Fix:**

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  final audio = context.read<AudioProvider>();
  // ...
});
```

---

### ISSUE #11 — Default Timer Re-Applied After User Explicitly Cancels

**Category:** Correctness & Logic
**Severity:** 🟡 Medium

[sound_playing.dart L42-44](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart#L42-L44):

```dart
if (audio.timerMinutes == null && settings.defaultTimerMinutes != null) {
  audio.setTimer(settings.defaultTimerMinutes);
}
```

**Scenario:** User sets default timer to 30m. Opens SoundPlaying → timer auto-starts at 30m. User opens timer bottom sheet, selects "Off" (sets `timerMinutes = null`). User presses back. User opens SoundPlaying again → `initState` fires → timer is re-applied at 30m.

**Production failure:** User cannot permanently cancel the timer while a default is set. Frustrating UX.

**Fix:** Track whether the timer was explicitly cleared by the user:

```dart
// In AudioProvider:
bool _timerExplicitlyCleared = false;

void setTimer(int? minutes) {
  _timerExplicitlyCleared = (minutes == null);
  // ...
}

// In SoundPlaying initState:
if (audio.timerMinutes == null && 
    !audio.timerExplicitlyCleared &&
    settings.defaultTimerMinutes != null) {
  audio.setTimer(settings.defaultTimerMinutes);
}
```

---

## File 3: `sleep_mode.dart` — Lifecycle Bugs

---

### ISSUE #12 — Re-Dims Screen on `resumed` Even If User Already Exited Sleep Mode

**Category:** Flutter-Specific, Production Readiness
**Severity:** 🟠 High

[sleep_mode.dart L26-33](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/sleep_mode/sleep_mode.dart#L26-L34):

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused || ...) {
    _disableSleepMode();
  } else if (state == AppLifecycleState.resumed) {
    _enableSleepMode();  // Dims screen to 5% AGAIN
  }
}
```

**Scenario:** User is in sleep mode. User opens notification shade (→ `inactive`/`paused`). Brightness is restored. User returns to app (→ `resumed`). Screen dims to 5% again. **Even if `Navigator.pop` is in progress**, the lifecycle callback fires first, dimming the screen.

**Worse scenario:** User presses "Wake Up" button → `Navigator.pop(context)` starts, `dispose()` scheduled. Before `dispose()` runs, OS fires `resumed`. `_enableSleepMode()` dims screen. Then `dispose()` resets it. User sees a flash of dim brightness.

**Fix:** Add a `_disposed` guard:

```dart
bool _isActive = true;

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (!_isActive) return;
  // ...
}

@override
void dispose() {
  _isActive = false;
  WidgetsBinding.instance.removeObserver(this);
  _disableSleepMode();
  super.dispose();
}
```

---

### ISSUE #13 — `_enableSleepMode` and `_disableSleepMode` Have No Concurrency Guard

**Category:** Concurrency
**Severity:** 🟡 Medium

Rapid lifecycle transitions (e.g., user rapidly switching apps) can fire `_enableSleepMode` and `_disableSleepMode` concurrently. Both are async and call `ScreenBrightness()` methods. The interleaving can leave brightness in an unpredictable state.

**Fix:**

```dart
bool _isBrightnessOperationRunning = false;

Future<void> _enableSleepMode() async {
  if (_isBrightnessOperationRunning) return;
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
```

---

## File 4: `audio_handler.dart` — Background Controls

---

### ISSUE #14 — `skipToNext` / `skipToPrevious` Don't Update Notification Metadata

**Category:** Correctness
**Severity:** 🟡 Medium

[audio_handler.dart L79-87](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/services/audio_handler.dart#L79-L87):

```dart
@override
Future<void> skipToNext() async {
  onSkipToNextCallback?.call();  // Calls AudioProvider.nextVariant()
  // But doesn't update playbackState or mediaItem!
}
```

After skipping, the lock screen notification still shows the old variant info until `AudioProvider._playMainSound()` completes and calls `updateState()`. If `_playMainSound` fails, the notification is permanently stale.

**Fix:**

```dart
@override
Future<void> skipToNext() async {
  onSkipToNextCallback?.call();
  // playbackState will be updated by AudioProvider via updateState()
  // but add a processing state indicator for the transition period:
  playbackState.add(playbackState.value.copyWith(
    processingState: AudioProcessingState.loading,
  ));
}
```

---

### ISSUE #15 — `play()` Double-Updates Playback State

**Category:** Performance, Correctness
**Severity:** 🟡 Medium

[audio_handler.dart L59-62](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/services/audio_handler.dart#L58-L62):

```dart
@override
Future<void> play() async {
  playbackState.add(playbackState.value.copyWith(playing: true));
  onPlayCallback?.call();  // → AudioProvider.play() → updateState(playing: true)
}
```

`playbackState` is updated twice: once here, once when `AudioProvider.play()` calls `updateState()`. The first update is premature — the audio isn't actually playing yet. If `_playMainSound()` fails, the notification shows "playing" but nothing is playing.

**Fix:** Remove the premature update from the handler:

```dart
@override
Future<void> play() async {
  // Don't update playbackState here — let AudioProvider.play() 
  // call updateState() when audio actually starts
  onPlayCallback?.call();
}
```

---

## File 5: `navbar.dart` — Performance

---

### ISSUE #16 — Entire Scaffold Rebuilds Every Second During Timer

**Category:** Performance, Flutter-Specific
**Severity:** 🟠 High

[navbar.dart L32](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/navbar.dart#L31-L33):

```dart
final audio = context.watch<AudioProvider>();
final showMiniPlayer = audio.isPlaying || audio.timerRemainingSeconds != null;
```

`context.watch<AudioProvider>()` in `_NavbarState.build()` subscribes the **entire** `Navbar` widget to `AudioProvider`. Every second during the timer countdown, `notifyListeners()` fires, and the entire `Scaffold` + `IndexedStack` + all four screens rebuild.

`IndexedStack` keeps all children alive, so all four screens have their `build()` called every second. With each screen doing `context.watch`, this cascades.

**Production failure:** UI jank on low-end devices. Battery drain. Dropped frames.

**Fix:** Extract the mini-player visibility check into a `Selector` or `Consumer`:

```dart
@override
Widget build(BuildContext context) {
  return NotificationListener<TabSwitchNotification>(
    onNotification: (notification) {
      setState(() { _currentIndex = notification.index; });
      return true;
    },
    child: Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Only this part rebuilds on audio changes
          Selector<AudioProvider, bool>(
            selector: (_, audio) => audio.isPlaying || audio.timerRemainingSeconds != null,
            builder: (context, showMiniPlayer, _) {
              if (!showMiniPlayer) return const SizedBox.shrink();
              return const _MiniPlayerBar();
            },
          ),
          // Bottom nav bar — no longer rebuilds on audio changes
          _buildBottomNavBar(context),
        ],
      ),
    ),
  );
}
```

---

## File 6: `notification_service.dart` — Error Handling

---

### ISSUE #17 — No `try/catch` Around Notification `show()`

**Category:** Error Handling
**Severity:** 🟡 Medium

[notification_service.dart L38-43](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/services/notification_service.dart#L38-L43):

```dart
await _notificationsPlugin.show(
  101,
  'Sleep Timer Ended 🌙',
  'Your sleep sounds have turned off. Sleep tight!',
  details,
);
```

The caller in [audio_provider.dart L361](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart#L361) also has no try/catch:

```dart
NotificationService.showTimerEndedNotification();  // fire-and-forget
```

If the notification channel is blocked, permission revoked, or the plugin encounters an error, this throws an unhandled exception inside the timer callback. This can crash the timer logic.

**Fix:**

```dart
static Future<void> showTimerEndedNotification() async {
  try {
    await _notificationsPlugin.show(
      101,
      'Sleep Timer Ended 🌙',
      'Your sleep sounds have turned off. Sleep tight!',
      details,
    );
  } catch (e) {
    debugPrint('Notification error: $e');
  }
}
```

---

## File 7: `permission_service.dart` — Incomplete

---

### ISSUE #18 — `isPermanentlyDenied` Not Handled

**Category:** Production Readiness, UX
**Severity:** 🟡 Medium

[permission_service.dart L4-12](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/services/permission_service.dart#L4-L12):

```dart
static Future<bool> requestNotificationPermission() async {
  final status = await Permission.notification.status;
  if (status.isGranted) return true;
  if (status.isDenied || status.isLimited) {
    final result = await Permission.notification.request();
    return result.isGranted;
  }
  return false;  // isPermanentlyDenied falls through silently
}
```

On Android, once a user denies the permission twice, it becomes permanently denied. `Permission.notification.request()` no longer shows a dialog. The user has no way to enable notifications without manually going to Settings.

**Fix:**

```dart
static Future<bool> requestNotificationPermission() async {
  final status = await Permission.notification.status;
  if (status.isGranted) return true;
  if (status.isPermanentlyDenied) {
    // Return false — caller should prompt user to open Settings
    return false;
  }
  if (status.isDenied || status.isLimited) {
    final result = await Permission.notification.request();
    return result.isGranted;
  }
  return false;
}

// Add a helper for the Settings screen:
static Future<bool> openNotificationSettings() async {
  return await openAppSettings();
}
```

---

## File 8: `favorites_provider.dart` — Silent Data Corruption

---

### ISSUE #19 — `getById` Fallback Silently Returns Wrong Sound

**Category:** Data Consistency
**Severity:** 🟠 High

[sound_model.dart L503-508](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/models/sound_model.dart#L503-L508):

```dart
static SoundType getById(String id) {
  return allSounds.firstWhere(
    (s) => s.id == id,
    orElse: () => allSounds.first,  // Silent fallback to Ocean Waves
  );
}
```

[favorites_provider.dart L16-19](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/favorites_provider.dart#L16-L19):

```dart
List<SoundType> get favoriteSounds {
  return _favoriteIds
      .map((id) => SoundRegistry.getById(id))
      .toList();
}
```

**Scenario:** In a future app update, you rename or remove a sound ID. All users who had that sound favorited now see "Ocean Waves" in their favorites instead. They see duplicate entries. They can't remove the phantom because the underlying ID doesn't match.

This also affects `recentSoundIds` in `AudioProvider` ([home.dart L54-56](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart#L54-L56)).

**Fix:**

```dart
static SoundType? getByIdOrNull(String id) {
  final matches = allSounds.where((s) => s.id == id);
  return matches.isEmpty ? null : matches.first;
}

// In FavoritesProvider:
List<SoundType> get favoriteSounds {
  return _favoriteIds
      .map((id) => SoundRegistry.getByIdOrNull(id))
      .whereType<SoundType>()  // Filter out nulls (removed sounds)
      .toList();
}
```

---

## File 9: `home.dart` — Stale State

---

### ISSUE #20 — Greeting and Featured Sound Never Update While Screen Is Visible

**Category:** Correctness
**Severity:** 🟡 Medium

[home.dart L14-15](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart#L14-L15):

```dart
String _getTimeGreeting() {
  final hour = DateTime.now().hour;
```

[home.dart L33](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart#L33):

```dart
final dailyIndex = DateTime.now().day % allSounds.length;
```

`HomeScreen` is a `StatelessWidget`. These values are computed in `build()` and never refresh on their own. If the app stays open from 8:59 PM to 9:01 PM, the greeting stays "Good Evening" instead of switching to "Good Night".

The `dailyIndex` uses `DateTime.now().day`, so at midnight the featured sound should change but won't until a rebuild is triggered by something else.

**Fix:** Convert to `StatefulWidget` with a periodic timer to refresh, or simply accept this as low priority. If kept as-is, document the limitation.

---

### ISSUE #21 — `HomeScreen` Uses `context.watch` but Is Inside `IndexedStack`

**Category:** Performance
**Severity:** 🟡 Medium

[home.dart L29](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart#L29):

```dart
final audio = context.watch<AudioProvider>();
```

Because `Navbar` uses `IndexedStack`, `HomeScreen` stays in the widget tree even when the user is on Sounds, Favorites, or Settings tabs. Every `AudioProvider.notifyListeners()` (which fires **every second** during timer) rebuilds `HomeScreen` even though it's not visible.

This compounds with Issue #16.

**Fix:** Use `Selector` to only watch the specific fields `HomeScreen` needs:

```dart
// Only rebuild when play counts or recent sounds change
Selector<AudioProvider, ({Map<String, int> counts, List<String> recent})>(
  selector: (_, a) => (counts: a.playCounts, recent: a.recentSoundIds),
  builder: (context, data, _) {
    // build home content
  },
)
```

---

## File 10: `onboarding.dart` — Theme + Navigation

---

### ISSUE #22 — Hardcoded Dark Theme Colors

**Category:** Flutter-Specific
**Severity:** 🟡 Medium

Throughout the onboarding screen, colors like `AppColors.textPrimary` (white) and `AppColors.textSecondary` are used directly instead of the context-aware `AppColors.text(context)` helpers:

- [Line 78](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/onboarding/onboarding.dart#L78): `color: AppColors.textPrimary`
- [Line 88](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/onboarding/onboarding.dart#L88): `color: AppColors.textSecondary`
- [Lines 190, 200, 228, 234, etc.](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/onboarding/onboarding.dart#L190): Many more throughout

**Production failure:** If the user's system theme is Light when they first launch the app, the onboarding shows white text on a white/light background — unreadable.

**Fix:** Replace all `AppColors.textPrimary` with `AppColors.text(context)` and `AppColors.textSecondary` with `AppColors.textMuted(context)`.

---

### ISSUE #23 — `pushReplacement` Doesn't Clear Navigation Stack

**Category:** Production Readiness
**Severity:** 🔵 Low

[onboarding.dart L55-57](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/onboarding/onboarding.dart#L55-L57):

```dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (context) => const Navbar()),
);
```

`pushReplacement` only replaces the top route. If there were any routes pushed below (from deep linking, system recreate, etc.), they remain in the stack. Use `pushAndRemoveUntil` for safety:

```dart
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (context) => const Navbar()),
  (route) => false,
);
```

---

## Cross-Cutting Issues

---

### ISSUE #24 — No Offline/Background Kill Recovery for Timer State

**Category:** Production Readiness
**Severity:** 🟠 High

The sleep timer state (`_timerRemainingSeconds`, `_timerMinutes`) is entirely in-memory. If the OS kills the app during a sleep timer (common on Android for battery optimization), the timer is lost. Audio stops (process killed), but:

- No notification is sent
- No record of the timer existing is preserved
- On next launch, the user has no idea what happened

**Fix (within current architecture):** Persist timer end time to SharedPreferences:

```dart
void setTimer(int? minutes) {
  // ...
  if (minutes != null) {
    final endTime = DateTime.now().add(Duration(minutes: minutes));
    _prefs?.setString('timer_end_time', endTime.toIso8601String());
  } else {
    _prefs?.remove('timer_end_time');
  }
}
```

On app startup in `_loadHistory()`, check if a timer was active and expired.

---

### ISSUE #25 — `TabSwitchNotification` Defined in Wrong File

**Category:** Architecture (minor)
**Severity:** 🔵 Low

[favourite.dart L11-13](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/favourite/favourite.dart#L11-L13):

```dart
class TabSwitchNotification extends Notification {
  final int index;
  TabSwitchNotification(this.index);
}
```

This class is defined in `favourite.dart` but used in [home.dart L248](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart#L248), creating a dependency where `home.dart` imports `favourite.dart`. Move to a shared location like `utils/`.

---

### ISSUE #26 — Notification ID Collision Risk

**Category:** Correctness
**Severity:** 🔵 Low

[notification_service.dart L39](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/services/notification_service.dart#L38): Hardcoded `id: 101`. If you add other notification types later, they'll overwrite each other. Use an enum or constants class for notification IDs.

---

### ISSUE #27 — `MixerBoard` in Onboarding Uses Hardcoded Dark Colors

**Category:** Flutter-Specific
**Severity:** 🔵 Low

[onboarding.dart L789](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/onboarding/onboarding.dart#L789): `AppColors.cardColor` and `AppColors.borderLight` are hardcoded dark theme values, not context-aware. Same category as Issue #22.

---

## Defensive Programming Recommendations

| Technique | Where to Apply |
|-----------|----------------|
| **Re-entrancy guards** (`_isStopping`, `_isPlaying` flags) | All `AudioProvider` public methods |
| **`mounted` checks** after every `await` in StatefulWidgets | `sound_playing.dart`, `sleep_mode.dart`, `onboarding.dart` |
| **`_isDisposed` flag** on ChangeNotifiers | `AudioProvider`, `FavoritesProvider`, `SettingsProvider` |
| **Initialization futures** (`late final Future _initFuture`) | `AudioProvider` constructor |
| **`Selector` instead of `watch`** for fine-grained rebuilds | `navbar.dart`, `home.dart`, `sounds.dart`, `favourite.dart` |
| **Idempotent operations** — check state before mutating | `play()`, `stop()`, `pause()`, `setTimer()` |
| **Wrap all player ops in try/catch** consistently | `pause()`, `stop()`, `setVolume()`, `dispose()` |

---

## Priority Fix Order

| Order | Issues | Impact |
|-------|--------|--------|
| **1st** | #1 (infinite recursion), #3 (dispose crash) | App crashes |
| **2nd** | #2 (double playback), #10 (mounted check) | Broken audio + crash |
| **3rd** | #9 (SnackBar spam), #16 (rebuild storm) | UX degradation + jank |
| **4th** | #4 (null player), #5 (fade fight), #12 (re-dim) | Silent failures |
| **5th** | #17-#19 (error handling, permissions, fallback) | Edge case hardening |
| **6th** | Everything else | Polish |
