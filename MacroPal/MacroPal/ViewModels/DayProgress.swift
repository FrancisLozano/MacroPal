//
//  DayProgress.swift
//  MacroPal
//

import Foundation

/// How far a plan day's workout has got in one session: how many of its exercises have their
/// target sets logged, how many of its sets are logged and the volume they moved. The Current
/// Plan card's today row and the day's own screen both read it, so "done" means the same in
/// both places.
struct DayProgress: Equatable {
    /// Exercises on the day (ones whose exercise still exists).
    let exercises: Int
    /// Exercises with at least their target sets logged.
    let exercisesDone: Int
    /// Sets of the day's exercises logged in the session.
    let setsLogged: Int
    /// Volume of those sets, counted like the Progress tab (see `volumeKg(of:bodyweightKg:)`).
    let volumeKg: Double

    /// Every exercise on the day has its target sets logged.
    var isComplete: Bool { exercises > 0 && exercisesDone == exercises }

    init(exercises: Int, exercisesDone: Int, setsLogged: Int, volumeKg: Double = 0) {
        self.exercises = exercises
        self.exercisesDone = exercisesDone
        self.setsLogged = setsLogged
        self.volumeKg = volumeKg
    }

    init(day: PlanDay, session: WorkoutSession?, bodyweightKg: Double? = nil) {
        let planned = day.exercises.filter { $0.exercise != nil }
        let daySets = (session?.setEntries ?? []).filter { entry in
            planned.contains { $0.exercise == entry.exercise }
        }
        func logged(_ planExercise: PlanExercise) -> Int {
            daySets.filter { $0.exercise == planExercise.exercise }.count
        }
        exercises = planned.count
        exercisesDone = planned.filter { logged($0) >= $0.targetSets }.count
        setsLogged = daySets.count
        volumeKg = Self.volumeKg(of: daySets, bodyweightKg: bodyweightKg)
    }

    /// Weight × reps of each set, counted the way the Progress tab and the body map count it
    /// (both dumbbells, machines scaled, a share of bodyweight for bodyweight moves).
    static func volumeKg(of sets: [WorkoutSetEntry], bodyweightKg: Double?) -> Double {
        sets.reduce(0) { total, entry in
            guard let exercise = entry.exercise else { return total }
            let set = LoggedSet(date: entry.session?.date ?? .now, exerciseName: exercise.name,
                                muscleGroup: exercise.muscleGroup, weightKg: entry.weightKg, reps: entry.reps)
            let profile = ExerciseMuscleData.profile(forName: exercise.name, group: exercise.muscleGroup)
            let load = MuscleLevelEngine.load(of: set, profile: profile, bodyweightKg: bodyweightKg)
            return total + load * Double(max(0, entry.reps))
        }
    }
}
