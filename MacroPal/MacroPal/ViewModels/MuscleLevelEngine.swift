//
//  MuscleLevelEngine.swift
//  MacroPal
//

import Foundation

/// One logged set, stripped to what levelling needs so the engine is testable without SwiftData.
struct LoggedSet {
    let date: Date
    let exerciseName: String
    let muscleGroup: MuscleGroup
    let weightKg: Double
    let reps: Int
}

/// Turns training history into a level (0 = untrained, 1…6 = Beginner…World Class) per muscle.
///
/// Two things have to agree. **Volume** — every set's weight × reps, credited to the muscles
/// it works by how much it works them, added up over all time and divided by your
/// bodyweight: "bodyweights moved". **Time** — how long you've trained the muscle, which caps
/// the level so a burst of volume can't skip the years. About 3 weeks of training reaches
/// Novice, about a year Advanced, and World Class takes 5 years or more. Since the total only
/// grows, a muscle never drops a level after a break.
enum MuscleLevelEngine {
    static let levelNames = ["Beginner", "Novice", "Intermediate", "Advanced", "Elite", "World Class"]

    /// Bodyweights of volume a muscle needs for each level, Beginner … World Class. Beginner is
    /// any training at all. A first guess (2026-09-23), sized for roughly 30 bodyweights a
    /// week per muscle early on, rising to about 50: tune after real use.
    static let levelMinimumBodyweights: [Double] = [0, 90, 600, 2_500, 7_500, 15_000]

    /// Months a muscle has to have been trained before each level is allowed — the tenure cap.
    static let levelMinimumMonths: [Double] = [0, 0.5, 3, 12, 36, 60]

    /// Women move less relative to bodyweight; their volume is divided by this.
    static let femaleFactor = 0.65
    /// Minimum involvement for a set to count as training a muscle at all.
    private static let trainedInvolvement = 0.5

    /// Each muscle's volume in kg, credited by involvement. Bodyweight movements need
    /// `bodyweightKg` for their load; without it only their added weight counts.
    static func volumeKg(sets: [LoggedSet], bodyweightKg: Double?) -> [Muscle: Double] {
        var volume: [Muscle: Double] = [:]
        for set in sets where set.reps > 0 {
            let profile = ExerciseMuscleData.profile(forName: set.exerciseName, group: set.muscleGroup)
            let setVolume = load(of: set, profile: profile, bodyweightKg: bodyweightKg) * Double(set.reps)
            guard setVolume > 0 else { continue }
            for (muscle, involvement) in profile.muscles {
                volume[muscle, default: 0] += setVolume * involvement
            }
        }
        return volume
    }

    /// The weight one rep moves: the logged weight (both dumbbells, machines scaled down), plus a
    /// share of bodyweight for bodyweight movements.
    static func load(of set: LoggedSet, profile: ExerciseProfile, bodyweightKg: Double?) -> Double {
        let bodyweightPart = (profile.bodyweightShare ?? 0) * (bodyweightKg ?? 0)
        return max(0, set.weightKg) * profile.loadScale + bodyweightPart
    }

    static func levels(sets: [LoggedSet], bodyweightKg: Double?, sex: Sex, now: Date = .now) -> [Muscle: Int] {
        var firstTrained: [Muscle: Date] = [:]
        for set in sets {
            let profile = ExerciseMuscleData.profile(forName: set.exerciseName, group: set.muscleGroup)
            for (muscle, involvement) in profile.muscles where involvement >= trainedInvolvement {
                firstTrained[muscle] = min(firstTrained[muscle] ?? set.date, set.date)
            }
        }

        let volume = volumeKg(sets: sets, bodyweightKg: bodyweightKg)
        var result: [Muscle: Int] = [:]
        for (muscle, start) in firstTrained {
            var level = 1
            if let bodyweightKg, bodyweightKg > 0 {
                let moved = bodyweightsMoved(volumeKg: volume[muscle] ?? 0, bodyweightKg: bodyweightKg, sex: sex)
                let months = now.timeIntervalSince(start) / (30.44 * 86_400)
                level = max(1, min(self.level(forBodyweights: moved), tenureCap(months: months)))
            }
            result[muscle] = level
        }
        return result
    }

    static func bodyweightsMoved(volumeKg: Double, bodyweightKg: Double, sex: Sex) -> Double {
        volumeKg / bodyweightKg / (sex == .female ? femaleFactor : 1)
    }

    /// How many level minimums `bodyweights` has reached (1…6 once trained at all).
    static func level(forBodyweights bodyweights: Double) -> Int {
        levelMinimumBodyweights.filter { bodyweights >= $0 }.count
    }

    /// Highest level allowed for a muscle trained for `months`.
    static func tenureCap(months: Double) -> Int {
        levelMinimumMonths.filter { months >= $0 }.count
    }
}
