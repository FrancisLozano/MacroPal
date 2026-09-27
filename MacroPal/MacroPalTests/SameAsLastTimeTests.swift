//
//  SameAsLastTimeTests.swift
//  MacroPalTests
//

import Testing
import Foundation
import SwiftData
@testable import MacroPal

@MainActor
struct SameAsLastTimeTests {
    private let container = try! ModelContainer(
        for: AppSchema.schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    private let viewModel = NutritionViewModel()
    private let calendar = Calendar.current
    private let today = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: 1_800_000_000))

    private func at(daysAgo: Int, hour: Int, minute: Int = 0) -> Date {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    private func entry(_ name: String, _ meal: MealType, _ date: Date, calories: Double = 100) -> FoodEntry {
        FoodEntry(date: date, mealType: meal, servingSizeG: 150, nameSnapshot: name, caloriesKcal: calories, proteinG: 10, carbG: 5, fatG: 2)
    }

    @Test func picksTheMostRecentEarlierDayWithThatMealInLoggedOrder() {
        let entries = [
            entry("Toast", .breakfast, at(daysAgo: 2, hour: 8, minute: 5)),
            entry("Oats", .breakfast, at(daysAgo: 5, hour: 7)),
            entry("Eggs", .breakfast, at(daysAgo: 2, hour: 8)),
            entry("Salad", .lunch, at(daysAgo: 1, hour: 12)),
            entry("Yogurt", .breakfast, at(daysAgo: 0, hour: 9)),
        ]
        let result = viewModel.lastTimeEntries(for: .breakfast, before: today, in: entries)
        #expect(result.map(\.nameSnapshot) == ["Eggs", "Toast"])
    }

    @Test func nothingWhenTheMealWasNeverLoggedBefore() {
        let entries = [entry("Yogurt", .breakfast, at(daysAgo: 0, hour: 9)), entry("Salad", .lunch, at(daysAgo: 1, hour: 12))]
        #expect(viewModel.lastTimeEntries(for: .breakfast, before: today, in: entries).isEmpty)
    }

    @Test func logAgainCopiesSnapshotsOntoTheNewDayKeepingTimeOfDay() throws {
        let context = container.mainContext
        let bowl = entry("Protein Bowl", .lunch, at(daysAgo: 3, hour: 12, minute: 30), calories: 420)
        bowl.ingredientSnapshots = [
            MealIngredient(nameSnapshot: "Yogurt", quantityG: 200, caloriesPer100gSnapshot: 60, proteinPer100gSnapshot: 10, carbPer100gSnapshot: 4, fatPer100gSnapshot: 0),
        ]
        context.insert(bowl)

        viewModel.logAgain([bowl], as: .dinner, on: today, context: context)

        let copies = try context.fetch(FetchDescriptor<FoodEntry>()).filter { $0 !== bowl }
        #expect(copies.count == 1)
        let copy = try #require(copies.first)
        #expect(copy.date == at(daysAgo: 0, hour: 12, minute: 30))
        #expect(copy.mealType == .dinner)
        #expect(copy.nameSnapshot == "Protein Bowl")
        #expect(copy.caloriesKcal == 420)
        #expect(copy.servingSizeG == 150)
        #expect(copy.ingredientSnapshots.map(\.nameSnapshot) == ["Yogurt"])
        // Its own ingredient rows, not the original's.
        #expect(copy.ingredientSnapshots.first !== bowl.ingredientSnapshots.first)
    }
}
