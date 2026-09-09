# Usability Notes & Feedback Log

**Status:** Living document — ongoing, not tied to a phase
**Started:** 2026-09-06

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
| Triaged (in Backlog) | 13 |
| Done | 0 |
| Won't Fix | 0 |

## Backlog (triaged)

Promoted items only — things worth actually doing. Once a project has enough of these piling
up, consider moving them to GitHub Issues instead (per [SPEC.md §7](../SPEC.md#7-repository--git-workflow)'s
guidance for open questions), so they don't just rot in a markdown table.

| Priority | Item | Source | Status |
|---|---|---|---|
| P1 | Delete a logged food entry | Dislikes → Nutrition (2026-09-08) | Triaged |
| P1 | Weight-entry date auto-fills to today | Suggestions → Body (2026-09-08) | Triaged |
| P1 | Redesign nutrition summary (compact macro row, calorie kept prominent, filter toggle for calories+protein vs. full macros) | Dislikes → General UI (2026-09-07) + Suggestions → General UI (2026-09-07) + Suggestions → Nutrition (2026-09-08, macro filter) | Triaged |
| P1 | Redesign Workouts page (visual appeal + faster set logging) | Dislikes → Workouts (2026-09-08, "lacks visual appeal...") | Triaged |
| P2 | Food database integration (search/brands, not manual-only) | Dislikes → Nutrition (2026-09-08, "no brands...") + Suggestions → Nutrition (2026-09-08, "larger variety...") | Triaged |
| P2 | Redesign food history (show calories vs. target, show macros per entry, scale better with more entries) | Dislikes → Nutrition (2026-09-08, three food-history entries) | Triaged |
| P2 | Fold Body page into another page instead of standalone | Dislikes → Body (2026-09-08) | Triaged |
| P2 | Replace Insights page with contextual info icons at point of relevance | Dislikes → Insights (2026-09-08) + Suggestions → Insights (2026-09-08) | Triaged |
| P2 | Add oz as a serving-size unit alongside grams | Dislikes → Nutrition (2026-09-08, "serving size is only in grams") | Triaged |
| P2 | Daily logged-food list scales better as more foods are added | Dislikes → Nutrition (2026-09-08, "day's logged-food list...") | Triaged |
| P2 | Clicking a macro shows which foods contributed to it | Suggestions → Nutrition (2026-09-08) | Triaged |
| P2 | Split Profile page into subpages to reduce visual overload | Dislikes → General UI (2026-09-08, "Profile page needs subpages") | Triaged |
| P3 | Nicer-looking exercise graph / add a workout-progress graphic | Dislikes → Workouts (2026-09-08, "exercise graph doesn't look good") + Suggestions → Workouts (2026-09-08, workout-progress graphic) | Triaged |

Priority scale: **P1** (actively annoying, fix soon) / **P2** (worth doing, no rush) /
**P3** (nice-to-have, may never happen). Status: `Triaged` → `In Progress` → `Done` (link the
commit) → `Won't Fix` (say why — same spirit as SPEC.md §7's "edit and explain why" convention).

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
