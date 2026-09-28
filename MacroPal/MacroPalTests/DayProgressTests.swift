//
//  DayProgressTests.swift
//  MacroPalTests
//

import Testing
import Foundation
import SwiftData
@testable import MacroPal

@MainActor
struct DayProgressTests {
    private let container = try! ModelContainer(
        for: AppSchema.schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    /// A Push day holding Bench (3 sets) and Dips (2 sets).
    private func pushDay() -> (PlanDay, bench: Exercise, dips: Exercise) {
        let context = container.mainContext
        let day = PlanDay(name: "Push", focus: "Chest, shoulders, triceps", weekday: 2)
        context.insert(day)
        let bench = Exercise(name: "Bench", muscleGroup: .chest, equipment: "")
        let dips = Exercise(name: "Dips", muscleGroup: .chest, equipment: "")
        for (order, (exercise, sets)) in [(bench, 3), (dips, 2)].enumerated() {
            context.insert(exercise)
            let planExercise = PlanExercise(order: order, exercise: exercise, targetSets: sets)
            planExercise.day = day
            context.insert(planExercise)
        }
        return (day, bench, dips)
    }

    private func session(_ sets: [Exercise]) -> WorkoutSession {
        let session = WorkoutSession(date: .now)
        container.mainContext.insert(session)
        for (number, exercise) in sets.enumerated() {
            let entry = WorkoutSetEntry(setNumber: number + 1, weightKg: 50, reps: 10, exercise: exercise)
            entry.session = session
            container.mainContext.insert(entry)
        }
        return session
    }

    @Test func nothingLoggedWithoutASession() {
        let (day, _, _) = pushDay()
        let progress = DayProgress(day: day, session: nil)
        #expect(progress == DayProgress(exercises: 2, exercisesDone: 0, setsLogged: 0))
        #expect(!progress.isComplete)
    }

    @Test func countsAnExerciseDoneAtItsTargetSets() {
        let (day, bench, dips) = pushDay()
        let other = Exercise(name: "Curl", muscleGroup: .biceps, equipment: "")
        container.mainContext.insert(other)
        let progress = DayProgress(day: day, session: session([bench, bench, bench, dips, other]))
        #expect(progress == DayProgress(exercises: 2, exercisesDone: 1, setsLogged: 4))
        #expect(!progress.isComplete)
    }

    @Test func completeOnceEveryExerciseHasItsSets() {
        let (day, bench, dips) = pushDay()
        let progress = DayProgress(day: day, session: session([bench, bench, bench, dips, dips]))
        #expect(progress.isComplete)
        #expect(progress.setsLogged == 5)
    }

    @Test func anEmptyDayIsNeverComplete() {
        let day = PlanDay(name: "Pull", focus: "Back, biceps", weekday: 3)
        container.mainContext.insert(day)
        #expect(!DayProgress(day: day, session: nil).isComplete)
    }
}
