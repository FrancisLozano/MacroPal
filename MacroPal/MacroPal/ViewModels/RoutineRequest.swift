//
//  RoutineRequest.swift
//  MacroPal
//

import Foundation
import FoundationModels

/// A routine described in words ("4 days a week, upper/lower"), as the on-device model reads
/// it. It only fills in the Edit Routine form — `resolve` turns it into the form's weekdays
/// and split, and nothing is saved until the user taps Save.
///
/// What the text says plainly wins over the model, which got these wrong: weekdays (it made
/// them up), a split's short names ("U/L"), and "twice a week" (it read "PPL twice a week" as
/// 2 days). See `MessageCues`.
@Generable
struct RoutineRequest {
    @Guide(description: "The number of days per week written in the message (a digit, a number word, or 'twice' for a split, so PPL twice a week is 6). nil if no number is written.", .range(2...6))
    var daysPerWeek: Int?

    @Guide(description: "The split written in the message: upperLower, pushPullLegs (PPL), pushPullLegsUpperLower (PPL and upper/lower together) or fullBody. recommended if the message doesn't write one.")
    var split: RoutineTemplate.Split

    /// The form's weekdays and split for `message`. `currentWeekdays` is what the form shows now.
    ///
    /// - Split: one named in the text, else the model's.
    /// - Days: 2–6 weekdays named in the text win. Otherwise "twice" doubles a named split
    ///   (PPL → 6) when the model read no count or read the "twice" as 2. Otherwise the model's
    ///   count if the text has a number, else 5 for PPL + Upper/Lower, else the current count.
    /// - Weekdays for a count: the current days if there are that many, else spread out by
    ///   `RoutineTemplate.defaultWeekdays`.
    func resolve(message: String, currentWeekdays: Set<Int>) -> (weekdays: Set<Int>, split: RoutineTemplate.Split) {
        let cues = MessageCues(message)
        let split = cues.split ?? split
        let range = RoutineTemplate.daysPerWeekRange
        if range.contains(cues.weekdays.count) {
            return (cues.weekdays, split)
        }

        // Without a number in the text, the model's count is made up.
        let modelDays = cues.hasNumber ? daysPerWeek : nil
        let cycle = RoutineTemplate.cycle(for: split)
        var count = modelDays ?? currentWeekdays.count
        if cues.saysTwice, modelDays == nil || modelDays == 2,
           let cycle, range.contains(cycle.count * 2) {
            count = cycle.count * 2
        } else if modelDays == nil, split == .pushPullLegsUpperLower, let cycle {
            count = cycle.count
        }
        count = min(max(count, range.lowerBound), range.upperBound)
        let weekdays = currentWeekdays.count == count ? currentWeekdays : RoutineTemplate.defaultWeekdays(count: count)
        return (weekdays, split)
    }

    /// Whether `message` has anything the form can use — a number, a weekday or a split — so
    /// an unrelated message gets a hint instead of whatever the model makes of it (it read
    /// "make me a sandwich" as 2 days a week).
    static func looksLikeARoutine(_ message: String) -> Bool {
        MessageCues(message).looksLikeARoutine
    }
}

/// What a message says in plain words, read without the model.
struct MessageCues {
    /// `Calendar` weekday numbers named ("Mon", "wednesday", "Fridays").
    let weekdays: Set<Int>
    /// A split named by its usual words or short names ("PPL", "U/L", "push pull legs",
    /// "full body"); PPL and Upper/Lower together make the 5-day hybrid.
    let split: RoutineTemplate.Split?
    /// "twice", "2x" or "two/2 times".
    let saysTwice: Bool
    /// A digit or a number word ("4", "4x", "three", "twice").
    let hasNumber: Bool
    let looksLikeARoutine: Bool

    init(_ message: String) {
        let words = message.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
        let pairs = Set(zip(words, words.dropFirst()).map { $0 + " " + $1 })
        let triples = Set(zip(words, zip(words.dropFirst(), words.dropFirst(2))).map { "\($0) \($1.0) \($1.1)" })
        let has = { (word: String) in words.contains(word) }

        weekdays = Set(words.compactMap { Self.weekdayWords[$0] })

        // "u/l" and "p/p/l" split into single letters, so they're matched as a run of words.
        let ppl = has("ppl") || triples.contains("p p l") || (has("push") && has("pull"))
        let upperLower = has("ul") || pairs.contains("u l") || (has("upper") && has("lower"))
        let fullBody = has("fullbody") || pairs.contains("full body")
        split = switch (ppl, upperLower) {
        case (true, true): .pushPullLegsUpperLower
        case (true, false): .pushPullLegs
        case (false, true): .upperLower
        case (false, false): fullBody ? .fullBody : nil
        }

        saysTwice = has("twice") || has("2x") || pairs.contains("two times") || pairs.contains("2 times")

        hasNumber = words.contains { $0.contains(where: \.isNumber) || Self.numberWords.contains($0) }
        looksLikeARoutine = hasNumber || split != nil || !weekdays.isEmpty || words.contains { Self.splitWords.contains($0) }
    }

    private static let weekdayWords: [String: Int] = [
        "sun": 1, "sunday": 1, "sundays": 1,
        "mon": 2, "monday": 2, "mondays": 2,
        "tue": 3, "tues": 3, "tuesday": 3, "tuesdays": 3,
        "wed": 4, "wednesday": 4, "wednesdays": 4,
        "thu": 5, "thur": 5, "thurs": 5, "thursday": 5, "thursdays": 5,
        "fri": 6, "friday": 6, "fridays": 6,
        "sat": 7, "saturday": 7, "saturdays": 7,
    ]

    private static let numberWords: Set<String> = ["two", "three", "four", "five", "six", "twice", "thrice"]

    /// Words that hint at a split on their own ("upper body days"), beyond the full names above.
    private static let splitWords: Set<String> = ["upper", "lower", "push", "pull", "leg", "legs", "full"]
}
