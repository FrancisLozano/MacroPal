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
    /// The original meal this one is a variation of (e.g. the nuts yogurt bowl, for the one
    /// with berries instead), nil for an original meal or a plain food. A variation is a whole
    /// meal of its own, logged like any other; deleting the original leaves its variations as
    /// meals in their own right. Defaulted so existing stores migrate.
    var variantOf: FoodItem? = nil
    /// The meals that are variations of this one (see `variantOf`); always flat, one level.
    @Relationship(deleteRule: .nullify, inverse: \FoodItem.variantOf)
    var variations: [FoodItem] = []

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

    /// The meal a family of variations hangs off: this one's original, or itself.
    var originalMeal: FoodItem {
        variantOf ?? self
    }

    /// The original meal first, then its variations by name: what Log Meal offers to switch
    /// between.
    var mealFamily: [FoodItem] {
        let original = originalMeal
        return [original] + original.variations.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    /// The short name on Log Meal's variation chips: "Original", or what a variation adds to
    /// the original's name ("Yogurt Bowl with Berries" → "with Berries"; "Yogurt Bowl
    /// (Variation 1)" → "Variation 1"), or its whole name when it was renamed to something else.
    var variationLabel: String {
        guard let original = variantOf else { return "Original" }
        guard name.hasPrefix(original.name) else { return name }
        let rest = name.dropFirst(original.name.count)
            .trimmingCharacters(in: .whitespaces.union(.punctuationCharacters))
        return rest.isEmpty ? name : rest
    }

    /// Calories for the whole meal, at its ingredients' amounts.
    var mealCalories: Double {
        caloriesPer100g * defaultServingSizeG / 100
    }

    /// A copy of this meal (same ingredients and amounts) inserted as a new variation of its
    /// original, named "<original> (Variation N)" until renamed, ready to have an ingredient
    /// swapped or added. A variation of a variation joins the original's family.
    func makeVariation(in context: ModelContext) -> FoodItem {
        let original = originalMeal
        let variation = FoodItem(
            name: "\(original.name) (Variation \(original.variations.count + 1))",
            caloriesPer100g: caloriesPer100g, proteinG: proteinG, carbG: carbG, fatG: fatG,
            defaultServingSizeG: defaultServingSizeG, isMeal: true
        )
        context.insert(variation)
        variation.ingredients = ingredients.map { ingredient in
            let copy = MealIngredient(
                nameSnapshot: ingredient.nameSnapshot,
                quantityG: ingredient.quantityG,
                brandSnapshot: ingredient.brandSnapshot,
                caloriesPer100gSnapshot: ingredient.caloriesPer100gSnapshot,
                proteinPer100gSnapshot: ingredient.proteinPer100gSnapshot,
                carbPer100gSnapshot: ingredient.carbPer100gSnapshot,
                fatPer100gSnapshot: ingredient.fatPer100gSnapshot,
                foodItem: ingredient.foodItem
            )
            context.insert(copy)
            return copy
        }
        variation.variantOf = original
        variation.lastUsedAt = .now
        return variation
    }
}
