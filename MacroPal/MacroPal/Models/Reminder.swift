//
//  Reminder.swift
//  MacroPal
//

import Foundation

/// A daily nudge to log something, set in Profile → Reminders. Each one is on or off with its
/// own time — device preferences in `UserDefaults`, like `WorkoutPreferences`. Off until turned
/// on, since turning one on asks for notification permission.
enum Reminder: String, CaseIterable, Identifiable {
    case steps, weight, breakfast, lunch, dinner

    var id: Self { self }

    var enabledKey: String { "reminder.\(rawValue).enabled" }
    /// Minutes after midnight.
    var minuteKey: String { "reminder.\(rawValue).minute" }

    /// The meal a food reminder is for; `nil` for steps and weight.
    var mealType: MealType? {
        switch self {
        case .steps, .weight: nil
        case .breakfast: .breakfast
        case .lunch: .lunch
        case .dinner: .dinner
        }
    }

    /// The food reminder for `meal`; `nil` for Snack, which has none.
    init?(meal: MealType) {
        guard let reminder = Self.allCases.first(where: { $0.mealType == meal }) else { return nil }
        self = reminder
    }

    /// Steps and weight at 9 PM; a meal at the end of its time frame (10:00 AM, 5:00 PM,
    /// 11:59 PM), the last moment it can still be logged under that meal.
    var defaultMinute: Int {
        guard let window = mealType?.defaultTimeWindow else { return 21 * 60 }
        return window.endHour * 60 + window.endMinute
    }

    var title: String {
        mealType?.displayName ?? (self == .steps ? "Steps" : "Weight")
    }

    var systemImage: String {
        switch self {
        case .steps: "figure.walk"
        case .weight: "scalemass"
        case .breakfast, .lunch, .dinner: mealType?.icon ?? "fork.knife"
        }
    }

    var notificationTitle: String {
        switch self {
        case .steps: "Log your steps"
        case .weight: "Log your weight"
        case .breakfast, .lunch, .dinner: "Log \(title.lowercased())"
        }
    }

    var notificationBody: String {
        switch self {
        case .steps: "Add today's step count before the day ends."
        case .weight: "Add today's weigh-in."
        case .breakfast, .lunch, .dinner: "Nothing is logged for \(title.lowercased()) today."
        }
    }

    func isEnabled(in defaults: UserDefaults) -> Bool {
        defaults.bool(forKey: enabledKey)
    }

    func minute(in defaults: UserDefaults) -> Int {
        defaults.object(forKey: minuteKey) as? Int ?? defaultMinute
    }
}
