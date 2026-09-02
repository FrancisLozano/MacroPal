//
//  WorkoutSetEntry.swift
//  MacroPal
//

import Foundation
import SwiftData

@Model
final class WorkoutSetEntry {
    var setNumber: Int
    var weightKg: Double
    var reps: Int
    /// Rate of perceived exertion, optional.
    var rpe: Double?

    var session: WorkoutSession?

    @Relationship(deleteRule: .nullify)
    var exercise: Exercise?

    init(setNumber: Int, weightKg: Double, reps: Int, rpe: Double? = nil, exercise: Exercise? = nil) {
        self.setNumber = setNumber
        self.weightKg = weightKg
        self.reps = reps
        self.rpe = rpe
        self.exercise = exercise
    }
}
