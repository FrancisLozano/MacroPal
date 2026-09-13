//
//  NutritionViewModel.swift
//  MacroPal
//

import Foundation
import SwiftData
import WidgetKit

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
        // Explicit save before reloading — SwiftData's autosave is opportunistic, not
        // immediate, and the widget extension opens its own fresh read of the shared
        // store, so an unsaved insert would be invisible to it at reload time.
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
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

    /// Local-catalog-only barcode lookup. Used both as an instant-select shortcut when a
    /// barcode has already been scanned/created before, and as a pre-check before hitting
    /// the network.
    func findFoodItem(byBarcode barcode: String, in context: ModelContext) -> FoodItem? {
        var descriptor = FetchDescriptor<FoodItem>(predicate: #Predicate { $0.barcode == barcode })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    /// Looks up `barcode` via Open Food Facts and maps a match into a new, uninserted
    /// `FoodItem` — the caller (a review screen) decides whether to actually save it, so an
    /// abandoned scan never orphans a catalog entry. Returns `nil` for a genuine "not
    /// found"; throws for network/decoding failures.
    func fetchFoodItemFromNetwork(barcode: String, client: OpenFoodFactsClient) async throws -> FoodItem? {
        guard let product = try await client.lookupProduct(barcode: barcode) else { return nil }
        let nutriments = product.nutriments
        return FoodItem(
            name: product.productName ?? "Unknown Item",
            caloriesPer100g: nutriments?.energyKcalPer100g ?? 0,
            proteinG: nutriments?.proteinsPer100g ?? 0,
            carbG: nutriments?.carbohydratesPer100g ?? 0,
            fatG: nutriments?.fatPer100g ?? 0,
            defaultServingSizeG: 100,
            barcode: barcode
        )
    }
}
