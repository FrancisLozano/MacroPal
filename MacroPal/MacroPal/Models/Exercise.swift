//
//  Exercise.swift
//  MacroPal
//

import Foundation
import SwiftData

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, legs, shoulders, arms, core, fullBody, other

    var id: Self { self }

    var displayName: String {
        switch self {
        case .chest: "Chest"
        case .back: "Back"
        case .legs: "Legs"
        case .shoulders: "Shoulders"
        case .arms: "Arms"
        case .core: "Core"
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
