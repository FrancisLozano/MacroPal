//
//  ExerciseMuscleData.swift
//  MacroPal
//

import Foundation

/// How strength on an exercise is judged against bodyweight. Each class carries the
/// bodyweight-multiple (estimated 1RM ÷ bodyweight, male) at which each level begins:
/// Beginner, Novice, Intermediate, Advanced, Elite, World Class.
///
/// These are approximations in the spirit of the published bodyweight-multiple strength
/// standards, not copied from one source — tune them here if a level feels off.
enum StrengthClass {
    case lowerCompound, press, pull, overhead, isolation

    var maleThresholds: [Double] {
        switch self {
        case .lowerCompound: [0.5, 1.0, 1.5, 2.0, 2.5, 3.0]
        case .press: [0.25, 0.6, 1.0, 1.5, 1.9, 2.3]
        case .pull: [0.3, 0.6, 0.9, 1.2, 1.5, 1.8]
        case .overhead: [0.2, 0.4, 0.65, 0.9, 1.15, 1.4]
        case .isolation: [0.1, 0.2, 0.35, 0.5, 0.7, 0.9]
        }
    }
}

/// What an exercise trains and how to score it.
struct ExerciseProfile {
    /// nil for bodyweight movements (plank, pull-up): they count as training a muscle but
    /// can't be judged against bodyweight from a logged load.
    let strengthClass: StrengthClass?
    /// Multiplies the logged load before comparing to bodyweight — 2 for a per-hand dumbbell
    /// lift (two dumbbells), below 1 for machines that load heavier than a barbell.
    let loadScale: Double
    /// Muscle → involvement, 1.0 primary down to ~0.3 for a minor assist.
    let muscles: [Muscle: Double]
}

enum ExerciseMuscleData {
    private static func profile(
        _ strengthClass: StrengthClass?, scale: Double = 1, _ muscles: [Muscle: Double]
    ) -> ExerciseProfile {
        ExerciseProfile(strengthClass: strengthClass, loadScale: scale, muscles: muscles)
    }

    /// Keyed by lowercased name — matches `StarterExerciseCatalog`.
    private static let byName: [String: ExerciseProfile] = [
        "barbell bench press": profile(.press, [.chest: 1, .shoulders: 0.6, .triceps: 0.6]),
        "incline barbell bench press": profile(.press, [.chest: 1, .shoulders: 0.7, .triceps: 0.6]),
        "dumbbell bench press": profile(.press, scale: 2, [.chest: 1, .shoulders: 0.6, .triceps: 0.6]),
        "incline dumbbell press": profile(.press, scale: 2, [.chest: 1, .shoulders: 0.7, .triceps: 0.6]),
        "cable chest fly": profile(.isolation, [.chest: 1, .shoulders: 0.3]),
        "push-up": profile(nil, [.chest: 1, .shoulders: 0.6, .triceps: 0.6, .abs: 0.3]),
        "chest dip": profile(nil, [.chest: 1, .triceps: 0.8, .shoulders: 0.5]),

        "deadlift": profile(.lowerCompound, [.hamstrings: 1, .glutes: 1, .lowerBack: 0.8, .quads: 0.6, .traps: 0.6, .forearms: 0.4, .lats: 0.4]),
        "pull-up": profile(nil, [.lats: 1, .biceps: 0.6, .forearms: 0.4, .traps: 0.4]),
        "lat pulldown": profile(.pull, [.lats: 1, .biceps: 0.6, .forearms: 0.3]),
        "barbell row": profile(.pull, [.lats: 1, .traps: 0.7, .biceps: 0.5, .lowerBack: 0.4]),
        "seated cable row": profile(.pull, [.lats: 1, .traps: 0.7, .biceps: 0.5]),
        "one-arm dumbbell row": profile(.pull, [.lats: 1, .traps: 0.6, .biceps: 0.5]),
        "face pull": profile(.isolation, [.shoulders: 1, .traps: 0.6]),

        "overhead press": profile(.overhead, [.shoulders: 1, .triceps: 0.6, .traps: 0.3]),
        "dumbbell shoulder press": profile(.overhead, scale: 2, [.shoulders: 1, .triceps: 0.6]),
        "lateral raise": profile(.isolation, scale: 2, [.shoulders: 1]),
        "rear delt fly": profile(.isolation, scale: 2, [.shoulders: 1, .traps: 0.4]),

        "barbell curl": profile(.isolation, [.biceps: 1, .forearms: 0.5]),
        "dumbbell curl": profile(.isolation, scale: 2, [.biceps: 1, .forearms: 0.4]),
        "hammer curl": profile(.isolation, scale: 2, [.biceps: 0.8, .forearms: 1]),
        "triceps pushdown": profile(.isolation, [.triceps: 1]),
        "skull crusher": profile(.isolation, [.triceps: 1]),
        "overhead triceps extension": profile(.isolation, [.triceps: 1]),

        "back squat": profile(.lowerCompound, [.quads: 1, .glutes: 0.8, .hamstrings: 0.4, .lowerBack: 0.3, .abs: 0.3]),
        "front squat": profile(.lowerCompound, [.quads: 1, .glutes: 0.6, .abs: 0.4]),
        "romanian deadlift": profile(.lowerCompound, [.hamstrings: 1, .glutes: 0.8, .lowerBack: 0.5]),
        "leg press": profile(.lowerCompound, scale: 0.6, [.quads: 1, .glutes: 0.7, .hamstrings: 0.3]),
        "walking lunge": profile(.lowerCompound, scale: 2, [.quads: 1, .glutes: 0.8, .hamstrings: 0.4]),
        "bulgarian split squat": profile(.lowerCompound, scale: 2, [.quads: 1, .glutes: 0.8]),
        "leg extension": profile(.isolation, [.quads: 1]),
        "leg curl": profile(.isolation, [.hamstrings: 1]),
        "hip thrust": profile(.lowerCompound, [.glutes: 1, .hamstrings: 0.5]),
        "standing calf raise": profile(.isolation, scale: 0.5, [.calves: 1]),

        "plank": profile(nil, [.abs: 1, .obliques: 0.6]),
        "hanging leg raise": profile(nil, [.abs: 1, .obliques: 0.5, .forearms: 0.3]),
        "cable crunch": profile(.isolation, [.abs: 1, .obliques: 0.4]),
        "ab wheel rollout": profile(nil, [.abs: 1, .obliques: 0.5]),
    ]

    /// A user-created exercise gets a coarse guess from its muscle group, scored as isolation.
    private static func fallback(for group: MuscleGroup) -> ExerciseProfile {
        switch group {
        case .chest: profile(.isolation, [.chest: 1, .shoulders: 0.4, .triceps: 0.4])
        case .back: profile(.isolation, [.lats: 1, .traps: 0.6, .biceps: 0.4])
        case .legs: profile(.isolation, [.quads: 1, .glutes: 0.6, .hamstrings: 0.6])
        case .shoulders: profile(.isolation, [.shoulders: 1])
        case .arms: profile(.isolation, [.biceps: 0.8, .triceps: 0.8])
        case .core: profile(nil, [.abs: 1, .obliques: 0.5])
        case .fullBody: profile(nil, [.quads: 0.5, .glutes: 0.5, .chest: 0.5, .lats: 0.5, .shoulders: 0.5])
        case .other: profile(nil, [:])
        }
    }

    static func profile(forName name: String, group: MuscleGroup) -> ExerciseProfile {
        byName[name.lowercased()] ?? fallback(for: group)
    }
}
