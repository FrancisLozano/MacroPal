//
//  MacroContributionTests.swift
//  MacroPalTests
//

import Testing
import Foundation
@testable import MacroPal

struct MacroContributionTests {
    private let viewModel = NutritionViewModel()

    private func entry(_ name: String, protein: Double, fat: Double = 0, minute: Double) -> FoodEntry {
        FoodEntry(
            date: Date(timeIntervalSince1970: 1_800_000_000 + minute * 60),
            mealType: .lunch,
            servingSizeG: 100,
            nameSnapshot: name,
            caloriesKcal: 0,
            proteinG: protein,
            carbG: 0,
            fatG: fat
        )
    }

    @Test func biggestSourceComesFirstWithItsShare() {
        let entries = [entry("Rice", protein: 5, minute: 0), entry("Chicken", protein: 30, minute: 1), entry("Eggs", protein: 15, minute: 2)]
        let result = viewModel.contributions(to: .protein, from: entries)
        #expect(result.map(\.entry.nameSnapshot) == ["Chicken", "Eggs", "Rice"])
        #expect(result.map(\.share) == [0.6, 0.3, 0.1])
    }

    @Test func foodsWithNoneOfTheMacroAreLeftOut() {
        let entries = [entry("Coffee", protein: 0, fat: 0, minute: 0), entry("Butter", protein: 0, fat: 12, minute: 1)]
        #expect(viewModel.contributions(to: .fat, from: entries).map(\.entry.nameSnapshot) == ["Butter"])
        #expect(viewModel.contributions(to: .protein, from: entries).isEmpty)
    }

    @Test func tiesKeepTheOrderTheyWereLogged() {
        let entries = [entry("Second", protein: 10, minute: 5), entry("First", protein: 10, minute: 1)]
        #expect(viewModel.contributions(to: .protein, from: entries).map(\.entry.nameSnapshot) == ["First", "Second"])
    }
}
