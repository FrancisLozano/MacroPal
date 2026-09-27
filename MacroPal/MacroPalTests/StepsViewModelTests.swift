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

    private func date(_ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day))!
    }

    @Test func weeksRunSundayToSaturdayFromTheFirstEntryThroughNow() {
        // 2026-09-22 is a Tuesday; the first entry is Friday 09-11.
        let weeks = StepsViewModel.periods(.week, from: day(-11), through: today, calendar: calendar)
        #expect(weeks.map(\.start) == [date(9, 6), date(9, 13), date(9, 20)])
        #expect(weeks.last?.end == date(9, 27))
    }

    @Test func monthsFollowTheCalendar() {
        let months = StepsViewModel.periods(.month, from: date(7, 31), through: today, calendar: calendar)
        #expect(months.map(\.start) == [date(7, 1), date(8, 1), date(9, 1)])
        #expect(months.last?.end == date(10, 1))
    }

    @Test func daysIncludeToday() {
        let days = StepsViewModel.periods(.day, from: day(-2), through: today, calendar: calendar)
        #expect(days.map(\.start) == [date(9, 20), date(9, 21), date(9, 22)])
    }

    @Test func aWeeksSummaryTotalsItsDaysAndCountsOnlyLoggedOnes() {
        let week = DateInterval(start: date(9, 20), end: date(9, 27))
        let logged = [(day(-2), 12_000), (day(0), 6_000), (day(-3), 50_000)]
        let summary = StepsViewModel.summary(of: week, logged.map { (day: $0.0, steps: $0.1) }, goal: 10_000, calendar: calendar)
        #expect(summary.days.count == 7)
        #expect(summary.days.first?.day == date(9, 20))
        #expect(summary.total == 18_000)
        #expect(summary.loggedDays == 2)
        #expect(summary.averagePerLoggedDay == 9_000)
        #expect(summary.daysGoalMet == 1)
    }

    @Test func aMonthsSummaryHasABarPerDay() {
        let february = DateInterval(start: date(2, 1), end: date(3, 1))
        let summary = StepsViewModel.summary(of: february, [], goal: 10_000, calendar: calendar)
        #expect(summary.days.count == 28)
        #expect(summary.total == 0)
        #expect(summary.averagePerLoggedDay == 0)
    }
}
