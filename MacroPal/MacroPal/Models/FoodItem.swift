//
//  FoodItem.swift
//  MacroPal
//

import Foundation
import SwiftData

/// A reusable food/ingredient definition. Macros are stored per 100g so any serving size
/// can be scaled at log time (see `FoodEntry`).
@Model
final class FoodItem {
    var name: String
    var caloriesPer100g: Double
    var proteinG: Double
    var carbG: Double
    var fatG: Double
    var defaultServingSizeG: Double
    var barcode: String?
    /// Last time this item was picked in the food search or logged. Drives the "Recents"
    /// tab in the food picker; `nil` until first use.
    var lastUsedAt: Date?
    /// The product's brand, e.g. "Walmart" — from Open Food Facts when this item came from
    /// search or a barcode scan; `nil` for a manually-entered food.
    var brand: String?
    /// A human name for `defaultServingSizeG` as a countable unit — e.g. "medium apple" or
    /// "cup" — so the log screen can offer "servings" as an alternative to grams. From Open
    /// Food Facts' `serving_size` when a barcode scan provides one, or set by hand when
    /// creating a food; `nil` means no named unit, just a plain "serving" of that many grams.
    var servingUnitLabel: String?
    /// True for a recipe built from other foods via New Meal/Edit Meal — drives the "My
    /// Meals" tab in the food picker. Stored explicitly (rather than inferred from
    /// `ingredients` being non-empty) so a meal edited down to zero ingredients still reads
    /// as a meal instead of silently reclassifying as a manually-added plain food.
    var isMeal: Bool = false
    /// The ingredients this food is composed of — e.g. a "Protein Yogurt Bowl" meal built
    /// from protein powder, yogurt, and almond milk. Empty for a plain (non-meal) food. When
    /// non-empty, this item's own macros and `defaultServingSizeG` are the aggregate of
    /// these ingredients at their entered amounts — see `recomputeAggregateFromIngredients()`,
    /// which must be called after adding, editing, or deleting an ingredient to keep them in
    /// sync (they're stored, not computed on read, so every other screen that just reads
    /// `caloriesPer100g` etc. — search results, Recents — doesn't need to know about meals).
    @Relationship(deleteRule: .cascade)
    var ingredients: [MealIngredient] = []

    init(
        name: String,
        caloriesPer100g: Double,
        proteinG: Double,
        carbG: Double,
        fatG: Double,
        defaultServingSizeG: Double,
        barcode: String? = nil,
        lastUsedAt: Date? = nil,
        brand: String? = nil,
        servingUnitLabel: String? = nil,
        isMeal: Bool = false,
        ingredients: [MealIngredient] = []
    ) {
        self.name = name
        self.caloriesPer100g = caloriesPer100g
        self.proteinG = proteinG
        self.carbG = carbG
        self.fatG = fatG
        self.defaultServingSizeG = defaultServingSizeG
        self.barcode = barcode
        self.lastUsedAt = lastUsedAt
        self.brand = brand
        self.servingUnitLabel = servingUnitLabel
        self.isMeal = isMeal
        self.ingredients = ingredients
    }

    /// Recomputes `caloriesPer100g`/`proteinG`/`carbG`/`fatG`/`defaultServingSizeG` from the
    /// current `ingredients`, scaled to their (possibly just-edited) `quantityG` amounts.
    /// Call after any change to `ingredients` — adding, editing an amount, or deleting one —
    /// so every other reader of this item's macros stays correct. A no-op when there are no
    /// ingredients (a plain food) or they sum to zero grams.
    func recomputeAggregateFromIngredients() {
        let totalGrams = ingredients.reduce(0) { $0 + $1.quantityG }
        guard totalGrams > 0 else { return }
        let totalCalories = ingredients.reduce(0) { $0 + $1.caloriesPer100gSnapshot * $1.quantityG / 100 }
        let totalProtein = ingredients.reduce(0) { $0 + $1.proteinPer100gSnapshot * $1.quantityG / 100 }
        let totalCarb = ingredients.reduce(0) { $0 + $1.carbPer100gSnapshot * $1.quantityG / 100 }
        let totalFat = ingredients.reduce(0) { $0 + $1.fatPer100gSnapshot * $1.quantityG / 100 }
        defaultServingSizeG = totalGrams
        caloriesPer100g = totalCalories / totalGrams * 100
        proteinG = totalProtein / totalGrams * 100
        carbG = totalCarb / totalGrams * 100
        fatG = totalFat / totalGrams * 100
    }
}
