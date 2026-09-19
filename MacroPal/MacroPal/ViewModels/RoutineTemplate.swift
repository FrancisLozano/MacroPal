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

    /// Replaces `plan`'s days with a split for `weekdays` (`Calendar` weekday numbers), keeping
    /// the exercises of any day whose name carries over. Creates the plan if there isn't one.
    @discardableResult
    static func apply(weekdays: Set<Int>, to plan: WorkoutPlan?, in context: ModelContext) -> WorkoutPlan {
        let plan = plan ?? {
            let new = WorkoutPlan()
            context.insert(new)
            return new
        }()

        var leftover = plan.sortedDays
        plan.days = []

        let sortedWeekdays = weekdays.sorted()
        for (slot, weekday) in zip(slots(forDaysPerWeek: sortedWeekdays.count), sortedWeekdays) {
            let day = PlanDay(name: slot.name, focus: slot.focus, weekday: weekday)
            if let match = leftover.firstIndex(where: { $0.name == slot.name }) {
                let old = leftover.remove(at: match)
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
