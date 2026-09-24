//
//  WorkoutProgressViewModel.swift
//  MacroPal
//

import Foundation
import SwiftData

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
    /// Load × reps summed over the sets, counted as the body map counts it: both dumbbells,
    /// machines scaled, a share of bodyweight for bodyweight moves.
    let volumeKg: Double

    var id: Date { date }
}

/// Read-side summaries of logged history for an exercise's Progress tab. Kept separate from
/// `WorkoutViewModel`, which is about logging sets.
@Observable
final class WorkoutProgressViewModel {
    /// Every session with `exercise`, newest first, with that exercise's sets in the order
    /// they were logged. `bodyweightKg` is the load of a bodyweight move (0 without it).
    func history(for exercise: Exercise, in sessions: [WorkoutSession], bodyweightKg: Double?) -> [ExerciseHistoryDay] {
        let profile = ExerciseMuscleData.profile(forName: exercise.name, group: exercise.muscleGroup)
        return sessions.compactMap { session -> ExerciseHistoryDay? in
            let sets = session.setEntries
                .filter { $0.exercise?.persistentModelID == exercise.persistentModelID }
                .sorted { $0.setNumber < $1.setNumber }
            guard !sets.isEmpty else { return nil }
            let volume = sets.reduce(0) { total, entry in
                let set = LoggedSet(
                    date: session.date, exerciseName: exercise.name, muscleGroup: exercise.muscleGroup,
                    weightKg: entry.weightKg, reps: entry.reps
                )
                return total + MuscleLevelEngine.load(of: set, profile: profile, bodyweightKg: bodyweightKg) * Double(max(0, entry.reps))
            }
            return ExerciseHistoryDay(
                date: session.date, planDayName: sets.compactMap(\.planDayName).first, sets: sets, volumeKg: volume
            )
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
