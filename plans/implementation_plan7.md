# Sleep Sounds — In-App Subscription System

Implement a client-side subscription system for the Sleep Sounds app using Google Play's `in_app_purchase` plugin. Subscriptions gate the **Sleep Music** (6 sounds) and **Relaxation** (8 sounds) categories behind monthly/yearly plans. Verification is client-side only (no Firebase Functions), with entitlement cached in SharedPreferences.

## User Review Required

> [!IMPORTANT]
> **No server-side verification.** This approach trusts the Google Play billing response on the client. A rooted device could theoretically spoof entitlement via SharedPreferences. This is acceptable for a v1 launch; server-side verification can be added later if needed.

> [!IMPORTANT]
> **Subscription IDs must match Google Play Console exactly.** The product IDs (`sleepsounds_monthly_subs`, `sleepsounds_yearly_subs`) and base plan IDs (`sleepsounds-monthly-subs`, `sleepsounds-yearly-subs`) must be created in the Google Play Console before testing.

## Proposed Changes

### 1. Subscription Service (Core Engine)

#### [NEW] [subscription_service.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/services/subscription_service.dart)

A `ChangeNotifier` singleton managing the entire subscription lifecycle:

- **Product IDs**: `sleepsounds_monthly_subs` (monthly), `sleepsounds_yearly_subs` (yearly)
- **Initialization**: Listen to `InAppPurchase.purchaseStream`, load cached status from SharedPreferences
- **Product fetching**: Query Google Play for both product IDs, expose `List<ProductDetails>` 
- **Purchase flow**: `buySubscription(ProductDetails)` → IAP stream → handle `purchased/restored/error/canceled/pending`
- **Client-side verification**: On `PurchaseStatus.purchased` or `PurchaseStatus.restored`:
  1. Grant entitlement immediately (optimistic)
  2. Cache to SharedPreferences (`ss_is_premium`, `ss_plan_type`, `ss_expiry_date`)
  3. Call `completePurchase()` to acknowledge to Google Play
- **Restore**: `restorePurchases()` triggers IAP stream with any active subscriptions
- **Expiry handling**: On app launch, check if cached subscription has expired → lock premium
- **Error mapping**: User-friendly messages for billing errors (already owned, payment declined, network, etc.)
- **Edge cases**:
  - IAP unavailable → graceful no-op, products empty
  - Pending purchases (deferred payment) → show "Purchase pending" state
  - User cancellation → silently ignored
  - `BillingResponse.itemAlreadyOwned` → prompt restore

---

### 2. Premium Category Gating

#### [MODIFY] [sound_category.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/models/sound_category.dart)

Add an `isPremium` getter to `SoundCategory`:
- `sleepMusic` → `true`
- `relaxation` → `true`
- All others → `false`

#### [MODIFY] [sound_model.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/models/sound_model.dart)

Add a computed `isPremium` getter to `SoundType` that delegates to `category.isPremium`.

---

### 3. App Entry Point

#### [MODIFY] [main.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/main.dart)

- Import and initialize `SubscriptionService` before `runApp()`
- Add `ChangeNotifierProvider.value(value: SubscriptionService())` to the `MultiProvider`
- On launch: check cached entitlement, auto-restore if needed

---

### 4. UI Integration — Sounds Library

#### [MODIFY] [sounds.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/sounds/sounds.dart)

- Watch `SubscriptionService` via Provider
- For each sound tile: if `sound.isPremium && !subscriptionService.isPremium`:
  - Add a **lock icon overlay** (🔒) on the sound image
  - Keep tap → navigate to `SoundPlaying` as usual (details are visible)
  - **Play button**: instead of `audio.selectAndPlay()`, navigate to `PremiumScreen`
  - **Favorite**: still works (users can favorite locked sounds)

---

### 5. UI Integration — Home Screen

#### [MODIFY] [home.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart)

- Same gating logic for featured sounds carousel and contextual picks
- Premium sounds in carousel show a lock badge
- Tapping play on a locked sound → `PremiumScreen`

---

### 6. UI Integration — Sound Playing Screen

#### [MODIFY] [sound_playing.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart)

