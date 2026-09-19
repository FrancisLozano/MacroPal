//
//  Muscle.swift
//  MacroPal
//

import Foundation

/// The finer-grained muscles the body map draws and levels. `MuscleGroup` (on `Exercise`) is
/// the coarse label a user picks; this is what an exercise actually works.
enum Muscle: String, CaseIterable, Identifiable {
    case chest, shoulders, biceps, triceps, forearms
    case abs, obliques, traps, lats, lowerBack
    case glutes, quads, hamstrings, calves

    var id: Self { self }

    var displayName: String {
        switch self {
        case .chest: "Chest"
        case .shoulders: "Shoulders"
        case .biceps: "Biceps"
        case .triceps: "Triceps"
        case .forearms: "Forearms"
        case .abs: "Abs"
        case .obliques: "Obliques"
        case .traps: "Traps"
        case .lats: "Lats"
        case .lowerBack: "Lower Back"
        case .glutes: "Glutes"
        case .quads: "Quads"
        case .hamstrings: "Hamstrings"
        case .calves: "Calves"
        }
    }
}
