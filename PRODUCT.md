# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

iPhone only. The Xcode target also builds for iPad (device family 1,2), but that is a default, not a target; don't spend design effort on iPad layouts.

## Users

- **Primary: the author, as a daily user on their own iPhone.** Logs food at meals, weight in the morning, steps, and strength sessions at the gym, often one-handed between sets. Every UX decision is judged first by whether it reduces friction in that daily routine. Real use drives the work: changes come from entries in [docs/usability.md](docs/usability.md), not from a feature list.
- **Secondary: people evaluating the project as a portfolio piece** (hiring reviewers reading the README, screenshots, commit history, and code). Screens should read clearly when seen cold in a screenshot, but this lens never overrides the daily user.

## Product Purpose

A free, fully offline iOS tracker for macros, body weight, steps, and strength training, plus a rule-based analysis engine ("the coach") that reviews logged data and proactively surfaces concrete, explainable recommendations. It is not a chatbot and doesn't wait to be asked.

Success is two things: the author keeps using it daily with less friction over time, and the project shows a documented diagnose → recommend → deliver loop, where friction is logged, triaged P1/P2/P3, and fixed against the log.

## Positioning

- Free, with no subscription gates on basic tracking (goals, logging, barcode scans), where comparable apps increasingly charge.
- Fully on-device and offline: no account, no backend, no data leaving the phone.
- Advice is deterministic and explainable (same data in, same insight out), with its supporting metric shown, instead of opaque AI-generated health advice. The only model use is Apple's on-device Foundation Models to turn a typed message into a routine form, which the user then confirms; it never gives advice.
- Built and shaped in the open from a written usability log.

## Operating Context

- Daily loop: log meals (Breakfast / Lunch / Dinner; Snack is hidden but old entries still decode), log weight, log steps, run the day's planned workout set by set.
- At the gym: per-set tracking with sets that log themselves after a pause, auto-complete of an exercise, an automatic rest timer with rest-over notifications, and a "workout complete" summary. One-handed reach matters here.
- Review: body map of muscle levels from lifetime volume, exercise Progress tab, weight trend against a goal weight, steps history by day / week / month, coach insights.
- Configuration lives in Profile: goals, reminders, workout settings, past training (months trained), acknowledgements.
- Home-screen widget mirrors today's macros.

## Capabilities and Constraints

- Swift, SwiftUI, SwiftData, Swift Charts, MVVM; iOS 26.5 deployment target. Idiomatic use of Apple frameworks is preferred over shortcuts (this is also a learning project).
- Food data from the Open Food Facts API (search and barcode). That is the only network dependency, and everything else works offline.
- Rule-based engine: weight plateau, protein intake, logging streak, goal weight reached, and strength stall, each unit-tested.
- Units: kg/lb and cm/ft-in display options; metric is stored internally.
- Out of scope unless the user reopens it: multi-user, accounts, backend, App Store distribution, social features, Android/web, iCloud sync, the paid LLM narrative layer, features needing a paid Apple Developer account, water tracking.
- Open: own photos for the 9 starter exercises without drawings (parked).

## Brand Commitments

- Name: **MacroPal**.
- App icon: "MacroPal" in bold white system font on dark navy (#10214D), no artwork. The user prefers plain and simple over imagery; a photo icon and a lighter blue were both rejected.
- Screens stay calm. Extra breakdowns go behind a tap (drill-down pages), not onto the main screen.
- Color carries meaning: macros own orange / green / purple; muscle levels use one hue (red) in light-to-dark steps. Don't add decorative color that competes with these.

## Evidence on Hand

- [docs/usability.md](docs/usability.md): the running usability log (likes, dislikes, suggestions, a P1/P2/P3 backlog, and a snapshot table). This is the main evidence for the case study.
- [README.md](README.md) and [SPEC.md](SPEC.md): pitch, case study, and the documented rules-over-LLM tradeoff.
- Exercise drawings from Everkinetic (CC BY-SA 4.0, credited in Acknowledgements). Other exercise image sources were rejected for unclear provenance.
- **Absent:** README screenshots (still placeholders), any other users, testimonials, or usage metrics. Don't fabricate them.

## Product Principles

1. **Real use decides.** Build from what daily use logged, then verify on the device; don't build from speculative feature lists.
2. **Least friction at the moment of logging.** Save as you type, sensible defaults, one hand, and repeat last time where it's safe.
3. **Calm surface, detail on demand.** The main screens show the day at a glance, and breakdowns live one tap away.
4. **Explainable over clever.** Recommendations show their numbers and rules, and the model never gives advice.
5. **Private and free by construction.** On-device data, no accounts, no paid dependencies.

## Accessibility & Inclusion

Standard iOS floor as good practice: support Dynamic Type, give meaningful VoiceOver labels (especially for charts, the body map, and color-coded values, where color is never the only signal), and keep text contrast sufficient in light and dark mode. No specific personal need was stated.
