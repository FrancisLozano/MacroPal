//
//  WorkoutProgressViewModel.swift
//  MacroPal
//

import Foundation
import SwiftData

struct ExerciseProgressPoint: Identifiable {
    let date: Date
    let topSetWeightKg: Double
    let topSetReps: Int
    let estimated1RM: Double

    var id: Date { date }
}

/// Read-side aggregation for the workout progression chart. Kept separate from
/// `WorkoutViewModel`, which is entirely about the logging draft-state flow — a different
/// concern from summarizing already-logged history.
@Observable
final class WorkoutProgressViewModel {
    /// `Exercise` has no inverse relationship to `WorkoutSetEntry` (it's a unidirectional
    /// `.nullify` link from the set's side), so distinct logged exercises must be derived
    /// by walking sessions rather than queried directly.
    func loggedExercises(from sessions: [WorkoutSession]) -> [Exercise] {
        var seen = Set<PersistentIdentifier>()
        var result: [Exercise] = []
        for exercise in sessions.flatMap(\.setEntries).compactMap(\.exercise) {
            if seen.insert(exercise.persistentModelID).inserted {
                result.append(exercise)
            }
        }
        return result.sorted { $0.name < $1.name }
    }

    /// The exercise that appears in the most recently logged session, used as a sensible
    /// default selection so the screen isn't empty-by-default on first visit.
    func mostRecentlyLoggedExercise(from sessions: [WorkoutSession]) -> Exercise? {
        sessions
            .sorted { $0.date > $1.date }
            .first { !$0.setEntries.isEmpty }?
            .setEntries.first?.exercise
    }

    /// One point per session containing the exercise, using that session's top set (max
    /// weight, tie-broken by higher reps). Sessions without the exercise are skipped
    /// entirely — unlike the macro chart, workout days are irregular by nature, so
    /// zero-filling would be misleading rather than informative.
    func progression(for exercise: Exercise, in sessions: [WorkoutSession]) -> [ExerciseProgressPoint] {
        sessions.compactMap { session -> ExerciseProgressPoint? in
            let sets = session.setEntries.filter { $0.exercise?.persistentModelID == exercise.persistentModelID }
            guard let topSet = sets.max(by: { a, b in
                a.weightKg == b.weightKg ? a.reps < b.reps : a.weightKg < b.weightKg
            }) else { return nil }
            return ExerciseProgressPoint(
                date: session.date,
                topSetWeightKg: topSet.weightKg,
                topSetReps: topSet.reps,
                estimated1RM: OneRepMaxEstimator.epley(weightKg: topSet.weightKg, reps: topSet.reps)
            )
        }
        .sorted { $0.date < $1.date }
    }
}
