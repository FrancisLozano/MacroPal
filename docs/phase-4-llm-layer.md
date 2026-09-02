# Phase 4 — Analysis Engine v2: LLM Narrative Layer (Optional)

**Status:** Not started
**Depends on:** [Phase 3](phase-3-analysis-engine.md)
**Spec reference:** see [SPEC.md §7](../SPEC.md#7-repository--git-workflow) for keeping API keys out of git.

## Goal
Make the rule engine's output read like a written plan instead of raw data — without letting the LLM invent numeric recommendations on its own.

## Scope
- [ ] Take the structured `Insight` objects from Phase 3 and pass them (plus recent summarized data, not raw logs) to an LLM API to generate a friendlier written summary/plan, e.g. "This week: hold calories, your protein has been low 3 of 7 days — try adding a shake on training days."
- [ ] The LLM only **explains and phrases** decisions already computed deterministically by Phase 3 — it does not invent new numeric recommendations. Rules decide, LLM narrates.
- [ ] Requires an API key (kept out of git — see [SPEC.md §7](../SPEC.md#7-repository--git-workflow)) and a simple wrapper around the Claude API.

## Definition of Done
Insights generated in Phase 3 are passed through the LLM wrapper and rendered as a written summary in the app, with the underlying numeric recommendation unchanged from what Phase 3 computed.
