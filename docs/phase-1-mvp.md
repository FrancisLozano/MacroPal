# Phase 1 — MVP: Manual Tracking Core

**Status:** Not started
**Depends on:** [Phase 0](phase-0-setup.md)
**Spec reference:** see [SPEC.md §4](../SPEC.md#4-core-domain-concepts-data-model) for the data model (`UserProfile`, `FoodItem`, `FoodEntry`, `WeightEntry`, `Exercise`, `WorkoutSession`, `WorkoutSetEntry`).

## Goal
Make the app usable for a full real day — log food, log a lift session, log your weight — without opening Xcode.

## Scope
- Log a food entry manually (name + macros, no database/barcode yet)
- Set and edit daily macro targets
- Daily summary screen: eaten vs. target, remaining macros
- Log a weight entry; set/update your goal weight at any time (reaching it, or revising it for a recomposition phase, are both just editing this field)
- Log a workout session (exercise, sets, reps, weight)
- Basic history list views for each (nutrition log, weight, workouts)
- All data persisted locally via SwiftData

## Definition of Done
You can use the app for a full real day — log food, log a lift session, log your weight — without opening Xcode.
