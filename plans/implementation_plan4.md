# Sleep Sounds App Overhaul

A comprehensive upgrade to transform the Sleep Sounds app from a basic MVP into a polished, feature-rich sleep companion.

---

## 1. Dynamic Home Screen

> [!IMPORTANT]
> This is the most visually impactful change — the home screen will feel alive and contextual.

#### [MODIFY] [home.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart)

**Auto-scrolling Featured Carousel:**
- Replace the single featured card with a `PageView` carousel showing 4-5 randomly selected sounds
- Add auto-scroll with a `Timer.periodic` (every 5 seconds) + smooth dot indicators
- Randomize the selection on each visit (seed from `DateTime.now().millisecondsSinceEpoch`)

**Time-of-Day Contextual Suggestions:**
- Add a new "Suggested for You" section below the carousel
- Morning (5-12): energizing nature sounds (Birds, Ocean Waves, Forest)
- Afternoon (12-17): focus sounds (White Noise, Fan, Clock)
- Evening (17-21): wind-down sounds (Fireplace, Rain, Relaxation Melodies)
- Night (21-5): deep sleep sounds (Deep Sleep Tone, Midnight Serenity, Heartbeat)
- Keep the existing greeting emoji but enhance with contextual subtitle

**Randomized Featured Sound:**
- Use a proper random seed so the featured sound changes on each app open, not just daily

**Popular & Recently Played:**
- Keep data-driven (play counts / recent history) — these are already good
- Only default to curated sounds when there's no history

---

## 2. Sound Layer UX Overhaul

#### [MODIFY] [sound_playing.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart)

**SnackBar Feedback on Layer Add/Remove:**
- Show a styled SnackBar when a layer is added: `"🎵 Rain added as layer • 2/5"`
- Show a SnackBar when a layer is removed: `"Rain removed • 1/5 layers"`
- Show an error SnackBar when max layers reached: `"Maximum 5 layers reached"`

**Badge Count on Add Layer Button:**
- Add a positioned badge counter (e.g., `2/5`) on the "Add Sound Layer" button
- Badge pulses briefly with `AnimationController` when count changes
- Button text changes to `"Manage Sound Layers (2/5)"` when layers are active

**Bottom Sheet UX Improvements:**
- Group sounds by category in the bottom sheet with section headers
- Show volume slider inline for already-added layers
- Add a "Clear All Layers" option

#### [MODIFY] [audio_provider.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart)

- Return feedback data from `addSoundLayer()` and `removeSoundLayer()` (sound name, current count)
- Add `layerCount` getter for easy badge display

---

## 3. Sleep Timer + Screen Dimming Fix

#### [MODIFY] [audio_provider.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart)

- Add brightness control integration into the timer logic
- During the last 30s fade period, also gradually dim screen brightness from current → 0.01
- Store the user's original brightness to restore it when timer ends or is cleared
- Add a `shouldNavigateToSleepMode` flag that the UI can react to

#### [MODIFY] [sound_playing.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart)

- When timer is set, automatically navigate to `SleepModeScreen`
- Listen for the timer-set event and trigger navigation

#### [MODIFY] [sleep_mode.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/sleep_mode/sleep_mode.dart)

- Integrate with the timer's brightness fade logic
- Show remaining timer with a circular progress indicator (not just text)
- Add a radial gradient/glow animation around the moon icon
- Show current sound + layer info
- Add swipe-to-dismiss gesture as alternative to the button

---

## 4. Sound Metadata Improvements

#### [MODIFY] [sound_model.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/models/sound_model.dart)

