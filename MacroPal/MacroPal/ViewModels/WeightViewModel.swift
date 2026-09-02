//
//  WeightViewModel.swift
//  MacroPal
//

import Foundation
import SwiftData

/// Deliberately thin — logging a `WeightEntry` is simple enough to live directly in its
/// View. The one piece of real logic is updating the goal weight on the singleton profile.
@Observable
final class WeightViewModel {
    func updateGoalWeight(_ goalWeightKg: Double, on profile: UserProfile) {
        profile.goalWeightKg = goalWeightKg
    }
}
