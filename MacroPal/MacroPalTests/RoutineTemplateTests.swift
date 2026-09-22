//
//  RoutineTemplateTests.swift
//  MacroPalTests
//

import Testing
@testable import MacroPal

struct RoutineTemplateTests {
    private func match(_ days: [String], toDaysPerWeek count: Int) -> (claimed: [String?], leftover: [String]) {
        RoutineTemplate.match(slots: RoutineTemplate.slots(forDaysPerWeek: count), to: days, name: { $0 })
    }

    private let fiveDay = ["Push", "Pull", "Legs & Abs", "Upper", "Lower"]

    @Test func sameSplitClaimsEveryDay() {
        let result = match(fiveDay, toDaysPerWeek: 5)
        #expect(result.claimed == fiveDay)
        #expect(result.leftover.isEmpty)
    }

    @Test func droppingToUpperLowerLeavesThePushPullDays() {
        let result = match(fiveDay, toDaysPerWeek: 4)
        #expect(result.claimed == ["Upper", "Lower", nil, nil])
        #expect(result.leftover == ["Push", "Pull", "Legs & Abs"])
    }

    @Test func eachDayIsClaimedAtMostOnce() {
        // Two Upper/Lower pairs map back onto a 4-day plan one-to-one, in order.
        let result = match(["Upper", "Lower", "Upper", "Lower"], toDaysPerWeek: 4)
        #expect(result.claimed == ["Upper", "Lower", "Upper", "Lower"])
        #expect(result.leftover.isEmpty)
    }

    @Test func noExistingDaysMeansNothingClaimed() {
        let result = match([], toDaysPerWeek: 3)
        #expect(result.claimed == [nil, nil, nil])
        #expect(result.leftover.isEmpty)
    }
}
