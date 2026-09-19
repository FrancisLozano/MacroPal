//
//  AppSchema.swift
//  MacroPal
//

import SwiftData

/// The one list of persisted models, shared by the app and the widget extension so the two
/// can never open the same on-disk store with different schemas.
///
/// Adding a model: list it here, and add its file to the widget target's membership
/// (`membershipExceptions` in `project.pbxproj`) — the widget won't build if you forget.
enum AppSchema {
    static let models: [any PersistentModel.Type] = [
        UserProfile.self,
        FoodItem.self,
        MealIngredient.self,
        FoodEntry.self,
        WeightEntry.self,
        Exercise.self,
        WorkoutSession.self,
        WorkoutSetEntry.self,
        WorkoutPlan.self,
        PlanDay.self,
        PlanExercise.self,
        Insight.self,
    ]

    static var schema: Schema { Schema(models) }
}
