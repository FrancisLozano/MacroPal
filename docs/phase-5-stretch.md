# Phase 5 — Nice-to-Haves / Stretch

**Status:** Not started
**Depends on:** [Phase 1](phase-1-mvp.md) at minimum; individual items may depend on later phases too.

## Goal
Optional features to pick from once the core app (Phases 1–3) is something you actually use daily. Not a sequential checklist — cherry-pick what's actually useful.

## Candidates
- [x] Barcode scanning for food lookup (via a public nutrition database API)
- [x] Home-screen widget showing today's macro remaining


## Candidates (Requiring Yearly-Payment)
- [ ] Apple Health integration (import weight/workouts, export data)
- [ ] Step count via HealthKit (read-only import, no manual entry UI — rides along with the Apple Health integration above)
- [ ] Apple Watch companion for logging sets during a workout
- [ ] iCloud sync via SwiftData + CloudKit (multi-device, still single-user)

## Definition of Done
Defined per feature when you pick one — write a short scope note in this file before starting it.

### Scope note: Barcode scanning for food lookup
Uses [Open Food Facts](https://world.openfoodfacts.org) — free, keyless, no signup — chosen specifically to avoid the API-key/billing overhead a keyed nutrition API (Nutritionix, Edamam, USDA) would add. Scans a barcode via VisionKit's `DataScannerViewController`, checks the local `FoodItem` catalog first (by the `barcode` field, unused since Phase 1), and falls back to a network lookup if not found locally. The user reviews/edits the fetched macros before saving, since Open Food Facts data quality varies. This is the app's first network call and first camera usage.

Out of scope: offline caching/pre-fetching, non-food barcode symbologies, editing an existing `FoodItem`'s barcode after creation, scan history. `barcode` values aren't uniquely constrained in SwiftData — a known non-issue for a single-user app.

Definition of done: scanning a real barcode on a physical device either finds a match (locally or via Open Food Facts) and lets you save it as a `FoodItem`, or shows a clear "not found" / "connection failed" state — distinguished from each other. Live camera scanning needs a real device to verify; the network/parsing/local-lookup logic is unit-tested and Simulator-verifiable independent of the camera.

**Implementation status:** done and verified on a physical device (a real iPhone, not the Simulator). Network client, JSON decoding, local-catalog lookup, and the full UI flow (scan → loading → found/not-found/failed states) are covered by 7 unit tests (37 total passing) plus a live end-to-end scan.

One bug found and fixed during device testing: the review form was hiding legitimate `0` macro values as blank text fields (meant to distinguish "never entered" from "entered as zero" for manual entry, but Open Food Facts genuinely reports 0 for some products' macros) — this made a successful scan look like nothing had been fetched, and blank fields also failed form validation. Fixed by always showing the real number, including zero.

### Scope note: Home-screen widget showing today's macro remaining
New `MacroPalWidgetExtension` target (WidgetKit) sharing the same SwiftData store as the main app via an App Group (`group.francislozano.MacroPal`) — the app's first cross-process feature. Shows a calorie-remaining ring (fills as you eat, center number counts down) plus a descriptive breakdown of what today's eaten calories came from by macro (e.g. "53% Carbs / 14% Fat / 32% Protein") — deliberately *not* tied to daily targets, so it stays meaningful regardless of what targets someone sets. Reuses `NutritionViewModel.dailyTotals`/`.remaining` as-is; no new aggregation logic. Small and medium widget families only.

Out of scope: user-configurable widget options, deep-linking taps to a specific screen, interactive widget buttons, large widget family, offline/cached snapshots beyond WidgetKit's own timeline mechanism.

Setup required a few one-time manual steps in Xcode (creating the extension target, adding the App Group capability to both targets, setting cross-target file membership for the shared model/ViewModel/networking files) — not achievable via file-drop alone the way earlier features were, since this is a genuinely new Xcode target rather than a new folder in an existing one.

One real bug found and fixed: `WidgetCenter.shared.reloadAllTimelines()` was being called immediately after `context.insert()`/`context.delete()` with no explicit save — SwiftData's autosave is opportunistic, not immediate, so the widget's fresh read of the shared store could run before the write actually reached disk, showing stale data. Fixed by calling `context.save()` explicitly before every reload trigger.

**Implementation status:** done and verified in the iOS Simulator (widgets, unlike the barcode scanner's camera, render fully in the Simulator — no physical device required). Confirmed: both widget sizes render correctly, remaining-calorie math and macro-percentage math match the app's own Nutrition tab, and the widget updates promptly after logging food.
