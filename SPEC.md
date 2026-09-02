# MacroPal — Personal Fitness & Macro Tracker

**Status:** Draft v0.3
**Author:** Luigi Lozano
**Last updated:** 2026-09-01

---

## 1. Vision

A personal, private, iOS-only app that combines:

1. **Macro/nutrition tracking** — MyFitnessPal-style food and macro logging.
2. **Body tracking** — weight logged consistently against a goal weight you can revise anytime (reaching it, or recomposing at the same weight, are both just editing the goal), optionally with progress photos.
3. **Workout tracking** — logging training sessions (exercises, sets, reps, weight).
4. **An analysis engine** ("the coach") — not a chatbot. It doesn't wait to be asked questions; it runs automatically against your logged data and proactively surfaces decisions and adjustments (e.g. "your weight has been flat for 2 weeks on a deficit — recommend lowering calories by 150/day" or "bench volume has stalled for 3 weeks — recommend a deload").

This is a **personal-use app first**. It will also live on GitHub as a public build-in-progress so the code and commit history are visible, but it is not being built as a product for other users (no App Store submission, no multi-user accounts, no onboarding flows) unless you decide later that you want that.

## 2. Goals & Non-Goals

**Goals**
- Track macros/calories daily with minimal friction.
- Track weight consistently against a goal weight you can revise anytime — e.g. after reaching it, or to redefine the goal mid-phase for a recomposition (same weight, different composition target).
- Log workouts (strength-training focus) and track progressive overload over time.
- Have an automated engine that periodically reviews your data and produces concrete, explainable recommendations — not generic chat responses.
- Ship something you actually use, iterating in small phases, with visible progress in git.
- Learn iOS development (Swift/SwiftUI) as you go — the spec should teach, not just prescribe.

**Non-Goals (for now)**
- Multi-user support, login/signup, or a backend server.
- App Store distribution.
- A general-purpose conversational chatbot UI (see [docs/phase-3-analysis-engine.md](docs/phase-3-analysis-engine.md) — the analysis engine is decision-driven, not conversation-driven).
- Social features, sharing with friends, leaderboards.
- Supporting Android or a web client.

These non-goals can move to "later" if priorities change — noted in §5 Roadmap as stretch phases.

## 3. Platform & Tech Stack

| Layer | Choice | Why (beginner-friendly reasoning) |
|---|---|---|
| Platform | iOS only | You use an iPhone; native gives the smoothest experience and access to HealthKit later. |
| Language | Swift | Apple's modern, safe-by-default language; required for SwiftUI. |
| UI framework | SwiftUI | Declarative, less boilerplate than UIKit, huge amount of current tutorials. |
| Architecture pattern | MVVM (Model-View-ViewModel) | Keeps screens (Views) dumb and testable; business logic lives in ViewModels; works naturally with SwiftUI's data-binding. |
| Local persistence | **SwiftData** (iOS 17+) | Apple's modern local database framework, built for SwiftUI, far less boilerplate than Core Data. Falls back to Core Data if you need iOS 16 support. |
| Data storage location | On-device only | No backend to host, no auth to build, fully private. Can add iCloud sync (via SwiftData + CloudKit) later almost for free. |
| Analysis engine (v1) | Plain Swift, rule-based | Deterministic, debuggable, free, works offline. See [docs/phase-3-analysis-engine.md](docs/phase-3-analysis-engine.md). |
| Analysis engine (v2, stretch) | LLM API call (e.g. Claude API) for narrative explanations | Turns rule-engine output into a readable written recommendation. Optional, added after v1 rules work. |
| Charts | Swift Charts (native, iOS 16+) | Native, no third-party dependency, integrates with SwiftUI. |
| Version control | Git + GitHub | Public repo to show progress; private local data never touches git (see §7). |

## 4. Core Domain Concepts (Data Model)

These are the entities you'll model as SwiftData `@Model` classes. Field lists are a starting point, not final.

### 4.1 `UserProfile` (single row — this is a personal app)
- `heightCm: Double`
- `birthDate: Date`
- `sex: Sex` (for BMR/TDEE calculation formulas only)
- `activityLevel: ActivityLevel` (sedentary → very active)
- `goal: Goal` (cut / maintain / bulk)
- `goalWeightKg: Double` — mutable. Change it anytime: reached it → set a new one; want to recomp at the same weight → just edit this field, no separate tracking needed.
- `calorieTarget: Int`
- `proteinTargetG / carbTargetG / fatTargetG: Int`

### 4.2 Nutrition
- `FoodItem` — a reusable food/ingredient: `name`, `caloriesPer100g`, `proteinG`, `carbG`, `fatG`, `defaultServingSizeG`, optional `barcode`.
- `FoodEntry` — one logged instance: `date`, `mealType` (breakfast/lunch/dinner/snack), reference to `FoodItem`, `servingSizeG` or `quantity`, computed macros for that entry.
- `DailyNutritionSummary` (computed, not stored) — sum of entries for a day vs. targets.

### 4.3 Body tracking
- `WeightEntry` — `date`, `weightKg`, optional `notes`. That's it — no waist/chest/arm/hip measurements, no body-fat %. Goal tracking is handled by the single `goalWeightKg` field on `UserProfile` (§4.1): reach it and set a new one, or edit it directly for a recomposition phase, without a separate measurement system.
- `ProgressPhoto` (optional/stretch) — `date`, local file reference, `angle` (front/side/back). Unaffected by this simplification if you still want it later.

