# Exercise Screen Plan (Workout / Overview / Progress)

**Status:** Built — all three steps done 2026-09-23
**Written:** 2026-09-23 · Next tasks step 2 in [usability.md](usability.md#next-tasks-as-of-2026-09-23)
**Source:** Suggestions → Training (2026-09-23): tabs, Workout tab, Overview tab, Progress tab.
Backlog rows: the P1 exercise screen, the P2 Progress tab and the P2 Overview tab.

## What it replaces

`ExerciseTrackView` is the screen today. Both a plan day's exercise (`PlanExerciseRow`) and
an unplanned workout (`UnplannedWorkoutView`, which can be back-dated) open it. Each row is
reps × weight prefilled from your last set, with a "% of best" bar and a check to log it.
Add Set adds rows, and a red minus removes extra ones.

The new screen keeps the same two entry points and the same `init`s, so its callers don't
change. It becomes `ExerciseScreen` with a segmented **Workout / Overview / Progress** control
under the navigation title (exercise name, inline). The current body turns into
`ExerciseWorkoutTab`.

## Decisions it builds on (usability.md → Decisions worth remembering)

- **Sets save as you type.** A row is saved once both boxes hold a valid value, updated when
  either box changes, and deleted when a box is cleared. Complete Exercise only finishes.
- **No GIFs.** Overview has just Muscles Involved.

## Step 1 — Workout tab (P1)

**Built 2026-09-23** — how it differs from the plan below:
- Still `ExerciseTrackView`, no tab control yet: a control with one tab is noise. The rename
  to `ExerciseScreen` + segmented control comes with the Progress tab.
- The rest timer stays at the **bottom**, as on the day list; it's the same shared bar.
- **Unlogging takes clearing both boxes.** Clearing one box of a logged set puts its value
  back; on an unlogged row, typing only one box takes the other from the suggestion.
- Focusing a box **selects its number**, so typing replaces it (the cursor otherwise landed
  in front of the number).
- Suggestions from a saved set carry down only to rows with no last session; rows that have
  one keep suggesting it.
- Logic in `SetRow` (`SetRowTests`), "Last:" in `WorkoutViewModel.lastSessionSets` /
  `lastValue` (`LastSessionSetsTests`). The unused `WorkoutViewModel.lastSet` is gone;
  `bestEstimated1RMKg` stays for the Progress tab.

**Layout** (reference: Caliber's set entry):

```
 Rest  1:30  [ −15 ] [ +15 ] [ Skip ]          ← RestTimerBar, moved to the top
 3 sets × 8–10 reps                  ⓘ
 ┌───────┬──────────────┬──────────────┐
 │ Set 1 │ [ 135 ] lbs  │ [  10 ] reps │
 │       │ Last: 135    │ Last: 10     │
 ├───────┼──────────────┼──────────────┤
 │ Set 2 │ [     ] lbs  │ [     ] reps │
 │       │ Last: 135    │ Last: 8      │
 └───────┴──────────────┴──────────────┘
 [        Complete Exercise        ]
```

- **Boxes start empty; the last value is the placeholder.** Today's rows are prefilled, which
  is fine behind a check. With save-as-you-type, a prefill would count as logged the moment
  the screen opened. So the box shows last session's value in gray, and "Last: 135" sits
  under it. **Complete Exercise fills any empty box from its placeholder** before finishing,
  so doing a repeat workout still means typing nothing.
- **"Last:" is per set number.** It comes from the last *earlier* session with this exercise,
  set by set: set 2 shows that session's set 2, and falls back to its final set when the
  session had fewer. New `WorkoutViewModel.lastSession(for:before:)` + tests.
- **Saving.** A row saves when it's valid and focus leaves it (`onChange(of: focus)`), not on
  each keystroke, because typing "135" shouldn't write 1, 13 and 135. It goes through the
  existing `viewModel.logSet(...)` (so `planDayName` is still recorded), then edits that
  `WorkoutSetEntry` in place. Clearing a box deletes the entry. Fill-forward keeps working:
  saving set 1 fills the *placeholders* of later empty rows, not their values.
- **Complete Exercise:** fill empty rows from placeholders, save them, dismiss the keyboard,
  start the rest timer (if Automatic Rest Timer is on), and pop back to the day list. That
  list already shows ✓ once the logged count reaches the target, so no new "completed" field
  is needed. The button is disabled until at least one row would save.
- **ⓘ next to the target:** "Sets come from your plan. To change them, use ⋯ → Edit Sets &
  Reps on this exercise in the day's list." For an unplanned exercise it points to Profile →
  Workout → Default Sets. **Add Set and the red minus go away**, as asked.
- **Kept:** Profile → Workout's lb/kg, reps-first / weight-first column order and rest timer
  settings. **Dropped from the row:** the "% of best" bar. It doesn't fit the Caliber-style
  row, so it moves to the Progress tab as a data point, and the Show PRs toggle moves with it
  (or goes; see open questions).

**Tests:** `lastSession`/per-set "Last" lookup; a row's save / update / delete transitions,
pulled into a small `SetRowState` value type so they can be unit-tested without the view;
Complete filling from placeholders.

**Simulator check:** plan day → exercise → type set 1 → back out → reopen: set 1 is still
there. Tap Complete on untouched rows: they log at last session's values, the day list shows
✓, and the rest timer runs. Then an unplanned, back-dated exercise. Put test sets back
afterwards.

## Step 2 — Progress tab (P2)

**Built 2026-09-23.** `ExerciseScreen` holds the segmented control (Workout / Progress) and
the title; `ExerciseProgressTab` is the old Exercise Progress minus its picker, plus History
(`WorkoutProgressViewModel.history`, `ExerciseHistoryTests`). Volume is shown per History row
rather than as a chart. Workout History (and `WorkoutSessionDetailView`) are deleted, so
swiping a History day deletes that exercise's sets from it — the only way left to remove
past sets. The screen is on the grouped gray background with white cards, like Training.
**Changed the same evening:** the tab is measured in volume, not 1RM — total volume, this
week vs last, a volume-per-session bar chart, then History (see usability.md Decisions).

- That exercise's **Exercise Progress** (best estimated 1RM, next-level target, chart, from
  `ExerciseProgressView`, minus its exercise picker), plus **volume per session** as a second
  line or bars, since volume is now what drives the body map.
- Then **its history**: past sessions for this exercise only, newest first, each set as
  "135 × 10".
- Once it's in: **remove the History / Progress shortcuts from the Training page**. Only
  "Log an Unplanned Workout" is left in that card. `WorkoutHistoryView` (all exercises)
  stays reachable from ... *open question below*.

## Step 3 — Overview tab (P2)

**Built 2026-09-23** (`ExerciseOverviewTab`), as planned. The control reads Workout /
Overview / Progress. Primary is involvement ≥ 0.8 (the thumbnail's existing solid/light
line) rather than exactly 1.0, now in `ExerciseProfile.primaryMuscles` for both.
Added after review: Primary / Secondary beside the figure, and How to Do It + Common
Mistakes cards (`ExerciseGuides`, starter exercises only).

- **Muscles Involved:** the existing body figure (`BodyFigure`) with this exercise's
  muscles filled: primary (involvement 1.0) solid, secondary (< 1.0) light. `Primary` /
  `Secondary` lists under it come from `ExerciseMuscleData`. **Flip View** switches front and
  back, and starts on whichever side has the primary muscle.
- No GIF (decided). If a licensed source turns up, it goes above the figure.

## Open questions (small, can be answered while building)

1. ~~Where does the all-exercise Workout History live?~~ Dropped (user, 2026-09-23).
2. **Show PRs** in Profile → Workout: move it to control the "% of best" line on the Progress
   tab, or delete it?
3. Unplanned workout: after Complete Exercise, go back to the exercise picker (to add the
   next one) or to the Training page?
