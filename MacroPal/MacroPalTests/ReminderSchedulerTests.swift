//
//  ReminderSchedulerTests.swift
//  MacroPalTests
//

import Foundation
import Testing
@testable import MacroPal

struct ReminderSchedulerTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }

    private func at(day: Int, hour: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    private func startOf(day: Int) -> Date {
        calendar.startOfDay(for: at(day: day, hour: 12))
    }

    @Test func defaultsAreNinePMAndTheEndOfEachMeal() {
        #expect(Reminder.steps.defaultMinute == 21 * 60)
        #expect(Reminder.weight.defaultMinute == 21 * 60)
        #expect(Reminder.breakfast.defaultMinute == 10 * 60)
        #expect(Reminder.lunch.defaultMinute == 17 * 60)
        #expect(Reminder.dinner.defaultMinute == 23 * 60 + 59)
    }

    @Test func oneADayForTheWeekStartingTodayWhenTheTimeIsStillAhead() {
        let planned = ReminderScheduler.plan(minutes: [.steps: 21 * 60], loggedDays: [:], now: at(day: 27, hour: 16), calendar: calendar)
        #expect(planned.count == 7)
        #expect(planned.first?.fireDate == at(day: 27, hour: 21))
        #expect(planned.last?.fireDate == calendar.date(from: DateComponents(year: 2026, month: 10, day: 3, hour: 21)))
    }

    @Test func todayIsSkippedOncePastTheTime() {
        let planned = ReminderScheduler.plan(minutes: [.breakfast: 10 * 60], loggedDays: [:], now: at(day: 27, hour: 16), calendar: calendar)
        #expect(planned.first?.fireDate == at(day: 28, hour: 10))
        #expect(planned.count == 6)
    }

    @Test func aLoggedDayIsSkippedForThatReminderOnly() {
        let planned = ReminderScheduler.plan(
            minutes: [.weight: 21 * 60, .dinner: 23 * 60 + 59],
            loggedDays: [.weight: [startOf(day: 27)]],
            now: at(day: 27, hour: 8),
            days: 2,
            calendar: calendar
        )
        #expect(planned.map(\.reminder) == [.dinner, .weight, .dinner])
        #expect(planned.first?.fireDate == at(day: 27, hour: 23, minute: 59))
    }

    @Test func identifiersAreOnePerReminderPerDay() {
        let planned = PlannedReminder(reminder: .lunch, fireDate: at(day: 27, hour: 17))
        #expect(planned.identifier(calendar: calendar) == "reminder.lunch.2026-09-27")
    }

    @Test func profileSummaryNamesTheRemindersThatAreOn() {
        let viewModel = ProfileViewModel()
        #expect(viewModel.remindersSummary(enabled: []) == "Off")
        #expect(viewModel.remindersSummary(enabled: [.steps, .dinner]) == "Steps, Dinner")
    }
}
