//
//  TrainingDatesTests.swift
//  MacroPalTests
//

import Testing
import Foundation
@testable import MacroPal

struct TrainingDatesTests {
    /// Sunday-first weeks, as in the US.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 1
        return calendar
    }

    /// Wednesday 2026-09-23, mid-afternoon.
    private var wednesday: Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: 23, hour: 15))!
    }

    private func day(_ date: Date?) -> Int? {
        date.map { calendar.component(.day, from: $0) }
    }

    @Test func findsTheWeeksDaysUpToToday() {
        #expect(day(CurrentPlanCard.dateThisWeek(weekday: 1, now: wednesday, calendar: calendar)) == 20)
        #expect(day(CurrentPlanCard.dateThisWeek(weekday: 2, now: wednesday, calendar: calendar)) == 21)
        #expect(day(CurrentPlanCard.dateThisWeek(weekday: 4, now: wednesday, calendar: calendar)) == 23)
    }

    @Test func leavesOutDaysStillToCome() {
        #expect(CurrentPlanCard.dateThisWeek(weekday: 5, now: wednesday, calendar: calendar) == nil)
        #expect(CurrentPlanCard.dateThisWeek(weekday: 7, now: wednesday, calendar: calendar) == nil)
    }

    @Test func followsAMondayFirstWeek() {
        var mondayFirst = calendar
        mondayFirst.firstWeekday = 2
        // Sunday is the end of a Monday-first week, so it hasn't come yet on Wednesday.
        #expect(CurrentPlanCard.dateThisWeek(weekday: 1, now: wednesday, calendar: mondayFirst) == nil)
        #expect(day(CurrentPlanCard.dateThisWeek(weekday: 2, now: wednesday, calendar: mondayFirst)) == 21)
    }

    @Test func listsTheWeekFromTheCalendarsFirstDay() {
        #expect(CurrentPlanCard.weekdaysInOrder(calendar: calendar) == [1, 2, 3, 4, 5, 6, 7])
        var mondayFirst = calendar
        mondayFirst.firstWeekday = 2
        #expect(CurrentPlanCard.weekdaysInOrder(calendar: mondayFirst) == [2, 3, 4, 5, 6, 7, 1])
    }

    @Test func saysHowLongAgoAWeighInWas() {
        let earlierToday = calendar.date(byAdding: .hour, value: -8, to: wednesday)!
        let lateYesterday = calendar.date(byAdding: .hour, value: -16, to: wednesday)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: wednesday)!
        #expect(GoalsCard.age(of: earlierToday, now: wednesday, calendar: calendar) == "today")
        #expect(GoalsCard.age(of: lateYesterday, now: wednesday, calendar: calendar) == "yesterday")
        #expect(GoalsCard.age(of: threeDaysAgo, now: wednesday, calendar: calendar) == "3 days ago")
    }
}
