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

/// One of the three macros, for screens that work on "a macro" generically (the breakdown of
/// which foods contributed to it).
enum Macro: String, CaseIterable, Identifiable, Hashable {
    case protein, carbs, fat

    var id: Self { self }

    var displayName: String {
        switch self {
        case .protein: "Protein"
        case .carbs: "Carbs"
        case .fat: "Fat"
        }
    }

    func grams(in entry: FoodEntry) -> Double {
        switch self {
        case .protein: entry.proteinG
        case .carbs: entry.carbG
        case .fat: entry.fatG
        }
    }

    func grams(in totals: MacroTotals) -> Double {
        switch self {
        case .protein: totals.proteinG
        case .carbs: totals.carbG
        case .fat: totals.fatG
        }
    }

    func targetGrams(for profile: UserProfile) -> Double {
        switch self {
        case .protein: Double(profile.proteinTargetG)
        case .carbs: Double(profile.carbTargetG)
        case .fat: Double(profile.fatTargetG)
        }
    }
}

/// One food's share of a macro for the day.
struct MacroContribution {
    let entry: FoodEntry
    let grams: Double
    /// 0…1 of the day's total for that macro.
    let share: Double
}

/// One meal's calories for the day.
struct MealCalories {
    let meal: MealType
    let calories: Double
    /// 0…1 of the calories eaten across the day's meals.
    let share: Double
}

@Observable
final class NutritionViewModel {
    /// The day's calories split into Breakfast, Lunch and Dinner, in that order, every meal
    /// included even when it's empty. Snacks aren't one of the Daily Log's meals, so they're
    /// left out of both the calories and the shares.
    func mealCalories(from entries: [FoodEntry]) -> [MealCalories] {
        let meals: [MealType] = [.breakfast, .lunch, .dinner]
        let calories = meals.map { meal in
            entries.filter { $0.mealType == meal }.reduce(0) { $0 + $1.caloriesKcal }
        }
        let total = calories.reduce(0, +)
        return zip(meals, calories).map { meal, kcal in
            MealCalories(meal: meal, calories: kcal, share: total > 0 ? kcal / total : 0)
        }
    }

