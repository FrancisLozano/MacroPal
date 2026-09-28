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

extension LoggedSet {
    /// Every set in `sessions` whose exercise still exists — what the body map and each
    /// exercise's muscle levels are worked out from.
    static func all(in sessions: [WorkoutSession]) -> [LoggedSet] {
        sessions.flatMap { session in
            session.setEntries.compactMap { entry -> LoggedSet? in
                guard let exercise = entry.exercise else { return nil }
                return LoggedSet(
                    date: session.date,
                    exerciseName: exercise.name,
                    muscleGroup: exercise.muscleGroup,
                    weightKg: entry.weightKg,
                    reps: entry.reps
                )
            }
        }
    }
}

/// One exercise's part of a muscle's volume, credited by how much it works the muscle.
struct MuscleContribution: Equatable {
    let exerciseName: String
    let volumeKg: Double
    /// Whether the muscle is one of the exercise's main movers, as on its Overview.
    let isPrimary: Bool
    /// The share of each set's volume the muscle gets, 0…1.
    let involvement: Double
}

/// Training done before MacroPal, entered in Profile → Past Training: counted as that many
/// months of time trained and as the volume the engine's own pacing puts at that many months,
/// for each muscle the plan worked when it was entered (`involvement`, 0…1, the most any plan
/// exercise works it). A secondary muscle gets its share of the volume but the full time.
struct PriorTraining: Equatable {
    let months: Int
    /// When the months were entered; they end here, so time keeps counting from it.
    let enteredOn: Date
    let involvement: [Muscle: Double]

    /// When the past training is taken to have started.
    var startDate: Date {
        enteredOn.addingTimeInterval(-Double(months) * MuscleLevelEngine.secondsPerMonth)
    }

    /// Each muscle `plan` works, with the most any of its exercises works it.
    static func involvement(of plan: WorkoutPlan?) -> [Muscle: Double] {
        var involvement: [Muscle: Double] = [:]
        for day in plan?.days ?? [] {
            for exercise in day.exercises.compactMap(\.exercise) {
                let profile = ExerciseMuscleData.profile(forName: exercise.name, group: exercise.muscleGroup)
                for (muscle, share) in profile.muscles where share > 0 {
                    involvement[muscle] = max(involvement[muscle] ?? 0, share)
                }
            }
        }
        return involvement
    }

    /// The bodyweights moved credited to `muscle`.
    func bodyweights(for muscle: Muscle) -> Double {
        MuscleLevelEngine.bodyweights(afterMonths: Double(months)) * (involvement[muscle] ?? 0)
    }
}

extension UserProfile {
    /// The past training the level engine counts, or nil when starting over.
    var priorTraining: PriorTraining? {
        guard priorTrainingMonths > 0, let priorTrainingEnteredOn else { return nil }
        let involvement = Dictionary(uniqueKeysWithValues: priorTrainingInvolvement.compactMap { key, value in
            Muscle(rawValue: key).map { ($0, value) }
        })
        return PriorTraining(months: priorTrainingMonths, enteredOn: priorTrainingEnteredOn, involvement: involvement)
    }

    /// Counts `months` of past training for the muscles `plan` works, as of `now`; 0 starts over.
    func setPriorTraining(months: Int, plan: WorkoutPlan?, now: Date = .now) {
        guard months > 0 else {
            priorTrainingMonths = 0
            priorTrainingEnteredOn = nil
            priorTrainingInvolvement = [:]
            return
        }
        priorTrainingMonths = months
        priorTrainingEnteredOn = now
        priorTrainingInvolvement = Dictionary(uniqueKeysWithValues: PriorTraining.involvement(of: plan).map { ($0.key.rawValue, $0.value) })
    }
}

/// Where one muscle stands: its level, what it has moved, and what the next level asks for.
/// The body map's muscle detail shows it.
struct MuscleProgress: Equatable {
    /// 0 = untrained, 1…6 = Beginner…World Class.
    let level: Int
    let volumeKg: Double
    /// Biggest first.
    let contributions: [MuscleContribution]
    /// The part of `volumeKg` credited from past training (0 without it, or without a
    /// bodyweight to turn it into kg).
    var priorVolumeKg: Double = 0
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

    static let secondsPerMonth = 30.44 * 86_400

    /// The bodyweights moved a muscle trained steadily for `months` reaches, following the
    /// levels' own pacing: each level's minimum volume lands at its minimum months, straight
    /// lines between, and World Class's minimum from 5 years on. Past training is credited this.
    static func bodyweights(afterMonths months: Double) -> Double {
        guard months > 0 else { return 0 }
        for index in 1..<levelMinimumMonths.count where months < levelMinimumMonths[index] {
            let (startMonths, endMonths) = (levelMinimumMonths[index - 1], levelMinimumMonths[index])
            let (start, end) = (levelMinimumBodyweights[index - 1], levelMinimumBodyweights[index])
            return start + (end - start) * (months - startMonths) / (endMonths - startMonths)
        }
        return levelMinimumBodyweights[levelMinimumBodyweights.count - 1]
    }

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

