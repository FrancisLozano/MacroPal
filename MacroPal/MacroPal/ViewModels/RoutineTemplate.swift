//
//  RoutineTemplate.swift
//  MacroPal
//

import Foundation
import FoundationModels
import SwiftData

/// Turns a set of training weekdays into a sensible split, and rebuilds a plan from one.
enum RoutineTemplate {
    static let daysPerWeekRange = 2...6

    /// Which kind of days fill the week. `recommended` picks one from the day count.
    /// `@Generable` so a described routine (`RoutineRequest`) can name one.
    @Generable
    enum Split: String, CaseIterable, Identifiable {
        case recommended, upperLower, pushPullLegs, fullBody

        var id: Self { self }

        var displayName: String {
            switch self {
            case .recommended: "Recommended"
            case .upperLower: "Upper/Lower"
            case .pushPullLegs: "PPL"
            case .fullBody: "Full Body"
            }
        }
    }

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
    private static let fullBody = Slot(name: "Full Body", focus: "Legs, chest, back, shoulders")

    /// Spread-out training days for `count` days a week (`Calendar` weekday numbers), for when
    /// nothing says which days: 2 → Mon/Thu, 3 → Mon/Wed/Fri, 4 → Mon/Tue/Thu/Fri, 5 → Mon–Fri,
    /// 6 → Mon–Sat.
    static func defaultWeekdays(count: Int) -> Set<Int> {
        switch count {
        case ...2: [2, 5]
        case 3: [2, 4, 6]
        case 4: [2, 3, 5, 6]
        case 5: Set(2...6)
        default: Set(2...7)
        }
    }

    /// A named split repeats its days in order when the count doesn't divide evenly: PPL on
    /// 4 days is Push, Pull, Legs, Push.
    static func slots(for split: Split = .recommended, daysPerWeek count: Int) -> [Slot] {
        let cycle: [Slot]
        switch split {
        case .recommended:
            switch count {
            case ...2: return [upper, lower]
            case 3: return [push, pull, legs]
            case 4: return [upper, lower, upper, lower]
            case 5: return [push, pull, legsAndAbs, upper, lower]
            default: return [push, pull, legs, push, pull, legs]
            }
        case .upperLower: cycle = [upper, lower]
        case .pushPullLegs: cycle = [push, pull, legs]
        case .fullBody: cycle = [fullBody]
        }
        return (0..<max(count, 0)).map { cycle[$0 % cycle.count] }
    }

    /// The split whose days are `names` (in week order), so the editor opens on the split the
    /// plan already has. `recommended` wins a tie, and is the answer for anything else.
    static func inferredSplit(fromDayNames names: [String]) -> Split {
        guard !names.isEmpty else { return .recommended }
        return Split.allCases.first { slots(for: $0, daysPerWeek: names.count).map(\.name) == names } ?? .recommended
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
        case fullBody.name: [.fullBody, .legs, .chest, .back, .shoulders]
        default: []
        }
    }

    /// The split for `weekdays` (`Calendar` weekday numbers): one slot per day, in week order.
    static func split(for weekdays: Set<Int>, split: Split = .recommended) -> [(weekday: Int, slot: Slot)] {
        let sorted = weekdays.sorted()
        return zip(sorted, slots(for: split, daysPerWeek: sorted.count)).map { (weekday: $0, slot: $1) }
    }

    /// Pairs each slot with an existing day of the same name, so the day's exercises carry over.
    /// Closest weekdays pair first: a day whose weekday is still in the split stays on it, and
    /// otherwise moves to the nearest same-named slot (counting across the weekend). `claimed[i]`
    /// is the day slot `i` takes over (nil if none); `leftover` is every day no slot claimed —
    /// those get deleted, exercises and all, when the new split is applied.
    static func match<Day>(
        split: [(weekday: Int, slot: Slot)],
        to days: [Day],
        name: (Day) -> String,
        weekday: (Day) -> Int
    ) -> (claimed: [Day?], leftover: [Day]) {
        typealias Pair = (distance: Int, slotIndex: Int, dayIndex: Int)
        let pairs = split.indices.flatMap { slotIndex -> [Pair] in
            days.indices
                .filter { name(days[$0]) == split[slotIndex].slot.name }
                .map { dayIndex in
                    (daysApart(split[slotIndex].weekday, weekday(days[dayIndex])), slotIndex, dayIndex)
                }
        }
        .sorted { ($0.distance, $0.slotIndex, $0.dayIndex) < ($1.distance, $1.slotIndex, $1.dayIndex) }

        var claimed = [Day?](repeating: nil, count: split.count)
        var claimedDays = Set<Int>()
        for pair in pairs where claimed[pair.slotIndex] == nil && !claimedDays.contains(pair.dayIndex) {
            claimed[pair.slotIndex] = days[pair.dayIndex]
            claimedDays.insert(pair.dayIndex)
        }
        let leftover = days.indices.filter { !claimedDays.contains($0) }.map { days[$0] }
        return (claimed, leftover)
    }

    /// Days between two weekdays, going whichever way round the week is shorter (Sat–Sun is 1).
    private static func daysApart(_ a: Int, _ b: Int) -> Int {
        let gap = abs(a - b)
        return min(gap, 7 - gap)
    }

    /// Replaces `plan`'s days with `split` on `weekdays` (`Calendar` weekday numbers), keeping
    /// the exercises of any day whose name carries over. Creates the plan if there isn't one.
    @discardableResult
    static func apply(
        weekdays: Set<Int>,
        split: Split = .recommended,
        to plan: WorkoutPlan?,
        in context: ModelContext
    ) -> WorkoutPlan {
        let plan = plan ?? {
            let new = WorkoutPlan()
            context.insert(new)
            return new
        }()

        let newSplit = Self.split(for: weekdays, split: split)
        let (claimed, leftover) = match(split: newSplit, to: plan.sortedDays, name: \.name, weekday: \.weekday)
        plan.days = []

        for ((weekday, slot), old) in zip(newSplit, claimed) {
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