**Better icons & descriptions:**
- Review all 28 sounds for accurate icon assignments (e.g., cat shouldn't use `birds_chirping.png`)
- Fix image path mappings (several sounds share the same images incorrectly)
- Add `tags` field to `SoundType` for improved search and categorization
- Improve descriptions to be more evocative and consistent

**Tags system:**
- Add tags like `['sleep', 'calm', 'nature']` to each sound
- Enable tag-based search in the Sounds screen

#### [MODIFY] [sounds.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/sounds/sounds.dart)
- Update search to also match against tags

---

## 5. Dynamic App Version

#### [MODIFY] [pubspec.yaml](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/pubspec.yaml)
- Add `package_info_plus: ^8.0.0` to dependencies

#### [MODIFY] [settings.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/settings/settings.dart)
- Replace hardcoded `'v1.0.0'` with `PackageInfo.fromPlatform()` to show real version
- Display as `v1.0.2 (build 2)` format
- Use a `FutureBuilder` to load the version info asynchronously

---

## 6. Sound Mix Presets (Save/Load)

#### [NEW] [mix_preset.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/models/mix_preset.dart)
- `MixPreset` model: name, main sound ID, list of layer IDs with volumes, master volume
- JSON serialization for SharedPreferences storage

#### [NEW] [presets_provider.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/presets_provider.dart)
- CRUD operations for presets (save, load, delete, rename)
- Max 10 presets stored in SharedPreferences
- Apply preset → sets main sound + layers + volumes

#### [NEW] [presets_screen.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/presets/presets_screen.dart)
- Dedicated screen showing saved presets as cards
- Each card shows: preset name, main sound icon, layer count, tap to apply
- Long press to rename/delete
- "Save Current Mix" FAB

#### [MODIFY] [navbar.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/navbar.dart)
- Add a 5th tab "Mixes" between Favorites and Settings
- Update bottom navigation bar

#### [MODIFY] [sound_playing.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart)
- Add "Save as Preset" button in the now-playing screen (when layers are active)

#### [MODIFY] [main.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/main.dart)
- Register `PresetsProvider` in the `MultiProvider`

---

## 7. Breathing Exercise Guide

#### [NEW] [breathing_exercise.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/breathing/breathing_exercise.dart)
- Full-screen animated breathing guide overlay
- Animated expanding/contracting circle with glow effects
- Three patterns: 4-7-8 (Sleep), Box Breathing (Calm), Simple (Relax)
- Inhale → Hold → Exhale phases with smooth transitions
- Text prompts: "Breathe In...", "Hold...", "Breathe Out..."
- Works alongside currently playing sound (doesn't interrupt audio)
- Session timer (default 3 minutes, customizable)

#### [MODIFY] [home.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart)
- Add a "Breathing Exercise" card/button on the home screen

#### [MODIFY] [sound_playing.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart)
- Add breathing exercise button in the now-playing toolbar

---

## 8. Animated Visual Themes for Now Playing

#### [MODIFY] [sound_playing.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart)

**Category-based animated backgrounds:**
- Nature sounds: slow-moving gradient of deep greens and blues
- Rain sounds: animated rain-drop ripple effect using custom painter
- White Noise: subtle static/grain animation
- Sleep Music: slow aurora borealis gradient animation
- Ambient: warm flickering glow (like fireplace light)
- Relaxation: gentle breathing gradient pulse

**Implementation:**
- Use `AnimationController` with `CustomPainter` for smooth animations
- Gradients shift slowly using `Tween<Color>` sequences
- Particle effects for rain/static using lightweight custom painting
- Low battery impact — only animate when screen is visible

---

## Verification Plan

### Automated Tests
- `flutter analyze` — ensure no lint errors
- `flutter build apk --debug` — verify clean build

### Manual Verification
- Hot reload on connected Infinix device
- Test each feature:
  - Home screen: verify carousel auto-scrolls, contextual suggestions change by time
  - Sound layers: verify SnackBar appears, badge updates, bottom sheet categories work
  - Sleep timer: verify auto-navigation to sleep mode, brightness dims, volume fades
  - App version: verify shows `v1.0.2 (build 2)` in settings
  - Mix presets: save/load/delete presets, verify audio state restores correctly
  - Breathing: verify animations are smooth, audio continues during exercise
  - Visual themes: verify backgrounds animate correctly per category
