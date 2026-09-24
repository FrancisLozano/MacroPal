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
/// Weekdays aren't asked of the model: it made them up for messages that named none, so
/// they're read from the text instead (`weekdays(in:)`).
@Generable
struct RoutineRequest {
    @Guide(description: "The number of days per week written in the message (a digit, a number word, or 'twice' for a split, so PPL twice a week is 6). nil if no number is written.", .range(2...6))
    var daysPerWeek: Int?

    @Guide(description: "The split written in the message. recommended if the message doesn't write upper/lower, push/pull/legs, PPL or full body.")
    var split: RoutineTemplate.Split

    /// The form's weekdays and split for this request. Weekdays named in the message win when
    /// there are 2–6 of them. Otherwise the day count is the one read (else the current
    /// count), on the current days if there are that many, or else spread out by
    /// `RoutineTemplate.defaultWeekdays`.
    func resolve(namedWeekdays: Set<Int>, currentWeekdays: Set<Int>) -> (weekdays: Set<Int>, split: RoutineTemplate.Split) {
        let range = RoutineTemplate.daysPerWeekRange
        if range.contains(namedWeekdays.count) {
            return (namedWeekdays, split)
        }
        let count = min(max(daysPerWeek ?? currentWeekdays.count, range.lowerBound), range.upperBound)
        let weekdays = currentWeekdays.count == count ? currentWeekdays : RoutineTemplate.defaultWeekdays(count: count)
        return (weekdays, split)
    }
}

extension RoutineRequest {
    /// Words that name a weekday, and its `Calendar` weekday number.
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

    private static let splitWords: Set<String> = ["upper", "lower", "push", "pull", "leg", "legs", "ppl", "full"]

    private static func words(in message: String) -> [String] {
        message.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
    }

    /// `Calendar` weekday numbers named in `message` ("Mon", "wednesday", "Fridays").
    static func weekdays(in message: String) -> Set<Int> {
        Set(words(in: message).compactMap { weekdayWords[$0] })
    }

    /// Whether `message` has anything the form can use — a number, a weekday or a split — so
    /// an unrelated message gets a hint instead of whatever the model makes of it (it read
    /// "make me a sandwich" as 2 days a week).
    static func looksLikeARoutine(_ message: String) -> Bool {
        words(in: message).contains { word in
            word.contains(where: \.isNumber) || numberWords.contains(word)
                || weekdayWords[word] != nil || splitWords.contains(word)
        }
    }
}
