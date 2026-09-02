# Phase 3 — Analysis Engine v1 (Rule-Based)

**Status:** Not started
**Depends on:** [Phase 2](phase-2-trends.md)
**Spec reference:** see [SPEC.md §4.5](../SPEC.md#4-core-domain-concepts-data-model) for the `Insight` entity.

## Goal
Build "the coach" — an engine that reviews your logged data and proactively surfaces concrete, explainable recommendations. Not a chatbot: it doesn't wait to be asked.

## Interaction model — why not a chatbot
The AI component is **decision-output-first, conversation-second (or never)**:

- No persistent chat thread UI is required for this phase or Phase 4.
- The primary surface is a feed of `Insight` cards (like notifications), each with: what was observed, what's recommended, and why (the supporting metric).
- You can tap an insight to mark it "applied" (e.g. it updates your calorie target automatically) or "dismissed."
- A chat-style Q&A could be added later as a *secondary* feature layered on top of the same rule engine/data — e.g. "why did you suggest this?" explains an existing `Insight` — rather than the whole app being a chat window.

This keeps the core app usable and fast even if Phase 4 (the LLM layer) never gets built.

## Scope
The engine runs on-demand (button: "Analyze my progress") and/or automatically on a schedule (e.g. every Sunday), and writes `Insight` records. Implement at least these rules, each as its own small, testable Swift function `(historicalData) -> Insight?`:

- [ ] **Weight plateau on a cut:** if 14-day rolling average weight change is within ±0.1% bodyweight/week AND goal is "cut" → suggest a calorie reduction (e.g. -100 to -200 kcal/day) or a diet break, with the reasoning shown.
- [ ] **Under-eating protein:** if 7-day average protein intake < 90% of target → flag it with specific foods/servings needed to close the gap.
- [ ] **Strength stall:** if top-set weight for a lift hasn't increased in N consecutive sessions (e.g. 4) at the same rep range → suggest a deload week or an accessory-volume change.
- [ ] **Missed logging streak:** if no food log or no weigh-in for X days → surface a gentle "you've gone quiet" nudge.
- [ ] **Goal weight reached:** when current weight crosses `goalWeightKg` → surface an insight prompting a decision: set a new goal weight, switch to maintenance, or hold this weight and shift into a recomposition phase.

## Definition of Done
At least 3 rules are implemented and unit-tested, each producing a correct `Insight` (or `nil`) against known sample data.
