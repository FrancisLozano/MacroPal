//
//  WorkoutViewModel.swift
//  MacroPal
//

import Foundation
import SwiftUI
import SwiftData

@Observable
final class WorkoutViewModel {
    /// Logs one set straight into the session for `date`'s day, creating that session if this
    /// is the first set of the day.
    @discardableResult
    func logSet(exercise: Exercise, weightKg: Double, reps: Int, on date: Date = .now, context: ModelContext) -> WorkoutSetEntry {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? date
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.date >= dayStart && $0.date < dayEnd },
            sortBy: [SortDescriptor(\.date)]
        )
        let session: WorkoutSession
        if let existing = (try? context.fetch(descriptor))?.first {
            session = existing
        } else {
            session = WorkoutSession(date: date)
            context.insert(session)
        }
        let setEntry = WorkoutSetEntry(
            setNumber: session.setEntries.count + 1,
            weightKg: weightKg,
            reps: reps,
            exercise: exercise
        )
        setEntry.session = session
        context.insert(setEntry)
        return setEntry
    }

    /// The best estimated one-rep max (kg) across the logged sets of `exercise` from sessions
    /// before `cutoff`, used as the reference a planned set's weight is shown as a percentage of.
    /// The tracking screen passes the start of today, so today's sets are never measured against
    /// themselves (a first-ever set would otherwise read as ~80% of its own 1RM).
    static func bestEstimated1RMKg(for exercise: Exercise, in sessions: [WorkoutSession], before cutoff: Date = .distantFuture) -> Double? {
        sessions
            .filter { $0.date < cutoff }
            .flatMap(\.setEntries)
            .filter { $0.exercise == exercise && $0.reps > 0 }
            .map { OneRepMaxEstimator.epley(weightKg: $0.weightKg, reps: $0.reps) }
            .max()
    }

    /// The most recent set logged for `exercise` in `sessions` (which must be newest-first).
    static func lastSet(for exercise: Exercise, in sessions: [WorkoutSession]) -> WorkoutSetEntry? {
        for session in sessions {
            let sets = session.setEntries
                .filter { $0.exercise == exercise }
                .sorted { $0.setNumber < $1.setNumber }
            if let last = sets.last { return last }
        }
        return nil
    }
}
