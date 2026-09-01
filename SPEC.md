# MacroPal — Personal Fitness & Macro Tracker

**Status:** Draft v0.1
**Author:** Luigi Lozano
**Last updated:** 2026-09-01

---

## 1. Vision

A personal, private, iOS-only app that combines:

1. **Macro/nutrition tracking** — MyFitnessPal-style food and macro logging.
2. **Body tracking** — weight and body measurements (waist, chest, arms, etc.) logged consistently over time, optionally with progress photos.
3. **Workout tracking** — logging training sessions (exercises, sets, reps, weight).
4. **An analysis engine** ("the coach") — not a chatbot. It doesn't wait to be asked questions; it runs automatically against your logged data and proactively surfaces decisions and adjustments (e.g. "your weight has been flat for 2 weeks on a deficit — recommend lowering calories by 150/day" or "bench volume has stalled for 3 weeks — recommend a deload").

This is a **personal-use app first**. It will also live on GitHub as a public build-in-progress so the code and commit history are visible, but it is not being built as a product for other users (no App Store submission, no multi-user accounts, no onboarding flows) unless you decide later that you want that.

## 2. Goals & Non-Goals

**Goals**
- Track macros/calories daily with minimal friction.
- Track body measurements + weight on a consistent schedule and visualize trends.
- Log workouts (strength-training focus) and track progressive overload over time.
- Have an automated engine that periodically reviews your data and produces concrete, explainable recommendations — not generic chat responses.
- Ship something you actually use, iterating in small phases, with visible progress in git.
- Learn iOS development (Swift/SwiftUI) as you go — the spec should teach, not just prescribe.

**Non-Goals (for now)**
- Multi-user support, login/signup, or a backend server.
- App Store distribution.
- A general-purpose conversational chatbot UI (see §6 — the analysis engine is decision-driven, not conversation-driven).
- Social features, sharing with friends, leaderboards.
- Supporting Android or a web client.

These non-goals can move to "later" if priorities change — noted in §9 Roadmap as stretch phases.

## 3. Platform & Tech Stack

| Layer | Choice | Why (beginner-friendly reasoning) |
|---|---|---|
| Platform | iOS only | You use an iPhone; native gives the smoothest experience and access to HealthKit later. |
| Language | Swift | Apple's modern, safe-by-default language; required for SwiftUI. |
| UI framework | SwiftUI | Declarative, less boilerplate than UIKit, huge amount of current tutorials. |
| Architecture pattern | MVVM (Model-View-ViewModel) | Keeps screens (Views) dumb and testable; business logic lives in ViewModels; works naturally with SwiftUI's data-binding. |
| Local persistence | **SwiftData** (iOS 17+) | Apple's modern local database framework, built for SwiftUI, far less boilerplate than Core Data. Falls back to Core Data if you need iOS 16 support. |
| Data storage location | On-device only | No backend to host, no auth to build, fully private. Can add iCloud sync (via SwiftData + CloudKit) later almost for free. |
| Analysis engine (v1) | Plain Swift, rule-based | Deterministic, debuggable, free, works offline. See §6. |
| Analysis engine (v2, stretch) | LLM API call (e.g. Claude API) for narrative explanations | Turns rule-engine output into a readable written recommendation. Optional, added after v1 rules work. |
| Charts | Swift Charts (native, iOS 16+) | Native, no third-party dependency, integrates with SwiftUI. |
| Version control | Git + GitHub | Public repo to show progress; private local data never touches git (see §8). |

## 4. Core Domain Concepts (Data Model)

These are the entities you'll model as SwiftData `@Model` classes. Field lists are a starting point, not final.

### 4.1 `UserProfile` (single row — this is a personal app)
- `heightCm: Double`
- `birthDate: Date`
- `sex: Sex` (for BMR/TDEE calculation formulas only)
- `activityLevel: ActivityLevel` (sedentary → very active)
- `goal: Goal` (cut / maintain / bulk)
- `calorieTarget: Int`
- `proteinTargetG / carbTargetG / fatTargetG: Int`

### 4.2 Nutrition
- `FoodItem` — a reusable food/ingredient: `name`, `caloriesPer100g`, `proteinG`, `carbG`, `fatG`, `defaultServingSizeG`, optional `barcode`.
- `FoodEntry` — one logged instance: `date`, `mealType` (breakfast/lunch/dinner/snack), reference to `FoodItem`, `servingSizeG` or `quantity`, computed macros for that entry.
- `DailyNutritionSummary` (computed, not stored) — sum of entries for a day vs. targets.

