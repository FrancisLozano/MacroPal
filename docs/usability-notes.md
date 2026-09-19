# Usability Notes & Feedback Log

**Status:** Living document — ongoing, not tied to a phase
**Started:** 2026-09-06

## Progress summary (as of 2026-09-19)

15 of 21 triaged backlog items are Done, 1 was verified as "No change needed", 5 are open.
(The 09-15 summary said "9 of 16"; the table actually held 17 rows then — the counts below
are recounted from the table.)

This stretch closed the P1 Workouts redesign and the P2 "fold Body into another page" item
together, following [discovery-workouts-body-redesign.md](discovery-workouts-body-redesign.md)
(Option 2): Body and Workouts are now **one Training tab**, built out from a whiteboard
sketch of the user's — progress body map on top, Current Plan (today's workout, tap for the
week), Goals below. Body weight and lifts can be shown in lb or kg (default lb).

Remaining open items, by priority:
- **P2** — Redesign food history (calories vs. target, per-entry macros, better scaling).
- **P2** — Replace Insights page with contextual info icons.
- **P2** — Clicking a macro shows which foods contributed to it.
- **P2** — Split Profile page into subpages.
- **P3** — Nicer-looking exercise graph / workout-progress graphic (not touched by the
  Training redesign — `WorkoutProgressChart` is still the plain two-line chart).

### Next steps on the Training page

Roughly in the order I'd do them:

1. **Steps goal + bar chart.** The whiteboard's Goals card has goal weight (line graph, done)
   *and* a steps goal (bar chart, not started). Needs a steps model and goal. Plan: manual
   entry first; HealthKit later (needs a real device and permissions — can't be tested in the
   simulator).
2. **Body map polish.** First pass is shipped but rough: the figures read as a stiff
   mannequin, untrained muscles are barely darker than the silhouette, the back-view traps
   look odd, abs are one flat block. Also worth trying the "Weekly" toggle from the reference
   image (level vs. this-week's training).
3. **Exercise progress graphic** (the open P3 above), and give it a "progress toward
   something" element — the third success criterion in the discovery doc is still unmet.
4. **Faster logging for unplanned workouts.** Plan-driven logging is fast now (one check per
   set, prefilled), but "Log an Unplanned Workout" still uses the old flow: + → Add Set →
   Choose Exercise → fields, up to three sheets deep. The tap-count baseline the discovery doc
   asked for was never measured, so the "fewer taps" criterion can't be formally checked.
5. **Plan editing gaps.** Reps are a single number (the reference app uses a range like 8–10);
   exercises within a day can't be reordered; the exercise name shows twice on the tracking
   screen (nav bar + header card); the New Exercise form defaults to Full Body, which hides a
   custom exercise from the day-based "Suggested" list.
6. **Rest timer / target icons** from the tracking-screen reference — deliberately left out.

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

### Not yet verified in the simulator

Exercise-row muscle thumbnails; unchecking a set; Add Set on the tracking screen; the
ellipsis menu (edit sets & reps / remove); dragging to reorder in the week view; editing an
existing routine (exercises should carry over for days that keep their name); the bottom
"more" list on the Training page; the home-screen widget after the schema change. Sessions
logged from a plan day showing up in Workout History was also not checked.

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
| Triaged (in Backlog) | 21 |
| Done | 15 |
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
| P2 | Redesign food history (show calories vs. target, show macros per entry, scale better with more entries) | Dislikes → Nutrition (2026-09-08, three food-history entries) | Triaged |
| P2 | Fold Body page into another page instead of standalone — Body and Workouts merged into one Training tab; weight is a Goals-card row with a log button and a chart link | Dislikes → Body (2026-09-08) | Done (4d4f8dc, 41b27b9) |
| P2 | Replace Insights page with contextual info icons at point of relevance | Dislikes → Insights (2026-09-08) + Suggestions → Insights (2026-09-08) | Triaged |
| P2 | Add oz as a serving-size unit alongside grams | Dislikes → Nutrition (2026-09-08, "serving size is only in grams") | Done (1a3b380) — status corrected 2026-09-15; cdb333f later added cups/tbsp/tsp and fraction input on top of it |
| P2 | Daily logged-food list scales better as more foods are added — replaced the flat "Logged Today" list with a swipeable Breakfast/Lunch/Dinner carousel; each card is a fixed-size two-line summary (what's logged + calories) instead of growing with every entry | Dislikes → Nutrition (2026-09-08, "day's logged-food list...") | Done (c3a8e87) |
| P2 | Clicking a macro shows which foods contributed to it | Suggestions → Nutrition (2026-09-08) | Triaged |
| P2 | Split Profile page into subpages to reduce visual overload | Dislikes → General UI (2026-09-08, "Profile page needs subpages") | Triaged |
| P1 | My Meals recipes: build a meal from existing foods (97d8f36), show/edit its ingredients while logging (872e9f8, 4ec4ce1), flexible serving units + fraction input (cdb333f), consistent rounded display everywhere (614f4fe), and edit a saved meal's ingredients after the fact via swipe-to-edit (92cdcef) | User request (direct, 2026-09-12 → 2026-09-15, not from the log below) | Done (92cdcef) |
| P2 | New Food form asks for macros per the entered serving size (e.g. "36g, as printed on the label") instead of per 100g, converting to the stored per-100g value at save time | User request (direct, 2026-09-15) | Done (6b9da81) |
| P1 | Fix My Meals tab picking up manually-added plain foods (no brand looked the same as a meal) — added an explicit `FoodItem.isMeal` flag, split the old Recents tab into History → Recents + a permanent Foods Manually Added section, and reworded the not-found search state to "Item not found in database" | User request (direct, 2026-09-15, "I just made rwoaw as an example and realized a flaw...") | Done (06e67a2) |
| P2 | Let a manually-added (non-meal) food's macros/serving size be edited after creation, the same swipe-to-edit affordance My Meals rows got in 92cdcef — right now Foods Manually Added only supports delete | Follow-up from the row above | Done (da4b4f6) |
| P1 | Training plan: create a weekly routine by picking training weekdays (split follows the count — 3 days → Push/Pull/Legs, 5 → Push/Pull/Legs & Abs/Upper/Lower), Current Plan card with today's workout, expanded week view (calendar icon) with reorder and routine editor (ellipsis) | User request (direct, 2026-09-19, whiteboard sketch) | Done (d4b9f61) |
| P2 | Show body weight and lift weights in lb (default) or kg via a toggle on the Goals card; stored in kg underneath; Log Weight sheet shortened and Notes field removed | User request (direct, 2026-09-19) | Done (a2003ed, ca6b473) |
| P2 | Starter exercise catalog (38 common lifts, seeded once) and day-based "Suggested" exercises in the picker — the picker was empty on a fresh install | Found while testing the plan feature | Done (60f1dc9) |
| P2 | Progress body map: front/back figures colored Beginner → World Class per muscle from logged lifts vs. bodyweight, tenure-capped; muscle-highlight thumbnails on exercise rows | User request (direct, 2026-09-19, whiteboard sketch + reference image) | Done (b581523) — first pass, drawing needs polish; see next steps |
| P3 | Nicer-looking exercise graph / add a workout-progress graphic | Dislikes → Workouts (2026-09-08, "exercise graph doesn't look good") + Suggestions → Workouts (2026-09-08, workout-progress graphic) | Triaged |

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
