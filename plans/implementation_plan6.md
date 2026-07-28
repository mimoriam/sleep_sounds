# Sleep Sounds — Bug Fixes, Edge Cases & UI/UX Polish (Plan 6)

Comprehensive plan addressing 10 remaining bugs and 6 UI/UX improvements discovered during deep code review of the plan4 + plan5 implementations.

---

## Proposed Changes

### Component 1: Audio Provider Core Fixes

#### [MODIFY] [audio_provider.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart)

**Bug #4 — Restore volume on manual timer clear during fade:**
- In `setTimer(null)`, check if `_isInFadeOut` is true. If so, restore `_masterVolume` to `_preFadeVolume`, restore all layer volumes to their `preFadeVolume`, and update all player volumes before clearing.

**Bug #5 — Remove `play()` from `loadPreset()`:**
- Remove the `await play()` call at the end of `loadPreset()`. The caller (`PresetsScreen`) pushes `SoundPlaying` which handles `selectAndPlay` on mount. This prevents double play-count and double audio loading.

**Bug #6 — Expose `isInFadeOut` getter:**
- Add `bool get isInFadeOut => _isInFadeOut;` for the UI to disable sliders and show the fading indicator.

**Bug #10 — Timer persistence across app restart:**
- In `_initialize()`, after `_loadHistory()`, read back `_keyTimerEndTime` from SharedPreferences.
- Calculate remaining seconds from `endTime - DateTime.now()`.
- If remaining > 0, call `setTimer()` with the remaining minutes (rounded up).
- If remaining ≤ 0, clear the stored key.

---

### Component 2: SoundPlaying Screen Fixes

#### [MODIFY] [sound_playing.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart)

