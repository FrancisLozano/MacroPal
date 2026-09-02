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

    init(
        name: String,
        caloriesPer100g: Double,
        proteinG: Double,
        carbG: Double,
        fatG: Double,
        defaultServingSizeG: Double,
        barcode: String? = nil
    ) {
        self.name = name
        self.caloriesPer100g = caloriesPer100g
        self.proteinG = proteinG
        self.carbG = carbG
        self.fatG = fatG
        self.defaultServingSizeG = defaultServingSizeG
        self.barcode = barcode
    }
}
