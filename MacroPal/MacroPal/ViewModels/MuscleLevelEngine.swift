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
/// Two things have to agree. **Strength** — your best recent estimated 1RM on an exercise
/// that works the muscle, as a multiple of bodyweight, against that exercise's standards.
/// **Tenure** — how long you've actually trained the muscle, which caps the level so a
/// single heavy day can't skip the years. A muscle you've trained for about a year can reach
/// Advanced (blue); Elite and World Class take several.
enum MuscleLevelEngine {
    static let levelNames = ["Beginner", "Novice", "Intermediate", "Advanced", "Elite", "World Class"]

    /// Only recent lifting counts toward strength, so a level reflects current shape.
    static let recentWindowDays = 90
    /// Women's standards run lower relative to bodyweight; ratios are divided by this.
    static let femaleFactor = 0.65
    /// Minimum involvement for a set to count as training a muscle at all.
    private static let trainedInvolvement = 0.5

    static func levels(sets: [LoggedSet], bodyweightKg: Double?, sex: Sex, now: Date = .now) -> [Muscle: Int] {
        let recentCutoff = Calendar.current.date(byAdding: .day, value: -recentWindowDays, to: now) ?? now
        var firstTrained: [Muscle: Date] = [:]
        var strengthLevel: [Muscle: Int] = [:]

        for set in sets {
            let profile = ExerciseMuscleData.profile(forName: set.exerciseName, group: set.muscleGroup)
            for (muscle, involvement) in profile.muscles where involvement >= trainedInvolvement {
                if let existing = firstTrained[muscle] {
                    firstTrained[muscle] = min(existing, set.date)
                } else {
                    firstTrained[muscle] = set.date
                }
            }

            guard set.date >= recentCutoff, set.weightKg > 0, set.reps > 0,
                  let strengthClass = profile.strengthClass,
                  let bodyweightKg, bodyweightKg > 0
            else { continue }

            let oneRepMax = OneRepMaxEstimator.epley(weightKg: set.weightKg * profile.loadScale, reps: set.reps)
            let ratio = oneRepMax / bodyweightKg / (sex == .female ? femaleFactor : 1)
            for (muscle, involvement) in profile.muscles {
                let level = level(forRatio: ratio * involvement, thresholds: strengthClass.maleThresholds)
                strengthLevel[muscle] = max(strengthLevel[muscle] ?? 0, level)
            }
        }

        var result: [Muscle: Int] = [:]
        for (muscle, start) in firstTrained {
            let months = now.timeIntervalSince(start) / (30.44 * 86_400)
            let capped = min(strengthLevel[muscle] ?? 0, tenureCap(months: months))
            result[muscle] = max(1, capped)
        }
        return result
    }

    /// How many of `thresholds` the ratio has reached (0…6).
    static func level(forRatio ratio: Double, thresholds: [Double]) -> Int {
        thresholds.filter { ratio >= $0 }.count
    }

    /// Months a muscle has to have been trained before each level (Beginner … World Class) is
    /// allowed — the tenure cap, also shown in the body map's level explanation.
    static let levelMinimumMonths: [Double] = [0, 1, 4, 12, 36, 60]

    /// Highest level allowed for a muscle trained for `months`.
    static func tenureCap(months: Double) -> Int {
        levelMinimumMonths.filter { months >= $0 }.count
    }
}
