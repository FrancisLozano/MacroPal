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
    func logSet(
        exercise: Exercise, weightKg: Double, reps: Int, on date: Date = .now,
        planDayName: String? = nil, context: ModelContext
    ) -> WorkoutSetEntry {
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
        setEntry.planDayName = planDayName
        setEntry.session = session
        context.insert(setEntry)
        return setEntry
    }

    /// The sets of `exercise` from the most recent session before `cutoff` that has any, in the
    /// order they were logged — the exercise screen's "Last:" values. `sessions` must be
    /// newest-first.
    static func lastSessionSets(for exercise: Exercise, in sessions: [WorkoutSession], before cutoff: Date) -> [WorkoutSetEntry] {
        for session in sessions where session.date < cutoff {
            let sets = session.setEntries
                .filter { $0.exercise == exercise }
                .sorted { $0.setNumber < $1.setNumber }
            if !sets.isEmpty { return sets }
        }
        return []
    }

    /// Set `index` (0-based) of a previous session, or its final set when it had fewer.
    static func lastValue(forSet index: Int, in lastSets: [WorkoutSetEntry]) -> WorkoutSetEntry? {
        index < lastSets.count ? lastSets[index] : lastSets.last
    }
}
