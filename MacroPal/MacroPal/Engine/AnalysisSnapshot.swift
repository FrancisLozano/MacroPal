//
//  AnalysisSnapshot.swift
//  MacroPal
//

import Foundation

/// The bundled input every analysis rule reads from. One consistent shape for every rule,
/// rather than per-rule parameter lists, and a single obvious place to build test fixtures.
struct AnalysisSnapshot {
    let profile: UserProfile
    let weightEntries: [WeightEntry]
    let foodEntries: [FoodEntry]
    let workoutSessions: [WorkoutSession]
    let referenceDate: Date
    let calendar: Calendar
    /// How weights read in messages — the user's lb/kg setting.
    let weightUnit: WeightUnit

    init(
        profile: UserProfile,
        weightEntries: [WeightEntry],
        foodEntries: [FoodEntry],
        workoutSessions: [WorkoutSession],
        referenceDate: Date = .now,
        calendar: Calendar = .current,
        weightUnit: WeightUnit = .kg
    ) {
        self.profile = profile
        self.weightEntries = weightEntries
        self.foodEntries = foodEntries
        self.workoutSessions = workoutSessions
        self.referenceDate = referenceDate
        self.calendar = calendar
        self.weightUnit = weightUnit
    }
}
