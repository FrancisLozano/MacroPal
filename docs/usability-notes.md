# Usability Notes & Feedback Log

**Status:** Living document — ongoing, not tied to a phase
**Started:** 2026-09-06

## Progress summary (as of 2026-09-22, end of day)

29 of 33 triaged backlog items are Done, 1 was verified as "No change needed", and 3 are open —
all three are small P3 rough edges. **Every P1 and P2 item is done.** (The 09-15 summary said
"9 of 16"; the table actually held 17 rows then — counts are recounted from the table.)

The 2026-09-19 stretch merged Body and Workouts into **one Training tab**, following
[discovery-workouts-body-redesign.md](discovery-workouts-body-redesign.md) (Option 2) and the
user's whiteboard sketch — body map on top, Current Plan, Goals below. On 2026-09-22 all three
of that doc's success criteria were met.

### What changed on 2026-09-22

Morning: a simulator pass over everything unverified (no broken features, seven rough edges
logged), fixes for the two worst (`fc7d42a` set-weight prefill, `ab0bd10` Edit Routine warning),
and the steps goal with a bar chart (`a46cfe9`). Then, in order:

| Commit | What |
|---|---|
| `651389f` | Cancel on the Log Workout / Add Set sheets; food-history row closed (already done by `ab68f73`/`4e02e89`) |
| `cb532ed` | Body map redrawn (smooth curves, clearer untrained muscles, six-pack, kite traps) + Level/Weekly toggle |
| `ba0d917` | Exercise Progress: best 1RM, progress to the next strength level, one-line chart with a target line, tap to inspect; "% of best" no longer compares today's sets against themselves |
| `1737ed2` | Unplanned workouts use the plan's per-set tracking screen — 12 taps → 8 |
| `7cfc42b` | Plan rep ranges (8–10), Move Up/Down within a day, New Exercise defaults to the day's group; launch-crash retry |
| `dab0aea`, `78417fe` | Tap a macro → which foods it came from (grams + % of the day; no chevrons, no per-food bars — user feedback) |
| `209bc15` | Insights tab replaced by inline callouts with an ⓘ sheet (protein on Nutrition, weight on the Goals card, stalls on Exercise Progress) |
| `be8196a`, `e973f41`, `8e3dbb2` | Profile in sections — Personal / Workout / Goal & Daily Targets / Units & Measurements; Workout settings page (from a reference screenshot) and a rest timer; lb/kg moved off the Goals card; height in cm or ft/in |

Details for each are in the Backlog rows and the "Next steps on the Training page" list below.

### Decisions worth remembering

- **Insights are live, not stored.** Rules return `InsightFinding` values that are recomputed
  from the data and shown where they're relevant; they vanish when the condition stops. No
  Analyze button, no apply/dismiss. The logging-streak rule is kept but not shown (it'd make a
  better notification). The old `Insight` model stays in `AppSchema`, unused, so stores open
  without a migration.
- **Workout preferences live in UserDefaults** (`WorkoutPreferences`, `HeightUnit`), like
  lb/kg — they're device settings, not data. Default sets/reps only apply to exercises added
  from now on; exercises already in the plan keep their own targets.
- **The rest timer is one shared `RestTimerModel`** in the environment (created in
  `RootView`), so it keeps counting across the day list and the next exercise. It doesn't
  survive quitting the app and doesn't notify in the background.
- **Unplanned workouts dropped RPE and session notes** (only the old form could enter them;
  old sessions still show theirs).
- **Exercise targets and body-map levels use the same strength standards**, but Exercise
  Progress skips the body map's tenure cap (it judges the lift, not the muscle).

### Remaining open items

- **P3** — Edit Routine carries exercises to the *first* day with the same name.
- **P3** — Medium widget lists macros Carbs / Fat / Protein; the app uses Protein / Carbs / Fat.
- **P3** — Workout History rows show only date + set count, not the plan day or exercises.

Known follow-ups that aren't Backlog rows yet: a notification when rest ends in the
background; a per-lift goal you set yourself on Exercise Progress (needs a model field);
HealthKit step import (needs a real device); Log Weight / Log Steps lose typed input if you tap
the dimmed area; Default Time from the reference screenshot (no timed exercises exist).

## Next task

**Start here next session:**

1. **P3: Workout History rows** — show the plan day ("Pull") and the exercises, not just date
   + set count.
2. **P3: widget macro order** — match the app (Protein / Carbs / Fat). A one-liner in
   `MacroPalWidget`.
3. **P3: Edit Routine day matching** — carry exercises to the same-named day in the same
   position, not the first one.

