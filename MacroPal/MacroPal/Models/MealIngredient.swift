//
//  MealIngredient.swift
//  MacroPal
//

import Foundation
import SwiftData

/// One ingredient inside a composed "meal" `FoodItem` (e.g. "1 scoop protein powder" inside
/// a protein yogurt bowl). Snapshots the ingredient's name and per-100g macros at the time
/// the meal was built — like `FoodEntry`'s snapshot fields — so they stay correct for
/// display even if the source `FoodItem` is edited or deleted later. The parent meal's own
/// aggregate macros are computed once at creation time and stored directly on it, so this
/// snapshot isn't re-summed on every read — it exists purely to remember what went into
/// the recipe.
@Model
final class MealIngredient {
    var nameSnapshot: String
    var quantityG: Double
    /// The ingredient's own brand, e.g. "Nature's Promise"; `nil` for one created under My
    /// Meals — same convention as `FoodEntry.brandSnapshot`.
    var brandSnapshot: String?
    var caloriesPer100gSnapshot: Double
    var proteinPer100gSnapshot: Double
    var carbPer100gSnapshot: Double
    var fatPer100gSnapshot: Double

    /// Convenience link back to the source food. Not the source of truth for this
    /// ingredient's contribution — see snapshot fields above.
    @Relationship(deleteRule: .nullify)
    var foodItem: FoodItem?

    init(
        nameSnapshot: String,
        quantityG: Double,
        brandSnapshot: String? = nil,
        caloriesPer100gSnapshot: Double,
        proteinPer100gSnapshot: Double,
        carbPer100gSnapshot: Double,
        fatPer100gSnapshot: Double,
        foodItem: FoodItem? = nil
    ) {
        self.nameSnapshot = nameSnapshot
        self.quantityG = quantityG
        self.brandSnapshot = brandSnapshot
        self.caloriesPer100gSnapshot = caloriesPer100gSnapshot
        self.proteinPer100gSnapshot = proteinPer100gSnapshot
        self.carbPer100gSnapshot = carbPer100gSnapshot
        self.fatPer100gSnapshot = fatPer100gSnapshot
        self.foodItem = foodItem
    }
}
