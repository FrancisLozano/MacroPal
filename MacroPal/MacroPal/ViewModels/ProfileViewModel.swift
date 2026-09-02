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
}
