//
//  NutritionViewModelBarcodeTests.swift
//  MacroPalTests
//

import Testing
import Foundation
import SwiftData
@testable import MacroPal

struct NutritionViewModelBarcodeTests {
    private func makeInMemoryContext() -> ModelContext {
        let container = try! ModelContainer(
            for: FoodItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func findsExistingItemByBarcode() {
        let context = makeInMemoryContext()
        let target = FoodItem(name: "Peanut Butter", caloriesPer100g: 588, proteinG: 25, carbG: 20, fatG: 50, defaultServingSizeG: 100, barcode: "0123456789012")
        let other = FoodItem(name: "Rice", caloriesPer100g: 130, proteinG: 2.7, carbG: 28, fatG: 0.3, defaultServingSizeG: 150, barcode: "9999999999999")
        context.insert(target)
        context.insert(other)

        let viewModel = NutritionViewModel()
        let found = viewModel.findFoodItem(byBarcode: "0123456789012", in: context)
        #expect(found?.name == "Peanut Butter")
    }

    @Test func returnsNilForUnknownBarcode() {
        let context = makeInMemoryContext()
        context.insert(FoodItem(name: "Rice", caloriesPer100g: 130, proteinG: 2.7, carbG: 28, fatG: 0.3, defaultServingSizeG: 150, barcode: "9999999999999"))

        let viewModel = NutritionViewModel()
        #expect(viewModel.findFoodItem(byBarcode: "0000000000000", in: context) == nil)
    }

    @Test func nilBarcodesNeverMatch() {
        let context = makeInMemoryContext()
        context.insert(FoodItem(name: "Manual Entry", caloriesPer100g: 200, proteinG: 10, carbG: 10, fatG: 10, defaultServingSizeG: 100, barcode: nil))

        let viewModel = NutritionViewModel()
        #expect(viewModel.findFoodItem(byBarcode: "0000000000000", in: context) == nil)
    }
}
