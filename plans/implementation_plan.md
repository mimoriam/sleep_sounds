# Sleep Sounds App — Full Implementation Plan

Transform the UI-only sleep sounds app into a fully functional, local-first audio playback app with sleep mode, sound mixing, favorites persistence, and graceful error handling.

## Design Decisions Summary

| Decision | Choice |
|---|---|
| Auth/Login | **Remove entirely** — fully local app |
| Navigation | Home, Sounds, Favorites, **Settings** (replaces Profile) |
| Audio Playback | `just_audio` + `audio_service` |
| State Management | `provider` (AudioProvider, FavoritesProvider, SettingsProvider) |
| Local Storage | `shared_preferences` |
| Splash Screen | **Skip** — use native splash, route directly to Onboarding/Home |
| Sleep Mode | `screen_brightness` for dimming + `wakelock_plus` |
| Notifications | `flutter_local_notifications` — sleep timer only |
| Platforms | **Android + iOS** |
| Premium | Keep UI as "Coming Soon" placeholder, all content free |
| Sound Organization | 27 types → 6 categories, mapped with display names + icons |
| Error Handling | Graceful — audio fallback, empty states, brightness restore |

---

## Proposed Changes

### Phase 1: Core Infrastructure

---

#### Dependencies & Configuration

##### [MODIFY] [pubspec.yaml](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/pubspec.yaml)

Add all required dependencies and register `assets/sounds/` in assets:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.9
  # Audio
  just_audio: ^0.9.43
  audio_service: ^0.18.17
  just_audio_background: ^0.0.1-beta.14
  # State Management
  provider: ^6.1.5
  # Local Storage
  shared_preferences: ^2.5.3
  # Permissions
  permission_handler: ^11.4.0
  # Sleep Mode
  screen_brightness: ^1.0.1
  wakelock_plus: ^1.3.2
  # Notifications
  flutter_local_notifications: ^19.2.1
```

Also add `assets/sounds/` to the `assets` section.

##### [MODIFY] [AndroidManifest.xml](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/android/app/src/main/AndroidManifest.xml)

Add required Android permissions:
- `WAKE_LOCK`
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_MEDIA_PLAYBACK`
- `POST_NOTIFICATIONS` (Android 13+)
- `RECEIVE_BOOT_COMPLETED`

Add `<service>` declaration for `audio_service`.

##### [MODIFY] iOS `Info.plist`

Add:
- `UIBackgroundModes` → `audio`
- `NSMicrophoneUsageDescription` (required by audio_service even if unused)

---

#### Remove Auth Flow

##### [DELETE] `lib/screens/auth/` (entire directory)
- [login.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/auth/login/login.dart)
- [signup.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/auth/signup/signup.dart)
- [google_logo.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/auth/widgets/google_logo.dart)

##### [DELETE] [auth_provider.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/auth_provider.dart)
Empty file, no longer needed.

##### [DELETE] [user_model.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/models/user_model.dart)
Empty file, no longer needed.

---

#### Sound Data Model

##### [NEW] `lib/models/sound_model.dart`

Define a `SoundType` class mapping each of the 27 sound types to:
- `id` (filename prefix: `rain`, `wave`, `fan`, etc.)
- `displayName` (user-friendly: "Rain", "Ocean Waves", "Fan", etc.)
- `category` (one of: Nature, Rain, White Noise, Sleep Music, Ambient, Relaxation)
- `icon` (Material icon)
- `variants` count (how many `_1.opus`, `_2.opus`, etc.)
- `imagePath` (optional local asset image if available)

Categories mapping:
| Category | Sound Types |
|---|---|
| **Nature** | wave, frog, horse, cat, bird (if any) |
| **Rain** | rain, washing, flush |
| **White Noise** | noise, fan, machine-fan |
| **Sleep Music** | sleeping_tone, relaxing_tone, midnight, happy_day, olo |
| **Ambient** | fire-sounds, clock, coal, radio |
| **Relaxation** | heart, birthday, holiday, jogging, karate, shoes, bus, car |

##### [NEW] `lib/models/sound_category.dart`

Enum/class for the 6 sound categories with display names and icons.

---

#### State Management Providers

##### [NEW] `lib/providers/audio_provider.dart`

`AudioProvider` (ChangeNotifier):
- Manages multiple `AudioPlayer` instances (for sound mixing/layers)
- Exposes: `currentSound`, `isPlaying`, `volume`, `soundLayers[]`
- Methods: `play(soundType, variantIndex)`, `pause()`, `resume()`, `stop()`, `nextVariant()`, `previousVariant()`, `addLayer(soundType)`, `removeLayer(index)`, `setLayerVolume(index, volume)`, `setMasterVolume(volume)`
- Loop mode: all sounds loop by default (ambient nature)
- Error handling: try-catch on all audio operations, emit error state

