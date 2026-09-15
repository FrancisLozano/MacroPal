//
//  EditMealView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Edits an existing My Meals recipe directly — rename it, add a missing ingredient, or tap
/// an existing one to adjust its amount or remove it (reusing `MealIngredientDetailView`, the
/// same screen reached while logging a meal). Reachable from the My Meals tab's swipe action,
/// for fixing up a meal after the fact (e.g. it's missing an ingredient) rather than only
/// while first building or logging it.
struct EditMealView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var mealItem: FoodItem

    @State private var isPresentingIngredientPicker = false

    private var totalGrams: Double {
        mealItem.ingredients.reduce(0) { $0 + $1.quantityG }
    }

    private var totalCalories: Double {
        mealItem.caloriesPer100g * totalGrams / 100
    }

    private var totalProtein: Double {
        mealItem.proteinG * totalGrams / 100
    }

    private var totalCarb: Double {
        mealItem.carbG * totalGrams / 100
    }

    private var totalFat: Double {
        mealItem.fatG * totalGrams / 100
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Meal name", text: $mealItem.name)
            }

            // Macronutrients above the ingredient list — same ordering as New Meal, Log
            // Food, and an ingredient's own detail screen.
            if !mealItem.ingredients.isEmpty {
                Section("Macronutrients (\(Int(totalGrams.rounded()))g)") {
                    macrosRow
                }
            }

            Section("Ingredients") {
                if mealItem.ingredients.isEmpty {
                    Text("Add the foods that make up this meal.")
                        .foregroundStyle(.secondary)
                }
                ForEach(mealItem.ingredients) { ingredient in
                    NavigationLink {
                        MealIngredientDetailView(ingredient: ingredient) {
                            deleteIngredient(ingredient)
                        } onChange: {
                            handleIngredientsChanged()
                        }
                    } label: {
                        HStack {
                            Text(ingredient.nameSnapshot)
                            Spacer()
                            Text("\(Int(ingredient.quantityG.rounded()))g")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Button {
                    isPresentingIngredientPicker = true
                } label: {
                    Label("Add Ingredient", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Edit Meal")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $isPresentingIngredientPicker) {
            NavigationStack {
                FoodItemPickerView { item in
                    addIngredient(from: item)
                }
            }
        }
    }

    private var macrosRow: some View {
        HStack(spacing: 12) {
            macroChip(name: "Calories", color: .blue, value: "\(Int(totalCalories.rounded()))")
            macroChip(name: "Protein", color: .orange, value: "\(Int(totalProtein.rounded()))g")
            macroChip(name: "Carbs", color: .green, value: "\(Int(totalCarb.rounded()))g")
            macroChip(name: "Fat", color: .purple, value: "\(Int(totalFat.rounded()))g")
        }
    }

    private func macroChip(name: String, color: Color, value: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(name)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }

    /// Appends a freshly picked food as a new ingredient, at its own default serving size —
    /// same starting point `NewMealView` gives a just-added ingredient, since there's no
    /// "how much" step here either; adjust the amount afterward via its own detail screen.
    private func addIngredient(from item: FoodItem) {
        let ingredient = MealIngredient(
            nameSnapshot: item.name,
            quantityG: item.defaultServingSizeG,
            brandSnapshot: item.brand,
            caloriesPer100gSnapshot: item.caloriesPer100g,
            proteinPer100gSnapshot: item.proteinG,
            carbPer100gSnapshot: item.carbG,
            fatPer100gSnapshot: item.fatG,
            foodItem: item
        )
        modelContext.insert(ingredient)
        mealItem.ingredients.append(ingredient)
        handleIngredientsChanged()
    }

    private func deleteIngredient(_ ingredient: MealIngredient) {
        mealItem.ingredients.removeAll { $0 === ingredient }
        modelContext.delete(ingredient)
        handleIngredientsChanged()
    }

    /// Re-derives `mealItem`'s stored aggregate from its current ingredients — called after
    /// adding, editing, or deleting one, same as `LogFoodEntryView.handleIngredientsChanged`
    /// does for a not-yet-logged meal.
    private func handleIngredientsChanged() {
        mealItem.recomputeAggregateFromIngredients()
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        EditMealView(mealItem: FoodItem(name: "Sample Meal", caloriesPer100g: 150, proteinG: 10, carbG: 15, fatG: 5, defaultServingSizeG: 200))
    }
    .modelContainer(for: FoodItem.self, inMemory: true)
}
