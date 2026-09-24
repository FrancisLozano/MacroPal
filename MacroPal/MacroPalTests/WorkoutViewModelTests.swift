//
//  WorkoutViewModelTests.swift
//  MacroPalTests
//

import Testing
import Foundation
import SwiftData
@testable import MacroPal

@MainActor
struct WorkoutViewModelTests {
    private let container = try! ModelContainer(
        for: AppSchema.schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    private let viewModel = WorkoutViewModel()

    @Test func aDaysSetsShareOneSessionAndKeepTheirPlanDay() {
        let context = container.mainContext
        let row = Exercise(name: "Barbell Row", muscleGroup: .back, equipment: "")
        context.insert(row)

        let unplanned = viewModel.logSet(exercise: row, weightKg: 40, reps: 8, context: context)
        let pull = viewModel.logSet(exercise: row, weightKg: 40, reps: 8, planDayName: "Pull", context: context)

        // The Progress tab's History reads the plan day from each set.
        #expect(unplanned.planDayName == nil)
        #expect(pull.planDayName == "Pull")
        #expect(pull.setNumber == 2)
        #expect(try! context.fetch(FetchDescriptor<WorkoutSession>()).count == 1)
    }
}
