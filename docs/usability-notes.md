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

Append a new entry under **Log**, newest at the top. Keep each entry small — one observation,
one entry. Copy this template:

```
### 2026-09-06 — [LIKE|DISLIKE|SUGGESTION] — Area

What happened / what you noticed. Be concrete: what screen, what action, what you expected
vs. what you got. For a suggestion, say what "better" would look like, not just "this is bad."

**Status:** Open
```

- **Category** — `LIKE` (keep doing this, don't regress it), `DISLIKE` (friction, but not
  necessarily actionable yet), `SUGGESTION` (a concrete idea to try).
- **Area** — `Nutrition` / `Body` / `Workouts` / `Insights` / `Widget` / `Barcode` / `General UI`.
- **Status** — `Open` → `Triaged` (worth doing, moved to Backlog below) → `Done` (shipped, link
  the commit) → `Won't Fix` (considered, rejected — say why, same spirit as SPEC.md §7's
  "edit and explain why" convention).

## Snapshot

Update this table whenever you triage. It's the fastest way to see whether the app is
actually improving or just accumulating complaints.

| Metric | Count |
|---|---|
| Total entries logged | 0 |
| Open | 0 |
| Triaged (in Backlog) | 0 |
| Done | 0 |
| Won't Fix | 0 |

## Backlog (triaged)

Promoted items only — things worth actually doing. Once a project has enough of these piling
up, consider moving them to GitHub Issues instead (per [SPEC.md §7](../SPEC.md#7-repository--git-workflow)'s
guidance for open questions), so they don't just rot in a markdown table.

| Priority | Item | Source entry | Status |
|---|---|---|---|
| — | *(none yet)* | — | — |

Priority scale: **P1** (actively annoying, fix soon) / **P2** (worth doing, no rush) /
**P3** (nice-to-have, may never happen).

## Log

*(newest first — add new entries above this line)*
