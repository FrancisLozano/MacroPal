//
//  WorkoutPlan.swift
//  MacroPal
//

import Foundation
import SwiftData
import SwiftUI // for `Array.move(fromOffsets:toOffset:)`

/// The user's weekly training routine. Single-row in practice — there is one current plan.
@Model
final class WorkoutPlan {
    @Relationship(deleteRule: .cascade, inverse: \PlanDay.plan)
    var days: [PlanDay] = []

    init() {}

    /// Training days in calendar-week order (Sunday-first, matching `Calendar` weekday numbers).
    var sortedDays: [PlanDay] {
        days.sorted { $0.weekday < $1.weekday }
    }

    /// The workout scheduled on a `Calendar` weekday (1 = Sunday … 7 = Saturday), if any.
    func day(on weekday: Int) -> PlanDay? {
        days.first { $0.weekday == weekday }
    }

    /// Reorders the workouts while leaving the training weekdays (and so the rest days) where
    /// they are — the workouts swap places between those weekdays.
    func moveDays(from source: IndexSet, to destination: Int) {
        let ordered = sortedDays
        let weekdays = ordered.map(\.weekday)
        var reordered = ordered
        reordered.move(fromOffsets: source, toOffset: destination)
        for (day, weekday) in zip(reordered, weekdays) {
            day.weekday = weekday
        }
    }
}

/// One scheduled workout in a plan, e.g. "Push" on Monday.
@Model
final class PlanDay {
    var name: String
    var focus: String
    /// `Calendar` weekday number: 1 = Sunday … 7 = Saturday.
    var weekday: Int
    var plan: WorkoutPlan?

    @Relationship(deleteRule: .cascade, inverse: \PlanExercise.day)
    var exercises: [PlanExercise] = []

    init(name: String, focus: String, weekday: Int) {
        self.name = name
        self.focus = focus
        self.weekday = weekday
    }

    var sortedExercises: [PlanExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    /// Moves an exercise `offset` places up (negative) or down (positive) the day's list,
    /// clamped to the ends, and renumbers `order` so it stays contiguous.
    func move(_ planExercise: PlanExercise, by offset: Int) {
        var ordered = sortedExercises
        guard let index = ordered.firstIndex(where: { $0 === planExercise }) else { return }
        let target = min(max(index + offset, 0), ordered.count - 1)
        ordered.insert(ordered.remove(at: index), at: target)
        for (order, exercise) in ordered.enumerated() {
            exercise.order = order
        }
    }
}

/// An exercise slotted into a plan day, with its target sets × reps.
@Model
final class PlanExercise {
    var order: Int
    var targetSets: Int
    /// The target reps, or the bottom of the range when `targetRepsMax` is set.
    var targetReps: Int
    /// Top of a rep range ("8–10"), or nil for a single number. Defaulted where it's declared
    /// so existing stores migrate without a versioned schema.
    var targetRepsMax: Int? = nil
    var exercise: Exercise?
    var day: PlanDay?

    init(order: Int, exercise: Exercise, targetSets: Int = 3, targetReps: Int = 10) {
        self.order = order
        self.exercise = exercise
        self.targetSets = targetSets
        self.targetReps = targetReps
    }

    /// "10" or "8–10".
    var repsLabel: String {
        guard let targetRepsMax, targetRepsMax > targetReps else { return "\(targetReps)" }
        return "\(targetReps)–\(targetRepsMax)"
    }
}
