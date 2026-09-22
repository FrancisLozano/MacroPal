//
//  LiftStandard.swift
//  MacroPal
//

import Foundation

/// Where one lift's estimated 1RM sits on its strength standard, and how far it is to the
/// next level — the "progress toward something" on the Exercise Progress screen.
///
/// Uses the same bodyweight multiples as the body map (`StrengthClass`), but for this lift
/// alone and without the body map's tenure cap: the cap answers "how developed is this
/// muscle", this answers "how strong is this lift". Weights are in logged load, so a
/// dumbbell target is per dumbbell, the same number you'd type into a set.
struct LiftStandard: Equatable {
    /// 0 (below Beginner) … 6 (World Class), as in `MuscleLevelEngine.levelNames`.
    let level: Int
    /// Estimated 1RM at which the current level starts; 0 below Beginner.
    let levelStartKg: Double
    /// Estimated 1RM at which the next level starts; nil at World Class.
    let nextLevelKg: Double?

    /// 0…1 through the current level, toward the next one. 1 at World Class.
    func progress(oneRepMaxKg: Double) -> Double {
        guard let nextLevelKg, nextLevelKg > levelStartKg else { return 1 }
        return min(1, max(0, (oneRepMaxKg - levelStartKg) / (nextLevelKg - levelStartKg)))
    }

    /// nil when the lift has no standard (bodyweight movements) or bodyweight is unknown.
    static func evaluate(
        exerciseName: String, group: MuscleGroup, oneRepMaxKg: Double, bodyweightKg: Double?, sex: Sex
    ) -> LiftStandard? {
        let profile = ExerciseMuscleData.profile(forName: exerciseName, group: group)
        guard let strengthClass = profile.strengthClass, let bodyweightKg, bodyweightKg > 0,
              profile.loadScale > 0
        else { return nil }

        let sexFactor = sex == .female ? MuscleLevelEngine.femaleFactor : 1
        let thresholdsKg = strengthClass.maleThresholds.map { $0 * bodyweightKg * sexFactor / profile.loadScale }
        let level = thresholdsKg.filter { oneRepMaxKg >= $0 }.count
        return LiftStandard(
            level: level,
            levelStartKg: level > 0 ? thresholdsKg[level - 1] : 0,
            nextLevelKg: level < thresholdsKg.count ? thresholdsKg[level] : nil
        )
    }
}
