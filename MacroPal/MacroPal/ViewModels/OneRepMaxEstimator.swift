//
//  OneRepMaxEstimator.swift
//  MacroPal
//

import Foundation

/// Stateless estimated-1RM formulas. Kept as pure functions (no SwiftData/Observable
/// dependency) so Phase 3's analysis engine can reuse this without pulling in view state.
enum OneRepMaxEstimator {
    /// Epley formula. Chosen over Brzycki, which has a singularity at reps == 37 and
    /// produces nonsensical values above that — a real risk since `WorkoutSetEntry.reps`
    /// isn't capped.
    static func epley(weightKg: Double, reps: Int) -> Double {
        weightKg * (1 + Double(reps) / 30)
    }
}
