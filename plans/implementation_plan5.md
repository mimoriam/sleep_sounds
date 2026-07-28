# Fix 11 Bugs & Issues Found in Sleep Sounds Overhaul

Comprehensive bug-fix plan addressing all issues discovered during the code review of the implementation_plan4 changes.

---

## Proposed Changes

### Audio Provider Core Fixes

#### [MODIFY] [audio_provider.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart)

**Bug #3 — Block volume slider during fade-out:**
- In `setMasterVolume()`, add an early return if `_isInFadeOut` is true, so the user can't fight the fade timer
- This prevents jarring volume jumps during the last 30 seconds

**Bug #4 & #8 — Add `timerTotalSeconds` field:**
- Add `int? _timerTotalSeconds` field to store the initial timer duration when `setTimer()` is called
- Expose it via `int? get timerTotalSeconds => _timerTotalSeconds`
- Set it in `setTimer()`: `_timerTotalSeconds = minutes * 60`
- Clear it in `_cancelTimer()` and when timer expires

**Bug #8 — Update `_masterVolume` during fade:**
- In the fade-out section of the timer callback, also update `_masterVolume` to the faded value so the slider reflects the real volume

**Bug #9 — Add brightness fade support:**
- Add `double? get fadeProgress` getter that returns the current fade progress (0.0 to 1.0) during the last 30 seconds
- The `SleepModeScreen` will use this to gradually dim brightness

**Bug #11 — Fix `loadPreset()` to not use `stop()`:**
- Replace `await stop()` with a manual cleanup that:
  - Stops and disposes layer players
  - Clears the layer list
  - Stops the main player
  - Does NOT cancel the timer
  - Does NOT update audio handler to "Stopped"

---

### Sound Model Fix

#### [MODIFY] [sound_model.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/models/sound_model.dart)

**Bug #1 — Fix typo in noise_2 path:**
- Change `'assets/sounds/noise_2..opus'` → `'assets/sounds/noise_2.opus'`

---

### Sound Playing Screen Fixes

#### [MODIFY] [sound_playing.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart)

**Bug #2 — Fix timer bottom sheet navigation context:**
- In `_TimerBottomSheet`, capture the parent navigator before `Navigator.pop()` and use it for the sleep mode push
- Use `Navigator.of(context, rootNavigator: true)` or pass a callback from `_SoundPlayingState`

**Bug #5 — Make SoundPlaying reflect current sound state:**
- Remove the `selectAndPlay` call from `initState` (it's already called by the caller)
- Use `audio.currentSound` consistently throughout the UI (already done in `build()`)
- Only call `selectAndPlay` if audio is not already playing the correct sound

**Bug #7 — Dispose TextEditingControllers:**
- Add `controller.dispose()` in the `_showSaveMixDialog` after the dialog is dismissed (use `.then()` on `showDialog`)

**Missing Feature — Category grouping in Add Sound bottom sheet:**
- Group the flat list by `SoundCategory` with styled section headers
- Show each category as a collapsible/titled section

---

### Sleep Mode Screen Fixes

#### [MODIFY] [sleep_mode.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/sleep_mode/sleep_mode.dart)

**Bug #4 — Fix progress ring calculation:**
- Use `audio.timerTotalSeconds` (the new getter) instead of recalculating from `timerMinutes`
- Fallback to `1` only when `timerTotalSeconds` is null

**Bug #9 — Tie brightness to fade timer:**
- Listen to `AudioProvider.fadeProgress` and gradually dim brightness from 0.05 → 0.01 during the last 30 seconds
- Use a periodic check or listen to provider changes

---

### Presets Screen Fix

#### [MODIFY] [presets_screen.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/presets/presets_screen.dart)

**Bug #6 — Handle missing sound IDs gracefully:**
- Use `SoundRegistry.getByIdOrNull()` instead of `getById()`
- If `mainSoundId` is not found, show a warning badge on the preset card
- If a layer's `soundId` is not found, skip that layer when loading
- Show a SnackBar explaining which sounds couldn't be found

**Bug #7 — Dispose TextEditingControllers:**
- Add `controller.dispose()` in `_showSaveMixDialog` and `_showRenameDialog` after dialogs close

---

### Breathing Exercise Fix

#### [MODIFY] [breathing_exercise.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/breathing/breathing_exercise.dart)

**Bug #10 — Clean animation restart on pattern switch:**
- Before `_startPattern()`, call `_animController.stop()` and `_animController.reset()`
- This prevents the circle from snapping when switching between patterns

---

## Verification Plan

### Automated Tests
- `flutter analyze` — ensure no lint errors after all changes

### Manual Verification
- **Bug #1**: Play "Deep Static" and cycle through all 6 variants — variant 2 should load
- **Bug #2**: Set a timer from the bottom sheet — Sleep Mode should open correctly
- **Bug #3**: Set a 1-minute timer, wait for fade, try dragging the volume slider — should be locked
- **Bug #4**: Set a 30-minute timer, open Sleep Mode — progress ring should show correct fill
- **Bug #5**: Play "Rain", go back, tap "Ocean Waves" mini player — should show current playing sound
- **Bug #6**: (Hard to test without removing a sound, but verify preset loading with all current sounds)
- **Bug #7**: Open and close the save mix dialog multiple times — no memory warnings
- **Bug #8**: Set a short timer, watch the volume slider during fade — should animate down
- **Bug #9**: Enter Sleep Mode with timer — brightness should gradually dim in last 30 seconds
- **Bug #10**: Open breathing exercise, switch between patterns — circle should animate smoothly
- **Bug #11**: Set timer, load a preset — timer should still be active
