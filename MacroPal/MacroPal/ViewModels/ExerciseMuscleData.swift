//
//  ExerciseMuscleData.swift
//  MacroPal
//

import Foundation

/// What an exercise trains and how to count its volume.
struct ExerciseProfile {
    /// For bodyweight movements (push-up, pull-up), the share of bodyweight a rep moves; the
    /// logged weight is added on top (a weighted pull-up). Nil for loaded lifts, where the
    /// logged weight is the load.
    let bodyweightShare: Double?
    /// Multiplies the logged load — 2 for a per-hand dumbbell lift (two dumbbells), below 1
    /// for machines that load heavier than a barbell.
    let loadScale: Double
    /// Muscle → involvement, 1.0 primary down to ~0.3 for a minor assist.
    let muscles: [Muscle: Double]

    /// Involvement from which a muscle counts as a main mover (solid on the thumbnail).
    static let primaryThreshold = 0.8

    /// The main movers, most involved first. When nothing reaches the threshold (a full-body
    /// guess), the most involved muscles stand in, so there's always a primary.
    var primaryMuscles: [Muscle] {
        let top = muscles.values.max() ?? 0
        let cutoff = min(Self.primaryThreshold, top)
        return ranked.filter { muscles[$0, default: 0] >= cutoff && top > 0 }
    }

    /// The assisting muscles, most involved first.
    var secondaryMuscles: [Muscle] {
        let primary = Set(primaryMuscles)
        return ranked.filter { !primary.contains($0) }
    }

    /// Worked muscles by involvement, ties in `Muscle` order (head to toe).
    private var ranked: [Muscle] {
        let order = Dictionary(uniqueKeysWithValues: Muscle.allCases.enumerated().map { ($1, $0) })
        return muscles.keys
            .filter { muscles[$0, default: 0] > 0 }
            .sorted { a, b in
                muscles[a] == muscles[b] ? order[a, default: 0] < order[b, default: 0] : muscles[a, default: 0] > muscles[b, default: 0]
            }
    }
}

enum ExerciseMuscleData {
    private static func profile(scale: Double = 1, _ muscles: [Muscle: Double]) -> ExerciseProfile {
        ExerciseProfile(bodyweightShare: nil, loadScale: scale, muscles: muscles)
    }

    private static func bodyweight(_ share: Double, _ muscles: [Muscle: Double]) -> ExerciseProfile {
        ExerciseProfile(bodyweightShare: share, loadScale: 1, muscles: muscles)
    }

    /// Keyed by lowercased name — matches `StarterExerciseCatalog`.
    private static let byName: [String: ExerciseProfile] = [
        "barbell bench press": profile([.chest: 1, .shoulders: 0.6, .triceps: 0.6]),
        "incline barbell bench press": profile([.chest: 1, .shoulders: 0.7, .triceps: 0.6]),
        "dumbbell bench press": profile(scale: 2, [.chest: 1, .shoulders: 0.6, .triceps: 0.6]),
        "incline dumbbell press": profile(scale: 2, [.chest: 1, .shoulders: 0.7, .triceps: 0.6]),
        "cable chest fly": profile([.chest: 1, .shoulders: 0.3]),
        "push-up": bodyweight(0.65, [.chest: 1, .shoulders: 0.6, .triceps: 0.6, .abs: 0.3]),
        "chest dip": bodyweight(0.9, [.chest: 1, .triceps: 0.8, .shoulders: 0.5]),

        "deadlift": profile([.hamstrings: 1, .glutes: 1, .lowerBack: 0.8, .quads: 0.6, .traps: 0.6, .forearms: 0.4, .lats: 0.4]),
        "pull-up": bodyweight(1.0, [.lats: 1, .biceps: 0.6, .forearms: 0.4, .traps: 0.4]),
        "lat pulldown": profile([.lats: 1, .biceps: 0.6, .forearms: 0.3]),
        "barbell row": profile([.lats: 1, .traps: 0.7, .biceps: 0.5, .lowerBack: 0.4]),
        "seated cable row": profile([.lats: 1, .traps: 0.7, .biceps: 0.5]),
        "one-arm dumbbell row": profile([.lats: 1, .traps: 0.6, .biceps: 0.5]),
        "face pull": profile([.shoulders: 1, .traps: 0.6]),

        "overhead press": profile([.shoulders: 1, .triceps: 0.6, .traps: 0.3]),
        "dumbbell shoulder press": profile(scale: 2, [.shoulders: 1, .triceps: 0.6]),
        "lateral raise": profile(scale: 2, [.shoulders: 1]),
        "rear delt fly": profile(scale: 2, [.shoulders: 1, .traps: 0.4]),

        "barbell curl": profile([.biceps: 1, .forearms: 0.5]),
        "dumbbell curl": profile(scale: 2, [.biceps: 1, .forearms: 0.4]),
        "hammer curl": profile(scale: 2, [.biceps: 0.8, .forearms: 1]),
        "triceps pushdown": profile([.triceps: 1]),
        "skull crusher": profile([.triceps: 1]),
        "overhead triceps extension": profile([.triceps: 1]),

        "back squat": profile([.quads: 1, .glutes: 0.8, .hamstrings: 0.4, .lowerBack: 0.3, .abs: 0.3]),
        "front squat": profile([.quads: 1, .glutes: 0.6, .abs: 0.4]),
        "romanian deadlift": profile([.hamstrings: 1, .glutes: 0.8, .lowerBack: 0.5]),
        "leg press": profile(scale: 0.6, [.quads: 1, .glutes: 0.7, .hamstrings: 0.3]),
        "walking lunge": profile(scale: 2, [.quads: 1, .glutes: 0.8, .hamstrings: 0.4]),
        "bulgarian split squat": profile(scale: 2, [.quads: 1, .glutes: 0.8]),
        "leg extension": profile([.quads: 1]),
        "leg curl": profile([.hamstrings: 1]),
        "hip thrust": profile([.glutes: 1, .hamstrings: 0.5]),
        "standing calf raise": profile(scale: 0.5, [.calves: 1]),

        "plank": bodyweight(0.1, [.abs: 1, .obliques: 0.6]),
        "hanging leg raise": bodyweight(0.3, [.abs: 1, .obliques: 0.5, .forearms: 0.3]),
        "cable crunch": profile([.abs: 1, .obliques: 0.4]),
        "ab wheel rollout": bodyweight(0.5, [.abs: 1, .obliques: 0.5]),
    ]

    /// A user-created exercise gets a coarse guess from its muscle group, loaded by what's logged.
    private static func fallback(for group: MuscleGroup) -> ExerciseProfile {
        switch group {
        case .chest: profile([.chest: 1, .shoulders: 0.4, .triceps: 0.4])
        case .back: profile([.lats: 1, .traps: 0.6, .biceps: 0.4])
        case .legs: profile([.quads: 1, .glutes: 0.6, .hamstrings: 0.6])
        case .shoulders: profile([.shoulders: 1])
        case .arms: profile([.biceps: 0.8, .triceps: 0.8])
        case .core: profile([.abs: 1, .obliques: 0.5])
        case .fullBody: profile([.quads: 0.5, .glutes: 0.5, .chest: 0.5, .lats: 0.5, .shoulders: 0.5])
        case .other: profile([:])
        }
    }

    static func profile(forName name: String, group: MuscleGroup) -> ExerciseProfile {
        byName[name.lowercased()] ?? fallback(for: group)
    }
}
