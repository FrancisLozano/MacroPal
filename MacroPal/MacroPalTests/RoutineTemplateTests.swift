//
//  RoutineTemplateTests.swift
//  MacroPalTests
//

import Testing
@testable import MacroPal

struct RoutineTemplateTests {
    /// A plan day reduced to what matching looks at.
    private struct Day: Equatable {
        let name: String
        let weekday: Int
    }

    // `Calendar` weekday numbers.
    private let sun = 1, mon = 2, tue = 3, wed = 4, thu = 5, fri = 6, sat = 7

    private func match(_ days: [Day], toWeekdays weekdays: Set<Int>) -> (claimed: [Day?], leftover: [Day]) {
        RoutineTemplate.match(split: RoutineTemplate.split(for: weekdays), to: days, name: \.name, weekday: \.weekday)
    }

    private var fiveDay: [Day] {
        [Day(name: "Push", weekday: mon), Day(name: "Pull", weekday: tue), Day(name: "Legs & Abs", weekday: wed),
         Day(name: "Upper", weekday: fri), Day(name: "Lower", weekday: sat)]
    }

    private var fourDay: [Day] {
        [Day(name: "Upper", weekday: mon), Day(name: "Lower", weekday: tue),
         Day(name: "Upper", weekday: thu), Day(name: "Lower", weekday: sat)]
    }

    @Test func sameSplitClaimsEveryDay() {
        let result = match(fiveDay, toWeekdays: [mon, tue, wed, fri, sat])
        #expect(result.claimed == fiveDay)
        #expect(result.leftover.isEmpty)
    }

    @Test func droppingToUpperLowerLeavesThePushPullDays() {
        let result = match(fiveDay, toWeekdays: [mon, tue, thu, sat])
        #expect(result.leftover.map(\.name) == ["Push", "Pull", "Legs & Abs"])
    }

    @Test func aDayStaysOnItsWeekdayWhenTheNewSplitHasOne() {
        // 5 → 4 days: Saturday's Lower stays on Saturday rather than moving to Tuesday, the
        // first Lower of the new split.
        let result = match(fiveDay, toWeekdays: [mon, tue, thu, sat])
        #expect(result.claimed[1] == nil)
        #expect(result.claimed[3] == Day(name: "Lower", weekday: sat))
    }

    @Test func otherwiseADayMovesToTheNearestWeekday() {
        // Friday's Upper goes to Thursday's Upper, not Monday's.
        let result = match(fiveDay, toWeekdays: [mon, tue, thu, sat])
        #expect(result.claimed[0] == nil)
        #expect(result.claimed[2] == Day(name: "Upper", weekday: fri))
    }

    @Test func nearestCountsAcrossTheWeekend() {
        // Sunday is one day from Saturday, not six, so Saturday's Upper wins over Tuesday's.
        // (Upper lands on a Saturday after reordering days in the week view.)
        let days = [Day(name: "Upper", weekday: tue), Day(name: "Lower", weekday: wed),
                    Day(name: "Lower", weekday: fri), Day(name: "Upper", weekday: sat)]
        let result = match(days, toWeekdays: [sun, wed])
        #expect(result.claimed == [Day(name: "Upper", weekday: sat), Day(name: "Lower", weekday: wed)])
    }

    @Test func droppingDaysKeepsTheOnesOnKeptWeekdays() {
        // 4 → 2 days on Thursday and Saturday: those two keep their exercises, and the
        // Monday/Tuesday pair is what the editor warns about.
        let result = match(fourDay, toWeekdays: [thu, sat])
        #expect(result.claimed == [Day(name: "Upper", weekday: thu), Day(name: "Lower", weekday: sat)])
        #expect(result.leftover == [Day(name: "Upper", weekday: mon), Day(name: "Lower", weekday: tue)])
    }

    @Test func eachDayIsClaimedAtMostOnce() {
        // Two Upper/Lower pairs map back onto a 4-day plan one-to-one, in order.
        let result = match(fourDay, toWeekdays: [mon, tue, thu, sat])
        #expect(result.claimed == fourDay)
        #expect(result.leftover.isEmpty)
    }

    @Test func noExistingDaysMeansNothingClaimed() {
        let result = match([], toWeekdays: [mon, wed, fri])
        #expect(result.claimed == [nil, nil, nil])
        #expect(result.leftover.isEmpty)
    }
}
