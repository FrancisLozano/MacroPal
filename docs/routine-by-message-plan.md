# Edit Routine by Message Plan

**Status:** Built — all three steps done 2026-09-23 (user OK'd the plan, Full Body in,
Recommended as the default)
**Written:** 2026-09-23 · was Next tasks step 1; now a Done row in the Backlog of [usability.md](usability.md#backlog-triaged)
**Source:** Suggestions → Training (2026-09-23, ⋯ menu, Edit half). Backlog row: the P3
"Edit Routine by describing it in a message".

## What changed while building

- **The split picker is a menu, not segments** — "Recommended" was cut off at a quarter of
  the width. "Your split" became **Your week** so it doesn't repeat the "Split" heading.
- **Weekdays are read from the text, not asked of the model.** It made days up for messages
  that named none ("4 days a week" → Tue/Wed/Fri/Sat). `RoutineRequest.weekdays(in:)` finds
  "Mon", "Wednesdays", "Thurs"… as whole words, and 2–6 named days win over the model's count
  (it read "Mon Wed Fri full body" as 4 days).
- **No `isAboutARoutine` field.** The model said true for "make me a sandwich". Instead,
  `RoutineRequest.looksLikeARoutine` skips the model unless the message has a number, a number
  word, a weekday or a split word, and shows "Say how many days or which split. Try: 3 days,
  full body."
- **The first instructions were refused** ("may contain sensitive content") for every message,
  even "4 days a week, upper/lower". The wording now in `RoutineAssistant` isn't. Guides are
  strict ("the number … written in the message", "recommended if the message doesn't write
  …") and sampling is **greedy**, so a message always reads the same way.
- **The sheet opens taller** (62% of the screen instead of half) and its form scrolls, so a
  6-day week fits under the message field (user, 2026-09-23); the field sits 8 pt below the
  navigation bar.
- **Split names and "twice" are read from the text too** (user request, same night). "PPL",
  "p/p/l", "push pull legs", "U/L", "UL", "upper/lower", "full body" name a split; PPL and
  U/L together name the new **PPL + U/L** split (Push, Pull, Legs & Abs, Upper, Lower — the
  same days as Recommended on 5, so switching keeps exercises; 5 days unless a number is
  given). "Twice" / "2x" / "two times" doubles a named split (PPL → 6, U/L → 4, full body → 2)
  when that fits in 6 days. The model's count is ignored when the message has no number,
  since it's made up then. All in `MessageCues`.
- Failures are logged (`RoutineAssistant` category) with the error, since the UI only shows a
  hint.

**How messages read** (the Mac's on-device model, greedy, 2026-09-23 — the first two rows
also checked in the app):

| Message | Days | Split | Form shows |
|---|---|---|---|
| 4 days a week, upper/lower | 4 | Upper/Lower | Mon/Tue/Thu/Fri, Upper/Lower |
| Mon Wed Fri full body | 4 (overridden) | Full Body | Mon/Wed/Fri, Full Body |
| three days, full body | 3 | Full Body | |
| switch to push pull legs | — | PPL | current days, PPL |
| I want to train 5 times a week | 5 | Recommended | |
| upper body one day, lower body the next, 4x a week | 4 | Upper/Lower | |
| PPL twice a week | 2 → 6 in code | Recommended → PPL in code | Mon–Sat, PPL (checked in the app) |
| ppl and U/L | | PPL + U/L in code | current 5 days, PPL + U/L (checked in the app) |
| make me a sandwich | not sent to the model | | the hint |

## What it changes

`RoutineEditorView` is the Edit Routine sheet today (⋯ → Edit Routine, or Create your plan).
You tap weekdays, and the split follows **only from how many days** you picked
(`RoutineTemplate.slots(forDaysPerWeek:)`): 4 days is always Upper/Lower, 3 is always
Push/Pull/Legs. So "4 days a week, push/pull/legs" can't be expressed yet, with or without a
message. The message needs a **split choice** to write into, and that choice is also the
"split picker" the form fallback needs.

## Decisions it builds on (usability.md → Decisions worth remembering)

- **Apple's on-device Foundation Models** (iOS 26.5 target): no API key, no server.
- **One apply path.** Whatever the message says ends in `RoutineTemplate.apply`, so
  exercises carry over by weekday, then name, as today.
- **No removal warnings** in the editor (user request); `apply` still deletes days no slot
  claims.

## The sheet

```
 Cancel            Edit Routine             Save
 ┌─────────────────────────────────────────────┐
 │ 4 days a week, upper/lower             [ ↑ ] │   ← only with Apple Intelligence
 └─────────────────────────────────────────────┘
 Training days
 (S) (M) (T) (W) (T) (F) (S)
 Split
 [ Recommended | Upper/Lower | PPL | Full Body ]
 Your split
 Monday          Upper
 Tuesday         Lower
 Thursday        Upper
 Friday          Lower
```

- **The message fills in the form; it never saves.** Sending it sets the weekday circles and
  the split picker, and "Your split" updates as it does now. You check it, adjust anything,
  and tap Save. That's how the result is shown before it's applied, and a misread message
  costs one tap to fix instead of a wrong plan.
- **The form is the fallback.** Without Apple Intelligence (device not eligible, turned off,
  model still downloading) the text field is hidden and the rest of the sheet is unchanged —
  the split picker is new for everyone.
- While the model runs, the send button becomes a spinner. If it fails or the message isn't
  about a routine, a gray line under the field says so with an example ("Try: 3 days, full
  body"), and the form is left as it was.

## What the model may return

**Only splits `RoutineTemplate` knows — no free-form day names.** Known names are what make
the rest work: carry-over matching pairs days by name, and `muscleGroups(forDayNamed:)`
suggests exercises for a day. Free-form names ("Arms", "Chest & Back") would need a focus
line and suggested groups made up for each one, and a typo in a model's name would drop a
day's exercises on the next edit.

*As planned — see "What changed while building" for what's different (no weekdays or
`isAboutARoutine` from the model):*

```swift
@Generable struct RoutineRequest {
    @Guide(description: "Training days per week", .range(2...6))
    var daysPerWeek: Int
    @Guide(description: "The split asked for, or recommended if none was named")
    var split: Split                 // @Generable enum, below
    @Guide(description: "Weekdays named in the message, if any")
    var weekdays: [Weekday]          // empty = none named
}
```

`Split` is a new enum in `RoutineTemplate`: **recommended** (today's day-count table),
**upperLower**, **pushPullLegs**, **fullBody**. A split with a day count it doesn't divide
into repeats in order (PPL on 4 days → Push, Pull, Legs, Push; Upper/Lower on 3 → Upper,
Lower, Upper). Full Body is a new `Slot` ("Full Body", all groups).

**Weekdays:** named weekdays win if their count matches `daysPerWeek`. Otherwise keep the
plan's current weekdays if there are that many, else spread them out: 2 → Mon/Thu,
3 → Mon/Wed/Fri, 4 → Mon/Tue/Thu/Fri, 5 → Mon–Fri, 6 → Mon–Sat.

## Code

- `RoutineTemplate`: add `Split`, `slots(for split:, daysPerWeek:)`, `split(for:weekdays:)`,
  `defaultWeekdays(count:)`; `apply` takes a `Split` (defaulting to `.recommended`, so today's
  callers and tests are unchanged).
- `RoutineRequest` + `RoutineRequest.resolve(currentWeekdays:) -> (weekdays: Set<Int>, split: Split)`
  — a plain function with no model in it.
- `RoutineAssistant`: holds the `LanguageModelSession` (short instructions listing the splits),
  `availability` from `SystemLanguageModel.default`, and one `func interpret(_ message:) async throws -> RoutineRequest`.
- `RoutineEditorView`: the text field, the split picker, `@State split`.

## Testing

The model can't run in unit tests, so the tests stop at the typed value:

- `RoutineTemplateTests`: each split at each day count (repeats, the 5-day hybrid staying as
  today under Recommended), default weekdays, and that `apply` with a split still carries
  exercises over.
- `RoutineRequestTests`: `resolve` — named weekdays win, a mismatched count falls back to the
  current weekdays, then the spread table.
- **By hand in the simulator** (it uses the Mac's Apple Intelligence, if it's on): a handful
  of messages — "4 days a week, upper/lower", "PPL twice a week" (→ 6 days), "Mon Wed Fri full
  body", "make me a sandwich" — noting what each fills in, in this file.

## Steps

1. Split picker + `RoutineTemplate.Split` and tests (useful on its own — ships first).
2. `RoutineRequest`, `resolve`, tests.
3. `RoutineAssistant` + the text field, checked by hand.

## Open questions for the user (answered 2026-09-23)

1. **Full Body** as a fourth split — **in**.
2. **"Recommended"** as the picker's default — **yes**.
