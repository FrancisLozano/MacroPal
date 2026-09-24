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

/// An exercise's volume at a glance: all time, and this calendar week against the last.
struct VolumeSummary: Equatable {
    let totalKg: Double
    let thisWeekKg: Double
    let lastWeekKg: Double
}

/// One day's sets of an exercise, for its Progress tab history.
struct ExerciseHistoryDay: Identifiable {
    let date: Date
    /// The plan day the sets were logged from ("Legs & Abs"), nil when unplanned.
    let planDayName: String?
    let sets: [WorkoutSetEntry]

    var id: Date { date }

    /// Weight × reps summed over the sets.
    var volumeKg: Double {
        sets.reduce(0) { $0 + $1.weightKg * Double($1.reps) }
    }
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

    /// One point per session containing the exercise, using that session's top set (max
    /// weight, tie-broken by higher reps). `estimated1RM` is the best estimate from *any* set
    /// that session — a lighter set for more reps can out-estimate the top set, and the chart's
    /// headline "best estimated 1RM" must match its highest point. Sessions without the exercise are skipped
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
                estimated1RM: sets.map { OneRepMaxEstimator.epley(weightKg: $0.weightKg, reps: $0.reps) }.max() ?? 0
            )
        }
        .sorted { $0.date < $1.date }
    }

    /// Every session with `exercise`, newest first, with that exercise's sets in the order
    /// they were logged.
    func history(for exercise: Exercise, in sessions: [WorkoutSession]) -> [ExerciseHistoryDay] {
        sessions.compactMap { session -> ExerciseHistoryDay? in
            let sets = session.setEntries
                .filter { $0.exercise?.persistentModelID == exercise.persistentModelID }
                .sorted { $0.setNumber < $1.setNumber }
            guard !sets.isEmpty else { return nil }
            return ExerciseHistoryDay(date: session.date, planDayName: sets.compactMap(\.planDayName).first, sets: sets)
        }
        .sorted { $0.date > $1.date }
    }

    /// Total volume in `history`, and the current and previous calendar weeks' (by
    /// `calendar`'s first weekday).
    func volumeSummary(_ history: [ExerciseHistoryDay], now: Date = .now, calendar: Calendar = .current) -> VolumeSummary {
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)
        let lastWeek = thisWeek.flatMap { calendar.dateInterval(of: .weekOfYear, for: $0.start.addingTimeInterval(-1)) }
        func volume(in interval: DateInterval?) -> Double {
            guard let interval else { return 0 }
            return history.filter { interval.contains($0.date) && $0.date < interval.end }.reduce(0) { $0 + $1.volumeKg }
        }
        return VolumeSummary(
            totalKg: history.reduce(0) { $0 + $1.volumeKg },
            thisWeekKg: volume(in: thisWeek),
            lastWeekKg: volume(in: lastWeek)
        )
    }
}
