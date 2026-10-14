//
//  GoalWording.swift
//  MacroPal
//

import Foundation

/// How the app says where a day stands against a goal: "1,150 left" under it, "250 above
/// goal" past it, shown in the same quiet secondary color either way. In the user
/// interviews (#3, #4, #5, #8), red numbers and "over" were reasons people quit tracking.
/// The widget keeps its red "kcal over" (the user's choice, 2026-10-10).
enum GoalWording {
    /// - Parameters:
    ///   - remaining: goal minus eaten; negative past the goal.
    ///   - unit: appended to the number, e.g. "g".
    ///   - underGoal: the word while under the goal ("left", or "remaining" for macros).
    static func remaining(_ remaining: Double, unit: String = "", underGoal: String = "left") -> String {
        let amount = Int(abs(remaining).rounded()).formatted()
        return remaining >= 0 ? "\(amount)\(unit) \(underGoal)" : "\(amount)\(unit) above goal"
    }
}