### 4.3 Body tracking
- `BodyMeasurement` — `date`, `weightKg`, and optional fields: `waistCm`, `chestCm`, `hipCm`, `armCm`, `thighCm`, `bodyFatPercent` (if measured), `notes`.
- `ProgressPhoto` (optional/stretch) — `date`, local file reference, `angle` (front/side/back).

### 4.4 Workouts
- `Exercise` — a reusable exercise definition: `name`, `muscleGroup`, `equipment`.
- `WorkoutSession` — `date`, `notes`, list of `WorkoutSetEntry`.
- `WorkoutSetEntry` — reference to `Exercise`, `setNumber`, `weightKg`, `reps`, `rpe` (rate of perceived exertion, optional).

### 4.5 Analysis engine
- `Insight` — a generated recommendation: `dateGenerated`, `category` (nutrition/body/training), `severity` (info/suggestion/action-needed), `message`, `supportingMetric` (e.g. "avg weight change: -0.1kg/wk over 14 days"), `acknowledged: Bool`.

## 5. Feature Breakdown by Phase

### Phase 1 — MVP: Manual Tracking Core
- Log a food entry manually (name + macros, no database/barcode yet).
- Set and edit daily macro targets.
- Daily summary screen: eaten vs. target, remaining macros.
- Log a body measurement entry (weight at minimum).
- Log a workout session (exercise, sets, reps, weight).
- Basic history list views for each (nutrition log, measurements, workouts).
- All data persisted locally via SwiftData.

**Definition of done:** you can use the app for a full real day — log food, log a lift session, log your weight — without opening Xcode.

### Phase 2 — Trends & Visualization
- Weight trend chart (raw + rolling 7-day average — raw daily weight is noisy).
- Measurement trend charts per body part.
- Macro adherence chart (e.g. last 14 days, calories vs. target).
- Workout progression chart per exercise (top set weight over time, estimated 1RM).

### Phase 3 — Analysis Engine v1 (Rule-Based)
This is "the coach." It runs on-demand (button: "Analyze my progress") and/or automatically on a schedule (e.g. every Sunday), and writes `Insight` records. Example rules to implement:

- **Weight plateau on a cut:** if 14-day rolling average weight change is within ±0.1% bodyweight/week AND goal is "cut" → suggest a calorie reduction (e.g. -100 to -200 kcal/day) or a diet break, with the reasoning shown.
- **Under-eating protein:** if 7-day average protein intake < 90% of target → flag it with specific foods/servings needed to close the gap.
- **Strength stall:** if top-set weight for a lift hasn't increased in N consecutive sessions (e.g. 4) at the same rep range → suggest a deload week or an accessory-volume change.
- **Missed logging streak:** if no food log or no weigh-in for X days → surface a gentle "you've gone quiet" nudge (this is about consistency, one of your stated goals).
- **Measurement vs. scale weight divergence:** if scale weight is flat/up but waist is trending down → note recomposition is likely happening (reassurance rule — important for a cutting phase).

Each rule should be its own small, testable Swift function: `(historicalData) -> Insight?`. This keeps the engine explainable and lets you unit-test each rule independently — no ML model, no black box.

### Phase 4 — Analysis Engine v2 (LLM Narrative Layer, Optional)
- Take the structured `Insight` objects from Phase 3 and pass them (plus recent summarized data, not raw logs) to an LLM API to generate a friendlier written summary/plan, e.g. "This week: hold calories, your protein has been low 3 of 7 days — try adding a shake on training days."
- The LLM only **explains and phrases** decisions already computed deterministically by Phase 3 — it does not invent new numeric recommendations. This keeps it trustworthy: rules decide, LLM narrates.
- Requires an API key (kept out of git — see §8) and a simple wrapper around the Claude API.

### Phase 5 — Nice-to-Haves / Stretch
- Barcode scanning for food lookup (via a public nutrition database API).
- Apple Health integration (import weight/workouts, export data).
- Progress photos with side-by-side comparison view.
- Home-screen widget showing today's macro remaining.
- Apple Watch companion for logging sets during a workout.
- iCloud sync via SwiftData + CloudKit (multi-device, still single-user).

## 6. Why "Not a Chatbot" — Interaction Model for the Analysis Engine

Important distinction driving the architecture: the AI component is **decision-output-first, conversation-second (or never)**.

- No persistent chat thread UI is required for v1/v2.
- The primary surface is a feed of `Insight` cards (like notifications), each with: what was observed, what's recommended, why (the supporting metric).
- You can tap an insight to mark it "applied" (e.g. it updates your calorie target automatically) or "dismissed."
- If you add a chat-style Q&A later, it's a *secondary* feature layered on top of the same rule engine/data — you'd ask "why did you suggest this?" and it explains the existing `Insight`, rather than the whole app being a chat window.