    /// The foods that contributed to `macro` across `entries`, biggest first. Entries with none
    /// of it (e.g. fat in black coffee) are left out; ties keep the order they were logged.
    func contributions(to macro: Macro, from entries: [FoodEntry]) -> [MacroContribution] {
        let total = entries.reduce(0) { $0 + macro.grams(in: $1) }
        guard total > 0 else { return [] }
        return entries
            .map { MacroContribution(entry: $0, grams: macro.grams(in: $0), share: macro.grams(in: $0) / total) }
            .filter { $0.grams > 0 }
            .sorted { $0.grams != $1.grams ? $0.grams > $1.grams : $0.entry.date < $1.entry.date }
    }

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
        // A meal's `MealIngredient.quantityG` is stated for its full recipe batch
        // (`defaultServingSizeG`), so logging any other amount needs its own scale factor —
        // e.g. logging half a batch should show half of each ingredient, not the full recipe.
        let recipeScale = foodItem.defaultServingSizeG > 0 ? servingSizeG / foodItem.defaultServingSizeG : 0
        let entry = FoodEntry(
            date: date,
            mealType: mealType,
            servingSizeG: servingSizeG,
            nameSnapshot: foodItem.name,
            brandSnapshot: foodItem.brand,
            caloriesKcal: foodItem.caloriesPer100g * scale,
            proteinG: foodItem.proteinG * scale,
            carbG: foodItem.carbG * scale,
            fatG: foodItem.fatG * scale,
            foodItem: foodItem,
            ingredientSnapshots: Self.cloneIngredients(from: foodItem, scale: recipeScale)
        )
        context.insert(entry)
        foodItem.lastUsedAt = .now
        // Explicit save before reloading — SwiftData's autosave is opportunistic, not
        // immediate, and the widget extension opens its own fresh read of the shared
        // store, so an unsaved insert would be invisible to it at reload time.
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Updates an already-logged `FoodEntry` in place — used when editing an entry from the
    /// Daily Log (as opposed to `logEntry`, which creates a new one). Re-snapshots macros
    /// from `foodItem` scaled to the new `servingSizeG`, so an edited serving size, meal, or
    /// date stays consistent with what logging it fresh would compute.
    func updateEntry(
        _ entry: FoodEntry,
        foodItem: FoodItem,
        servingSizeG: Double,
        mealType: MealType,
        date: Date,
        context: ModelContext
    ) {
        let scale = servingSizeG / 100
        // Rescale the entry's existing ingredient snapshots in place, by the ratio of the
        // new serving to the previous one — not re-derived from `foodItem`, which for an
        // edit is a synthetic per-100g rebuild from the entry's own snapshot (see
        // `LogFoodEntryView.init(entry:)`) and doesn't carry the original recipe's
        // ingredient list.
        let previousServingSizeG = entry.servingSizeG
        if previousServingSizeG > 0 {
            let ingredientScale = servingSizeG / previousServingSizeG
            for ingredient in entry.ingredientSnapshots {
                ingredient.quantityG *= ingredientScale
            }
        }
        entry.mealType = mealType
        entry.date = date
        entry.servingSizeG = servingSizeG
        entry.nameSnapshot = foodItem.name
        entry.brandSnapshot = foodItem.brand
        entry.caloriesKcal = foodItem.caloriesPer100g * scale
        entry.proteinG = foodItem.proteinG * scale
        entry.carbG = foodItem.carbG * scale
        entry.fatG = foodItem.fatG * scale
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Copies `foodItem.ingredients` (a meal's recipe, stated for its full batch) into fresh
    /// `MealIngredient` instances scaled by `scale`, for a `FoodEntry` to own independently —
    /// empty for a plain (non-meal) food, since `foodItem.ingredients` is empty too.
    private static func cloneIngredients(from foodItem: FoodItem, scale: Double) -> [MealIngredient] {
        foodItem.ingredients.map { ingredient in
            MealIngredient(
                nameSnapshot: ingredient.nameSnapshot,
                quantityG: ingredient.quantityG * scale,
                brandSnapshot: ingredient.brandSnapshot,
                caloriesPer100gSnapshot: ingredient.caloriesPer100gSnapshot,
                proteinPer100gSnapshot: ingredient.proteinPer100gSnapshot,
                carbPer100gSnapshot: ingredient.carbPer100gSnapshot,
                fatPer100gSnapshot: ingredient.fatPer100gSnapshot
            )
        }
    }

    /// Items picked or logged most recently first, for the food picker's "Recents" tab.
    func recentFoodItems(in context: ModelContext, limit: Int = 15) -> [FoodItem] {
        var descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate { $0.lastUsedAt != nil },
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
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
            defaultServingSizeG: product.servingQuantity ?? 100,
            barcode: barcode,
            brand: product.brandName,
            servingUnitLabel: product.servingUnitLabel
        )
    }

    /// Free-text search against Open Food Facts, mapped into new, uninserted `FoodItem`s —
    /// same "caller decides whether to save" contract as `fetchFoodItemFromNetwork`. Results
    /// come back popularity-sorted (see `OpenFoodFactsClient.searchProducts`), then get
    /// re-ranked here so a name that actually matches what was typed — "Orange" for a search
    /// of "orange" — beats a merely-popular product where the query is just one word buried
    /// in a longer name, e.g. "Orange Citron".
    func searchOpenFoodFacts(matching query: String, client: OpenFoodFactsClient) async throws -> [FoodItem] {
        let items = try await client.searchProducts(matching: query).map { product -> FoodItem in
            let nutriments = product.nutriments
            return FoodItem(
                name: product.productName ?? "Unknown Item",
                caloriesPer100g: nutriments?.energyKcalPer100g ?? 0,
                proteinG: nutriments?.proteinsPer100g ?? 0,
                carbG: nutriments?.carbohydratesPer100g ?? 0,
                fatG: nutriments?.fatPer100g ?? 0,
                defaultServingSizeG: 100,
                barcode: product.code,
                brand: product.brandName
            )
        }
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        return items.sorted {
            let lhs = Self.nameRelevance($0.name, to: trimmedQuery)
            let rhs = Self.nameRelevance($1.name, to: trimmedQuery)
            if lhs.bucket != rhs.bucket { return lhs.bucket < rhs.bucket }
            return lhs.length < rhs.length
        }
    }

    /// Ranks a name's relevance to `query` on two levels: `bucket` (lower is more relevant —
    /// an exact name match beats one that merely starts with the query, which beats the
    /// query appearing as a whole word, which beats it merely appearing as a substring), then
    /// `length` as a tiebreaker within the same bucket, so "Orange" outranks "Orange Juice"
    /// even though both start with the query — the shorter name is the closer match. Ties
    /// (including the "no match at all" case, which shouldn't occur since Open Food Facts
    /// only returns token matches) keep their relative order, preserving the server's sort.
    private static func nameRelevance(_ name: String, to query: String) -> (bucket: Int, length: Int) {
        let lowerName = name.lowercased()
        let lowerQuery = query.lowercased()
        let bucket: Int
        if lowerName == lowerQuery { bucket = 0 }
        else if lowerName.hasPrefix(lowerQuery) { bucket = 1 }
        else if lowerName.split(separator: " ").contains(Substring(lowerQuery)) { bucket = 2 }
        else if lowerName.contains(lowerQuery) { bucket = 3 }
        else { bucket = 4 }
        return (bucket, lowerName.count)
    }
}
