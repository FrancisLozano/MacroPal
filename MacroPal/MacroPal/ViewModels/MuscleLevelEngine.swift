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

/// One exercise's part of a muscle's volume, credited by how much it works the muscle.
struct MuscleContribution: Equatable {
    let exerciseName: String
    let volumeKg: Double
}

/// Where one muscle stands: its level, what it has moved, and what the next level asks for.
/// The body map's muscle detail shows it.
struct MuscleProgress: Equatable {
    /// 0 = untrained, 1…6 = Beginner…World Class.
    let level: Int
    let volumeKg: Double
    /// Biggest first.
    let contributions: [MuscleContribution]
    /// The volume the current level started at, and the one the next level needs — nil at
    /// World Class, before the muscle is trained, or without a bodyweight to measure against.
    let levelVolumeKg: Double?
    let nextLevelVolumeKg: Double?
    /// When the muscle will have been trained long enough for the next level; nil once it has.
    let nextLevelUnlocks: Date?

    /// How far through the current level the volume is, 0…1; 1 once the next level's volume
    /// is reached, even while time still holds the level back.
    var fractionToNextLevel: Double? {
        guard let levelVolumeKg, let nextLevelVolumeKg, nextLevelVolumeKg > levelVolumeKg else { return nil }
        return min(max((volumeKg - levelVolumeKg) / (nextLevelVolumeKg - levelVolumeKg), 0), 1)
    }
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

    /// When each muscle was first worked hard enough to count as trained — where its time
    /// on the tenure cap starts.
    private static func firstTrained(sets: [LoggedSet]) -> [Muscle: Date] {
        var firstTrained: [Muscle: Date] = [:]
        for set in sets {
            let profile = ExerciseMuscleData.profile(forName: set.exerciseName, group: set.muscleGroup)
            for (muscle, involvement) in profile.muscles where involvement >= trainedInvolvement {
                firstTrained[muscle] = min(firstTrained[muscle] ?? set.date, set.date)
            }
        }
        return firstTrained
    }

    static func levels(sets: [LoggedSet], bodyweightKg: Double?, sex: Sex, now: Date = .now) -> [Muscle: Int] {
        let firstTrained = firstTrained(sets: sets)
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

    /// `muscle`'s level, volume and the exercises it came from, and how far it is from the
    /// next level — the same numbers `levels` uses.
    static func progress(for muscle: Muscle, sets: [LoggedSet], bodyweightKg: Double?, sex: Sex, now: Date = .now) -> MuscleProgress {
        var byExercise: [String: Double] = [:]
        for set in sets where set.reps > 0 {
            let profile = ExerciseMuscleData.profile(forName: set.exerciseName, group: set.muscleGroup)
            guard let involvement = profile.muscles[muscle] else { continue }
            let credited = load(of: set, profile: profile, bodyweightKg: bodyweightKg) * Double(set.reps) * involvement
            if credited > 0 { byExercise[set.exerciseName, default: 0] += credited }
        }
        let contributions = byExercise
            .map { MuscleContribution(exerciseName: $0.key, volumeKg: $0.value) }
            .sorted { $0.volumeKg != $1.volumeKg ? $0.volumeKg > $1.volumeKg : $0.exerciseName < $1.exerciseName }
        let volumeKg = contributions.reduce(0) { $0 + $1.volumeKg }
        let level = levels(sets: sets, bodyweightKg: bodyweightKg, sex: sex, now: now)[muscle] ?? 0

        var levelVolumeKg: Double?
        var nextLevelVolumeKg: Double?
        var nextLevelUnlocks: Date?
        if level > 0, level < levelNames.count, let bodyweightKg, bodyweightKg > 0 {
            // A level's volume in kg: its bodyweights × your bodyweight (fewer for women).
            let kgPerBodyweight = bodyweightKg * (sex == .female ? femaleFactor : 1)
            levelVolumeKg = levelMinimumBodyweights[level - 1] * kgPerBodyweight
            nextLevelVolumeKg = levelMinimumBodyweights[level] * kgPerBodyweight
            if let start = firstTrained(sets: sets)[muscle] {
                let unlocks = start.addingTimeInterval(levelMinimumMonths[level] * 30.44 * 86_400)
                nextLevelUnlocks = unlocks > now ? unlocks : nil
            }
        }
        return MuscleProgress(
            level: level, volumeKg: volumeKg, contributions: contributions,
            levelVolumeKg: levelVolumeKg, nextLevelVolumeKg: nextLevelVolumeKg, nextLevelUnlocks: nextLevelUnlocks
        )
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
