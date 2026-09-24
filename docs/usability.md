# Usability Notes & Feedback Log

**Status:** Living document — ongoing, not tied to a phase
**Started:** 2026-09-06 · **Last updated:** 2026-09-23 (night)

## Start here (as of 2026-09-23, night)

**Where things stand.** All 13 Training / Goals suggestions from 2026-09-23 are built,
committed and pushed to `origin/main`; the working tree is clean. **Nothing is being built
right now** — the next step is the week of real use (Next tasks). The last piece, **Edit
Routine by message**, was built at night: a split menu plus a "Describe it" field that fills
in the form with Apple's on-device model; on request, "PPL twice a week" (→ 6 days PPL) and
"ppl and U/L" (→ the new PPL + U/L split) were then made to work. Plan, what changed and a
table of how messages read: [routine-by-message-plan.md](routine-by-message-plan.md). The
rest of the day's work:

- **Exercise screen** (a plan day → an exercise, or an unplanned workout): a
  **Workout / Overview / Progress** switch. Plan and what changed while building:
  [exercise-screen-plan.md](exercise-screen-plan.md).
- **Muscle colors come from lifetime volume**, not 1RM, and all 1RM code is deleted. The
  numbers are under **Decisions worth remembering** and **Things to know about the muscle
  levels**; the constants are in the **Things you might want adjusted** table.
- The user's answers to every open question are recorded under **Decisions**. None are
  pending.

**What the app has now**, so you know what you're judging:

- **Nutrition** — day picker, calorie ring segmented by macro (tap the pie to switch between
  protein only and all macros), Macros card (tap a macro → which foods it came from), protein
  callout, a Breakfast/Lunch/Dinner carousel with quick-add. Food search (Open Food Facts),
  barcode scanning, My Meals built from foods, oz/cups/tbsp/tsp and fractions. Daily Log
  history.
- **Training** — body map colored by volume level (ⓘ → How Levels Work: each level in lb/kg
  for your bodyweight plus the time it needs), Current Plan card ("Gym Workout"; tap to
  expand the week in place; ⋯ → drag to reorder or Edit Routine — weekdays, a split menu
  (Recommended / Upper/Lower / PPL / PPL + U/L / Full Body) and, with Apple Intelligence, a "Describe it"
  field that fills both in), Goals card (weight + steps,
  each with a + to log; tap the value for its history and chart), Log an Unplanned Workout.
  No all-workouts history (removed on request); past sets live in each exercise's Progress.
- **Exercise screen** — *Workout*: a row per set (reps and lb boxes, "Last:" from the
  previous session), boxes start empty with the suggestion in gray, sets save when you leave
  the row, clearing both boxes unlogs a set, Complete Exercise logs untouched rows at their
  suggestion and goes back, ⓘ says where to change the set count, rest timer. *Overview*:
  figure with Primary / Secondary beside it, Flip View, How to Do It, Common Mistakes with
  fixes (text for all 38 starter exercises in `ExerciseGuide.swift`; none for exercises you
  create). *Progress*: total volume, this week vs last, volume-per-session bars, History
  (swipe a day to delete it).
- **Profile** — Personal Info, Workout settings (set-row order, default sets/reps, rest
  timer; Show PRs was removed), Goal & Daily Targets, Units (lb/kg, cm or ft/in).
- **Widget** — small (calorie ring) and medium (calories + Protein / Carbs / Fat).

**Simulator notes for the next session:**
- iPhone 17 Pro, `A30B354E-BDCE-4007-B1A0-9F79091EE9E5`. The simulator tool's screenshot
  fails there, so use `xcrun simctl io … screenshot` instead.
- A full `xcodebuild test` (with UI tests) shuts the simulator down. Run
  `-only-testing:MacroPalTests`, or boot it again afterwards.
- Today's Cable Crunch sets in the simulator (3 × 30 lb: 8, 12, 12) are the user's own.
  Don't delete them while testing.
- Its muscles all show Beginner: there isn't enough volume logged to reach Novice.
- The simulator has Apple Intelligence (through the Mac), so the "Describe it" field shows
  and works there. When testing Edit Routine, **Cancel** — Save rewrites the user's 5-day
  plan (Mon/Tue/Wed/Fri/Sat, Push/Pull/Legs & Abs/Upper/Lower).
- **Trying prompt wording:** a small `swiftc` script on the Mac with `import FoundationModels`
  runs the same on-device model as the simulator, and is much faster than typing into the
  app. The model is weak (~3B): it refused a first set of instructions as "sensitive", made
  up weekdays and day counts, and couldn't spot off-topic messages. So anything the text says
  plainly is read in code (`MessageCues`), with the model as the fallback — keep new rules
  there, with a test, rather than only tweaking the prompt.
- Model failures are logged: `xcrun simctl spawn booted log show --last 5m --predicate
  'subsystem == "com.francislozano.MacroPal" AND category == "RoutineAssistant"' --info`.

## Next tasks (as of 2026-09-23, night)

1. **Tune the volume thresholds** once real weeks are logged: `MuscleLevelEngine.levelMinimumBodyweights`
   (90 / 600 / 2,500 / 7,500 / 15,000 bodyweights), the tenure months, and the bodyweight shares
   in `ExerciseMuscleData.swift`. The ⓘ sheet follows the constants.
2. **Keep logging** Likes / Dislikes / Suggestions during the week of use below, then triage
   them at the end of the week — including how Edit Routine by message does with your own
   wording (note the exact message and what it filled in).

**Small leftovers, fine to do anytime:**
- `WorkoutSession.planDayName` / `exerciseNames` are now only used by `WorkoutSessionTests`,
  since Workout History was the only screen that used them. Delete them with their tests, or
  keep them if a history screen comes back.