(Done 2026-09-22, evening: the bad weigh-in — the 227 kg entry was deleted from Weight History
and re-logged as 227 lb, dated 2026-09-22 — and removing an extra Add Set row; see the Backlog.
Exercise Progress with the corrected bodyweight hasn't been re-checked yet.)

After that the backlog is empty, so the most useful next step is **a week of real use**: log
food and workouts for real and add new Likes / Dislikes / Suggestions below — the raw log
hasn't had an entry since 2026-09-08, and everything since has been built from it.

**Watch for:** the launch-crash retry (`7cfc42b`) is untested — the next time a `@Model`
gains a field, launch the app with the widget installed and confirm it opens first time.

## Details and reference

### Next steps on the Training page (all done 2026-09-22 — kept for the details)



1. ~~**Steps goal + bar chart.**~~ Done 2026-09-22 with manual entry: a Steps row on the
   Goals card (today vs. goal, Log, chart) and a Steps screen with 7/30-day bars against the
   goal. Decisions worth knowing:
   - **One total per day.** Steps are a running daily count, not separate readings like
     weigh-ins, so logging a day that already has a total replaces it. The Log sheet shows
     the picked day's current total, opens with the keyboard up, and won't pick future dates.
   - **The summary counts logged days only** ("Average per logged day", "Goal met: 1 of 2
     days"). With manual entry a blank day usually means "didn't log", not "didn't walk".
     Switching to every day in the range is a small change in `StepsHistoryView.summary`.
   - Bars are green when the goal is met, blue otherwise; the goal is a grey dashed line.
     The 30-day axis uses explicit weekly marks because automatic ones clipped the last label.
   - `stepGoal` is defaulted where it's declared (10,000), which is what lets existing
     stores migrate without a versioned schema — checked against the real simulator data.

   **Still open:** HealthKit import (needs a real device and permissions — can't be tested
   in the simulator); the Log Steps sheet, like Log Weight, closes and drops what was typed if
   you tap the dimmed area above it; Log Weight doesn't focus its field on open the way Log
   Steps now does.
2. ~~**Body map polish.**~~ Done 2026-09-22. All four complaints addressed in
   `BodyFigure.swift`: every outline is now a smooth closed curve (Catmull-Rom through the
   points) instead of a polygon, with new proportions and the muscles kept slightly apart so
   thin separation lines show; untrained muscles use `systemGray2` instead of `systemGray3`;
   the traps are a rounded kite from the neck to mid-back; abs are a six-pack plus lower abs;
   the quads gained a separate inner teardrop, the hamstrings and calves are split in two.
   The exercise-row thumbnails use the same drawing, so they changed too.
   - **Weekly toggle** (Level | Weekly, remembered between launches): colors each muscle by
     sets this calendar week — a main mover (involvement ≥ 0.8) counts 1, an assisting muscle
     (≥ 0.5) counts ½ — in four blue bands, 1–4 / 5–9 / 10–19 / 20+ sets, loosely after the
     "10–20 sets per muscle per week" rule of thumb. `WeeklyMuscleVolume` +
     `WeeklyMuscleVolumeTests`. The week follows the phone's locale (Sunday start in the US).
   - The card is a little shorter in Weekly mode (one legend row instead of two), so what's
     below it shifts when you switch.
   - Tip for future drawing work: the figure was iterated with a macOS harness that renders
     `BodyFigure` to PNG via `ImageRenderer` (system grays swapped for fixed RGB), far faster
     than a simulator round trip. It lived in the session scratchpad, not the repo.
3. ~~**Exercise progress graphic.**~~ Done 2026-09-22 — closes the discovery doc's third
   success criterion. Exercise Progress now shows, top to bottom:
   - **Best estimated 1RM** as a headline number, with "+12 lb since Aug 3" once there are
     two or more sessions.
   - **Progress to the next strength level** for that lift: "Novice → Intermediate" chips in
     the level colors, a bar, "147 of 176 lb · 29 lb to go", and what the target means
     ("starts at an estimated 1RM of 1.5× your bodyweight"). `LiftStandard` +
     `LiftStandardTests`. It uses the body map's standards but *not* its tenure cap (a
     footnote says the body map can show a muscle lower). Dumbbell targets are per dumbbell,
     the number you'd type into a set. No bodyweight → a prompt to log it; bodyweight
     movements → no standard.
   - **The chart:** one line (estimated 1RM per session) instead of two, with a dashed line
     for the next level's target (the y-axis always includes it, so the gap shows), date
     labels that no longer vanish (the x-range is at least a week wide), and tap a session
     to see its date, estimated 1RM and top set (tap again to clear). The tap replaces
     Swift Charts' default press-and-drag, which fought the List's scrolling and cleared
     the moment the finger lifted.
   - Each session's point now uses its *best* set's estimated 1RM, not the heaviest set's,
     so the headline always matches the top of the chart. `StrengthStallRule` only reads the
     top set, so it isn't affected.
   - **"% of best 1RM" fix:** the tracking screen now only compares against sets from before
     today, so a first-ever set shows no bar instead of ~80% of itself.

   **Not checked in the simulator:** a chart with several sessions (the simulator's only
   Barbell Row data is one session) and the "% of best" fix (Barbell Row is no longer in the
   plan). A per-lift goal you set yourself would be the natural next step — it'd need a new
   model field.
4. ~~**Faster logging for unplanned workouts.**~~ Done 2026-09-22. "Log an Unplanned Workout"
   now opens `UnplannedWorkoutView`: straight into the exercise picker, then the same
   tracking screen plan days use (`ExerciseTrackView` now takes either a plan exercise or an
   exercise + date). Sets save as they're checked, so there's no Save step, and closing the
   sheet loses nothing.
   - **Tap count** for 3 sets of an exercise with no history (baseline from the old code,
     new flow counted in the simulator): **12 → 8.** Old: open, Add Set, Choose exercise,
     pick, weight field, reps field, Add, then Add Set + Add twice, Save — three sheets
     deep. New: open, pick, reps field, weight field, three checks, Done. With history to
     prefill from it's 6 (open, pick, three checks, Done).
   - The workout screen lists the exercises logged that day (including plan sets), with
     thumbnails and set counts, plus Add Exercise; a date picker (no future dates) back-dates
     a forgotten workout.
   - **Dropped:** RPE and session notes, which only the old form could enter. Old sessions
     still show theirs. Easy to bring back if they're missed.
   - The old form (`LogWorkoutSessionView`) and its draft-set code in `WorkoutViewModel` are
     deleted. The exercise picker and the New Exercise form gained Cancel buttons (the
     picker now opens on its own, so it needed a way out other than swiping).
   - Unplanned exercises start with 3 empty rows; unused rows just aren't logged. (Still no
     way to delete an extra row — the P3 below.)