This keeps the core app usable and fast even if you never build the LLM layer at all.

## 7. Non-Functional Requirements
- **Offline-first:** the app must be fully usable with no network connection (all v1–v3 features have zero network dependency).
- **Privacy:** all personal health data stays on-device unless/until you explicitly add iCloud sync or an LLM call — and even then, only summarized/derived data should ever leave the device, never raw logs, if you add Phase 4.
- **Performance:** lists (food log, workout history) should use lazy loading; don't load your entire history into memory on every screen.
- **Data durability:** local backups matter since there's no server — rely on iCloud device backup at minimum; consider a manual export-to-JSON/CSV feature early (cheap to build, cheap insurance).

## 8. Repository & Git Workflow

Since this is going on git for others to see progress:

- **Repo structure:**
  ```
  /MacroPal/
    MacroPal.xcodeproj (or .xcworkspace)
    MacroPal/
      Models/          -- SwiftData @Model classes
      Views/            -- SwiftUI views, grouped by feature (Nutrition/, Body/, Workouts/, Insights/)
      ViewModels/
      Engine/           -- rule-based analysis engine (Phase 3+)
      Resources/
    MacroPalTests/
    SPEC.md             -- this file, kept up to date as the source of truth
    README.md           -- short project pitch + screenshots + current phase status
    .gitignore          -- standard Xcode .gitignore (ignore .xcuserdata, DerivedData, etc.)
  ```
- **Secrets:** if/when Phase 4 adds an LLM API key, put it in a git-ignored `Secrets.swift` or `.xcconfig` file — never commit an API key.
- **Branching:** simple enough to work directly on `main` with small, frequent commits per phase/feature; open a branch only if you're trying something risky you might discard.
- **README.md** should track current phase (1 through 5) and a short changelog/screenshot so visitors can see progress at a glance.
- **Editing this spec:** this file is a living document, not a frozen contract. When you disagree with something here, edit it directly and commit the change with a message explaining *why* (e.g. `"Drop iCloud sync from Phase 5 — not worth the complexity yet"`), not just `"update spec"`. `git log SPEC.md` then becomes a running history of how the requirements evolved. Bump the `Status`/`Last updated` header on any meaningful pass. Move open questions (§10) into GitHub Issues once the repo has a remote, so decisions get closed out instead of the prose getting cluttered.

## 9. Roadmap / Milestones

| Phase | Milestone | Rough scope |
|---|---|---|
| 0 | Project setup | Xcode project created, git repo initialized, SPEC.md + README committed, empty SwiftUI app running in Simulator. |
| 1 | MVP manual tracking | §5 Phase 1 complete — usable for a full real day. |
| 2 | Trends & charts | §5 Phase 2 complete. |
| 3 | Rule-based analysis engine | §5 Phase 3 complete — at least 3 rules implemented and unit-tested. |
| 4 | LLM narrative layer (optional) | §5 Phase 4 complete. |
| 5+ | Stretch features | Pick from §5 Phase 5 as desired. |

Suggested pace for a beginner working solo: treat each phase as its own multi-week milestone; don't start Phase 2 charts until Phase 1 is something you're actually using daily.

## 10. Open Questions (revisit as you go)
- Do you want a food database (even a small built-in common-foods list) in Phase 1, or purely manual macro entry to start?
- Units: kg/cm vs lb/in — pick one as the internal storage unit (recommend metric internally, display toggle later) to avoid conversion bugs.
- How often should the analysis engine auto-run — on app open, daily, weekly, or manual button only for v1?
- Is body-fat % something you'll measure (calipers/scan) or should the app estimate it from measurements (less accurate, avoid over-engineering v1)?

## 11. Glossary (for reference while learning)
- **SwiftUI:** Apple's declarative UI framework — you describe *what* the UI should look like for a given state, and it re-renders automatically when state changes.
- **SwiftData:** Apple's local persistence framework (successor to Core Data) for saving structured data on-device.
- **MVVM:** a pattern separating *View* (UI), *ViewModel* (state + logic for that view), and *Model* (raw data) so code stays organized and testable.
- **TDEE:** Total Daily Energy Expenditure — estimated calories burned per day, used to set calorie targets.
- **RPE:** Rate of Perceived Exertion — a 1–10 subjective scale of how hard a set felt, used in strength training logs.
- **Rolling average:** average over the last N days, recalculated daily — smooths out daily noise (e.g. water-weight fluctuation).