##### [NEW] `lib/providers/favorites_provider.dart`

`FavoritesProvider` (ChangeNotifier):
- Stores list of favorite sound type IDs
- Persists to `shared_preferences` as JSON list
- Methods: `toggleFavorite(soundId)`, `isFavorite(soundId)`, `loadFavorites()`, `clearAll()`

##### [NEW] `lib/providers/settings_provider.dart`

`SettingsProvider` (ChangeNotifier):
- `themeMode` (dark/light/system)
- `hasCompletedOnboarding` (bool)
- `defaultTimerMinutes` (int?)
- `notificationsEnabled` (bool)
- All persisted to `shared_preferences`
- Methods: `setThemeMode()`, `completeOnboarding()`, `setDefaultTimer()`, `loadSettings()`

---

#### App Entry Point & Routing

##### [MODIFY] [main.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/main.dart)

- Wrap `MyApp` in `MultiProvider` with all 3 providers
- Initialize `shared_preferences` in `main()` before `runApp`
- Use `SettingsProvider.hasCompletedOnboarding` to route:
  - First launch → `OnboardingScreen`
  - Returning user → `Navbar` (home)
- Theme mode from `SettingsProvider.themeMode`

##### [MODIFY] [onboarding.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/onboarding/onboarding.dart)

- Remove import of `LoginScreen`
- `_finishOnboarding()` → mark onboarding complete via `SettingsProvider`, then navigate to `Navbar`

---

### Phase 2: Audio Playback Integration

---

#### Audio Service Setup

##### [NEW] `lib/services/audio_handler.dart`

Custom `BaseAudioHandler` extending `audio_service` for:
- Background audio playback controls
- Media notification with play/pause/stop
- Lock screen controls

##### [NEW] `lib/services/audio_manager.dart`

High-level audio management service:
- Initializes `just_audio` players
- Handles loading `.opus` files from assets
- Manages looping behavior
- Implements sound mixing (multiple concurrent `AudioPlayer` instances)
- Sleep timer countdown with actual `Timer` + optional notification on completion

---

#### Wire Existing UI to Real Audio

##### [MODIFY] [sound_playing.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart)

- Replace mock state with `AudioProvider` via `context.watch`
- Play/Pause button → `audioProvider.play()` / `audioProvider.pause()`
- Volume slider → `audioProvider.setMasterVolume()`
- Skip prev/next → `audioProvider.previousVariant()` / `audioProvider.nextVariant()`
- Sound layers → bind to `audioProvider.soundLayers`
- Add layer → `audioProvider.addLayer()`
- Timer → real countdown via `AudioProvider`/`AudioManager`

##### [MODIFY] [home.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart)

- Sound cards navigate to `SoundPlaying` with actual sound data from `SoundType` model
- Featured sound = random or curated `SoundType`
- Popular/Recently Added sections pull from the sound data model

##### [MODIFY] [sounds.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/sounds/sounds.dart)

- Replace hardcoded `SleepSound` list with data from `SoundType` model
- Category filter uses real categories
- Tapping a sound card plays the actual audio via `AudioProvider`
- Favorite toggle persists via `FavoritesProvider`

---

### Phase 3: Features

---

#### Favorites Persistence

##### [MODIFY] [favourite.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/favourite/favourite.dart)

- Replace hardcoded `FavoriteSound` list with `FavoritesProvider` data
- Use local asset images instead of Unsplash network URLs
- Add empty state UI when no favorites ("No favorites yet — explore sounds to add some! 🎵")
- "Explore Sounds" button → switch to Sounds tab

---

#### Settings Screen (replaces Profile)

##### [NEW] `lib/screens/navbar/settings/settings.dart` (replaces profile)

New Settings screen with sections:
1. **Appearance** — Theme toggle (Dark/Light/System)
2. **Playback** — Default timer duration picker
3. **Notifications** — Toggle notifications on/off, request permission if needed
4. **About** — App version, "Rate App", "Privacy Policy", "Open Source Licenses"
5. **Premium** — Link to existing Premium screen (with "Coming Soon" badge)

Style: match existing app aesthetic (dark cards, cyan accents, rounded corners).

##### [MODIFY] [navbar.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/navbar.dart)

- Replace `ProfileScreen` import/reference with `SettingsScreen`
- Rename tab label from "Profile" to "Settings"
- Update icon from `person` to `settings`

---

#### Sleep Mode

##### [NEW] `lib/screens/sleep_mode/sleep_mode.dart`

