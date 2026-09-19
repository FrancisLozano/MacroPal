# Discovery — Workouts & Body Redesign

**Status:** In progress — Option 2 signed off and largely built (2026-09-19); see "What shipped" below
**Date:** 2026-09-14 (discovery), updated 2026-09-19
**Source:** [usability-notes.md](usability-notes.md) backlog (Body + Workouts items)

## Problem statement

Body and Workouts currently ship as two separate tabs (see [RootView.swift](../MacroPal/MacroPal/Views/RootView.swift)) with no shared surface, but the actual complaint from daily use isn't "each page is bad in isolation" — it's that splitting them is the wrong information architecture for how the app is actually used, and the Workouts page itself is slow to log against. Treated as two separate backlog items, this would be two small patches. Treated as one diagnosis, it's a single information-architecture and interaction-speed problem.

## Current state (grounded in code + logged feedback)

- **Body** is a standalone tab (`WeightHistoryView`) with its own history list, trend chart, and goal-weight editor. It has one real open complaint: *"having weight on a separate page from workouts makes the flow inefficient to use"* (Dislikes → Body, 2026-09-08). Its only other backlog item (weight-entry date auto-fill) was already verified as working, no code issue there.
- **Workouts** is a standalone tab (`WorkoutHistoryView`, `LogWorkoutSessionView`, `ExercisePickerView`, `ExerciseProgressView`) with two open complaints: *"lacks visual appeal, and logging sets/workouts takes too long to set up each time"* (Dislikes → Workouts, 2026-09-08, P1) and *"the exercise graph doesn't look good"* (Dislikes → Workouts, 2026-09-08, P3, tied to a suggestion for an intermediate-progress graphic).
- Both are body-composition/training data that gets logged around the same gym session in practice, weigh in, then train, but the app makes you leave one tab and enter another to do it.

## Root cause

The friction isn't visual polish on either page in isolation, it's that the tab split doesn't match the actual logging workflow, and on top of that, the Workouts logging flow itself (`LogWorkoutSessionView` at 175 lines, `ExercisePickerView` at 126 lines) has enough steps that it was flagged as slow independent of the IA problem.

## Options considered

1. **Leave both as separate tabs, just restyle each.** Fixes visual appeal but not the "inefficient flow" complaint, which is specifically about the split existing at all. Rejected, it treats a structural complaint as a cosmetic one.
2. **Fold Body into Workouts as a single "Training" tab** (weight entry as a lightweight card/section alongside session logging, one entry point for a gym session). Directly answers the Body complaint and gives room to also address Workouts' speed and visual complaints in the same pass, since the whole surface is being touched anyway.
3. **Fold Workouts into Body instead.** Weight tracking is lower-frequency and lower-friction than a workout session (usually a single number vs. multiple sets/exercises), so it should be secondary content on a page whose primary job is fast session logging, not the other way around. Rejected for that reason.

## Recommendation

Option 2: merge into a single Training-oriented surface where a weigh-in is a fast secondary action and workout logging is the primary flow, and use the redesign to also cut down the steps in `LogWorkoutSessionView`/`ExercisePickerView` and improve the exercise progress graphic. One coherent change instead of three disconnected patches, same shape as the food logging rework.

## Success criteria (stated before building, so the readout can check against it)

- The "separate page, inefficient flow" complaint is closed: weight and a workout session can both be logged without switching tabs mid-session.
- Fewer taps/screens to log a full set than the current `LogWorkoutSessionView` flow (baseline to be measured against current build before changing it).
- The exercise progress view communicates progress toward something (a lift goal or trend), not just a raw plotted history.

## Open questions

- Does the merged tab need a new name (e.g. "Training") or does "Workouts" absorb Body content under its existing name?
- Should the goal-weight editor stay a standalone sheet or move into a shared "Training" profile-ish section?

## Decisions (2026-09-19)

- Option 2 approved: one **Training** tab.
- Open questions answered: the tab is named "Training"; the goal-weight editor stayed a small
  sheet, now opened from the Goals card (the full weight history/chart is one tap deeper).
- The design grew beyond the original recommendation, from the user's whiteboard sketch: a
  progress body map on top, a Current Plan card (today's workout; tap for the week), then
  Goals (goal weight line graph; steps goal bar chart). The plan and body map were not in
  this doc's original scope.

## What shipped

| Commit | What |
|---|---|
| 4d4f8dc | Body + Workouts tabs merged into Training |
| 41b27b9, a2003ed, ca6b473 | Goals card; lb/kg toggle for body weight and lifts |
| d4b9f61 | Workout plan models, Current Plan card, week view, routine editor |
| 60f1dc9 | Starter exercise catalog + day-based suggestions |
| 3c6d1d3 | Exercise list + per-set tracking screen (supersedes the inline cards from 21c280e) |
| b581523 | Body map with muscle levels; scrolling Training page |

## Success criteria — where they stand

1. *Weight and a workout session loggable without switching tabs* — **met.**
2. *Fewer taps than the old `LogWorkoutSessionView` flow* — **met for plan-driven logging**
   (one check per set, prefilled from the last set); **unmet for unplanned workouts**, which
   still use the old flow, and the baseline tap count was never measured.
3. *Exercise progress communicates progress toward something* — **not done.**
   `WorkoutProgressChart` is unchanged. (The tracking screen's "% of best 1RM" bar and the
   body map are new progress signals, but not the chart the criterion was about.)

## Implementation notes (for whoever touches this next)

- **Adding a `@Model` takes two steps:** list it in `AppSchema.models` (`Models/AppSchema.swift`,
  the one schema shared by the app and the widget), and add its file to the widget target's
  membership (the "membershipExceptions" block in `project.pbxproj`). The widget opens the
  same on-disk store as the app, so the two must never have different schemas. Forgetting the
  membership step fails the widget build rather than failing silently. (This used to be three
  hand-edited places — two separate schema lists plus membership — until the list was shared.)
- Buttons stay out of `List` sections whose shape changes (see the Daily Log chevron bug).
  The plan day and tracking screens use `ScrollView` + cards for that reason; the picker's
  Suggested/All switch sits above its `List`.
- Muscle levels are a judgement call — thresholds, tenure caps and per-exercise muscle
  involvement are documented in [usability-notes.md](usability-notes.md) and live in
  `MuscleLevelEngine.swift` / `ExerciseMuscleData.swift` (covered by `MuscleLevelEngineTests`).
- Exercise → muscle mapping is by exercise *name* (matches the starter catalog); a
  user-created exercise falls back to a coarse guess from its muscle group. No schema change
  was needed for the finer muscles.

## Remaining work

See "Next steps on the Training page" in [usability-notes.md](usability-notes.md) — steps goal
and chart, body map polish, exercise progress graphic, unplanned-workout logging speed, plan
editing gaps.
