# Phase 5 — Nice-to-Haves / Stretch

**Status:** Not started
**Depends on:** [Phase 1](phase-1-mvp.md) at minimum; individual items may depend on later phases too.

## Goal
Optional features to pick from once the core app (Phases 1–3) is something you actually use daily. Not a sequential checklist — cherry-pick what's actually useful.

## Candidates
- [ ] Barcode scanning for food lookup (via a public nutrition database API)
- [ ] Progress photos with side-by-side comparison view
- [ ] Home-screen widget showing today's macro remaining


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

**Implementation status:** code complete — network client, JSON decoding (verified against the real Open Food Facts API, not just hardcoded fixtures), local-catalog lookup, and the full UI flow (scan → loading → found/not-found/failed states) are all built and covered by 7 new unit tests (37 total passing). The Simulator correctly falls back to a "Scanner Unavailable" alert since it has no camera. **Not yet verified:** an actual live barcode scan on a physical device — check off the box above once you've tried it on your phone.
