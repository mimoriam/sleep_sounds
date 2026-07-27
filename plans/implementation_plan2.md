# Sleep Sounds App — Improvements & Edge Case Fixes

Comprehensive improvement plan based on a thorough audit of the current codebase against the original implementation plan. All items below were discussed and approved during the `/grill-me` interview.

---

## Bug Fixes

### 1. Invalid Default Favorite ID
#### [MODIFY] [favorites_provider.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/favorites_provider.dart)
- **Bug:** Line 10 hardcodes `'forest_night'` as a default favorite, but no sound with that ID exists in `SoundRegistry`. This creates a phantom entry (silently falls back to `wave`, creating a duplicate).
- **Fix:** Remove all hardcoded defaults — start with an empty `Set<String>`.

---

### 2. Double-Dot Typo in Asset Path
#### [MODIFY] [sound_model.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/models/sound_model.dart)
- **Bug:** Line 196: `'assets/sounds/noise_2..opus'` has a double dot. This will cause a file-not-found error for "Deep Static" variant 2.
- **Fix:** Change to `'assets/sounds/noise_2.opus'`.

---

## Edge Case Fixes

### 3. Screen Brightness Lifecycle Guard
#### [MODIFY] [sleep_mode.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/sleep_mode/sleep_mode.dart)
- **Problem:** Brightness is only restored in `dispose()`, which is NOT called when the OS kills the app or the user force-closes it. Screen stays at 5% system-wide.
- **Fix:**
  1. Add `WidgetsBindingObserver` mixin to `_SleepModeScreenState`
  2. Restore brightness in `didChangeAppLifecycleState` when state is `paused` or `detached`
  3. Use `ScreenBrightness().resetApplicationScreenBrightness()` instead of restoring to a saved value (more reliable, hands control back to system)

#### [MODIFY] [main.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/main.dart)
- **Fix:** Add `ScreenBrightness().resetApplicationScreenBrightness()` call in `main()` before `runApp()` to clear any stale brightness override from a previous crashed session.

---

### 4. Sound Layer Memory Limit
#### [MODIFY] [audio_provider.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart)
- **Problem:** No upper limit on concurrent `AudioPlayer` instances from `addSoundLayer()`. On low-end devices, 10+ layers will cause stuttering, excessive memory use, and battery drain.
- **Fix:** Cap at 5 layers max. Add a `static const int maxLayers = 5` and check in `addSoundLayer()`. Return a `bool` or set an error message so the UI can show a SnackBar.

---

### 5. Audio Error Feedback & Auto-Skip
#### [MODIFY] [audio_provider.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart)
- **Problem:** `_errorMessage` is set on audio failure but never displayed in the UI. No auto-skip to next variant.
- **Fix:**
  1. In `_playMainSound()`, on error, auto-try the next variant (with a retry counter to prevent infinite loops — max 3 attempts)
  2. If all variants fail, set a `soundUnavailable` flag

#### [MODIFY] [sound_playing.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart)
- **Fix:** Listen for `errorMessage` changes and show a SnackBar with a "Try Next" action button.

---

## Feature Gaps

### 6. Background Media Controls (Two-Way)
#### [MODIFY] [audio_handler.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/services/audio_handler.dart)
- **Problem:** `play()`, `pause()`, `stop()`, `skipToNext()`, `skipToPrevious()` in `SleepAudioHandler` only update `playbackState` — they don't actually control the `AudioPlayer` instances. Lock screen controls are visual-only.
- **Fix:** Add callback references so the handler delegates to `AudioProvider`:
  ```dart
  VoidCallback? onPlay;
  VoidCallback? onPause;
  VoidCallback? onStop;
  VoidCallback? onSkipToNext;
  VoidCallback? onSkipToPrevious;
  ```

#### [MODIFY] [audio_provider.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart)
- Wire up the handler callbacks in the constructor to call `play()`, `pause()`, `stop()`, `nextVariant()`, `previousVariant()`.

---

### 7. Default Timer Auto-Apply
#### [MODIFY] [sound_playing.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart)
- **Problem:** `SettingsProvider.defaultTimerMinutes` is stored but never read — the timer is only set manually.
- **Fix:** In `initState()`, read `settingsProvider.defaultTimerMinutes` and, if non-null and no timer is currently active, auto-set via `audioProvider.setTimer()`.

---

### 8. Notification Toggle Enforcement
#### [MODIFY] [audio_provider.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart)
- **Problem:** Timer-ended notification fires regardless of `settingsProvider.notificationsEnabled`.
- **Fix:** Add a `notificationsEnabled` flag to `AudioProvider` (settable from outside). Check it before calling `NotificationService.showTimerEndedNotification()`.

