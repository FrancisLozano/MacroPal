//
//  NutritionViewModel.swift
//  MacroPal
//

import Foundation
import SwiftData

struct MacroTotals {
    var calories: Double = 0
    var proteinG: Double = 0
    var carbG: Double = 0
    var fatG: Double = 0
}

@Observable
final class NutritionViewModel {
    /// Logs a new `FoodEntry`, snapshotting macros from `foodItem` scaled to `servingSizeG`
    /// so later edits to the `FoodItem` don't retroactively change this entry.
    func logEntry(
        foodItem: FoodItem,
        servingSizeG: Double,
        mealType: MealType,
        date: Date,
        context: ModelContext
    ) {
        let scale = servingSizeG / 100
        let entry = FoodEntry(
            date: date,
            mealType: mealType,
            servingSizeG: servingSizeG,
            nameSnapshot: foodItem.name,
            caloriesKcal: foodItem.caloriesPer100g * scale,
            proteinG: foodItem.proteinG * scale,
            carbG: foodItem.carbG * scale,
            fatG: foodItem.fatG * scale,
            foodItem: foodItem
        )
        context.insert(entry)
    }

    func searchFoodItems(matching query: String, in context: ModelContext) -> [FoodItem] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            let descriptor = FetchDescriptor<FoodItem>(sortBy: [SortDescriptor(\.name)])
            return (try? context.fetch(descriptor)) ?? []
        }
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate { $0.name.localizedStandardContains(query) },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func dailyTotals(for entries: [FoodEntry]) -> MacroTotals {
        entries.reduce(into: MacroTotals()) { totals, entry in
            totals.calories += entry.caloriesKcal
            totals.proteinG += entry.proteinG
            totals.carbG += entry.carbG
            totals.fatG += entry.fatG
        }
    }

    func remaining(totals: MacroTotals, profile: UserProfile) -> MacroTotals {
        MacroTotals(
            calories: Double(profile.calorieTarget) - totals.calories,
            proteinG: Double(profile.proteinTargetG) - totals.proteinG,
            carbG: Double(profile.carbTargetG) - totals.carbG,
            fatG: Double(profile.fatTargetG) - totals.fatG
        )
    }
}
