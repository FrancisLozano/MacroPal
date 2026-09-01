# Phase 2 — Trends & Visualization

**Status:** Not started
**Depends on:** [Phase 1](phase-1-mvp.md)
**Spec reference:** see [SPEC.md §3](../SPEC.md#3-platform--tech-stack) — charts use native Swift Charts.

## Goal
Turn the raw logs from Phase 1 into trends you can actually read progress from, with no new data-entry screens.

## Scope
- Weight trend chart (raw + rolling 7-day average — raw daily weight is noisy), with your current goal weight shown as a reference line
- Macro adherence chart (e.g. last 14 days, calories vs. target)
- Workout progression chart per exercise (top set weight over time, estimated 1RM)

## Definition of Done
All three charts render correctly against real Phase 1 data you've logged, with no additional data-entry required to populate them.
