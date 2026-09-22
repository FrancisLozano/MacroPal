//
//  PlanDayTests.swift
//  MacroPalTests
//

import Testing
import Foundation
import SwiftData
@testable import MacroPal

@MainActor
struct PlanDayTests {
    private let container = try! ModelContainer(
        for: AppSchema.schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    /// A Push day holding Bench, Press, Dips, in that order.
    private func pushDay() -> PlanDay {
        let context = container.mainContext
        let day = PlanDay(name: "Push", focus: "Chest, shoulders, triceps", weekday: 2)
        context.insert(day)
        for (order, name) in ["Bench", "Press", "Dips"].enumerated() {
            let exercise = Exercise(name: name, muscleGroup: .chest, equipment: "")
            context.insert(exercise)
            let planExercise = PlanExercise(order: order, exercise: exercise)
            planExercise.day = day
            context.insert(planExercise)
        }
        return day
    }

    private func names(_ day: PlanDay) -> [String] {
        day.sortedExercises.compactMap { $0.exercise?.name }
    }

    @Test func movesAnExerciseDownAndUp() {
        let day = pushDay()
        day.move(day.sortedExercises[0], by: 1)
        #expect(names(day) == ["Press", "Bench", "Dips"])
        day.move(day.sortedExercises[2], by: -1)
        #expect(names(day) == ["Press", "Dips", "Bench"])
        #expect(day.sortedExercises.map(\.order) == [0, 1, 2])
    }

    @Test func movingPastTheEndsIsANoOp() {
        let day = pushDay()
        day.move(day.sortedExercises[0], by: -1)
        day.move(day.sortedExercises[2], by: 1)
        #expect(names(day) == ["Bench", "Press", "Dips"])
    }

    @Test func repsLabelShowsARangeOnlyWhenItIsOne() {
        let exercise = PlanExercise(order: 0, exercise: Exercise(name: "Bench", muscleGroup: .chest, equipment: ""), targetReps: 8)
        #expect(exercise.repsLabel == "8")
        exercise.targetRepsMax = 10
        #expect(exercise.repsLabel == "8–10")
        exercise.targetRepsMax = 8
        #expect(exercise.repsLabel == "8")
    }
}