- `Insight.RuleIdentifier.strengthStall` stays so old stored `Insight` rows still decode.
  The rule itself is gone.

## A week of real use (2026-09-24 → 2026-09-30)

The raw log went from 2026-09-08 to 2026-09-23 without an entry, and everything in between was
built from those entries. This week is for collecting the next round.

### Every day

1. Log real food and any workout, weigh-ins and steps, the way you normally would.
2. When something is annoying, slow, confusing, or you wish it were different, add one bullet
   under **Likes / Dislikes / Suggestions** at the bottom — see **How to log an entry**. One
   line is enough; write it while you still remember which screen and what you tapped.
3. If you want something **adjusted** (a number, a default, a wording, a size), check the
   table below first — many of these are a one-line change, and naming the row makes the fix
   quick.

### What to watch for

- Does the Training page feel as calm as Nutrition now?
- The Current Plan card: is expanding the week in place better than a separate page, and is
  drag-to-reorder (⋯ → Reorder Workouts) easy to find?
- Do you miss the Weekly body-map view (sets per muscle this week)?
- Are the level targets fair — does a level come too easily or feel out of reach?
- Does the rest timer get in the way, or do you miss it when the app is in the background?
- Is anything still slow to log — count the taps if it feels like too many.
- Do the callouts show up when they should, and are they useful or noise?
- Edit Routine by message: does it read what you type? Note any message it gets wrong.

**Not seen in the app yet** — note it if you run into one: the protein callout (needs 4 logged
days), a muscle reaching Novice on the body map, a Progress chart with several sessions, ft/in height entry, a "Push + Pull" History label.

### Things you might want adjusted — and where they live

Values as of 2026-09-23. "In app" means you can change it yourself; the rest are code.

| Adjustment | Now | Where |
|---|---|---|
| Calorie / macro targets | 2,000 kcal · 150P / 200C / 65F | In app: Profile → Goal & Daily Targets |
| Step goal | 10,000 | In app: Goals card → tap today's steps → Daily Goal |
| Goal weight | 154.3 lb | In app: Goals card → tap the goal weight → Goal Weight |
| lb/kg, cm or ft/in | lb, cm | In app: Profile → Units & Measurements |
| Default sets / reps for new exercises | 3 × 10 | In app: Profile → Workout |
| Rest time, auto-start rest timer | 120 s, off | In app: Profile → Workout |
| Set rows reps-first or weight-first | reps-first | In app: Profile → Workout |
| Volume per level (too easy / too hard) | 90 / 600 / 2,500 / 7,500 / 15,000 bodyweights | `MuscleLevelEngine.levelMinimumBodyweights` (the ⓘ sheet follows) |
| Bodyweight share per rep of a bodyweight move | push-up 0.65, dip 0.9, pull-up 1.0, hanging leg raise 0.3, ab wheel 0.5, plank 0.1 per logged rep (as seconds) | `bodyweight(…)` entries in `ExerciseMuscleData.swift` |
| Female volume | divided by 0.65 | `MuscleLevelEngine.femaleFactor` |
| Time required per level | 0 / 2 weeks / 3 / 12 / 36 / 60 months | `MuscleLevelEngine.levelMinimumMonths` (the ⓘ sheet follows) |
| Protein callout | 7-day avg < 90% of target, ≥ 4 logged days | `ProteinIntakeRule` |
| Weight-plateau callout | < 0.1% change/week, ≥ 13 days of data | `WeightPlateauRule` |
| Steps average / goal-met | logged days only | `StepsHistoryView.summary` |
| Weekly body-map view | removed | git history before `373f28e` |
| RPE / session notes on unplanned workouts | removed | old `LogWorkoutSessionView`, git history before `1737ed2` |
| Rest-timer choices | 30 s – 5 min | `WorkoutPreferences.restChoices` |
| Splits, and which days a count spreads to | Recommended, Upper/Lower, PPL, PPL + U/L, Full Body; 3 days → Mon/Wed/Fri | `RoutineTemplate.Split`, `slots(for:daysPerWeek:)`, `defaultWeekdays(count:)` |
| How a message is read | on-device model; weekdays, split names ("PPL", "U/L") and "twice" in code | `RoutineAssistant.instructions`, the `@Guide`s in `RoutineRequest`, word lists in `MessageCues` |

Anything visual (sizes, spacing, colors, wording) — note the screen and what you'd change;
a screenshot or sketch works best, as with the whiteboard for Training.

### At the end of the week

1. Read through the new Likes / Dislikes / Suggestions.
2. Promote what's worth doing into the **Backlog** with a priority (P1 annoying / P2 worth
   doing / P3 nice-to-have) and a link back to the bullet.
3. Decide on the parked follow-ups below — promote, keep parked, or drop.
4. Update the **Snapshot** counts and this section's "Start here" status.

### Parked follow-ups (not yet triaged)