- If `sound.isPremium && !subscriptionService.isPremium`:
  - Show a banner or overlay: "This is a Premium sound"
  - Play button → navigate to `PremiumScreen` instead of playing
  - Show an "Unlock with Premium" CTA

---

### 7. Premium Screen (Paywall) — Wired Up

#### [MODIFY] [premium.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/profile/widgets/premium.dart)

Major refactor of existing screen:

- **Watch `SubscriptionService`** via Provider
- **If already subscribed**: Show "You're Premium! ✓" status with plan details and a "Manage Subscription" link
- **If not subscribed**:
  - Fetch real prices from `subscriptionService.products` (replace hardcoded `$2.99/mo`)
  - Show loading spinner while products load
  - Show error state if products fail to load
  - Plan cards use real `ProductDetails.price` strings
  - Yearly card: calculate and display "Save X%" badge from real monthly vs yearly prices
  - Pre-select yearly plan (index 1)
  - "Start Free Trial" button → `subscriptionService.buySubscription(selectedProduct)`
  - Show loading overlay during purchase flow
  - On success → show existing success dialog → pop back
  - On error → show SnackBar with friendly message
- **Restore Purchases** button at the bottom: `subscriptionService.restorePurchases()`

---

### 8. Settings Screen — Status & Restore

#### [MODIFY] [settings.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/settings/settings.dart)

- Update "Premium Pass" tile:
  - **If subscribed**: Show "Premium Active • Monthly/Yearly" with green checkmark icon, subtitle shows next billing date if available
  - **If not subscribed**: Show "Upgrade to Premium" with a CTA arrow
- Add **"Restore Purchases"** tile below the Premium tile
  - Shows loading indicator while restoring
  - Success → SnackBar "Purchases restored!"
  - No purchases found → SnackBar "No active subscriptions found"

---

### 9. Audio Provider — Expiry Enforcement

#### [MODIFY] [audio_provider.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart)

- When subscription status changes (listen via callback or check on play):
  - If a premium sound is currently playing and the user is no longer subscribed:
    - Stop playback gracefully
    - The UI layer will show a toast: "Your premium subscription has expired"

---

## File Summary

| File | Action | Purpose |
|------|--------|---------|
| [subscription_service.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/services/subscription_service.dart) | NEW | Core IAP engine, entitlement management |
| [sound_category.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/models/sound_category.dart) | MODIFY | Add `isPremium` flag to enum |
| [sound_model.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/models/sound_model.dart) | MODIFY | Add `isPremium` computed getter |
| [main.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/main.dart) | MODIFY | Initialize + provide SubscriptionService |
| [sounds.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/sounds/sounds.dart) | MODIFY | Lock icon + paywall gate on play |
| [home.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/home.dart) | MODIFY | Lock badges on featured/contextual picks |
| [sound_playing.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/home/widgets/sound_playing.dart) | MODIFY | Premium CTA overlay on locked sounds |
| [premium.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/profile/widgets/premium.dart) | MODIFY | Wire up real IAP, prices, purchase flow |
| [settings.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/screens/navbar/settings/settings.dart) | MODIFY | Dynamic status + restore button |
| [audio_provider.dart](file:///c:/Users/Mimo/StudioProjects/sleep_sounds/lib/providers/audio_provider.dart) | MODIFY | Stop premium playback on expiry |

## Verification Plan

### Build Verification
- `flutter analyze` — no errors or warnings
- `flutter build apk --debug` — clean build

### Manual Verification
1. **Fresh install**: All Nature, Rain, White Noise, Ambient sounds play freely
2. **Premium lock**: Sleep Music & Relaxation sounds show lock icon, tapping play → paywall
3. **Purchase flow**: Selecting a plan → Google Play billing sheet → success → sounds unlock
4. **Restore**: Uninstall → reinstall → tap "Restore Purchases" → sounds re-unlock
5. **Settings status**: Shows "Premium Active" when subscribed, "Upgrade" when not
6. **Error handling**: Turn off network → attempt purchase → friendly SnackBar
7. **Expiry**: If subscription lapses, premium sounds re-lock, currently playing stops
