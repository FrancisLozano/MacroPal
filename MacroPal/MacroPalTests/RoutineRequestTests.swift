//
//  RoutineRequestTests.swift
//  MacroPalTests
//

import Testing
@testable import MacroPal

/// The on-device model can't run here, so these start from the `RoutineRequest` it returns.
struct RoutineRequestTests {
    // `Calendar` weekday numbers.
    private let sun = 1, mon = 2, tue = 3, wed = 4, thu = 5, fri = 6, sat = 7

    private func resolve(
        days: Int? = nil,
        split: RoutineTemplate.Split = .recommended,
        named: Set<Int> = [],
        current: Set<Int>
    ) -> (weekdays: Set<Int>, split: RoutineTemplate.Split) {
        RoutineRequest(daysPerWeek: days, split: split).resolve(namedWeekdays: named, currentWeekdays: current)
    }

    // MARK: - resolve

    @Test func namedDaysWinOverTheCount() {
        // The model read "Mon Wed Fri full body" as 4 days.
        let resolved = resolve(days: 4, split: .fullBody, named: [mon, wed, fri], current: [tue, thu])
        #expect(resolved.weekdays == [mon, wed, fri])
        #expect(resolved.split == .fullBody)
    }

    @Test func oneNamedDayIsNotEnough() {
        let resolved = resolve(days: 3, named: [mon], current: [tue, thu])
        #expect(resolved.weekdays == [mon, wed, fri])
    }

    @Test func noCountKeepsTheCurrentDays() {
        // "Switch to push pull legs"
        let resolved = resolve(split: .pushPullLegs, current: [mon, wed, fri, sat])
        #expect(resolved.weekdays == [mon, wed, fri, sat])
        #expect(resolved.split == .pushPullLegs)
    }

    @Test func theSameCountKeepsTheCurrentDays() {
        #expect(resolve(days: 3, current: [tue, thu, sat]).weekdays == [tue, thu, sat])
    }

    @Test func aNewCountSpreadsTheDaysOut() {
        #expect(resolve(days: 4, split: .upperLower, current: [mon, wed, fri]).weekdays == [mon, tue, thu, fri])
    }

    @Test func theCountIsKeptInRange() {
        #expect(resolve(current: []).weekdays.count == 2)
        #expect(resolve(days: 9, current: []).weekdays.count == 6)
    }

    @Test func defaultWeekdaysSpreadOut() {
        #expect(RoutineTemplate.defaultWeekdays(count: 2) == [mon, thu])
        #expect(RoutineTemplate.defaultWeekdays(count: 3) == [mon, wed, fri])
        #expect(RoutineTemplate.defaultWeekdays(count: 5) == [mon, tue, wed, thu, fri])
        #expect(RoutineTemplate.defaultWeekdays(count: 6) == [mon, tue, wed, thu, fri, sat])
    }

    // MARK: - Reading the message

    @Test func weekdaysAreReadFromTheText() {
        #expect(RoutineRequest.weekdays(in: "Mon, Wed & Fri full body") == [mon, wed, fri])
        #expect(RoutineRequest.weekdays(in: "Tuesdays and Thurs") == [tue, thu])
        #expect(RoutineRequest.weekdays(in: "Sunday/saturday") == [sun, sat])
        #expect(RoutineRequest.weekdays(in: "4 days a week, upper/lower").isEmpty)
    }

    @Test func weekdayWordsInsideOtherWordsDontCount() {
        // "sat" in "satisfied", "wed" in "wedding".
        #expect(RoutineRequest.weekdays(in: "satisfied with a wedding").isEmpty)
    }

    @Test func routineMessagesAreRecognized() {
        #expect(RoutineRequest.looksLikeARoutine("4 days a week, upper/lower"))
        #expect(RoutineRequest.looksLikeARoutine("PPL twice a week"))
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
