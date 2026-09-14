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
        servingUnitLabel: String? = nil
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
    }
}
