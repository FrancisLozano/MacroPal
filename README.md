# MacroPal

A personal iOS app for tracking macros, body measurements, and workouts — with a rule-based
analysis engine that reviews your logged data and surfaces concrete recommendations, instead
of a chatbot you have to ask.

Built for personal use; shared here to track progress in the open.

**Current phase:** All free-to-build phases complete. Phase 4 and the remaining Phase 5
candidates are skipped — they all require a paid API or developer account, which conflicts
with the goal of a free app with no ongoing costs.

See [SPEC.md](SPEC.md) for the overview (vision, tech stack, data model, conventions) and
[docs/](docs/) for a detailed spec per phase. These are living documents — edited and committed
as requirements change, so `git log` on any of them doubles as a history of how the plan evolved.

## Roadmap
- [x] [Phase 0 — Project setup](docs/phase-0-setup.md)
- [x] [Phase 1 — MVP manual tracking](docs/phase-1-mvp.md)
- [x] [Phase 2 — Trends & charts](docs/phase-2-trends.md)
- [x] [Phase 3 — Rule-based analysis engine](docs/phase-3-analysis-engine.md)
- [ ] [Phase 4 — LLM narrative layer](docs/phase-4-llm-layer.md) — skipped, requires a
      pay-per-use Claude API key
- [x] [Phase 5 — Stretch features](docs/phase-5-stretch.md) — free candidates (barcode
      scanning, home-screen widget) done; remaining candidates skipped, require a paid Apple
      Developer account

Now in ongoing daily use — see [docs/usability-notes.md](docs/usability-notes.md) for the
running dogfooding log (what's working, what isn't, what to improve next).
