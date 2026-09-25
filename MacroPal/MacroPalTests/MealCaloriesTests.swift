//
//  MealCaloriesTests.swift
//  MacroPalTests
//

import Testing
import Foundation
@testable import MacroPal

struct MealCaloriesTests {
    private let viewModel = NutritionViewModel()

    private func entry(_ meal: MealType, calories: Double) -> FoodEntry {
        FoodEntry(
            date: Date(timeIntervalSince1970: 1_800_000_000),
            mealType: meal,
            servingSizeG: 100,
            nameSnapshot: "Food",
            caloriesKcal: calories,
            proteinG: 0,
            carbG: 0,
            fatG: 0
        )
    }

    @Test func eachMealAddsUpItsFoodsWithItsShare() {
        let entries = [entry(.lunch, calories: 300), entry(.breakfast, calories: 100), entry(.lunch, calories: 300), entry(.dinner, calories: 300)]
        let result = viewModel.mealCalories(from: entries)
        #expect(result.map(\.meal) == [.breakfast, .lunch, .dinner])
        #expect(result.map(\.calories) == [100, 600, 300])
        #expect(result.map(\.share) == [0.1, 0.6, 0.3])
    }

    @Test func emptyMealsStayWithNoShare() {
        let result = viewModel.mealCalories(from: [entry(.dinner, calories: 500)])
        #expect(result.map(\.calories) == [0, 0, 500])
        #expect(result.map(\.share) == [0, 0, 1])
        #expect(viewModel.mealCalories(from: []).map(\.share) == [0, 0, 0])
    }

    @Test func snacksAreLeftOut() {
        let result = viewModel.mealCalories(from: [entry(.snack, calories: 200), entry(.lunch, calories: 400)])
        #expect(result.map(\.meal) == [.breakfast, .lunch, .dinner])
        #expect(result.map(\.share) == [0, 1, 0])
    }
}
