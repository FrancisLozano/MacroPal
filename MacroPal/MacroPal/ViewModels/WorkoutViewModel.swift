//
//  WorkoutViewModel.swift
//  MacroPal
//

import Foundation
import SwiftUI
import SwiftData

/// One not-yet-persisted set row in an in-progress workout session.
struct DraftSetEntry: Identifiable {
    let id = UUID()
    var exercise: Exercise
    var weightKg: Double
    var reps: Int
    var rpe: Double?
}

@Observable
final class WorkoutViewModel {
    private(set) var draftSets: [DraftSetEntry] = []

    func addSet(exercise: Exercise, weightKg: Double, reps: Int, rpe: Double?) {
        draftSets.append(DraftSetEntry(exercise: exercise, weightKg: weightKg, reps: reps, rpe: rpe))
    }

    func removeSet(at offsets: IndexSet) {
        draftSets.remove(atOffsets: offsets)
    }

    /// Defaults for the next set row — same exercise/weight/reps as the last set, if any.
    var nextSetDefaults: (exercise: Exercise?, weightKg: Double, reps: Int) {
        guard let last = draftSets.last else { return (nil, 0, 0) }
        return (last.exercise, last.weightKg, last.reps)
    }

    /// Atomically inserts one `WorkoutSession` and all its draft `WorkoutSetEntry` children.
    func saveSession(date: Date, notes: String?, context: ModelContext) {
        let session = WorkoutSession(date: date, notes: notes)
        context.insert(session)
        for (index, draft) in draftSets.enumerated() {
            let setEntry = WorkoutSetEntry(
                setNumber: index + 1,
                weightKg: draft.weightKg,
                reps: draft.reps,
                rpe: draft.rpe,
                exercise: draft.exercise
            )
            setEntry.session = session
            context.insert(setEntry)
        }
    }

    /// Logs one set straight into the session for `date`'s day, creating that session if this
    /// is the first set of the day. Used by the plan's inline logging, which has no draft step.
    func logSet(exercise: Exercise, weightKg: Double, reps: Int, on date: Date = .now, context: ModelContext) {
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
