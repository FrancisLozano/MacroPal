//
//  ProfileViewModel.swift
//  MacroPal
//

import Foundation

/// Thin validation helper around editing `UserProfile`. Fetch-or-create logic for the
/// singleton row itself lives on `UserProfile.current(in:)`.
@Observable
final class ProfileViewModel {
    /// A soft, non-blocking hint shown when macro targets don't roughly add up to the
    /// calorie target (protein/carb at 4 kcal/g, fat at 9 kcal/g).
    func macroConsistencyHint(calorieTarget: Int, proteinTargetG: Int, carbTargetG: Int, fatTargetG: Int) -> String? {
        guard calorieTarget > 0 else { return nil }
        let macroCalories = proteinTargetG * 4 + carbTargetG * 4 + fatTargetG * 9
        let difference = abs(macroCalories - calorieTarget)
        guard Double(difference) > Double(calorieTarget) * 0.1 else { return nil }
        return "Your macro targets add up to \(macroCalories) kcal, which doesn't quite match your \(calorieTarget) kcal target."
    }

    /// Joins a number and its unit ("2 min", "3 × 8–10") with non-breaking spaces, so large
    /// text wraps the summary lines between values, never inside one.
    private func keepTogether(_ text: String) -> String {
        text.replacingOccurrences(of: " ", with: "\u{00A0}")
    }

    /// The Workout row's summary: "Reps first · 3 × 8–10 · Rest 2 min".
    func workoutSummary(weightFirst: Bool, sets: Int, reps: Int, repsMax: Int, restSeconds: Int, autoRest: Bool) -> String {
        let order = weightFirst ? "Weight first" : "Reps first"
        let target = keepTogether("\(sets) × \(WorkoutPreferences.repsLabel(reps: reps, repsMax: repsMax))")
        let rest = keepTogether("Rest \(WorkoutPreferences.restLabel(seconds: restSeconds))") + (autoRest ? ", auto" : "")
        return [order, target, rest].joined(separator: " · ")
    }

    /// Past Training: "Not counted", or the time — "8 months", "1 year", "2 years 3 months".
    func pastTrainingSummary(months: Int) -> String {
        guard months > 0 else { return "Not counted" }
        let (years, rest) = (months / 12, months % 12)
        let parts = [
            years > 0 ? keepTogether("\(years) \(years == 1 ? "year" : "years")") : nil,
            rest > 0 ? keepTogether("\(rest) \(rest == 1 ? "month" : "months")") : nil,
        ]
        return parts.compactMap { $0 }.joined(separator: " ")
    }

    /// The Reminders row's summary: "Off", "All", or the reminders that are on — "Steps,
    /// Weight, Dinner". Reminders switched on while iOS blocks notifications won't arrive, so
    /// the row says so instead of listing them.
    func remindersSummary(enabled: [Reminder], notificationsDenied: Bool = false) -> String {
        if enabled.isEmpty { return "Off" }
        if notificationsDenied { return "Off in iOS Settings" }
        if enabled.count == Reminder.allCases.count { return "All" }
        return enabled.map(\.title).joined(separator: ", ")
    }

    /// The Daily Targets row's summary: "2,000 kcal · 150P · 200C · 65F".
    func targetsSummary(calorieTarget: Int, proteinTargetG: Int, carbTargetG: Int, fatTargetG: Int) -> String {
        keepTogether("\(calorieTarget.formatted()) kcal") + " · \(proteinTargetG)P · \(carbTargetG)C · \(fatTargetG)F"
    }
}
