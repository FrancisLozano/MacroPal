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
    /// The plan day ("Pull") the set was logged from — a copy of the name rather than a link,
    /// so history keeps it after the plan is edited. Nil for unplanned sets and ones logged
    /// before it was recorded. Defaulted where it's declared so existing stores migrate
    /// without a versioned schema.
    var planDayName: String? = nil

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