---

### 9. Proactive Notification Permission Request
#### [MODIFY] [onboarding.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/onboarding/onboarding.dart)
- **Problem:** `POST_NOTIFICATIONS` is never requested until the user visits Settings. On Android 13+, timer notifications are silently suppressed.
- **Fix:** After `completeOnboarding()` and before navigating to Navbar, call `PermissionService.requestNotificationPermission()`.

---

### 10. Sleep Timer Gradual Fade-Out
#### [MODIFY] [audio_provider.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart)
- **Problem:** Timer expires and audio stops abruptly — jarring and can wake the user up.
- **Fix:** When `_timerRemainingSeconds <= 30`, begin a linear volume fade from the current master volume to 0 over 30 seconds. Save the original volume and restore it after stopping. This provides a natural, sleep-friendly transition.

---

## UX Improvements

### 11. Persistent Mini-Player Bar
#### [MODIFY] [navbar.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/navbar.dart)
- **Problem:** No playback indicator on main screens. Users can't see what's playing or pause without navigating back to SoundPlaying.
- **Fix:** Add a `MiniPlayerBar` widget above the `BottomNavigationBar` that shows:
  - Current sound icon + title
  - Play/Pause button
  - Timer countdown (if active)
  - Tap to navigate to full `SoundPlaying` screen
  - Only visible when `audioProvider.isPlaying` or `audioProvider.timerRemainingSeconds != null`

---

### 12. Dynamic Home Screen Content
#### [MODIFY] [home.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart)
- **Problem:** Featured sound, Popular sounds, and Recently Added are all hardcoded and never change.
- **Fix:**
  1. **Featured:** Rotate daily using `DateTime.now().day % allSounds.length` as a seed
  2. **Popular:** Track play counts in `shared_preferences` (via a new lightweight tracking method in `AudioProvider` or `FavoritesProvider`), sort by count
  3. **Recently Played (rename "Recently Added"):** Show last-played sounds based on tracking

> [!NOTE]
> This requires adding play-count tracking to `AudioProvider` or a new `PlayHistoryProvider`. The tracking will be simple: a `Map<String, int>` persisted to shared_preferences.

---

### 13. Clear All Favorites
#### [MODIFY] [favorites_provider.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/favorites_provider.dart)
- **Fix:** Add `clearAll()` method (was in original plan but never implemented).

#### [MODIFY] [favourite.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/favourite/favourite.dart)
- **Fix:** Add a "Clear All" icon button in the header (only visible when favorites exist) with a confirmation dialog.

---

## Summary of All Changes

| # | File | Type | Description |
|---|------|------|-------------|
| 1 | `favorites_provider.dart` | Bug fix | Remove invalid `forest_night` default + add `clearAll()` |
| 2 | `sound_model.dart` | Bug fix | Fix `noise_2..opus` → `noise_2.opus` |
| 3 | `sleep_mode.dart` | Edge case | `WidgetsBindingObserver` + `resetApplicationScreenBrightness()` |
| 4 | `main.dart` | Edge case | Brightness reset on startup |
| 5 | `audio_provider.dart` | Multiple | Layer limit (5), error auto-skip, fade-out timer, notification check, play tracking |
| 6 | `audio_handler.dart` | Feature | Two-way background media controls |
| 7 | `sound_playing.dart` | Feature | Error SnackBar, auto-apply default timer |
| 8 | `onboarding.dart` | Feature | Request notification permission |
| 9 | `navbar.dart` | UX | Persistent mini-player bar with timer countdown |
| 10 | `home.dart` | UX | Dynamic featured/popular/recently played |
| 11 | `favourite.dart` | Feature | Clear All button with confirmation |

---

## Verification Plan

### Automated Tests
```bash
flutter analyze    # Ensure no lint errors
flutter build apk  # Verify APK builds
```

### Manual Verification
1. **Fresh install** — favorites start empty, onboarding requests notification permission
2. **Audio error** — rename a `.opus` file temporarily → SnackBar shows, auto-skips to next variant
3. **Layer limit** — try adding 6+ layers → SnackBar shows "Max 5 layers"
4. **Sleep timer fade** — set 1-minute timer → volume fades over last 30 seconds
5. **Background controls** — play sound, lock screen → pause/play/skip controls work bidirectionally
6. **Mini-player** — play sound, go to Home → mini-player shows with timer countdown
7. **Brightness safety** — enter sleep mode, force-kill app → reopen, brightness is normal
8. **Default timer** — set default to 30m in Settings, play a new sound → timer auto-starts at 30m
9. **Notification toggle** — disable notifications in Settings, let timer end → no notification appears
10. **Dynamic home** — open app on different days → featured sound changes