**Bug #1 — SoundPlaying sync with mini-player navigation:**
- In `initState`, compare `widget.sound.id` against `audio.currentSound.id`. If they match AND audio is already playing, skip `selectAndPlay()` entirely (already done at line 52).
- This is already partially handled, but the root fix is in home.dart and navbar.dart (see Bug #8).

**Bug #2 — Error message side-effects in build():**
- Remove the `errorMsg` block from `build()` entirely.
- In `initState`, add an `AudioProvider` listener that checks `errorMessage`, shows the SnackBar, and clears it. Use `addPostFrameCallback` to safely show SnackBar.

**Bug #3 — Remove auto-sleep-mode on default timer:**
- In `initState`'s `addPostFrameCallback`, remove the `Navigator.push(SleepModeScreen)` block when the default timer is auto-set. Keep only the `audio.setTimer(settings.defaultTimerMinutes)` call.
- Sleep mode navigation will only happen from the Timer Bottom Sheet (explicit user action).

**Bug #6 — Disable slider + show fading chip during fade-out:**
- On the master volume `Slider`, set `onChanged: audio.isInFadeOut ? null : (val) => audio.setMasterVolume(val)`.
- On each layer volume `Slider`, set `onChanged: audio.isInFadeOut ? null : ...`.
- Below the master volume slider, add an `AnimatedSize` + `AnimatedOpacity` widget that shows `"🌙 Fading to sleep..."` chip when `audio.isInFadeOut` is true.

**UI #4 — Timer countdown on Now Playing screen:**
- In the top bar, next to the timer icon button, conditionally show a small `Text` with the formatted remaining time (e.g., `"12:45"`) when `audio.timerRemainingSeconds != null`.

---

### Component 3: Home Screen Fixes

#### [MODIFY] [home.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart)

**Bug #8 — Remove `selectAndPlay()` from carousel and SoundCardWidget:**
- In the carousel's `onTap` (line 204): Remove `context.read<AudioProvider>().selectAndPlay(sound)`. Only push `SoundPlaying(sound: sound)`.
- In `SoundCardWidget.onTap` (line 650): Remove `context.read<AudioProvider>().selectAndPlay(sound)`. Only push `SoundPlaying(sound: sound)`.

**UI #6 — Proper empty state for Recently Played:**
- When `history.recent.isEmpty`, instead of showing hardcoded fallback sounds, show a styled empty state: an icon + text saying "Play a sound to see your history here".
- Add `RefreshIndicator` wrapping the `SingleChildScrollView` to allow pull-to-refresh that re-randomizes the carousel featured sounds.

---

### Component 4: Sleep Mode Screen Fixes

#### [MODIFY] [sleep_mode.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/sleep_mode/sleep_mode.dart)

**Bug #9 — Move brightness update out of build():**
- Add a listener on `AudioProvider` in `initState` (using `addListener` or `WidgetsBinding.addPostFrameCallback`).
- When `fadeProgress` changes, call `_updateBrightness()` from the listener, not from `build()`.
- Remove the brightness call from `build()`.

---

### Component 5: Breathing Exercise Fixes

#### [MODIFY] [breathing_exercise.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/breathing/breathing_exercise.dart)

**Bug #7 — Disposal guard for timers:**
- Add a `bool _disposed = false;` field.
- In `dispose()`, set `_disposed = true` before cancelling timers.
- In `_runStep()` and `_startSessionCountdown()` callbacks, add `if (_disposed) return;` guard before any `setState()` call.

---

### Component 6: Presets Screen UX

#### [MODIFY] [presets_screen.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/presets/presets_screen.dart)

**UI #2 — Delete confirmation, validation, and swipe-to-delete:**
- Wrap each preset `Container` in a `Dismissible` widget with a red background and delete icon.
- In the `onDismissed` callback AND in the "Delete" option of the bottom sheet, show a confirmation dialog before deleting.
- In `_showSaveMixDialog` and `_showRenameDialog`, validate that the text field is not empty/whitespace before allowing save. Disable the Save button when the field is empty.

---

### Component 7: Navbar UX Improvements

#### [MODIFY] [navbar.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/navbar.dart)

**UI #3 — Mini-player equalizer animation + smooth enter/exit:**
- Replace the static "Playing" text in `_MiniPlayerBar` with an animated 3-bar equalizer widget (three thin bars with staggered height animations using `AnimationController` + `TweenSequence`).
- Wrap the mini-player `Selector` builder output in an `AnimatedSwitcher` with a `slideTransition` + `fadeTransition` so the mini-player smoothly slides in/out.

**UI #5 — Smooth cross-fade tab transitions:**
- Change `_NavbarState` to use `TickerProviderStateMixin`.
- Replace `IndexedStack(index: _currentIndex, children: _screens)` with an `AnimatedSwitcher` that cross-fades between `_screens[_currentIndex]`, using a `ValueKey(_currentIndex)` on each child to trigger the animation.
- Keep `IndexedStack` underneath for state preservation but layer an opacity animation on top using `AnimatedSwitcher`'s `transitionBuilder`.

> [!IMPORTANT]
> We need to be careful with tab transitions: using a pure `AnimatedSwitcher` would dispose tab state. The recommended approach is to keep `IndexedStack` but wrap it in an `AnimatedOpacity` or use a `Stack` with animated opacity for each screen.

---

### Component 8: Light Theme Compatibility

#### [MODIFY] [sound_playing.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart)

**UI #1 — Light theme support for Now Playing:**
- The animated dark gradient background already provides enough contrast for white text in dark mode. In light mode, the same gradient provides dark backgrounds, so white text remains visible. No changes needed here — the gradients are dark enough.
- However, check SnackBar and dialog colors — replace any hardcoded `Colors.white` text that should use `AppColors.text(context)`.

#### [MODIFY] [breathing_exercise.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/breathing/breathing_exercise.dart)

- The breathing screen uses hardcoded `Color(0xFF090D16)` background. This works in both themes since it's an immersive experience. No change needed.

#### [MODIFY] [sleep_mode.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/sleep_mode/sleep_mode.dart)

- Sleep mode uses `Colors.black` background. This is intentional for the sleep experience. No change needed.

---

## Verification Plan

### Automated Tests
- `flutter analyze` — ensure no lint errors after all changes

### Manual Verification
- **Bug #1**: Play "Rain", go back to home, tap "Ocean Waves" from mini-player → should open Now Playing with Ocean Waves
- **Bug #2**: Force an error (e.g., play non-existent variant) → SnackBar should show once, no jitter
- **Bug #3**: Set default timer to 30min in settings, open a sound → should NOT auto-navigate to Sleep Mode
- **Bug #4**: Set 1-min timer, wait for fade to start, tap Timer icon → set to "Off" → volume should snap back to original
- **Bug #5**: Load a preset from Mixes tab → play count should increment once, not twice
- **Bug #6**: Set 1-min timer, wait for fade → volume slider should be disabled with "🌙 Fading to sleep..." chip
- **Bug #7**: Open breathing exercise, rapidly switch patterns then back out → no crash
- **Bug #8**: Tap carousel card → sound should load once, not twice
- **Bug #9**: Set timer, enter Sleep Mode, wait for fade → brightness should dim smoothly without jitter
- **Bug #10**: Set 60-min timer, hot restart app → timer should resume from remaining time
- **UI #2**: Long-press preset → delete → should show confirmation dialog
- **UI #3**: Start playing a sound → mini-player should slide in smoothly with equalizer bars
- **UI #4**: Set timer on Now Playing → countdown should be visible in top bar
- **UI #5**: Switch between tabs → should cross-fade smoothly
- **UI #6**: Fresh install → "Recently Played" should show empty state, not fallback sounds; pull down to re-randomize carousel
