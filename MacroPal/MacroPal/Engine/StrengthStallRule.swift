//
//  StrengthStallRule.swift
//  MacroPal
//

import Foundation

/// Flags a lift whose top-set weight hasn't increased in `consecutiveSessions` sessions at
/// the same rep count. Can fire once per stalled exercise — unlike the other rules, which
/// are single-shot, this one returns an insight per lift.
enum StrengthStallRule {
    static let consecutiveSessions = 4

    struct Result {
        let currentWeightKg: Double
        let reps: Int
        let sessionsChecked: Int
    }

    /// Core, pure-array logic — the primary unit-test target. `points` should be one
    /// exercise's progression, sorted ascending by date (see `WorkoutProgressViewModel.progression`).
    static func evaluate(points: [ExerciseProgressPoint]) -> Result? {
        guard let currentReps = points.last?.topSetReps else { return nil }

        // Same rep range = exact match for MVP; a rep-range band is a future refinement.
        let sameRepPoints = points.filter { $0.topSetReps == currentReps }
        guard sameRepPoints.count >= consecutiveSessions else { return nil }

        let window = sameRepPoints.suffix(consecutiveSessions)
        guard let first = window.first else { return nil }
        let stalled = window.dropFirst().allSatisfy { $0.topSetWeightKg <= first.topSetWeightKg }
        guard stalled else { return nil }

        return Result(currentWeightKg: window.last!.topSetWeightKg, reps: currentReps, sessionsChecked: window.count)
    }

    static func evaluate(_ snapshot: AnalysisSnapshot) -> [Insight] {
        let workoutVM = WorkoutProgressViewModel()
        let exercises = workoutVM.loggedExercises(from: snapshot.workoutSessions)

        return exercises.compactMap { exercise -> Insight? in
            let points = workoutVM.progression(for: exercise, in: snapshot.workoutSessions)
            guard let result = evaluate(points: points) else { return nil }

            return Insight(
                dateGenerated: snapshot.referenceDate,
                category: .training,
                severity: .suggestion,
                message: "\(exercise.name) has stalled at \(String(format: "%.1f", result.currentWeightKg)) kg × \(result.reps) for \(result.sessionsChecked) sessions. Consider a deload week or an accessory-volume change.",
                supportingMetric: "no top-set increase in \(result.sessionsChecked) consecutive sessions",
                ruleIdentifier: .strengthStall,
                relatedExerciseName: exercise.name
            )
        }
    }
}
