//
//  FoodEntry.swift
//  MacroPal
//

import Foundation
import SwiftData

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack

    var id: Self { self }

    var displayName: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snack: "Snack"
        }
    }
}

/// One logged instance of eating a food. Macros are snapshotted at log time from the
/// `FoodItem` (scaled by `servingSizeG`) rather than derived live, so editing a `FoodItem`
/// later doesn't retroactively change already-logged history.
@Model
final class FoodEntry {
    var date: Date
    var mealType: MealType
    var servingSizeG: Double
    var nameSnapshot: String
    var caloriesKcal: Double
    var proteinG: Double
    var carbG: Double
    var fatG: Double

    /// Convenience link back to the source food, e.g. for "log again". Not the source of
    /// truth for this entry's macros — see snapshot fields above.
    @Relationship(deleteRule: .nullify)
    var foodItem: FoodItem?

    init(
        date: Date,
        mealType: MealType,
        servingSizeG: Double,
        nameSnapshot: String,
        caloriesKcal: Double,
        proteinG: Double,
        carbG: Double,
        fatG: Double,
        foodItem: FoodItem? = nil
    ) {
        self.date = date
        self.mealType = mealType
        self.servingSizeG = servingSizeG
        self.nameSnapshot = nameSnapshot
        self.caloriesKcal = caloriesKcal
        self.proteinG = proteinG
        self.carbG = carbG
        self.fatG = fatG
        self.foodItem = foodItem
    }
}
