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
}
