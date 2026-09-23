//
//  WorkoutSessionTests.swift
//  MacroPalTests
//

import Testing
import Foundation
import SwiftData
@testable import MacroPal

@MainActor
struct WorkoutSessionTests {
    private let container = try! ModelContainer(
        for: AppSchema.schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    private let viewModel = WorkoutViewModel()

    private func exercise(_ name: String) -> Exercise {
        let exercise = Exercise(name: name, muscleGroup: .back, equipment: "")
        container.mainContext.insert(exercise)
        return exercise
    }

    @Test func exerciseNamesAreDistinctInTheOrderFirstLogged() {
        let context = container.mainContext
        let row = exercise("Barbell Row")
        let curl = exercise("Barbell Curl")
        for lift in [row, row, curl, row] {
            _ = viewModel.logSet(exercise: lift, weightKg: 40, reps: 8, context: context)
        }
        let session = try! context.fetch(FetchDescriptor<WorkoutSession>()).first!
        #expect(session.exerciseNames == ["Barbell Row", "Barbell Curl"])
    }

    @Test func thePlanDayComesFromTheSetsLoggedFromIt() {
        let context = container.mainContext
        let row = exercise("Barbell Row")
        let unplanned = viewModel.logSet(exercise: row, weightKg: 40, reps: 8, context: context)
        let session = unplanned.session!
        #expect(session.planDayName == nil)

        _ = viewModel.logSet(exercise: row, weightKg: 40, reps: 8, planDayName: "Pull", context: context)
        _ = viewModel.logSet(exercise: row, weightKg: 40, reps: 8, planDayName: "Pull", context: context)
        #expect(session.planDayName == "Pull")

        let push = viewModel.logSet(exercise: row, weightKg: 40, reps: 8, planDayName: "Push", context: context)
        #expect(session.planDayName == "Pull + Push")

        // Unchecking a set deletes it, which takes its plan day with it.
        context.delete(push)
        try! context.save()
        #expect(session.planDayName == "Pull")
    }
}
