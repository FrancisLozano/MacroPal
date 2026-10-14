//
//  DataExportTests.swift
//  MacroPalTests
//

import Foundation
import Testing
import SwiftData
@testable import MacroPal

@MainActor
struct DataExportTests {
    private let container = try! ModelContainer(
        for: AppSchema.schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    /// Whole seconds, since the file keeps dates to the second.
    private func date(_ day: Int, _ hour: Int = 12) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    /// One of everything: a profile, a meal built from a food, a logged meal, a weigh-in,
    /// steps, a one-day plan and a workout with two sets.
    private func fillStore() {
        let context = container.mainContext
        let profile = UserProfile(birthDate: date(1), goalWeightKg: 70, calorieTarget: 2100)
        profile.stepGoal = 8000
        context.insert(profile)

        let oats = FoodItem(name: "Oats", caloriesPer100g: 380, proteinG: 13, carbG: 67, fatG: 7, defaultServingSizeG: 40)
        let bowl = FoodItem(
            name: "Oat Bowl", caloriesPer100g: 380, proteinG: 13, carbG: 67, fatG: 7,
            defaultServingSizeG: 40, isMeal: true,
            ingredients: [MealIngredient(nameSnapshot: "Oats", quantityG: 40, caloriesPer100gSnapshot: 380,
                                         proteinPer100gSnapshot: 13, carbPer100gSnapshot: 67,
                                         fatPer100gSnapshot: 7, foodItem: oats)]
        )
        context.insert(oats)
        context.insert(bowl)
        context.insert(FoodEntry(date: date(5, 8), mealType: .breakfast, servingSizeG: 40, nameSnapshot: "Oat Bowl",
                                 caloriesKcal: 152, proteinG: 5.2, carbG: 26.8, fatG: 2.8, foodItem: bowl))
        context.insert(WeightEntry(date: date(5, 7), weightKg: 80.4, notes: "after run"))
        context.insert(StepEntry(day: date(5, 0), steps: 9_312))

        let facePull = Exercise(name: "Face Pull", muscleGroup: .shoulders, equipment: "Cable")
        context.insert(facePull)
        let plan = WorkoutPlan()
        let push = PlanDay(name: "Push", focus: "Chest, shoulders", weekday: 2)
        let planned = PlanExercise(order: 0, exercise: facePull, targetSets: 3, targetReps: 12)
        planned.targetRepsMax = 15
        context.insert(plan)
        plan.days.append(push)
        push.exercises.append(planned)

        let session = WorkoutSession(date: date(5, 18))
        context.insert(session)
        for number in [2, 1] {
            let set = WorkoutSetEntry(setNumber: number, weightKg: 20, reps: 12, exercise: facePull)
            set.planDayName = "Push"
            session.setEntries.append(set)
        }
    }

    @Test func anEmptyStoreExportsEmptyLists() throws {
        let export = try DataExport(from: container.mainContext, exportedAt: date(13))
        #expect(export.profile == nil)
        #expect(export.foods.isEmpty && export.foodLog.isEmpty && export.weights.isEmpty)
        #expect(export.steps.isEmpty && export.exercises.isEmpty && export.plan.isEmpty && export.workouts.isEmpty)
        #expect(export.version == DataExport.currentVersion)
    }

    @Test func everythingLoggedIsInTheExport() throws {
        fillStore()
        let export = try DataExport(from: container.mainContext, exportedAt: date(13))

        #expect(export.profile?.calorieTarget == 2100)
        #expect(export.profile?.stepGoal == 8000)
        #expect(export.foods.map(\.name) == ["Oat Bowl", "Oats"])
        #expect(export.foods.first?.ingredients.map(\.name) == ["Oats"])
        #expect(export.foodLog.first?.meal == .breakfast)
        #expect(export.foodLog.first?.caloriesKcal == 152)
        #expect(export.weights == [.init(date: date(5, 7), weightKg: 80.4, notes: "after run")])
        #expect(export.steps.map(\.steps) == [9_312])
        #expect(export.exercises.map(\.name) == ["Face Pull"])
    }

    @Test func plansAndSetsNameTheirExercise() throws {
        fillStore()
        let export = try DataExport(from: container.mainContext, exportedAt: date(13))

        let day = try #require(export.plan.first)
        #expect(day.name == "Push" && day.weekday == 2)
        #expect(day.exercises == [.init(exercise: "Face Pull", targetSets: 3, targetReps: 12, targetRepsMax: 15)])

        let sets = try #require(export.workouts.first).sets
        #expect(sets.map(\.setNumber) == [1, 2])
        #expect(sets.allSatisfy { $0.exercise == "Face Pull" && $0.planDay == "Push" && $0.weightKg == 20 })
    }

    @Test func theJSONReadsBackTheSame() throws {
        fillStore()
        let export = try DataExport(from: container.mainContext, exportedAt: date(13))
        let data = try export.jsonData()

        #expect(try DataExport.decoder().decode(DataExport.self, from: data) == export)

        let text = try #require(String(data: data, encoding: .utf8))
        #expect(text.contains("\"app\" : \"MacroPal\""))
        #expect(text.contains("\"exercise\" : \"Face Pull\""))
        #expect(text.contains("\"date\" : \"2026-10-05T07:00:00Z\""))
    }

    @Test func theFileIsNamedForTheDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        #expect(DataExport.fileName(for: date(13), calendar: calendar) == "MacroPal Export 2026-10-13.json")
    }
}