    /// When each muscle was first worked, as a main mover or an assist — where its time on
    /// the tenure cap starts. Any set that credits a muscle counts as training it, and so does
    /// past training.
    private static func firstTrained(sets: [LoggedSet], prior: PriorTraining?) -> [Muscle: Date] {
        var firstTrained: [Muscle: Date] = [:]
        if let prior, prior.months > 0 {
            for (muscle, involvement) in prior.involvement where involvement > 0 {
                firstTrained[muscle] = prior.startDate
            }
        }
        for set in sets where set.reps > 0 {
            let profile = ExerciseMuscleData.profile(forName: set.exerciseName, group: set.muscleGroup)
            for (muscle, involvement) in profile.muscles where involvement > 0 {
                firstTrained[muscle] = min(firstTrained[muscle] ?? set.date, set.date)
            }
        }
        return firstTrained
    }

    static func levels(sets: [LoggedSet], bodyweightKg: Double?, sex: Sex, prior: PriorTraining? = nil, now: Date = .now) -> [Muscle: Int] {
        let firstTrained = firstTrained(sets: sets, prior: prior)
        let volume = volumeKg(sets: sets, bodyweightKg: bodyweightKg)
        var result: [Muscle: Int] = [:]
        for (muscle, start) in firstTrained {
            var level = 1
            if let bodyweightKg, bodyweightKg > 0 {
                let moved = bodyweightsMoved(volumeKg: volume[muscle] ?? 0, bodyweightKg: bodyweightKg, sex: sex)
                    + (prior?.bodyweights(for: muscle) ?? 0)
                let months = now.timeIntervalSince(start) / secondsPerMonth
                level = max(1, min(self.level(forBodyweights: moved), tenureCap(months: months)))
            }
            result[muscle] = level
        }
        return result
    }

    /// `muscle`'s level, volume and the exercises it came from, and how far it is from the
    /// next level — the same numbers `levels` uses.
    static func progress(for muscle: Muscle, sets: [LoggedSet], bodyweightKg: Double?, sex: Sex, prior: PriorTraining? = nil, now: Date = .now) -> MuscleProgress {
        var byExercise: [String: MuscleContribution] = [:]
        for set in sets where set.reps > 0 {
            let profile = ExerciseMuscleData.profile(forName: set.exerciseName, group: set.muscleGroup)
            guard let involvement = profile.muscles[muscle] else { continue }
            let credited = load(of: set, profile: profile, bodyweightKg: bodyweightKg) * Double(set.reps) * involvement
            guard credited > 0 else { continue }
            let soFar = byExercise[set.exerciseName]?.volumeKg ?? 0
            byExercise[set.exerciseName] = MuscleContribution(
                exerciseName: set.exerciseName, volumeKg: soFar + credited,
                isPrimary: profile.primaryMuscles.contains(muscle), involvement: involvement
            )
        }
        let contributions = byExercise.values
            .sorted { $0.volumeKg != $1.volumeKg ? $0.volumeKg > $1.volumeKg : $0.exerciseName < $1.exerciseName }
        // Past training in kg: its bodyweights × your bodyweight (fewer for women), as below.
        var priorVolumeKg = 0.0
        if let prior, let bodyweightKg, bodyweightKg > 0 {
            priorVolumeKg = prior.bodyweights(for: muscle) * bodyweightKg * (sex == .female ? femaleFactor : 1)
        }
        let volumeKg = contributions.reduce(priorVolumeKg) { $0 + $1.volumeKg }
        let level = levels(sets: sets, bodyweightKg: bodyweightKg, sex: sex, prior: prior, now: now)[muscle] ?? 0

        var levelVolumeKg: Double?
        var nextLevelVolumeKg: Double?
        var nextLevelUnlocks: Date?
        if level > 0, level < levelNames.count, let bodyweightKg, bodyweightKg > 0 {
            // A level's volume in kg: its bodyweights × your bodyweight (fewer for women).
            let kgPerBodyweight = bodyweightKg * (sex == .female ? femaleFactor : 1)
            levelVolumeKg = levelMinimumBodyweights[level - 1] * kgPerBodyweight
            nextLevelVolumeKg = levelMinimumBodyweights[level] * kgPerBodyweight
            if let start = firstTrained(sets: sets, prior: prior)[muscle] {
                let unlocks = start.addingTimeInterval(levelMinimumMonths[level] * secondsPerMonth)
                nextLevelUnlocks = unlocks > now ? unlocks : nil
            }
        }
        return MuscleProgress(
            level: level, volumeKg: volumeKg, contributions: contributions, priorVolumeKg: priorVolumeKg,
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

    /// The level a muscle worked fully (a main mover) starts at after `months` of past
    /// training: 1…6, Beginner…World Class.
    static func startingLevel(afterMonths months: Double) -> Int {
        max(1, min(level(forBodyweights: bodyweights(afterMonths: months)), tenureCap(months: months)))
    }

    /// Highest level allowed for a muscle trained for `months`.
    static func tenureCap(months: Double) -> Int {
        levelMinimumMonths.filter { months >= $0 }.count
    }
}
