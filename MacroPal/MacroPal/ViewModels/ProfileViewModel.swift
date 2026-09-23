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

    /// Whole years between `birthDate` and `now`.
    func age(birthDate: Date, now: Date = .now, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.year], from: birthDate, to: now).year ?? 0
    }

    /// The Personal Info row's summary: "Male · 24 · 170 cm · Sedentary" (or "5′7″").
    func personalSummary(
        sex: Sex, birthDate: Date, heightCm: Double, activityLevel: ActivityLevel,
        heightUnit: HeightUnit = .cm, now: Date = .now
    ) -> String {
        [sex.displayName, "\(age(birthDate: birthDate, now: now))", heightUnit.formatted(cm: heightCm), activityLevel.displayName]
            .joined(separator: " · ")
    }

    /// The Workout row's summary: "Reps first · 3 × 8–10 · Rest 2 min".
    func workoutSummary(weightFirst: Bool, sets: Int, reps: Int, repsMax: Int, restSeconds: Int, autoRest: Bool) -> String {
        let order = weightFirst ? "Weight first" : "Reps first"
        let target = "\(sets) × \(WorkoutPreferences.repsLabel(reps: reps, repsMax: repsMax))"
        let rest = "Rest \(WorkoutPreferences.restLabel(seconds: restSeconds))" + (autoRest ? ", auto" : "")
        return [order, target, rest].joined(separator: " · ")
    }

    /// The Daily Targets row's summary: "2,000 kcal · 150P · 200C · 65F".
    func targetsSummary(calorieTarget: Int, proteinTargetG: Int, carbTargetG: Int, fatTargetG: Int) -> String {
        "\(calorieTarget.formatted()) kcal · \(proteinTargetG)P · \(carbTargetG)C · \(fatTargetG)F"
    }
}
