//
//  RoutineRequestTests.swift
//  MacroPalTests
//

import Testing
@testable import MacroPal

/// The on-device model can't run here, so these start from the `RoutineRequest` it returns.
/// The model's answers below are the ones it gave for these messages (greedy, 2026-09-23).
struct RoutineRequestTests {
    // `Calendar` weekday numbers.
    private let sun = 1, mon = 2, tue = 3, wed = 4, thu = 5, fri = 6, sat = 7

    private func resolve(
        _ message: String,
        modelDays days: Int? = nil,
        modelSplit split: RoutineTemplate.Split = .recommended,
        current: Set<Int>
    ) -> (weekdays: Set<Int>, split: RoutineTemplate.Split) {
        RoutineRequest(daysPerWeek: days, split: split).resolve(message: message, currentWeekdays: current)
    }

    // MARK: - resolve

    @Test func namedDaysWinOverTheCount() {
        let resolved = resolve("Mon Wed Fri full body", modelDays: 4, modelSplit: .fullBody, current: [tue, thu])
        #expect(resolved.weekdays == [mon, wed, fri])
        #expect(resolved.split == .fullBody)
    }

    @Test func oneNamedDayIsNotEnough() {
        #expect(resolve("3 days, starting Monday", modelDays: 3, current: [tue, thu]).weekdays == [mon, wed, fri])
    }

    @Test func noCountKeepsTheCurrentDays() {
        let resolved = resolve("switch to push pull legs", modelSplit: .pushPullLegs, current: [mon, wed, fri, sat])
        #expect(resolved.weekdays == [mon, wed, fri, sat])
        #expect(resolved.split == .pushPullLegs)
    }

    @Test func theSameCountKeepsTheCurrentDays() {
        #expect(resolve("3 days", modelDays: 3, current: [tue, thu, sat]).weekdays == [tue, thu, sat])
    }

    @Test func aNewCountSpreadsTheDaysOut() {
        let resolved = resolve("4 days a week, upper/lower", modelDays: 4, modelSplit: .upperLower, current: [mon, wed, fri])
        #expect(resolved.weekdays == [mon, tue, thu, fri])
    }

    @Test func theCountIsKeptInRange() {
        #expect(resolve("upper lower", current: []).weekdays.count == 2)
        #expect(resolve("9 days", modelDays: 9, current: []).weekdays.count == 6)
    }

    @Test func twiceDoublesANamedSplit() {
        // The model read this as 2 days, Recommended.
        let ppl = resolve("PPL twice a week", modelDays: 2, current: [mon, wed, fri])
        #expect(ppl.split == .pushPullLegs)
        #expect(ppl.weekdays == [mon, tue, wed, thu, fri, sat])

        #expect(resolve("U/L 2x a week", current: [mon, wed, fri]).weekdays.count == 4)
        #expect(resolve("full body two times a week", current: [mon, wed, fri]).weekdays.count == 2)
    }

    @Test func twiceDoesNotOverrideAGivenCount() {
        #expect(resolve("4 days, PPL twice", modelDays: 4, current: []).weekdays.count == 4)
    }

    @Test func twiceIsIgnoredWhenDoublingDoesNotFit() {
        // PPL + Upper/Lower twice would be 10 days, so it gets its usual 5.
        #expect(resolve("ppl and ul twice a week", current: [mon, wed, fri]).weekdays.count == 5)
    }

    @Test func aSplitInTheTextWinsOverTheModel() {
        #expect(resolve("4 days, U/L", modelDays: 4, modelSplit: .recommended, current: []).split == .upperLower)
    }

    @Test func pplAndUpperLowerMakeTheHybrid() {
        let resolved = resolve("ppl and U/L", current: [mon, tue, wed, fri, sat])
        #expect(resolved.split == .pushPullLegsUpperLower)
        #expect(resolved.weekdays == [mon, tue, wed, fri, sat])
    }

    @Test func theHybridDefaultsToFiveDays() {
        #expect(resolve("ppl and U/L", modelDays: 2, current: [mon, wed, fri]).weekdays == [mon, tue, wed, thu, fri])
        #expect(resolve("6 days, ppl + ul", modelDays: 6, current: [mon, wed, fri]).weekdays.count == 6)
    }

    @Test func aCountIsOnlyTakenFromAMessageWithANumber() {
        // "Switch to full body" has no number, so a count from the model is made up.
        #expect(resolve("switch to full body", modelDays: 4, current: [mon, wed, fri]).weekdays == [mon, wed, fri])
    }

    @Test func defaultWeekdaysSpreadOut() {
        #expect(RoutineTemplate.defaultWeekdays(count: 2) == [mon, thu])
        #expect(RoutineTemplate.defaultWeekdays(count: 3) == [mon, wed, fri])
        #expect(RoutineTemplate.defaultWeekdays(count: 5) == [mon, tue, wed, thu, fri])
        #expect(RoutineTemplate.defaultWeekdays(count: 6) == [mon, tue, wed, thu, fri, sat])
    }

    // MARK: - Reading the message

    @Test func weekdaysAreReadFromTheText() {
        #expect(MessageCues("Mon, Wed & Fri full body").weekdays == [mon, wed, fri])
        #expect(MessageCues("Tuesdays and Thurs").weekdays == [tue, thu])
        #expect(MessageCues("Sunday/saturday").weekdays == [sun, sat])
        #expect(MessageCues("4 days a week, upper/lower").weekdays.isEmpty)
    }

    @Test func weekdayWordsInsideOtherWordsDontCount() {
        // "sat" in "satisfied", "wed" in "wedding".
        #expect(MessageCues("satisfied with a wedding").weekdays.isEmpty)
    }

    @Test func splitsAreReadFromTheirShortNames() {
        #expect(MessageCues("PPL").split == .pushPullLegs)
        #expect(MessageCues("p/p/l").split == .pushPullLegs)
        #expect(MessageCues("push, pull, legs").split == .pushPullLegs)
        #expect(MessageCues("U/L").split == .upperLower)
        #expect(MessageCues("UL split").split == .upperLower)
        #expect(MessageCues("upper/lower").split == .upperLower)
        #expect(MessageCues("full-body").split == .fullBody)
        #expect(MessageCues("PPL + UL").split == .pushPullLegsUpperLower)
        #expect(MessageCues("4 days a week").split == nil)
        #expect(MessageCues("upper body days").split == nil)
    }

    @Test func routineMessagesAreRecognized() {
        #expect(RoutineRequest.looksLikeARoutine("4 days a week, upper/lower"))
        #expect(RoutineRequest.looksLikeARoutine("PPL twice a week"))
        #expect(RoutineRequest.looksLikeARoutine("ppl and U/L"))
        #expect(RoutineRequest.looksLikeARoutine("three days"))
        #expect(RoutineRequest.looksLikeARoutine("4x a week"))
        #expect(RoutineRequest.looksLikeARoutine("switch to full body"))
        #expect(RoutineRequest.looksLikeARoutine("Mon and Thu"))
    }

    @Test func unrelatedMessagesAreNot() {
        #expect(!RoutineRequest.looksLikeARoutine("make me a sandwich"))
        #expect(!RoutineRequest.looksLikeARoutine("what's the weather"))
    }
}
