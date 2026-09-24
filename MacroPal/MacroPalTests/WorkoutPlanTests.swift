//
//  WorkoutPlanTests.swift
//  MacroPalTests
//

import Testing
import Foundation
import SwiftData
@testable import MacroPal

@MainActor
struct WorkoutPlanTests {
    private let container = try! ModelContainer(
        for: AppSchema.schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    /// Push on Monday, Pull on Wednesday, Legs on Friday.
    private func plan() -> WorkoutPlan {
        let context = container.mainContext
        let plan = WorkoutPlan()
        context.insert(plan)
        for (name, weekday) in [("Push", 2), ("Pull", 4), ("Legs", 6)] {
            let day = PlanDay(name: name, focus: "", weekday: weekday)
            day.plan = plan
            context.insert(day)
        }
        return plan
    }

    private func schedule(_ plan: WorkoutPlan) -> [String] {
        plan.sortedDays.map { "\($0.weekday) \($0.name)" }
    }

    @Test func reorderingSwapsWorkoutsBetweenTheSameWeekdays() {
        let plan = plan()
        let days = plan.sortedDays
        plan.reorderDays([days[2], days[0], days[1]])
        #expect(schedule(plan) == ["2 Legs", "4 Push", "6 Pull"])
    }

    @Test func anOrderThatIsNotThePlansDaysIsIgnored() {
        let plan = plan()
        let days = plan.sortedDays
        plan.reorderDays([days[1], days[0]])
        plan.reorderDays([days[0], days[0], days[1]])
        #expect(schedule(plan) == ["2 Push", "4 Pull", "6 Legs"])
    }
}
