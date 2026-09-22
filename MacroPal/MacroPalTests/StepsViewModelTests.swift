//
//  StepsViewModelTests.swift
//  MacroPalTests
//

import Foundation
import Testing
@testable import MacroPal

struct StepsViewModelTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }

    /// Noon on 2026-09-22 in the test calendar's time zone.
    private var today: Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: 22, hour: 12))!
    }

    private func day(_ offset: Int, hour: Int = 9) -> Date {
        let start = calendar.startOfDay(for: today)
        return calendar.date(byAdding: DateComponents(day: offset, hour: hour), to: start)!
    }

    private func totals(_ logged: [(day: Date, steps: Int)], days: Int) -> [DailySteps] {
        StepsViewModel.dailyTotals(logged, days: days, endingOn: today, calendar: calendar)
    }

    @Test func fillsMissingDaysWithZeroOldestFirst() {
        let result = totals([(day(0), 8_000), (day(-2), 12_000)], days: 3)
        #expect(result.map(\.steps) == [12_000, 0, 8_000])
        #expect(result.map(\.day) == [-2, -1, 0].map { calendar.startOfDay(for: day($0)) })
    }

    @Test func ignoresDaysOutsideTheRange() {
        let result = totals([(day(-7), 5_000), (day(1), 5_000)], days: 7)
        #expect(result.count == 7)
        #expect(result.allSatisfy { $0.steps == 0 })
    }

    @Test func entriesAtAnyTimeOfDayLandOnTheirDay() {
        let result = totals([(day(-1, hour: 23), 4_000)], days: 2)
        #expect(result.map(\.steps) == [4_000, 0])
    }

    @Test func zeroDaysIsEmpty() {
        #expect(totals([(day(0), 1_000)], days: 0).isEmpty)
    }
}
