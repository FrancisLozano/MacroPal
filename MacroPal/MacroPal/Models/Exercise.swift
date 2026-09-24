//
//  Exercise.swift
//  MacroPal
//

import Foundation
import SwiftData

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, legs, shoulders, biceps, triceps, core, fullBody, other
    /// Replaced by `biceps` / `triceps` on 2026-09-23. Kept so exercises stored as "arms" still
    /// load; `StarterExerciseCatalog.regroup` moves them at launch. Not offered anywhere.
    case arms

    var id: Self { self }

    /// The groups offered when picking or creating an exercise, in the order the exercise
    /// picker's headings go.
    static let choices: [MuscleGroup] = [.chest, .triceps, .biceps, .back, .shoulders, .legs, .core, .fullBody, .other]

    var displayName: String {
        switch self {
        case .chest: "Chest"
        case .back: "Back"
        case .legs: "Legs"
        case .shoulders: "Shoulders"
        case .biceps: "Biceps"
        case .triceps: "Triceps"
        case .arms: "Arms"
        case .core: "Abs"
        case .fullBody: "Full Body"
        case .other: "Other"
        }
    }
}

/// A reusable exercise definition, e.g. "Barbell Bench Press".
@Model
final class Exercise {
    var name: String
    var muscleGroup: MuscleGroup
    /// Free text — gym equipment vocabulary is unbounded, unlike muscle groups.
    var equipment: String

    init(name: String, muscleGroup: MuscleGroup, equipment: String) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
    }
}
