//
//  ReminderScheduler.swift
//  MacroPal
//

import Foundation
import SwiftData
import UserNotifications
import os

private let reminderLog = Logger(subsystem: "com.francislozano.MacroPal", category: "Reminders")

/// One notification to schedule: a reminder at a moment on one day.
struct PlannedReminder: Equatable {
    let reminder: Reminder
    let fireDate: Date

    /// "reminder.steps.2026-09-27" — one per reminder per day, so rescheduling replaces
    /// rather than duplicates, and a day that gets logged can simply be left out.
    func identifier(calendar: Calendar) -> String {
        let day = calendar.dateComponents([.year, .month, .day], from: fireDate)
        return String(format: "%@%@.%04d-%02d-%02d", ReminderScheduler.identifierPrefix, reminder.rawValue, day.year ?? 0, day.month ?? 0, day.day ?? 0)
    }
}

/// Keeps the pending reminder notifications in step with the settings and what's logged.
///
/// A repeating notification can't skip one day, so instead each enabled reminder gets a
/// one-off notification for each of the next `daysAhead` days, leaving out days it's already
/// logged and times already past. Rebuilt whenever the app opens or goes to the background
/// (so anything logged in between is accounted for) and when a setting changes. Opening the
/// app at least once a week keeps them coming.
@MainActor
enum ReminderScheduler {
    static let identifierPrefix = "reminder."
    static let daysAhead = 7

    /// The notifications to have pending: each enabled reminder (`minutes`, minutes after
    /// midnight) on each of the `days` days starting today, unless that day is in its
    /// `loggedDays` (starts of day) or the time has passed.
    nonisolated static func plan(
        minutes: [Reminder: Int],
        loggedDays: [Reminder: Set<Date>],
        now: Date,
        days: Int = daysAhead,
        calendar: Calendar
    ) -> [PlannedReminder] {
        let today = calendar.startOfDay(for: now)
        return (0..<days).flatMap { offset -> [PlannedReminder] in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { return [] }
            return Reminder.allCases.compactMap { reminder in
                guard let minute = minutes[reminder],
                      !(loggedDays[reminder]?.contains(day) ?? false),
                      let fireDate = calendar.date(byAdding: .minute, value: minute, to: day),
                      fireDate > now else { return nil }
                return PlannedReminder(reminder: reminder, fireDate: fireDate)
            }
        }
    }

    /// Replaces every pending reminder with a fresh plan. Only schedules when notifications
    /// are allowed — the permission prompt belongs to turning a reminder on, not to this.
    static func reschedule(in context: ModelContext, defaults: UserDefaults = .standard, now: Date = .now) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) })

        var minutes: [Reminder: Int] = [:]
        for reminder in Reminder.allCases where reminder.isEnabled(in: defaults) {
            minutes[reminder] = reminder.minute(in: defaults)
        }
        guard !minutes.isEmpty else { return }
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            reminderLog.notice("Reminders are on but notifications aren't allowed; nothing scheduled")
            return
        }

        let calendar = Calendar.current
        let planned = plan(minutes: minutes, loggedDays: loggedDays(from: now, in: context, calendar: calendar), now: now, calendar: calendar)
        for item in planned {
            let content = UNMutableNotificationContent()
            content.title = item.reminder.notificationTitle
            content.body = item.reminder.notificationBody
            content.sound = .default
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: item.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            do {
                try await center.add(UNNotificationRequest(identifier: item.identifier(calendar: calendar), content: content, trigger: trigger))
            } catch {
                reminderLog.error("Scheduling \(item.reminder.rawValue, privacy: .public) failed: \(error, privacy: .public)")
            }
        }
        reminderLog.info("Scheduled \(planned.count) reminders, first at \(planned.first?.fireDate.formatted() ?? "none", privacy: .public)")
    }

    /// The days from today on that already have steps, a weigh-in, or food under each meal.
    private static func loggedDays(from now: Date, in context: ModelContext, calendar: Calendar) -> [Reminder: Set<Date>] {
        let today = calendar.startOfDay(for: now)
        let steps = (try? context.fetch(FetchDescriptor<StepEntry>(predicate: #Predicate { $0.day >= today }))) ?? []
        let weights = (try? context.fetch(FetchDescriptor<WeightEntry>(predicate: #Predicate { $0.date >= today }))) ?? []
        let food = (try? context.fetch(FetchDescriptor<FoodEntry>(predicate: #Predicate { $0.date >= today }))) ?? []

        var logged: [Reminder: Set<Date>] = [
            .steps: Set(steps.filter { $0.steps > 0 }.map { calendar.startOfDay(for: $0.day) }),
            .weight: Set(weights.map { calendar.startOfDay(for: $0.date) }),
        ]
        for reminder in Reminder.allCases {
            guard let meal = reminder.mealType else { continue }
            logged[reminder] = Set(food.filter { $0.mealType == meal }.map { calendar.startOfDay(for: $0.date) })
        }
        return logged
    }
}