### 4.4 Workouts
- `Exercise` — a reusable exercise definition: `name`, `muscleGroup`, `equipment`.
- `WorkoutSession` — `date`, `notes`, list of `WorkoutSetEntry`.
- `WorkoutSetEntry` — reference to `Exercise`, `setNumber`, `weightKg`, `reps`, `rpe` (rate of perceived exertion, optional).

### 4.5 Analysis engine
- `Insight` — a generated recommendation: `dateGenerated`, `category` (nutrition/body/training), `severity` (info/suggestion/action-needed), `message`, `supportingMetric` (e.g. "avg weight change: -0.1kg/wk over 14 days"), `status` (pending/applied/dismissed), `ruleIdentifier` (which rule produced it, used to dedup re-runs), `relatedExerciseName` (optional, for rules that can fire once per exercise). `status` replaces an earlier single `acknowledged: Bool` — a Bool can't distinguish "applied" from "dismissed," both of which the interaction model (Phase 3) requires.

## 5. Roadmap & Phase Docs

Each phase has its own doc under [`docs/`](docs/) with detailed scope, interaction-model notes (for Phase 3's "not a chatbot" design), and a definition of done. This file stays the shared overview — vision, tech stack, data model, and conventions that every phase doc links back to.

| Phase | Doc | Milestone |
|---|---|---|
| 0 | [phase-0-setup.md](docs/phase-0-setup.md) | Xcode project created, git repo initialized, empty SwiftUI app running in Simulator. |
| 1 | [phase-1-mvp.md](docs/phase-1-mvp.md) | MVP manual tracking — usable for a full real day. |
| 2 | [phase-2-trends.md](docs/phase-2-trends.md) | Trends & charts. |
| 3 | [phase-3-analysis-engine.md](docs/phase-3-analysis-engine.md) | Rule-based analysis engine — at least 3 rules implemented and unit-tested. |
| 4 | [phase-4-llm-layer.md](docs/phase-4-llm-layer.md) | LLM narrative layer (optional). |
| 5+ | [phase-5-stretch.md](docs/phase-5-stretch.md) | Stretch features, pick as desired. |

Suggested pace for a beginner working solo: treat each phase as its own multi-week milestone; don't start Phase 2 until Phase 1 is something you're actually using daily.

## 6. Non-Functional Requirements
- **Offline-first:** the app must be fully usable with no network connection (all v1–v3 features have zero network dependency).
- **Privacy:** all personal health data stays on-device unless/until you explicitly add iCloud sync or an LLM call — and even then, only summarized/derived data should ever leave the device, never raw logs, if you add Phase 4.
- **Performance:** lists (food log, workout history) should use lazy loading; don't load your entire history into memory on every screen.
- **Data durability:** local backups matter since there's no server — rely on iCloud device backup at minimum; consider a manual export-to-JSON/CSV feature early (cheap to build, cheap insurance).

## 7. Repository & Git Workflow

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
    docs/
      phase-0-setup.md
      phase-1-mvp.md
      phase-2-trends.md
      phase-3-analysis-engine.md
      phase-4-llm-layer.md
      phase-5-stretch.md
    SPEC.md             -- overview: vision, goals, tech stack, data model, conventions
    README.md           -- short project pitch + screenshots + current phase status
    .gitignore          -- standard Xcode .gitignore (ignore .xcuserdata, DerivedData, etc.)
  ```
- **Secrets:** if/when Phase 4 adds an LLM API key, put it in a git-ignored `Secrets.swift` or `.xcconfig` file — never commit an API key.
- **Branching:** simple enough to work directly on `main` with small, frequent commits per phase/feature; open a branch only if you're trying something risky you might discard.
- **README.md** should track current phase (1 through 5) and a short changelog/screenshot so visitors can see progress at a glance.
- **Editing this spec:** this file (and the per-phase docs in `docs/`) are living documents, not a frozen contract. When you disagree with something here, edit it directly and commit the change with a message explaining *why* (e.g. `"Drop iCloud sync from Phase 5 — not worth the complexity yet"`), not just `"update spec"`. `git log SPEC.md` then becomes a running history of how the requirements evolved. Bump the `Status`/`Last updated` header on any meaningful pass. Move open questions (§8) into GitHub Issues once you want to track them individually, so decisions get closed out instead of the prose getting cluttered.

## 8. Open Questions (revisit as you go)
- Do you want a food database (even a small built-in common-foods list) in Phase 1, or purely manual macro entry to start?
- Units: kg/lb — pick one as the internal storage unit (recommend metric internally, display toggle later) to avoid conversion bugs.
- How often should the analysis engine auto-run — on app open, daily, weekly, or manual button only for v1?

## 9. Glossary (for reference while learning)
- **SwiftUI:** Apple's declarative UI framework — you describe *what* the UI should look like for a given state, and it re-renders automatically when state changes.
- **SwiftData:** Apple's local persistence framework (successor to Core Data) for saving structured data on-device.
- **MVVM:** a pattern separating *View* (UI), *ViewModel* (state + logic for that view), and *Model* (raw data) so code stays organized and testable.
- **TDEE:** Total Daily Energy Expenditure — estimated calories burned per day, used to set calorie targets.
- **RPE:** Rate of Perceived Exertion — a 1–10 subjective scale of how hard a set felt, used in strength training logs.
- **Rolling average:** average over the last N days, recalculated daily — smooths out daily noise (e.g. water-weight fluctuation).
