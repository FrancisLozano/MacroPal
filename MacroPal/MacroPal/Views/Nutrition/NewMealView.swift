//
//  NewMealView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Grams-equivalent unit for entering an ingredient's amount — same three cases as the
/// serving-unit pickers elsewhere (`LogFoodEntryView`, `FoodItemPickerView`'s
/// `NewFoodItemView`), kept local to this file per the app's existing convention of not
/// sharing these small unit enums across screens.
private enum IngredientUnit: Hashable {
    case grams
    case ounces
    case count

    var gramsPerUnit: Double? {
        switch self {
        case .grams: return 1
        case .ounces: return 28.349523125
        case .count: return nil
        }
    }
}

/// One ingredient being composed into a new meal — not yet a saved `MealIngredient`, just
/// the in-progress amount/unit for a picked `FoodItem`.
private struct DraftIngredient: Identifiable {
    let id = UUID()
    let foodItem: FoodItem
    var amountText: String
    var unit: IngredientUnit

    /// The food's named unit if it has one (e.g. "medium apple"), otherwise "serving" — same
    /// fallback as `LogFoodEntryView.countUnitLabel`.
    var countUnitLabel: String {
        foodItem.servingUnitLabel ?? "serving"
    }

    func grams(for unit: IngredientUnit) -> Double {
        unit.gramsPerUnit ?? foodItem.defaultServingSizeG
    }

    var quantityG: Double? {
        guard let amount = Double(amountText) else { return nil }
        return amount * grams(for: unit)
    }

    var calories: Double {
        (quantityG ?? 0) / 100 * foodItem.caloriesPer100g
    }
}

/// Builds a new My Meals `FoodItem` composed of multiple existing ingredients — e.g. a
/// protein yogurt bowl = 1 scoop protein powder + 2/3 cup yogurt + 1/3 cup almond milk —
/// instead of typing one food's macros by hand like `NewFoodItemView`. The saved item's
/// macros and `defaultServingSizeG` are the sum of its ingredients at their entered
/// amounts, computed once here, so from then on it behaves like any other food: it can be
/// searched, logged, and edited the same way.
struct NewMealView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let onCreate: (FoodItem) -> Void

    @State private var name = ""
    @State private var ingredients: [DraftIngredient] = []
    @State private var isPresentingIngredientPicker = false

    private var totalGrams: Double {
        ingredients.reduce(0) { $0 + ($1.quantityG ?? 0) }
    }

    private var totalCalories: Double {
        ingredients.reduce(0) { $0 + $1.calories }
    }

    private var totalProtein: Double {
        ingredients.reduce(0) { $0 + ($1.quantityG ?? 0) / 100 * $1.foodItem.proteinG }
    }

    private var totalCarb: Double {
        ingredients.reduce(0) { $0 + ($1.quantityG ?? 0) / 100 * $1.foodItem.carbG }
    }

    private var totalFat: Double {
        ingredients.reduce(0) { $0 + ($1.quantityG ?? 0) / 100 * $1.foodItem.fatG }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !ingredients.isEmpty
            && ingredients.allSatisfy { ($0.quantityG ?? 0) > 0 }
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Meal name", text: $name)
            }

            Section("Ingredients") {
                if ingredients.isEmpty {
                    Text("Add the foods that make up this meal.")
                        .foregroundStyle(.secondary)
                }
                ForEach($ingredients) { ingredient in
                    ingredientRow(ingredient)
                }
                .onDelete { offsets in ingredients.remove(atOffsets: offsets) }
                Button {
                    isPresentingIngredientPicker = true
                } label: {
                    Label("Add Ingredient", systemImage: "plus")
                }
            }

            if !ingredients.isEmpty {
                Section("Total (\(Int(totalGrams))g)") {
                    macrosRow
                }
            }
        }
        .navigationTitle("New Meal")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!isValid)
            }
        }
        .sheet(isPresented: $isPresentingIngredientPicker) {
            NavigationStack {
                FoodItemPickerView { item in
                    ingredients.append(
                        DraftIngredient(
                            foodItem: item,
                            amountText: Self.formatAmount(item.defaultServingSizeG),
                            unit: (item.servingUnitLabel?.isEmpty == false) ? .count : .grams
                        )
                    )
                }
            }
        }
    }

    private func ingredientRow(_ ingredient: Binding<DraftIngredient>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ingredient.wrappedValue.foodItem.name)
            HStack {
                TextField("Amount", text: ingredient.amountText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)
                Picker("", selection: ingredient.unit) {
                    Text("g").tag(IngredientUnit.grams)
                    Text("oz").tag(IngredientUnit.ounces)
                    Text(ingredient.wrappedValue.countUnitLabel.capitalized).tag(IngredientUnit.count)
                }
                .labelsHidden()
                .onChange(of: ingredient.wrappedValue.unit) { oldUnit, newUnit in
                    convertAmount(ingredient, from: oldUnit, to: newUnit)
                }
                Spacer()
                Text("\(Int(ingredient.wrappedValue.calories)) kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Keeps the represented amount continuous across a unit switch — same reasoning as
    /// `LogFoodEntryView.convertServingAmount`.
    private func convertAmount(_ ingredient: Binding<DraftIngredient>, from oldUnit: IngredientUnit, to newUnit: IngredientUnit) {
        guard oldUnit != newUnit, let amount = Double(ingredient.wrappedValue.amountText) else { return }
        let grams = amount * ingredient.wrappedValue.grams(for: oldUnit)
        ingredient.wrappedValue.amountText = Self.formatAmount(grams / ingredient.wrappedValue.grams(for: newUnit))
    }

    private static func formatAmount(_ value: Double) -> String {
        String(format: "%g", value)
    }

    private var macrosRow: some View {
        HStack(spacing: 12) {
            macroChip(name: "Calories", color: .blue, value: "\(Int(totalCalories))")
            macroChip(name: "Protein", color: .orange, value: "\(Int(totalProtein))g")
            macroChip(name: "Carbs", color: .green, value: "\(Int(totalCarb))g")
            macroChip(name: "Fat", color: .purple, value: "\(Int(totalFat))g")
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

    private func save() {
        guard isValid else { return }
        let grams = totalGrams
        let scale = grams > 0 ? 100 / grams : 0
        let ingredientModels = ingredients.map { draft in
            MealIngredient(
                nameSnapshot: draft.foodItem.name,
                quantityG: draft.quantityG ?? 0,
                caloriesPer100gSnapshot: draft.foodItem.caloriesPer100g,
                proteinPer100gSnapshot: draft.foodItem.proteinG,
                carbPer100gSnapshot: draft.foodItem.carbG,
                fatPer100gSnapshot: draft.foodItem.fatG,
                foodItem: draft.foodItem
            )
        }
        let mealItem = FoodItem(
            name: name.trimmingCharacters(in: .whitespaces),
            caloriesPer100g: totalCalories * scale,
            proteinG: totalProtein * scale,
            carbG: totalCarb * scale,
            fatG: totalFat * scale,
            defaultServingSizeG: grams,
            ingredients: ingredientModels
        )
        modelContext.insert(mealItem)
        onCreate(mealItem)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        NewMealView { _ in }
    }
    .modelContainer(for: FoodItem.self, inMemory: true)
}