- A notification when the rest timer ends with the app in the background (the timer is one
  shared `RestTimerModel`; it also doesn't survive quitting the app).
- A per-lift goal you set yourself on Exercise Progress (needs a new model field — optional
  or defaulted where it's declared, so no versioned schema is needed).
- HealthKit step import (needs a physical iPhone and permissions).
- Default Time from the Workout settings reference screenshot (only once timed exercises
  exist).
- Bring back RPE / session notes for unplanned workouts, if they're missed.
- Portfolio extras: try the app on a physical iPhone (nothing has been checked on one); move
  the Backlog to GitHub Issues if it grows again (SPEC.md §7 suggests it).

### Watch for: the store retry at launch

The launch-crash retry (`7cfc42b`) is still unconfirmed in a real race. It logs an error
"Opening the store failed, retrying: …" with the reason, then a notice "Opening the store
succeeded on retry" — silence means the first attempt worked. On the next schema change, with
the widget on the home screen, launch the new build and run:

```
xcrun simctl spawn booted log show --last 5m --predicate 'subsystem == "com.francislozano.MacroPal" AND category == "Store"' --info
```

Both messages were checked by forcing the first attempt to fail with a temporary throw
(removed before committing); a normal launch logs nothing.

## Decisions worth remembering

- **Muscle colors come from lifetime volume, not 1RM** (decided and built 2026-09-23). Every
  set's weight × reps is credited to the muscles it works, by involvement, and added up over
  all time. That total ÷ bodyweight ("bodyweights moved") sets the level: Novice 90,
  Intermediate 600, Advanced 2,500, Elite 7,500, World Class 15,000 — a first guess assuming
  about 30 bodyweights a week per muscle early on, rising to about 50. The tenure cap stays,
  so World Class needs 5 years of training however much you lift (user: "world class takes 5
  years or more"); Novice's minimum dropped from 1 month to 2 weeks so ~3 weeks can reach it.
  Since the total only grows, a muscle **never drops a level** after a break (accepted).
  Bodyweight moves count a share of bodyweight per rep plus any added weight. The body map
  and the Progress tab count volume the same way (both dumbbells, machines scaled down, a
  share of bodyweight for bodyweight moves; user, 2026-09-23) — the History rows still list
  each set as logged. Profile → Workout's Show PRs toggle was deleted with the 1RM code. All 1RM code is deleted (`LiftStandard`,
  `OneRepMaxEstimator`, `StrengthStallRule`, the 1RM chart).
- **Edit Routine by message uses Apple's on-device Foundation Models** (iOS 26: no API key,
  no server, free; built 2026-09-23). "4 days a week, upper/lower" becomes a typed
  `@Generable` result (days per week, split) that **only fills in the form** — the user checks
  it and taps Save, which goes through the same `RoutineTemplate.apply` path. Weekdays and
  "is this about a routine" are decided in code, not by the model (it made both up). Without
  Apple Intelligence the field is hidden and the form (weekdays + split menu) is all there is.
  The Claude API was ruled out because it needs a backend to keep the key out of the app.
- **A split is chosen, not only derived from the day count** (2026-09-23). Recommended keeps
  the old table (4 days → Upper/Lower, 5 → PPL + Upper/Lower…); a named split repeats in order
  (PPL on 4 days → Push, Pull, Legs, Push). The split isn't stored: the editor reads it back
  from the plan's day names (`inferredSplit`), with Recommended winning a tie.
- **No exercise GIFs for now.** The Overview tab has just Muscles Involved. The free GIF
  databases have unclear licenses.
- **Progress is measured in volume, not 1RM** (user, 2026-09-23). The Progress tab shows
  total volume, this week vs last (calendar weeks), a volume-per-session bar chart and the
  history; the 1RM summary, Beginner → Novice bar and stall callout were removed from it.
- **No all-workouts history.** Workout History was removed with the Progress tab (user,
  2026-09-23): past sets are seen, and deleted, per exercise in its Progress tab.
  `WorkoutSetEntry.planDayName` is still recorded and shows in each History row.
- **Sets save as you type; Complete Exercise only finishes.** Leaving the exercise screen
  midway loses nothing. Boxes start empty with last session's value as the placeholder, and
  Complete fills empty boxes from those placeholders, so a repeat workout is still one tap.
  Details in [exercise-screen-plan.md](exercise-screen-plan.md).

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
- **The plan day is stored per set, as a copied name** (`WorkoutSetEntry.planDayName`), not
  on the session and not as a link to `PlanDay`. A session's label ("Pull", "Push + Pull") is
  derived from the sets it still has, so unchecking a plan set takes the label with it, and
  history survives plan edits. A session-level field was tried first and kept a stale label.
  Sessions from before 2026-09-22 have no day and show the date.
- **The levels explainer reads the engine's own numbers** — `MuscleLevelEngine`'s
  `levelMinimumBodyweights` and `levelMinimumMonths` — so the
  ⓘ sheet can't drift from how levels are computed. Change a threshold there and the sheet
  follows.
- **Edit Routine matches days by weekday, then name.** When the split changes, a day keeps
  its exercises on the same weekday if the new split has a day of that name there, and
  otherwise moves to the nearest same-named day (Sat–Sun counts as 1 apart). Closest pairs
  are claimed first, so as many days carry over as the names allow. Since 2026-09-23 the editor
  no longer warns which days' exercises will be removed (user request) — `apply` still deletes
  them, so a split change can drop exercises without notice.
- **Removable set rows:** only unlogged rows *past* the baseline (the plan's set count, or
  the default sets for an unplanned exercise). Baseline rows would just come back the next
  time the screen opens; logged rows are still removed by unchecking.
- **Training is styled like Nutrition but isn't a `List`.** `TrainingSection` draws the gray
  heading + white card from stacks, because the cards are full of buttons and a `List` is
  where the button-detachment bug lives. Any new Training card should use `TrainingSection`
  (title optional, accessory button optional).
- **The Current Plan card expands in place; there's no week page.** Tapping "Gym Workout"
  toggles the week inside the card (remembered in `@AppStorage("trainingShowWeek")`), the way
  the Macros card's pie toggles carbs and fat. Reordering is a mode of the same card: a
  `List` exists only while reordering, for its native drag handles, and holds no buttons
  (Cancel / Save sit below it), so the button-detachment bug can't reach them. Saving calls
  `WorkoutPlan.reorderDays`, which keeps the weekdays and swaps the workouts between them.
- **Lines in the plan card are a 1-pt `Rectangle`, not `Divider()`** — the system hairline
  blurred away at some row positions, so some of the week's lines went missing.
- **The Weekly body-map view is deleted, not hidden** (`WeeklyMuscleVolume`, its tests and
  `VolumePalette`). It's in git history before `373f28e` if it's ever wanted back.

## Details and reference

### History

The 2026-09-19 stretch merged Body and Workouts into **one Training tab**, following
[discovery-workouts-body-redesign.md](discovery-workouts-body-redesign.md) (Option 2) and the
user's whiteboard sketch — body map on top, Current Plan, Goals below. On 2026-09-22 all three
of that doc's success criteria were met, and in the evening the tab was restyled to match
Nutrition. 2026-09-23 closed the last two P3s and the outstanding re-checks; in the afternoon
the user logged the first Training suggestions and the layout ones were built.

### What changed on 2026-09-23

| Commit | What |
|---|---|
| `c908ea1` | Medium widget lists macros Protein / Carbs / Fat, like the app (the small widget is only the calorie ring) |
| `4950b70` | Edit Routine keeps a day's exercises on its weekday — `RoutineTemplate.match` pairs the closest weekdays first; four new `RoutineTemplateTests` |
| `cef4f39` | Re-checks recorded: levels, Exercise Progress and the ⓘ sheet with the corrected 227 lb bodyweight, with sex set to female, and with no weigh-in — all correct |
| `9dd2034` | The launch-time store retry now logs (category `Store`), so a caught migration race is visible |
| `2d971c2` | Shared Xcode schemes committed (they're the only scheme files); the old untracked `scratchpad/` mockup deleted |
| `4b76216` | Log Weight / Log Steps keep typed input when you tap above the sheet; Log Weight gets Cancel and focuses its field on open |
| `9b9b9c5`, `a31ce7a` | 13 Training and Goals suggestions logged (the exercise-screen ones reference Caliber's set-entry and Overview screens, described in words — the screenshots aren't in the repo) |
| `9ccca06` | "Training" title at the same height as "Nutrition" (own large title above the scroll view, empty inline nav title, so no small title appears on scroll); scroll bar hidden. Goals card: tap the goal weight / today's steps for that history, Log is a + button, History buttons gone |
| `b8ced0d` | Goals card + buttons made smaller |
| `5307cdb` | Current Plan card: "Gym Workout" / "5 Days a Week" / "Today: Legs & Abs"; tapping it expands the week in place (like Macros) instead of opening a page (`WeekPlanView` deleted); calendar icon → ⋯ menu with Reorder Workouts (drag handles in the card, Cancel / Save, `WorkoutPlan.reorderDays` + `WorkoutPlanTests`) and Edit Routine (half sheet, days caption and removal warnings gone) |
| `ff37c2d`, `46f6ff5` | "Today: …" is tappable (opens that day), spaced like the week's lines, not bold; the week's lines aren't bold either |
| `9380468`, `7d659f9` | Suggestions triaged; the four decisions recorded (volume levels, on-device AI for Edit Routine, no GIFs, sets save as you type) and the exercise screen planned |
| `7f2e2f5` | Exercise screen Workout tab: set rows with "Last:", suggestions instead of prefills, save as you type, Complete Exercise, ⓘ for the set count, select-all on focus; Add Set / checks / % of best removed. `SetRow` + `SetRowTests`, `LastSessionSetsTests` |
| `9388e7b` | `ExerciseScreen` (Workout / Overview / Progress). Overview: muscles with Primary / Secondary beside the figure, Flip View, How to Do It + Common Mistakes (`ExerciseGuide`). Progress in volume (total, week vs week, bars, History with swipe-delete). Workout History, its detail screen and the 1RM chart deleted |
| `f365400` | Muscle levels from lifetime volume ÷ bodyweight (90 / 600 / 2,500 / 7,500 / 15,000), tenure cap kept (World Class ≥ 5 years, Novice ≥ 2 weeks); How Levels Work rewritten; `LiftStandard`, `OneRepMaxEstimator`, `StrengthStallRule` deleted |
| `e4ac35e` | Progress tab volume counted like the body map (both dumbbells, machines scaled, bodyweight share); Show PRs setting deleted |

### What changed on 2026-09-22

Morning: a simulator pass over everything unverified (no broken features, seven rough edges
logged), fixes for the two worst (`fc7d42a` set-weight prefill, `ab0bd10` Edit Routine warning),
and the steps goal with a bar chart (`a46cfe9`). Then, in order:

| Commit | What |
|---|---|
| `651389f` | Cancel on the Log Workout / Add Set sheets; food-history row closed (already done by `ab68f73`/`4e02e89`) |
| `cb532ed` | Body map redrawn (smooth curves, clearer untrained muscles, six-pack, kite traps) + Level/Weekly toggle (the toggle was removed again in `373f28e`) |
| `ba0d917` | Exercise Progress: best 1RM, progress to the next strength level, one-line chart with a target line, tap to inspect; "% of best" no longer compares today's sets against themselves |
| `1737ed2` | Unplanned workouts use the plan's per-set tracking screen — 12 taps → 8 |
| `7cfc42b` | Plan rep ranges (8–10), Move Up/Down within a day, New Exercise defaults to the day's group; launch-crash retry |
| `dab0aea`, `78417fe` | Tap a macro → which foods it came from (grams + % of the day; no chevrons, no per-food bars — user feedback) |
| `209bc15` | Insights tab replaced by inline callouts with an ⓘ sheet (protein on Nutrition, weight on the Goals card, stalls on Exercise Progress) |
| `be8196a`, `e973f41`, `8e3dbb2` | Profile in sections — Personal / Workout / Goal & Daily Targets / Units & Measurements; Workout settings page (from a reference screenshot) and a rest timer; lb/kg moved off the Goals card; height in cm or ft/in |
| — (simulator data) | The bad weigh-in fixed: the 227 kg entry deleted, re-logged as 227 lb dated 2026-09-22 |
| `50884c7` | Extra, unlogged Add Set rows can be removed (minus badge on the set number, rows past the plan's set count only) |
| `de05aa8` | Workout History rows show the plan day ("Lower"), "date · N sets" and the exercises |
| `373f28e` | Progress card: Level/Weekly toggle, color chips and description removed; an ⓘ opens **How Levels Work** |
| `15466e8` | Training page laid out like Nutrition — gray headings (Progress, Current Plan, Goals) above white cards, section buttons in the headings |

Details for each are in the Backlog rows and the "Next steps on the Training page" list below.

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
   - **Weekly toggle — removed later on 2026-09-22** (user: not needed, the card took too much
     space; see the Backlog row "Progress card: ⓘ instead of the Level/Weekly toggle"). What it
     was, in case it comes back — the code is in git history before that commit
     (Level | Weekly, remembered between launches): colors each muscle by
     sets this calendar week — a main mover (involvement ≥ 0.8) counts 1, an assisting muscle
     (≥ 0.5) counts ½ — in four blue bands, 1–4 / 5–9 / 10–19 / 20+ sets, loosely after the
     "10–20 sets per muscle per week" rule of thumb. `WeeklyMuscleVolume` +
     `WeeklyMuscleVolumeTests`. The week follows the phone's locale (Sunday start in the US).
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

- Level = the muscle's **lifetime volume ÷ bodyweight** (volume divided by 0.65 for women)
  against `MuscleLevelEngine.levelMinimumBodyweights` — a first guess, not from a source;
  expect to tune it after real use. Assisting muscles get credit in proportion to their
  involvement, but only muscles worked at 0.5 or more count as "trained" (colored at all).
- A **tenure cap** stops a burst of volume from skipping the years: 2 weeks for Novice, 3
  months Intermediate, a year Advanced, 3 years Elite, 5 years World Class.
- Dumbbell lifts count both dumbbells; leg press and calf raise are scaled down. Bodyweight
  moves use a share of bodyweight per rep (plank assumes reps are logged as seconds).
- Volume never goes down, so levels never drop after a break.
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
rows and the rest timer (auto-start, carry-over to the day list, ±15s, Skip). In the
evening: removing extra Add Set rows (badge only past the baseline, renumbering, a logged row
loses its badge); Workout History labels (a Lower set labelled the day "Lower", unchecking it
put the date back); both store migrations (app opened first time); the Progress ⓘ sheet with
a 227 lb bodyweight; the Nutrition-style Training layout and the calendar heading button.

**Verified (2026-09-23):** the medium widget's Protein / Carbs / Fat order; Edit Routine 5 → 4
→ 5 days keeping Saturday's Lower exercises on Saturday. Re-checks with the corrected 227 lb
bodyweight, all matching hand-worked numbers: body map (quads, glutes, back all Beginner);
Exercise Progress — Back Squat 180 of 227 lb to Novice, Barbell Row 120.3 of 136.2 lb; the ⓘ
sheet (Novice Squat 225 / Bench 135 lb, Intermediate 340 / 225). With sex set to female the
sheet showed × 0.65 (Novice 150 / 90 lb, Intermediate 220 / 150 lb) and Barbell Row moved to
Novice → Intermediate at 132.8 lb; the calorie and macro targets didn't change. With no
weigh-in the card showed its "Log your weight" line and the sheet showed multiples only with a
"Log your weight to see these in lb" footer. Sex was set back to male, and the weigh-in was
restored by copying back a backup of the store (see Housekeeping).

**Not seen live yet:** the protein and strength-stall callouts (need 4 logged days / 4
sessions of one lift), an Exercise Progress chart with several sessions, the ft/in height
entry, and a "Push + Pull" History label (unit-tested only).

**Not yet verified:** anything on a physical device.

### Housekeeping

- The simulator has leftover test data from these sessions: a "rwoaw" food entry and a
  "Chicken breast bites" entry on 2026-09-19, a Back Squat with 3 sets of 135 lb × 10, a 5-day
  plan (Lower has Back Squat + Bulgarian Split Squat, 3 × 10), one Barbell Row set (95 lb × 8)
  on 2026-09-22, steps for 2026-09-21/22, and one weigh-in of 227 lb on 2026-09-22 (it replaced
  an entry stored as 227 kg — the "227" typed in the wrong unit). None of it is in the repo.
  Every test set logged on 2026-09-22 was unchecked afterwards, the goal was put back to
  Maintain, and the Workout preferences were put back to their defaults. The Pull day in the
  plan has no exercises, so plan-day testing used Lower's Back Squat from the week view.
- The simulator with this data is the **iPhone 17 Pro**; its store is the app-group
  `MacroPal.sqlite` (open it with `sqlite3 -readonly` to check what an edit actually saved).
- The shared schemes (`MacroPal.xcodeproj/xcshareddata/xcschemes/`, MacroPal and
  MacroPalWidgetExtension) are committed as of 2026-09-23 — they're the only scheme files, so
  `xcodebuild -scheme MacroPal` depends on them. The old untracked `scratchpad/` (a Sep 8
  Nutrition gauge mockup, superseded by the ring) was deleted.
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
    the old value — wait a few seconds (up to ~15) before concluding a save failed.
  - Tap coordinates: `simctl io` screenshots are 1206×2622 px for a 402×874 pt screen (3×);
    shrunk to 800 px tall they're ~1.09× the tap coordinates.
  - To test with data removed (e.g. no weigh-in) and get it back exactly: terminate the app,
    copy `MacroPal.sqlite`, `-shm` and `-wal` somewhere, test, terminate again, copy them
    back. Done that way on 2026-09-23 so the 227 lb entry kept its original timestamp.
  - To check that each commit in a split builds on its own, build it from a temporary
    `git worktree` — that's how the three evening commits were checked.
- Adding a database model is now two steps — list it in `AppSchema.models`, and add its file
  to the widget target's membership — see the discovery doc's implementation notes. Adding a
  *field* to an existing model is one step if it's optional or defaulted where it's declared
  (`targetRepsMax`, `stepGoal`, `planDayName` all migrated that way).

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

- **Area** — `Nutrition` / `Training` / `Goals` (weight, steps) / `Profile` / `Widget` /
  `Barcode` / `General UI`. Entries before 2026-09-19 use the old tabs (`Body`, `Workouts`,
  `Insights`), which are now part of Training and the callouts.
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
| Suggestions | 20 |
| Triaged (in Backlog) | 48 |
| Done | 46 |
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
| P3 | Edit Routine carries exercises to the *first* day with the same name, so they can move day (4-day Upper/Lower: Saturday's Lower exercises land on Tuesday's Lower) — the repro was 5 → 4 days keeping Saturday: the 5-day plan's only Lower is on Saturday, and the 4-day split's first Lower is Tuesday. `RoutineTemplate.match` now takes the new split's weekdays: every same-named (slot, day) pair is sorted by how many days apart they are (going round the week), and the closest pairs claim first. A day stays on its weekday when it can and otherwise moves to the nearest same-named day. The old rule also lost exercises going back up (4 → 5 gave Saturday's slot Tuesday's empty Lower and deleted Saturday's). New `RoutineTemplate.split(for:)` pairs slots with weekdays for the editor preview, the warning and `apply`. Four new `RoutineTemplateTests` (all failed on the old rule) | Simulator pass (2026-09-22) | Done — checked in the simulator 2026-09-23 (5 → 4 → 5 days: Saturday's Lower kept its 2 exercises both ways, no warning, no orphaned rows; plan back to Mon/Tue/Wed/Fri/Sat) |
| P2 | Log Workout (unplanned) sheet has no Cancel button — swipe-down is the only way out — added Cancel to it and to its Add Set sheet, which had the same gap | Simulator pass (2026-09-22) | Done — checked in the simulator 2026-09-22; that sheet was later replaced by `UnplannedWorkoutView` (Done button, nothing to cancel) |
| P2 | Plan editing gaps: rep ranges (`targetRepsMax`), Move Up/Down within a day, name no longer repeated on the tracking screen, New Exercise defaults to the day's suggested group; plus a retry for a launch crash when the app and widget migrate the store at once | Next steps on the Training page, item 5 | Done — checked in the simulator 2026-09-22 (plan put back to 3 × 10 afterwards) |
| P1 | Faster unplanned-workout logging — picker first, then the plan's per-set tracking screen, sets saved on check; 12 → 8 taps for 3 sets of a new exercise; old draft form deleted; Cancel added to the exercise picker and New Exercise form | Next steps on the Training page, item 4 + discovery doc success criterion 2 | Done — checked in the simulator 2026-09-22 (test sets unchecked afterwards) |
| P3 | No way to delete an extra, unlogged row added with Add Set on the tracking screen — rows past the baseline (the plan's set count, or the default sets for an unplanned exercise) show a red minus badge on the set number while unlogged; tapping it removes the row and the rest renumber. Baseline rows can't be removed (`buildRows` would add them back on the next visit), and a logged row is removed by unchecking it, as before. Not a swipe: the screen deliberately isn't a `List` | Simulator pass (2026-09-22) | Done (50884c7) — checked in the simulator 2026-09-22 (unplanned Barbell Curl: 5 rows → minus on 4 and 5 only; removing 4 renumbered 5; a logged extra row loses the badge; test set unchecked afterwards) |
| P3 | Medium widget lists macros Carbs / Fat / Protein; the app uses Protein / Carbs / Fat — the three columns reordered to Protein / Carbs / Fat (colors already matched the app's). The small widget is just the calorie ring, so it had nothing to reorder | Simulator pass (2026-09-22) | Done — checked on the simulator home screen 2026-09-23 (medium widget re-added; it had gone missing since 09-22) |
| P3 | Workout History rows show only date + set count, not the plan day ("Pull") or exercises — each row now shows the plan day as its headline ("Lower"; "Push + Pull" on a mixed day), then "date · N sets", then the exercises in the order first logged. Unplanned sessions and ones logged before this keep the date as the headline. The day name is stored on each set (`WorkoutSetEntry.planDayName`, optional and defaulted, so the store migrated without a versioned schema) as a copy of the name, not a link to `PlanDay`, so history survives plan edits; the session's label is derived from its sets, so unchecking a plan set takes the label with it. A first version stored the name once on the session and kept "Lower" after its only Lower set was unchecked, which is why it moved to the set. `WorkoutSessionTests` | Simulator pass (2026-09-22) | Done — checked in the simulator 2026-09-22 (a Back Squat set from Lower labelled today's session "Lower"; unchecking it put the date back; test set unchecked afterwards) |
| P2 | Progress card: ⓘ instead of the Level/Weekly toggle — the card was too tall. It's now just "Progress", an ⓘ and the two figures: the Weekly view is gone (`WeeklyMuscleVolume`, its tests and `VolumePalette` deleted), and so are the color chips and the description under the figures. The ⓘ opens **How Levels Work** (`MuscleLevelInfoView`): the two things a muscle needs to move up (strength vs. bodyweight from the last 90 days, and time trained), then each level in its color with what it means, the Squat and Bench targets in the user's unit from their logged bodyweight (rounded to 5 lb / 2.5 kg; multiples only if no weight is logged; female standards applied from Profile), and the time required. The numbers come from the same `StrengthClass` thresholds and a new `MuscleLevelEngine.levelMinimumMonths` (the tenure cap now reads from it), so the sheet can't drift from the engine. The card still shows a one-line prompt when there's no bodyweight or no workout, since the figures can't say that themselves | User request (direct, 2026-09-22, screenshot of the legend) | Done — checked in the simulator 2026-09-22 |
| P2 | Training page laid out like Nutrition — Progress, Current Plan and Goals are gray headings above white rounded cards on the grouped gray background, with each section's button in its heading (the ⓘ, the week-plan calendar) the way Nutrition has the pie and ⓘ. The plan's "Workout · N days a week" line became "N days a week" inside the card. Shared `TrainingSection` view; built from stacks, not a `List`, to stay clear of the List button-detachment bug with all the card buttons. The shortcuts card (History / Progress / Unplanned) has no heading | User request (direct, 2026-09-22) | Done — checked in the simulator 2026-09-22 next to Nutrition; the calendar heading button opens the week |
| P2 | Log Weight / Log Steps drop what was typed when you tap the dimmed area above the sheet — both now use `.interactiveDismissDisabled` once there's an edit (Log Steps compares against the day's prefilled total, so an untouched prefill still closes on a tap); Cancel still discards. Log Weight had no Cancel, so it needed one once the tap-away was blocked, and it now focuses its field on open like Log Steps | Noticed 2026-09-22, listed under Next task | Done (4b76216) — checked in the simulator 2026-09-23 (typed a value in each, tapped above: sheet stayed with the value; Cancel closed it and nothing was saved) |
| P2 | Training title lined up with Nutrition's and no small title on scroll — own large title pinned above the scroll view with an empty inline nav title, as Nutrition does; scroll bar hidden | Suggestions → Training (2026-09-23, three entries: headline height, title on scroll, scroll bar) | Done (9ccca06) — checked in the simulator 2026-09-23 |
| P2 | Goals card simplified — History buttons removed, Log is a small + on the right, tapping the goal weight / today's steps opens that history (the goals are edited there) | Suggestions → Goals (2026-09-23, two entries) | Done (9ccca06, b8ced0d) — checked in the simulator 2026-09-23 |
| P2 | Current Plan card reads "Gym Workout" / "5 Days a Week" / a line / "Today: Legs & Abs" (tappable, opens the day); no arrows | Suggestions → Training (2026-09-23, Current Plan card) | Done (5307cdb, ff37c2d, 46f6ff5) — checked in the simulator 2026-09-23 |
| P2 | Tapping the card shows the whole week in place — one line per workout ("Monday: Push") with lines between; tapping one opens its exercises; the separate week page is gone | Suggestions → Training (2026-09-23, "shows all the week's workouts") + follow-ups in chat | Done (5307cdb, 46f6ff5) — checked in the simulator 2026-09-23 |
| P2 | ⋯ menu replaces the calendar icon: Reorder Workouts (drag handles in the card, Save / Cancel) and Edit Routine (half sheet, no caption or removal warnings) | Suggestions → Training (2026-09-23, ⋯ menu) | Done (5307cdb) — drag, Save and Cancel checked in the simulator 2026-09-23 (plan put back afterwards). The "describe it in a message" half is its own row below |
| P1 | Exercise screen with **Workout / Overview / Progress** tabs, opened from a plan day's exercise. Workout tab: rest timer; one row per set — "Set 1", lbs box, reps box, "Last: …" under each; one Complete Exercise button instead of per-set checks; an ⓘ says where to change the number of sets (Add Set goes) | Suggestions → Training (2026-09-23, tabs + Workout tab; reference: Caliber's set-entry screen) | Done (7f2e2f5, 9388e7b) — Workout tab built 2026-09-23 ([exercise-screen-plan.md](exercise-screen-plan.md), step 1): set rows with "Last:", sets save as you type, Complete Exercise, ⓘ for the set count; Add Set and the % of best bar gone. Checked in the simulator (Cable Crunch: typed set 1, backed out and reopened, Complete logged 2–3, clearing both boxes unlogged each; test sets removed). Not checked live: "Last:" with a real previous session (unit-tested) and the unplanned flow. The Workout / Overview / Progress control followed in 9388e7b |
| P2 | Progress tab: that exercise's history; then Workout History and Exercise Progress move off the Training page | Suggestions → Training (2026-09-23, Progress tab) | Done — built 2026-09-23: `ExerciseScreen` with a Workout / Progress control; the Progress tab is Exercise Progress for that one exercise plus a History list (each day's sets as "30 × 12", the plan day, the day's volume; swipe to delete that day's sets of the exercise). Workout History and its detail screen are deleted (user: no all-workouts history), and Exercise Progress's exercise picker with them; the Training page keeps only Log an Unplanned Workout. Checked in the simulator (Cable Crunch: 1RM 42 lb, Beginner → Novice, History "Wed, Sep 23 · Legs & Abs · 960 lb"; switching tabs keeps the logged sets). Swipe-to-delete not tried live — the only sets were the user's |
| P2 | Progress tab measured in volume instead of 1RM — headline total volume, this week vs last week (± %), volume per session as tappable bars (`ExerciseVolumeChart`, replacing the 1RM line chart), history unchanged; 1RM summary, level bar and stall callout removed from the tab. `WorkoutProgressViewModel.volumeSummary` + a test | User request (direct, 2026-09-23, "I do not want to really see 1rm, I am more interested in total volume") | Done — checked in the simulator 2026-09-23 (Cable Crunch: 960 lb total, this week 960 / last week 0, one bar; tapping it shows "Sep 23 · 960 lb · 3 sets") |
| P2 | Overview tab: a GIF of the exercise and Muscles Involved — body figure, Primary / Secondary labels, Flip View | Suggestions → Training (2026-09-23, Overview tab; reference: Caliber's Overview) | Done — built 2026-09-23 (`ExerciseOverviewTab`): Muscles Involved card: the figure on the left (primary solid, secondary light, the thumbnail's colors) with Primary / Secondary listed beside it on the right, most-involved first, and Flip View under the figure (lists moved beside the figure on user request, same evening). Then, also on request, **How to Do It** (numbered steps) and **Common Mistakes** (each mistake with its fix) cards under it, from `ExerciseGuides` — written for all 38 starter exercises (general coaching cues, not from one source; a test checks every starter exercise has one). Exercises the user created show a one-line note instead. Opens on the side with more of the primary muscles. Primary is involvement ≥ 0.8 (`ExerciseProfile.primaryMuscles`, now shared with the thumbnail; `ExerciseMusclesTests`); a full-body guess with nothing that high uses its top muscles. No GIF (decided). Checked in the simulator (Cable Crunch: Abs primary, Obliques secondary; flip to the back shows nothing highlighted). A back-first exercise opening on the back not seen live |
| P2 | Muscle colors by volume moved (sets × reps × weight, e.g. 2 × 8 × 35 lb = 560 lb), keeping 1RM as a data point | Suggestions → Training (2026-09-23, muscle colors) | Done — built 2026-09-23 with the proposed thresholds (see Decisions and Things to know about the muscle levels): `MuscleLevelEngine` rewritten on lifetime volume, ⓘ How Levels Work shows each level's volume in the user's unit and its time, `MuscleLevelEngineTests` rewritten (3 weeks → Novice, a year → Advanced, World Class needs 5 years, levels survive a break). 1RM code deleted. Checked in the simulator: the sheet reads 20,400 lb → Novice … 3,405,000 lb and 5 years → World Class at a 227 lb bodyweight; the simulator's muscles all show Beginner (little logged volume) |
| P3 | Edit Routine by describing it in a message ("4 days a week, upper/lower") | Suggestions → Training (2026-09-23, ⋯ menu, Edit half) | Done — built 2026-09-23 ([routine-by-message-plan.md](routine-by-message-plan.md)): a split menu (Recommended / Upper/Lower / PPL / Full Body, new Full Body day) and a "Describe it" field that fills in the weekdays and split via on-device Foundation Models; nothing saves until Save. `RoutineTemplateTests`, `RoutineRequestTests`. Checked in the simulator ("4 days a week, upper/lower" → Mon/Tue/Thu/Fri Upper/Lower; "Mon Wed Fri full body"; picking PPL; all cancelled, plan unchanged). Follow-up on request: "PPL twice a week" → 6 days PPL and "ppl and U/L" → the new PPL + U/L split, both read in code (`MessageCues`) and checked in the simulator |
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

- 2026-09-23 (Goals) — The Goals card has too much going on. Remove its History buttons and
  make Log just a + icon on the right, for both weight and steps.
- 2026-09-23 (Goals) — Tapping the goal weight opens the weight history page; tapping today's
  steps opens the steps history. That replaces the History buttons.
- 2026-09-23 (Training) — Tapping a plan day (e.g. Legs & Abs) lists its exercises; tapping an
  exercise opens a screen with three tabs: **Workout**, **Overview**, **Progress**.
- 2026-09-23 (Training) — Workout tab: the rest timer and the sets. Each set is one row —
  "Set 1", an lbs box and a reps box, with "Last: …" under each showing the previous session's
  value (reference: Caliber's set-entry screen). One **Complete Exercise** button at the
  bottom instead of a check mark per set. An ⓘ explains where to change the number of sets,
  so the Add Set button goes.
- 2026-09-23 (Training) — Overview tab: a GIF of the exercise if possible, and a Muscles
  Involved section — the body figure with the worked muscles highlighted, Primary and
  Secondary muscle labels, and a Flip View to see the back (reference: Caliber's exercise
  Overview).
- 2026-09-23 (Training) — Progress tab: that exercise's training history. With this, Workout
  History and Exercise Progress move off the main Training page into each exercise's tabs.
- 2026-09-23 (Training) — The "Training" headline sits lower than "Nutrition" does on the
  Nutrition page; line them up at the same height.
- 2026-09-23 (Training) — Scroll like the Nutrition page: once scrolled down, the "Training"
  title doesn't need to stay pinned at the top.
- 2026-09-23 (Training) — Hide the scroll bar on the Training page.
- 2026-09-23 (Training) — Muscle colors should track volume moved, not the one-rep max — e.g.
  2 sets × 8 reps × 35 lb = 560 lb moved. Keep the 1RM as a data point, but volume is what
  I want to track.
- 2026-09-23 (Training) — Current Plan card: heading "Gym Workout", subheading "5 Days a
  Week" (replacing the quads, hamstrings, glutes, core list), then a line under it "Today:
  Legs & Abs". No arrow to press.
- 2026-09-23 (Training) — Tapping the Gym Workout / 5 Days a Week section shows all the
  week's workouts; tapping a workout opens its exercises. No arrows.
- 2026-09-23 (Training) — Replace the calendar icon with a ⋯ menu offering Reorder and Edit
  Routine. Reorder happens right on the main page, with a Save. Edit opens a short popup
  where you describe the routine in a message, e.g. "4 days a week, focusing on an upper and
  lower routine."

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