5. ~~**Plan editing gaps.**~~ Done 2026-09-22, all four:
   - **Rep ranges:** Edit Sets & Reps has a Rep Range switch (on → bottom + 2, e.g. 8–10) and
     From / To steppers; stepping the bottom up past the top pushes the top along. Rows and the
     tracking screen show "3 sets x 8–10 reps"; empty set rows prefill with the bottom of the
     range. New field `PlanExercise.targetRepsMax` (optional, defaulted, so the store migrated
     without a versioned schema — checked in the simulator store).
   - **Reorder within a day:** Move Up / Move Down in each exercise's ellipsis menu (disabled
     at the ends). Not drag — the day screen deliberately avoids `List` (the button-detachment
     bug), and a menu works without it. `PlanDay.move(_:by:)` + `PlanDayTests`.
   - **Name twice:** the tracking screen's header card now shows the muscle thumbnail and
     "4 sets × 11–12 reps / 0 of 4 done"; the name is only in the nav bar.
   - **New Exercise default:** starts on the plan day's first suggested muscle group (Legs on
     Lower) instead of Full Body; Full Body only when there are no suggestions.
   - **Launch crash found on the way:** the first launch after adding the field crashed in
     `MacroPalApp.sharedModelContainer` — the widget extension started migrating the shared
     store at the same instant and the app lost the race ("store version hashes didn't
     migrate"). The app now waits half a second and retries once before giving up. The race
     couldn't be reproduced afterwards (the store was already migrated), so the retry is
     untested; watch for it on the next schema change.
6. ~~**Rest timer**~~ Done 2026-09-22 as part of Profile → Workout (see the Backlog row).
   Target icons from the reference are still left out.

### Things to know about the muscle levels

The body map's levels are a judgement call, so they're documented rather than buried in code
(`MuscleLevelEngine.swift`, `ExerciseMuscleData.swift`):

- Level = best **estimated 1RM in the last 90 days ÷ bodyweight**, compared against
  per-exercise-class thresholds (male; ratios divided by 0.65 for female). The thresholds are
  **approximations in the spirit of published bodyweight-multiple standards, not copied from
  one source** — expect to tune `StrengthClass.maleThresholds` after real use.
- A **tenure cap** stops a single heavy day from skipping the years: about a year of training a
  muscle allows Advanced (blue); Elite and World Class take several years. This is what makes
  "after a year it's blue" true.
- Bodyweight movements (pull-up, push-up, dips, plank, ab wheel) can't be judged from a
  logged load, so they only give the Beginner floor. Dumbbell lifts are doubled (two
  dumbbells); leg press and calf raise are scaled down. One-arm row is probably underrated.
- With no weight logged, every trained muscle just shows Beginner.

### Verified vs. not yet verified in the simulator

**Verified (2026-09-19):** Training tab layout; lb/kg toggle; Log Weight sheet; creating a
5-day plan; week view; Current Plan card ("Today: Lower"); adding an exercise to a day;
per-set tracking (logging set 3 with the check, "% of best 1RM" bar); starter catalog and the
Suggested/All picker; body map colors after a squat session (quads + glutes Beginner);
`MuscleLevelEngineTests` (8 passing); **home-screen widget after the shared-schema change** —
it read the shared store and updated from 2,000 to 1,950 cal after logging a 50 kcal food.
(Small widget only; not tried on a real device.)

**Verified (2026-09-22):** exercise-row muscle thumbnails (Barbell Row → back, arms fainter);
Edit Sets & Reps (3 × 10 → 4 × 8, reflected on the row and the tracking screen); unchecking a
set (deletes it, "0 done", fields editable again — re-checking doesn't double-count); Add Set;
dragging to reorder in the week view (names move, weekdays stay); editing an existing routine
(5 → 4 days kept Lower's exercises, checked in the store; no orphaned rows); Workout History
showing a session logged from a plan day, and its detail screen; Exercise Progress; Log an
Unplanned Workout opens; the medium-size widget (reads the shared store, calories + three
macros); Remove from Plan. Rough edges found are in the Backlog, sourced "Simulator pass
(2026-09-22)". Later the same day: the redrawn body map and Weekly toggle; Exercise Progress
(one session only) and tap-to-inspect; the unplanned-workout flow and its tap count; rep
ranges, Move Up/Down and the tracking header; the macro breakdown (one- and two-food days);
the goal-reached callout and its sheet; the Profile sections, Workout settings, weight-first
rows and the rest timer (auto-start, carry-over to the day list, ±15s, Skip).

**Not seen live yet:** the protein and strength-stall callouts (need 4 logged days / 4
sessions of one lift), an Exercise Progress chart with several sessions, and the ft/in height
entry.

**Not yet verified:** anything on a physical device.

### Housekeeping

- The simulator has leftover test data from these sessions: a "rwoaw" food entry and a
  "Chicken breast bites" entry on 2026-09-19, a Back Squat with 3 sets of 135 lb × 10, a 5-day
  plan (Lower has Back Squat + Bulgarian Split Squat, 3 × 10), one Barbell Row set (95 lb × 8)
  on 2026-09-22, steps for 2026-09-21/22, and one weigh-in of 227 lb on 2026-09-22 (it replaced
  an entry stored as 227 kg — the "227" typed in the wrong unit). None of it is in the repo. Every test set logged on 2026-09-22
  was unchecked afterwards, the goal was put back to Maintain, and the Workout preferences
  were put back to their defaults.
- The simulator with this data is the **iPhone 17 Pro**; its store is the app-group
  `MacroPal.sqlite` (open it with `sqlite3 -readonly` to check what an edit actually saved).
- Untracked and left alone: `MacroPal.xcodeproj/xcshareddata/` and `scratchpad/`.
- **Testing in the simulator — gotchas from 2026-09-22:**
  - `xcodebuild test` runs on a clone and leaves the iPhone 17 Pro shut down; boot it again
    (`xcrun simctl boot <udid>`) before launching the app.
  - After that reboot, the simulator tool's screenshots failed every time (`captureFailed`)
    while taps still worked. `xcrun simctl io <udid> screenshot <file>.png` works instead.
  - Sheets slide up when the keyboard opens, so the Save button moves — re-check its position
    before tapping. To close a date-picker popover, tap inside the sheet; tapping the dimmed
    area closes the whole sheet and loses the input.
  - The simulator tool's taps don't flip a `Toggle` switch; swipe across the knob instead.
  - SwiftData autosaves a moment later, so a `sqlite3` read right after an edit can still show
    the old value — wait a few seconds before concluding a save failed.
- Adding a database model is now two steps — list it in `AppSchema.models`, and add its file
  to the widget target's membership — see the discovery doc's implementation notes.

## Purpose

Phases 0–3 (core app) and the free half of Phase 5 (barcode scanning, home-screen widget) are
built — see [SPEC.md §5](../SPEC.md#5-roadmap--phase-docs) for the full roadmap. Phase 4 and
the paid Phase 5 candidates are intentionally skipped. That means the app is no longer being
built toward a milestone — it's being *used*.

This doc is where daily use turns into signal: what's pleasant, what's annoying, what's
missing. It's dogfooding notes, not a phase — there's no "definition of done." It exists so
usability feedback doesn't evaporate into memory and so this project's growth stays visible
in something more concrete than intuition ("this used to bug me and now it doesn't").

## How to log an entry

Add a one-line bullet under the matching section below (**Likes** / **Dislikes** /
**Suggestions**) — newest at the top of its section. Format:

```
- 2026-09-07 (Area) — what you noticed, kept concrete: what screen, what action, what you
  expected vs. what you got. For a suggestion, say what "better" looks like, not just "bad."
```

- **Area** — `Nutrition` / `Body` / `Workouts` / `Insights` / `Widget` / `Barcode` / `General UI`.
- No per-entry status — everything here is implicitly `Open` until it's promoted. Once
  something is worth actually doing, move it into **Backlog** below (with a priority and a
  link back to the bullet it came from) rather than tracking status inline.
- A dislike and the suggestion that addresses it don't need to be merged — cross-reference
  them in the Backlog when you triage instead of trying to keep the raw log tidy.

## Snapshot

Update this table whenever you triage. It's the fastest way to see whether the app is
actually improving or just accumulating complaints.

| Metric | Count |
|---|---|
| Likes | 1 |
| Dislikes | 13 |
| Suggestions | 7 |
| Triaged (in Backlog) | 33 |
| Done | 29 |
| No change needed | 1 |
| Won't Fix | 0 |

## Backlog (triaged)

Promoted items only — things worth actually doing. Once a project has enough of these piling
up, consider moving them to GitHub Issues instead (per [SPEC.md §7](../SPEC.md#7-repository--git-workflow)'s
guidance for open questions), so they don't just rot in a markdown table.

| Priority | Item | Source | Status |
|---|---|---|---|
| P1 | Delete a logged food entry | Dislikes → Nutrition (2026-09-08) | Done (58cb5d0) |
| P1 | Weight-entry date auto-fills to today | Suggestions → Body (2026-09-08) | No change needed — verified `LogWeightEntryView` already defaults `date` to `.now`; logged a real entry without touching the date field and it saved correctly dated today |
| P1 | Redesign nutrition summary — revised twice: first pass (00a444b) condensed macros into a compact row; second pass (0665d86) replaced that with a single Apple Health-style ring whose filled arc is segmented by macro color, plus a toggle icon that also recolors the ring | Dislikes → General UI (2026-09-07) + Suggestions → General UI (2026-09-07) + Suggestions → Nutrition (2026-09-08, macro filter) | Done (0665d86) |
| P1 | Redesign Workouts page (visual appeal + faster set logging) — done as part of the merged Training tab: plan-driven workout list, per-set tracking screen (reps × weight, % of best estimated 1RM, check to log, prefilled from last set) | Dislikes → Workouts (2026-09-08, "lacks visual appeal...") | Done (3c6d1d3) — unplanned-workout flow still the old slow one, see next steps |
| P2 | Food database integration (search/brands, not manual-only) — Open Food Facts search, barcode scanning, and relevance-ranked results | Dislikes → Nutrition (2026-09-08, "no brands...") + Suggestions → Nutrition (2026-09-08, "larger variety...") | Done (1a3b380) — status corrected 2026-09-15, this shipped before it was marked here |
| P2 | Redesign food history (show calories vs. target, show macros per entry, scale better with more entries) — became the Daily Log: a one-day-at-a-time diary with a calories bar against the target ("X/2,000 kcal", "left"/"over"), a macros card, and a p/c/f line on every entry | Dislikes → Nutrition (2026-09-08, three food-history entries) | Done (ab68f73, 4e02e89) — status corrected 2026-09-22 after checking `FoodHistoryView` against the three dislikes |
| P2 | Fold Body page into another page instead of standalone — Body and Workouts merged into one Training tab; weight is a Goals-card row with a log button and a chart link | Dislikes → Body (2026-09-08) | Done (4d4f8dc, 41b27b9) |
| P2 | Replace Insights page with contextual info icons at point of relevance — the rules now run live and each finding shows as an `InsightCallout` (headline + ⓘ) where it's relevant: protein running low in the Nutrition screen's Macros section (today only), goal weight reached / plateau under the Goals card's weight row, a strength stall in that lift's Exercise Progress summary. Tapping opens the recommendation and "Where this comes from": the numbers plus the rule in plain words. Messages now use the lb/kg setting. The Insights tab, "Analyze" button and apply/dismiss flow are gone; callouts disappear on their own when the condition stops holding. The logging-streak nudge isn't shown (redundant in an app you've just opened; better as a notification later). The `Insight` model stays in the schema, unused, so existing stores open without a migration | Dislikes → Insights (2026-09-08) + Suggestions → Insights (2026-09-08) | Done — goal-reached callout and its sheet checked in the simulator 2026-09-22 (goal set to Bulk to trigger it, then back to Maintain); the protein and stall callouts weren't seen live — the simulator lacks the 4 logged days / 4 sessions they need |
| P2 | Add oz as a serving-size unit alongside grams | Dislikes → Nutrition (2026-09-08, "serving size is only in grams") | Done (1a3b380) — status corrected 2026-09-15; cdb333f later added cups/tbsp/tsp and fraction input on top of it |
| P2 | Daily logged-food list scales better as more foods are added — replaced the flat "Logged Today" list with a swipeable Breakfast/Lunch/Dinner carousel; each card is a fixed-size two-line summary (what's logged + calories) instead of growing with every entry | Dislikes → Nutrition (2026-09-08, "day's logged-food list...") | Done (c3a8e87) |
| P2 | Clicking a macro shows which foods contributed to it — each Macros row on the Nutrition screen now opens a breakdown for the selected day: total vs. target, then every food with that macro, biggest first, with grams and % of the day's total (`MacroBreakdownView`; `NutritionViewModel.contributions` + `MacroContributionTests`). Rows stay tappable after the protein-only toggle changes the section's shape. Revised on user feedback the same day: no chevrons on the macro rows, and no per-food share bars — the percentage is enough; the total bar at the top stays | Suggestions → Nutrition (2026-09-08) | Done (dab0aea) — checked in the simulator 2026-09-22 (one-food day only; ranking is unit-tested) |
| P2 | Profile reorganised into sections from the user's reference screenshot: **Personal** (Personal Info), **Workout** (a settings page: reps-first / weight-first set rows, Show PRs toggle for the "% of best" bar, default sets and reps — range allowed — for newly added exercises and unplanned rows, default rest, Automatic Rest Timer; each with an ⓘ), **Goal & Daily Targets** (one section, to save space), **Units & Measurements** (no footer; lb/kg moved here off the Goals card to free space on Training; height in cm or ft/in, stored in cm). New **rest timer**: a bar above the tab bar with the countdown, −15s / +15s / Skip, a haptic when it ends; starts on checking a set when automatic, else from the timer button on the tracking screen; one shared `RestTimerModel`, so it keeps running on the day list and the next exercise. `WorkoutPreferences` (UserDefaults, like lb/kg), `HeightUnit`, `RestTimer` + `WorkoutSettingsTests`. Not done: Default Time (no timed exercises), a notification when rest ends with the app in the background, and the timer doesn't survive quitting the app | User request (direct, 2026-09-22, screenshot of another app's Workout settings) | Done — checked in the simulator 2026-09-22 (auto-start, carrying over to the day list, +15s, Skip; test set unchecked and preferences put back afterwards) |
| P2 | Split Profile page into subpages to reduce visual overload — Profile is now a three-row overview: **Personal Info** (summary "Male · 25 · 170 cm · Sedentary" → page with height, birth date, sex, activity), **Goal** (inline picker — a page for one picker would just add a tap), **Daily Targets** (summary "2,000 kcal · 150P · 200C · 65F" → page with the four fields and the macro-consistency hint; the widget refresh moved there). A footer points to the Goals card for goal weight, steps and lb/kg. Height got a visible label. `ProfileViewModel` summaries + `ProfileSummaryTests` | Dislikes → General UI (2026-09-08, "Profile page needs subpages") | Done — checked in the simulator 2026-09-22 |
| P1 | My Meals recipes: build a meal from existing foods (97d8f36), show/edit its ingredients while logging (872e9f8, 4ec4ce1), flexible serving units + fraction input (cdb333f), consistent rounded display everywhere (614f4fe), and edit a saved meal's ingredients after the fact via swipe-to-edit (92cdcef) | User request (direct, 2026-09-12 → 2026-09-15, not from the log below) | Done (92cdcef) |
| P2 | New Food form asks for macros per the entered serving size (e.g. "36g, as printed on the label") instead of per 100g, converting to the stored per-100g value at save time | User request (direct, 2026-09-15) | Done (6b9da81) |
| P1 | Fix My Meals tab picking up manually-added plain foods (no brand looked the same as a meal) — added an explicit `FoodItem.isMeal` flag, split the old Recents tab into History → Recents + a permanent Foods Manually Added section, and reworded the not-found search state to "Item not found in database" | User request (direct, 2026-09-15, "I just made rwoaw as an example and realized a flaw...") | Done (06e67a2) |
| P2 | Let a manually-added (non-meal) food's macros/serving size be edited after creation, the same swipe-to-edit affordance My Meals rows got in 92cdcef — right now Foods Manually Added only supports delete | Follow-up from the row above | Done (da4b4f6) |
| P1 | Training plan: create a weekly routine by picking training weekdays (split follows the count — 3 days → Push/Pull/Legs, 5 → Push/Pull/Legs & Abs/Upper/Lower), Current Plan card with today's workout, expanded week view (calendar icon) with reorder and routine editor (ellipsis) | User request (direct, 2026-09-19, whiteboard sketch) | Done (d4b9f61) |
| P2 | Show body weight and lift weights in lb (default) or kg via a toggle on the Goals card; stored in kg underneath; Log Weight sheet shortened and Notes field removed | User request (direct, 2026-09-19) | Done (a2003ed, ca6b473) |
| P2 | Starter exercise catalog (38 common lifts, seeded once) and day-based "Suggested" exercises in the picker — the picker was empty on a fresh install | Found while testing the plan feature | Done (60f1dc9) |
| P2 | Progress body map: front/back figures colored Beginner → World Class per muscle from logged lifts vs. bodyweight, tenure-capped; muscle-highlight thumbnails on exercise rows | User request (direct, 2026-09-19, whiteboard sketch + reference image) | Done (b581523) — first pass, drawing needs polish; see next steps |
| P2 | Body map polish (smooth curved figures, clearer untrained muscles, reshaped traps, six-pack abs) and a Level/Weekly toggle showing sets per muscle this week; `WeeklyMuscleVolumeTests` | Next steps on the Training page, item 2 (2026-09-19 first pass) | Done — checked in the simulator 2026-09-22 |
| P3 | Nicer-looking exercise graph / add a workout-progress graphic — Exercise Progress redesigned: best estimated 1RM, progress to the next strength level for that lift (`LiftStandard`), one-line chart with a dashed target, date labels, tap-to-inspect; also fixed "% of best 1RM" comparing today's sets against themselves | Dislikes → Workouts (2026-09-08, "exercise graph doesn't look good") + Suggestions → Workouts (2026-09-08, workout-progress graphic) | Done — checked in the simulator 2026-09-22 (one-session data only) |
| P1 | Tracking screen: the first time you do an exercise, the weight has to be typed on every set — rows are only prefilled when the screen opens, so typing 95 lb in set 1 leaves sets 2–4 at 0 lb, and Add Set copies the empty row rather than the one just logged — logging a set now fills its weight × reps into the later rows that have no weight yet, and Add Set copies the last row that has one | Simulator pass (2026-09-22) | Done (fc7d42a) |
| P1 | Edit Routine silently deletes a day's exercises when that day's name drops out of the new split (e.g. 5 → 4 days removes Pull and its exercises with no warning) — the editor now shows "Pull's exercise will be removed." under the split preview; the day-matching rule was pulled out into `RoutineTemplate.match` and unit-tested (`RoutineTemplateTests`) | Simulator pass (2026-09-22) | Done (ab0bd10) |
| P3 | Edit Routine carries exercises to the *first* day with the same name, so they can move day (4-day Upper/Lower: Saturday's Lower exercises land on Tuesday's Lower) | Simulator pass (2026-09-22) | Triaged |
| P2 | Log Workout (unplanned) sheet has no Cancel button — swipe-down is the only way out — added Cancel to it and to its Add Set sheet, which had the same gap | Simulator pass (2026-09-22) | Done — checked in the simulator 2026-09-22; that sheet was later replaced by `UnplannedWorkoutView` (Done button, nothing to cancel) |
| P2 | Plan editing gaps: rep ranges (`targetRepsMax`), Move Up/Down within a day, name no longer repeated on the tracking screen, New Exercise defaults to the day's suggested group; plus a retry for a launch crash when the app and widget migrate the store at once | Next steps on the Training page, item 5 | Done — checked in the simulator 2026-09-22 (plan put back to 3 × 10 afterwards) |
| P1 | Faster unplanned-workout logging — picker first, then the plan's per-set tracking screen, sets saved on check; 12 → 8 taps for 3 sets of a new exercise; old draft form deleted; Cancel added to the exercise picker and New Exercise form | Next steps on the Training page, item 4 + discovery doc success criterion 2 | Done — checked in the simulator 2026-09-22 (test sets unchecked afterwards) |
| P3 | No way to delete an extra, unlogged row added with Add Set on the tracking screen — rows past the baseline (the plan's set count, or the default sets for an unplanned exercise) show a red minus badge on the set number while unlogged; tapping it removes the row and the rest renumber. Baseline rows can't be removed (`buildRows` would add them back on the next visit), and a logged row is removed by unchecking it, as before. Not a swipe: the screen deliberately isn't a `List` | Simulator pass (2026-09-22) | Done (50884c7) — checked in the simulator 2026-09-22 (unplanned Barbell Curl: 5 rows → minus on 4 and 5 only; removing 4 renumbered 5; a logged extra row loses the badge; test set unchecked afterwards) |
| P3 | Medium widget lists macros Carbs / Fat / Protein; the app uses Protein / Carbs / Fat | Simulator pass (2026-09-22) | Triaged |
| P3 | Workout History rows show only date + set count, not the plan day ("Pull") or exercises | Simulator pass (2026-09-22) | Triaged |
| P1 | Steps goal with a bar chart (whiteboard Goals card) — `StepEntry` (one total per day; logging a day again replaces it), `UserProfile.stepGoal` (default 10,000, migrates existing stores), Steps row on the Goals card, Steps screen with 7/30-day bars (green when the goal is met), dashed goal line, and average / goal-met counted over logged days; `StepsViewModelTests` | User request (direct, 2026-09-19, whiteboard sketch) | Done (a46cfe9) |

Priority scale: **P1** (actively annoying, fix soon) / **P2** (worth doing, no rush) /
**P3** (nice-to-have, may never happen). Status: `Triaged` → `In Progress` → `Done` (link the
commit) / `No change needed` (verified the behavior already exists — say how you checked) /
`Won't Fix` (say why — same spirit as SPEC.md §7's "edit and explain why" convention).

## Likes

*(newest first)*

- 2026-09-07 (General UI) — Nutrition breakdown showing calories, protein, carbs, and fat
  with how much of each is remaining. The individual progress bars per macro make it easy to
  see at a glance which ones are on track vs. which need attention, without doing the
  subtraction yourself.

## Dislikes

*(newest first)*

- 2026-09-08 (Nutrition) — No brands or existing foods to search — every food has to be
  manually created before it can be chosen under "Choose Food." No lookup against a food
  database (barcode scanning aside, which only helps for items with a barcode).
- 2026-09-08 (Nutrition) — No way to delete a food entry once it's logged wrong.
- 2026-09-08 (Nutrition) — Serving size is only in grams — no oz (or other unit) option.
- 2026-09-08 (Nutrition) — The day's logged-food list takes up too much space once more
  foods are added — doesn't scale visually as the list grows.
- 2026-09-08 (Nutrition) — The food history graph isn't preferred — it doesn't show calories
  or how close calories are to the target, so it's unclear what the graph is actually
  communicating.
- 2026-09-08 (Nutrition) — Food history would also take up too much space (vertically and
  horizontally) as more food entries accumulate — same scaling problem as the daily log.
- 2026-09-08 (Nutrition) — Food entries in food history don't show their macros — only
  seeing part of the picture there.
- 2026-09-08 (Body) — The Body page feels unnecessary as its own page — having weight on a
  separate page from workouts makes the flow inefficient to use.
- 2026-09-08 (Workouts) — The Workouts page lacks visual appeal, and logging sets/workouts
  takes too long to set up each time.
- 2026-09-08 (Workouts) — The exercise graph doesn't look good.
- 2026-09-08 (Insights) — The Insights page doesn't need to be its own separate page.
- 2026-09-08 (General UI) — The Profile page needs subpages — too much visual overload on
  one screen.
- 2026-09-07 (General UI) — The nutrition section takes up too much vertical space — the
  progress bars don't need to fill all the excess area they're currently given. Want a more
  compact layout that leaves room for other content on screen without scrolling as much.

## Suggestions

*(newest first)*

- 2026-09-08 (Nutrition) — Clicking on a nutrition/macro should show which foods contributed
  to that macro's total for the day — a breakdown, not just the aggregate number.
- 2026-09-08 (Insights) — Instead of a separate Insights page, use an info ("i") icon at the
  point of relevance (e.g. next to a weight plateau or strength-stall callout) that shows
  where that recommendation/data point comes from. Addresses the "Insights doesn't need its
  own page" dislike above by surfacing the same info in context instead of a dedicated page.
- 2026-09-08 (Nutrition) — Add a way to filter/hide macros and view just calories + protein.
  (Same idea as the 2026-09-07 suggestion below — a toggle between a reduced and full macro
  view.)
- 2026-09-08 (Nutrition) — Larger variety of food options and brands — look into existing
  food databases to integrate rather than manual-only entry. *(Follow-up: worth a short
  research pass — see note below.)*
- 2026-09-08 (Workouts) — Add a workout-progress graphic (e.g. showing intermediate progress
  toward a lift goal), not just raw numbers.
- 2026-09-08 (Body) — The date on a logged weight entry should default automatically
  (today) instead of requiring it to be entered manually every time.
- 2026-09-07 (General UI) — Condense protein, carbs, and fat into a single compact row
  instead of three separate full-size blocks. Keep calories as its own prominent/full-width
  row since it's the primary number people scan for. Add a way to filter/toggle between
  "calories + protein only" and "calories + protein + carbs + fat" so people who only care
  about protein aren't forced to look at the full breakdown every time. (Addresses the
  General UI dislike above.)
