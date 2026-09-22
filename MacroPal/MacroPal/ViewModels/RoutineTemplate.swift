//
//  RoutineTemplate.swift
//  MacroPal
//

import Foundation
import SwiftData

/// Turns a set of training weekdays into a sensible split, and rebuilds a plan from one.
enum RoutineTemplate {
    static let daysPerWeekRange = 2...6

    struct Slot {
        let name: String
        let focus: String
    }

    private static let push = Slot(name: "Push", focus: "Chest, shoulders, triceps")
    private static let pull = Slot(name: "Pull", focus: "Back, biceps")
    private static let legs = Slot(name: "Legs", focus: "Quads, hamstrings, glutes, calves")
    private static let legsAndAbs = Slot(name: "Legs & Abs", focus: "Quads, hamstrings, glutes, core")
    private static let upper = Slot(name: "Upper", focus: "Chest, back, shoulders, arms")
    private static let lower = Slot(name: "Lower", focus: "Legs, glutes, core")

    static func slots(forDaysPerWeek count: Int) -> [Slot] {
        switch count {
        case ...2: [upper, lower]
        case 3: [push, pull, legs]
        case 4: [upper, lower, upper, lower]
        case 5: [push, pull, legsAndAbs, upper, lower]
        default: [push, pull, legs, push, pull, legs]
        }
    }

    /// Muscle groups a day of this name trains, for suggesting exercises. Empty for a name
    /// this file doesn't know.
    static func muscleGroups(forDayNamed name: String) -> [MuscleGroup] {
        switch name {
        case push.name: [.chest, .shoulders, .arms]
        case pull.name: [.back, .arms]
        case legs.name: [.legs]
        case legsAndAbs.name: [.legs, .core]
        case upper.name: [.chest, .back, .shoulders, .arms]
        case lower.name: [.legs, .core]
        default: []
        }
    }

    /// Pairs each slot with the first not-yet-claimed day of the same name. `claimed[i]` is the
    /// day slot `i` takes over (nil if none); `leftover` is every day no slot claimed — those
    /// get deleted, exercises and all, when the new split is applied.
    static func match<Day>(slots: [Slot], to days: [Day], name: (Day) -> String) -> (claimed: [Day?], leftover: [Day]) {
        var leftover = days
        let claimed = slots.map { slot -> Day? in
            guard let index = leftover.firstIndex(where: { name($0) == slot.name }) else { return nil }
            return leftover.remove(at: index)
        }
        return (claimed, leftover)
    }

    /// Days of `plan` that would lose their exercises if the split changed to `weekdays`.
    static func daysLosingExercises(weekdays: Set<Int>, plan: WorkoutPlan?) -> [PlanDay] {
        guard let plan else { return [] }
        return match(slots: slots(forDaysPerWeek: weekdays.count), to: plan.sortedDays, name: \.name)
            .leftover
            .filter { !$0.exercises.isEmpty }
    }

    /// Replaces `plan`'s days with a split for `weekdays` (`Calendar` weekday numbers), keeping
    /// the exercises of any day whose name carries over. Creates the plan if there isn't one.
    @discardableResult
    static func apply(weekdays: Set<Int>, to plan: WorkoutPlan?, in context: ModelContext) -> WorkoutPlan {
        let plan = plan ?? {
            let new = WorkoutPlan()
            context.insert(new)
            return new
        }()

        let sortedWeekdays = weekdays.sorted()
        let newSlots = slots(forDaysPerWeek: sortedWeekdays.count)
        let (claimed, leftover) = match(slots: newSlots, to: plan.sortedDays, name: \.name)
        plan.days = []

        for ((slot, weekday), old) in zip(zip(newSlots, sortedWeekdays), claimed) {
            let day = PlanDay(name: slot.name, focus: slot.focus, weekday: weekday)
            if let old {
                day.exercises = old.exercises
                old.exercises = []
                context.delete(old)
            }
            day.plan = plan
            context.insert(day)
        }
        for stale in leftover {
            context.delete(stale)
        }
        return plan
    }
}
