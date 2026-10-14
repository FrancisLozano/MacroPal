//
//  QuickAddTests.swift
//  MacroPalTests
//

import Foundation
import Testing
import SwiftData
@testable import MacroPal

@MainActor
struct QuickAddTests {
    private let container = try! ModelContainer(
        for: AppSchema.schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    private let viewModel = NutritionViewModel()

    private func entries() throws -> [FoodEntry] {
        try container.mainContext.fetch(FetchDescriptor<FoodEntry>(sortBy: [SortDescriptor(\.date)]))
    }

    @Test func aQuickAddCountsTowardTheDayWithNoFoodBehindIt() throws {
        viewModel.quickAdd(name: "Party plate", caloriesKcal: 850, proteinG: 40, mealType: .dinner,
                           date: .now, context: container.mainContext)

        let entry = try #require(try entries().first)
        #expect(entry.isQuickAdd)
        #expect(entry.foodItem == nil)
        #expect(entry.nameSnapshot == "Party plate")
        #expect(entry.mealType == .dinner)
        #expect(entry.caloriesKcal == 850 && entry.proteinG == 40 && entry.carbG == 0 && entry.fatG == 0)
        #expect(try container.mainContext.fetch(FetchDescriptor<FoodItem>()).isEmpty, "no catalog food is created")
    }

    @Test func aBlankNameReadsQuickAdd() throws {
        viewModel.quickAdd(name: "   ", caloriesKcal: 300, mealType: .lunch, date: .now, context: container.mainContext)
        #expect(try entries().first?.nameSnapshot == "Quick Add")
    }

    @Test func editingChangesTheNumbersAndMeal() throws {
        let entry = viewModel.quickAdd(name: "", caloriesKcal: 300, mealType: .lunch, date: .now,
                                       context: container.mainContext)
        viewModel.updateQuickAdd(entry, name: "Boba", caloriesKcal: 420, proteinG: 2, carbG: 80, fatG: 9,
                                 mealType: .dinner, context: container.mainContext)

        #expect(entry.nameSnapshot == "Boba" && entry.caloriesKcal == 420 && entry.carbG == 80)
        #expect(entry.mealType == .dinner)
        #expect(entry.isQuickAdd)
    }

    @Test func aLoggedFoodIsNotAQuickAdd() {
        let food = FoodEntry(date: .now, mealType: .lunch, servingSizeG: 150, nameSnapshot: "Rice",
                             caloriesKcal: 195, proteinG: 4, carbG: 42, fatG: 0.4)
        #expect(!food.isQuickAdd)
    }

    @Test func sameAsLastTimeKeepsItAQuickAdd() throws {
        let context = container.mainContext
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        let entry = viewModel.quickAdd(name: "Takeout", caloriesKcal: 900, mealType: .dinner, date: lastWeek, context: context)

        viewModel.logAgain([entry], as: .dinner, on: .now, context: context)

        let copies = try entries()
        #expect(copies.count == 2)
        #expect(copies.allSatisfy { $0.isQuickAdd && $0.nameSnapshot == "Takeout" && $0.caloriesKcal == 900 })
    }
}