Dedicated sleep mode overlay screen:
- Launched from `SoundPlaying` screen via a "Start Sleep" button
- Gradually dims screen brightness via `screen_brightness`
- Shows minimal UI: clock, timer countdown, stop button
- Keeps screen awake via `wakelock_plus`
- When timer ends: stop audio, restore brightness, show notification, pop back
- `AppLifecycleState` observer to restore brightness if app is killed/backgrounded

---

### Phase 4: Polish & Edge Cases

---

#### Permissions Handling

##### [NEW] `lib/services/permission_service.dart`

Centralized permission handling:
- `requestNotificationPermission()` — Android 13+ `POST_NOTIFICATIONS`, graceful fallback
- `checkAndRequestPermissions()` — called on first audio play
- iOS permission flow for notifications
- Never crash if permission denied — audio still works without notifications

---

#### Android & iOS Platform Config

##### [MODIFY] [AndroidManifest.xml](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/android/app/src/main/AndroidManifest.xml)

Full permissions block + foreground service declaration.

##### [MODIFY] iOS `Info.plist`

Background audio mode + description strings.

---

#### Graceful Degradation & Error Handling

Apply across all screens:

| Scenario | Handling |
|---|---|
| Audio file fails to load | Show snackbar "Couldn't play this sound", skip to next variant |
| All variants of a sound fail | Disable the sound card, show "Unavailable" badge |
| Empty favorites | Friendly illustration + "Explore Sounds" CTA |
| Empty category filter results | "No sounds in this category" message |
| Network image fails | Already handled with `errorBuilder` — ensure all images use local assets |
| Screen brightness not restored | `WidgetsBindingObserver` in sleep mode + `main.dart` lifecycle guard |
| Permission denied | Audio plays normally, just no notification; show one-time "Enable notifications for timer alerts" prompt |
| Battery optimization kills audio | Show info card in Settings: "For uninterrupted playback, disable battery optimization" |

##### [MODIFY] [sound_playing.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart)
- Add try-catch around all audio operations
- Restore brightness in `dispose()`

##### [MODIFY] [home.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart)
- Replace any remaining network image URLs with local asset paths

##### [MODIFY] [favourite.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/favourite/favourite.dart)
- Replace Unsplash URLs with local asset images
- Add empty state widget

---

## Files to Delete

| File | Reason |
|---|---|
| `lib/screens/auth/login/login.dart` | Auth removed |
| `lib/screens/auth/signup/signup.dart` | Auth removed |
| `lib/screens/auth/widgets/google_logo.dart` | Auth removed |
| `lib/providers/auth_provider.dart` | Empty, auth removed |
| `lib/models/user_model.dart` | Empty, auth removed |
| `lib/screens/navbar/profile/profile.dart` | Replaced by Settings |

---

## New Files Summary

| File | Purpose |
|---|---|
| `lib/models/sound_model.dart` | Sound type data model with categories |
| `lib/models/sound_category.dart` | Category enum/definitions |
| `lib/providers/audio_provider.dart` | Audio state management |
| `lib/providers/favorites_provider.dart` | Favorites persistence |
| `lib/providers/settings_provider.dart` | Settings/preferences |
| `lib/services/audio_handler.dart` | Background audio service handler |
| `lib/services/audio_manager.dart` | High-level audio management |
| `lib/services/permission_service.dart` | Centralized permission handling |
| `lib/screens/navbar/settings/settings.dart` | Settings tab (replaces Profile) |
| `lib/screens/sleep_mode/sleep_mode.dart` | Sleep mode overlay |

---

## Verification Plan

### Automated Tests
```bash
flutter analyze    # Ensure no lint errors or type issues
flutter build apk  # Verify the APK builds successfully
flutter build ios   # Verify iOS build (if on macOS)
```

### Manual Verification
1. **Fresh install** — onboarding shows, then Home. Second launch skips onboarding.
2. **Audio playback** — tap a sound → hear the `.opus` file play. Loop works.
3. **Sound mixing** — add 2-3 layers, adjust individual volumes, remove a layer.
4. **Sleep timer** — set 1-minute timer → audio stops, notification appears.
5. **Sleep mode** — screen dims, audio continues, timer counts down, brightness restores.
6. **Favorites** — tap heart, close app, reopen → favorites persist.
7. **Settings** — toggle theme, change default timer, toggle notifications.
8. **Background audio** — play sound, lock screen → audio continues, notification shows controls.
9. **Edge cases** — deny notification permission → audio still works. Kill app during sleep mode → brightness restored on next launch.

> [!IMPORTANT]
> This is a large implementation. I recommend we proceed phase by phase, verifying each phase works before moving on. Shall I begin with **Phase 1** (core infrastructure)?
