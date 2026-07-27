# Sleep Sounds App — Bug Fixes, Theme-Awareness & UX Polish

Comprehensive improvement plan based on a thorough code audit of the current implementation against both implementation plans and walkthroughs.

---

## Summary

This plan covers 4 areas of work:

1. **Bug fixes** — Timer fade-out ignoring sound layers, dead code cleanup
2. **Theme-awareness** — Make light mode actually functional across all screens
3. **UX polish** — Time-aware greetings, page transitions, haptic feedback, loading states
4. **Code cleanup** — Delete dead files, fix typo

---

## Proposed Changes

### Component 1: Bug Fixes

---

#### [MODIFY] [audio_provider.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart)

**Timer fade-out should fade ALL players, not just the main player.**

Currently (lines 347-352), only `_mainPlayer` volume is faded during the 30-second wind-down. Sound layers continue at full volume until abruptly stopped, which can wake someone up.

**Fix:** During the fade-out phase, proportionally reduce each sound layer's volume alongside the main player. Store each layer's pre-fade volume and restore them after stopping.

```diff
 // Gradual 30-second volume fade out before ending
 if (_timerRemainingSeconds! <= 30 && _preFadeVolume > 0) {
   final fadeFactor = _timerRemainingSeconds! / 30.0;
   final targetVolume = _preFadeVolume * fadeFactor;
   if (_mainPlayer != null) {
     await _mainPlayer!.setVolume(targetVolume.clamp(0.0, 1.0));
   }
+  // Fade sound layers proportionally
+  for (final layer in _soundLayers) {
+    if (layer.player != null) {
+      final layerTarget = layer.preFadeVolume * fadeFactor;
+      await layer.player!.setVolume(layerTarget.clamp(0.0, 1.0));
+    }
+  }
 }
```

Also add a `preFadeVolume` field to `SoundLayer` and capture it when the timer starts.

Also add an `isBuffering` state to `AudioProvider` so the UI can show a loading indicator while audio loads.

---

### Component 2: Theme-Awareness (Light Mode Fix)

> [!IMPORTANT]
> This is the most impactful change. Every screen currently hardcodes dark theme colors, making the light theme toggle in Settings completely broken (white text on white backgrounds).

---

#### [MODIFY] [app_colors.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/utils/app_colors.dart)

Add light theme color constants alongside the existing dark ones:

```dart
// Light theme colors
static const Color backgroundLight = Color(0xFFF5F7FA);
static const Color cardColorLight = Color(0xFFFFFFFF);
static const Color textPrimaryLight = Color(0xFF0B101E);
static const Color textSecondaryLight = Color(0xFF64748B);
static const Color borderLightTheme = Color(0xFFE2E8F0);
```

Add helper methods to get the correct color based on brightness:

```dart
static Color background(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? backgroundDark : backgroundLight;
static Color card(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? cardColor : cardColorLight;
// ...etc
```

---

#### [MODIFY] [app_themes.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/utils/app_themes.dart)

Expand the light theme to include proper `BottomNavigationBarThemeData`, `AppBarTheme`, and full `ColorScheme` with all surface/onSurface/card colors properly mapped. Ensure `ElevatedButtonTheme` and `InputDecorationTheme` use appropriate light colors.

---

#### [MODIFY] All Screen Files

Replace hardcoded color references throughout:

| Screen | File | Changes |
|--------|------|---------|
| Home | [home.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart) | `AppColors.backgroundDark` → `AppColors.background(context)`, `Colors.white` → `AppColors.textPrimary(context)` |
| Sounds | [sounds.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/sounds/sounds.dart) | Same pattern as Home |
| Favorites | [favourite.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/favourite/favourite.dart) | Same pattern |
| Settings | [settings.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/settings/settings.dart) | Same pattern |
| Navbar | [navbar.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/navbar.dart) | Bottom nav bar colors, mini-player colors |
| Sound Playing | [sound_playing.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart) | Same pattern |
| Sleep Mode | [sleep_mode.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/sleep_mode/sleep_mode.dart) | Keep dark — sleep mode should always be near-black |

**Approach:** Add context-aware helper methods to `AppColors` so changes are localized. Each screen just calls `AppColors.background(context)` instead of `AppColors.backgroundDark`.

---

### Component 3: UX Polish

---

#### [MODIFY] [home.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart)

**Time-aware greeting.** Replace static `"Good Night 🌙"` with:
- 5am–12pm: `"Good Morning ☀️"`
- 12pm–5pm: `"Good Afternoon 🌤️"`
- 5pm–9pm: `"Good Evening 🌅"`
- 9pm–5am: `"Good Night 🌙"`

---

#### [NEW] [page_transitions.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/utils/page_transitions.dart)

Custom `PageRouteBuilder` classes:
- `SlideUpFadeRoute` — For SoundPlaying screen (slide up from bottom + fade in, 400ms)
- `FadeRoute` — For SleepMode screen (simple fade, 500ms)

---

#### [MODIFY] All navigation call sites

Replace `MaterialPageRoute` with custom transitions when navigating to:
- `SoundPlaying` → `SlideUpFadeRoute`
- `SleepModeScreen` → `FadeRoute`

Files affected:
- [home.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart) (lines 116-121, 412-417)
- [sounds.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/sounds/sounds.dart) (lines 278-284)
- [favourite.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/favourite/favourite.dart) (lines 242-250)
- [navbar.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/navbar.dart) (mini-player tap, line 194-199)
- [sound_playing.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart) (sleep mode navigation, line 188-192)

---

#### [MODIFY] [sound_playing.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart)

**Haptic feedback.** Add `HapticFeedback.lightImpact()` on:
- Play/pause toggle
- Favorite toggle
- Timer selection
- Add/remove sound layer

**Loading indicator.** Show a subtle pulsing animation on the play button when `audioProvider.isBuffering` is true.

---

#### [MODIFY] [sounds.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/sounds/sounds.dart)

**Haptic feedback** on play/pause and favorite toggle buttons.

---

#### [MODIFY] [favourite.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/favourite/favourite.dart)

**Haptic feedback** on play/pause and favorite toggle buttons.

---

### Component 4: Cleanup

---

#### [MODIFY] [onboarding.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/onboarding/onboarding.dart)

Fix typo: `'Get Start'` → `'Get Started'` (line 137).

---

#### [DELETE] `lib/utils/constants.dart`

Empty file, never imported anywhere.

---

#### [DELETE] `lib/screens/splash/` (empty directory)

Dead directory with no files.

---

## Verification Plan

### Automated Tests
```bash
flutter analyze    # Ensure no lint errors
flutter build apk  # Verify APK builds
```

### Manual Verification
1. **Light theme** — Toggle to Light in Settings → all screens have readable text, proper backgrounds, and styled cards
2. **Dark theme** — Verify nothing regressed in the default dark appearance  
3. **Timer fade-out** — Play a sound + 2 layers, set 1-min timer → all layers fade together over last 30 seconds
4. **Haptics** — Feel light vibration on play/pause, favorite toggle, timer selection
5. **Page transitions** — SoundPlaying slides up gracefully, SleepMode fades in smoothly
6. **Time-aware greeting** — Check greeting matches the current time of day
7. **Onboarding** — Last page button says "Get Started"
8. **Loading indicator** — On first audio play, brief loading state is visible
