//
//  DayProgress.swift
//  MacroPal
//

import Foundation

/// How far a plan day's workout has got in one session: how many of its exercises have their
/// target sets logged, and how many of its sets are logged. The Current Plan card's today row
/// and the day's own screen both read it, so "done" means the same in both places.
struct DayProgress: Equatable {
    /// Exercises on the day (ones whose exercise still exists).
    let exercises: Int
    /// Exercises with at least their target sets logged.
    let exercisesDone: Int
    /// Sets of the day's exercises logged in the session.
    let setsLogged: Int

    /// Every exercise on the day has its target sets logged.
    var isComplete: Bool { exercises > 0 && exercisesDone == exercises }

    init(exercises: Int, exercisesDone: Int, setsLogged: Int) {
        self.exercises = exercises
        self.exercisesDone = exercisesDone
        self.setsLogged = setsLogged
    }

    init(day: PlanDay, session: WorkoutSession?) {
        let planned = day.exercises.filter { $0.exercise != nil }
        let entries = session?.setEntries ?? []
        func logged(_ planExercise: PlanExercise) -> Int {
            entries.filter { $0.exercise == planExercise.exercise }.count
        }
        exercises = planned.count
        exercisesDone = planned.filter { logged($0) >= $0.targetSets }.count
        setsLogged = planned.reduce(0) { $0 + logged($1) }
    }
}
