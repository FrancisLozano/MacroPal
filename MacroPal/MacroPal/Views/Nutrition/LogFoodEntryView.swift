//
//  LogFoodEntryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData
import WidgetKit

struct LogFoodEntryView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var selectedFoodItem: FoodItem?
    @State private var servingAmountText = ""
    @State private var servingUnit: ServingAmountUnit = .grams
    @State private var mealType: MealType
    @State private var date: Date

    /// Set only when editing an already-logged entry (tapped from the Daily Log) rather than
    /// creating a new one — `save()` updates this entry in place instead of inserting one.
    private let editingEntry: FoodEntry?

    /// This food's ingredient breakdown, if it's a meal — empty otherwise. Reads from the
    /// real `FoodItem` when logging fresh (`foodItem.ingredients`), or the entry's own
    /// snapshot when editing (`entry.ingredientSnapshots`, already scaled to what was
    /// actually logged) — never from `selectedFoodItem`'s synthetic rebuild, which doesn't
    /// carry ingredients (see `init(entry:)`). `@State` (not `let`) since deleting an
    /// ingredient here needs to remove it from this list too, to update the UI.
    @State private var ingredients: [MealIngredient]

    /// Closes the whole "Log Food" flow (the sheet it's presented in), called after a
    /// successful save. Not `@Environment(\.dismiss)` here — since this screen is pushed
    /// onto the picker's `NavigationStack`, that would only pop back to search instead of
    /// closing the sheet, which owns the real dismiss action at its NavigationStack root.
    /// (The Daily Log's edit entry point is a plain push, so it passes its own `dismiss()`
    /// here — see `FoodHistoryView`.)
    let onSaved: () -> Void

    private let viewModel = NutritionViewModel()

    /// `foodItem` is already chosen by the time this screen appears — `LogFoodFlowView`,
    /// the only caller, pushes this screen from the food picker via `navigationDestination`,
    /// so the system supplies a real back button (top-left) to return to search.
    init(foodItem: FoodItem, initialMealType: MealType = .breakfast, initialDate: Date = .now, onSaved: @escaping () -> Void) {
        _selectedFoodItem = State(initialValue: foodItem)
        _servingAmountText = State(initialValue: String(format: "%.0f", foodItem.defaultServingSizeG))
        _mealType = State(initialValue: initialMealType)
        _date = State(initialValue: initialDate)
        self.editingEntry = nil
        _ingredients = State(initialValue: foodItem.ingredients)
        self.onSaved = onSaved
    }

    /// Edits an already-logged `FoodEntry` — reached by tapping a row in the Daily Log. Always
    /// rebuilds a per-100g `FoodItem` from the entry's own snapshot rather than reading
    /// `entry.foodItem` — that relationship can point at a `FoodItem` whose backing data is
    /// gone (deleted from My Meals independently of its log entries), and merely *touching*
    /// an invalidated SwiftData model's property is a hard crash, not a catchable nil. The
    /// snapshot is self-sufficient for editing (name + brand + macros + serving size), so
    /// there's no need to risk it.
    init(entry: FoodEntry, onSaved: @escaping () -> Void) {
        let foodItem = FoodItem(
            name: entry.nameSnapshot,
            caloriesPer100g: entry.servingSizeG > 0 ? entry.caloriesKcal / entry.servingSizeG * 100 : 0,
            proteinG: entry.servingSizeG > 0 ? entry.proteinG / entry.servingSizeG * 100 : 0,
            carbG: entry.servingSizeG > 0 ? entry.carbG / entry.servingSizeG * 100 : 0,
            fatG: entry.servingSizeG > 0 ? entry.fatG / entry.servingSizeG * 100 : 0,
            defaultServingSizeG: entry.servingSizeG,
            brand: entry.brandSnapshot
        )
        _selectedFoodItem = State(initialValue: foodItem)
        _servingAmountText = State(initialValue: Self.formatAmount(entry.servingSizeG))
        _mealType = State(initialValue: entry.mealType)
        _date = State(initialValue: entry.date)
        self.editingEntry = entry
        _ingredients = State(initialValue: entry.ingredientSnapshots)
        self.onSaved = onSaved
    }

    /// The food's named unit if it has one (e.g. "medium apple"), otherwise a generic
    /// "serving" — either way, what "1" means when `servingUnit == .count`.
    private var countUnitLabel: String {
        selectedFoodItem?.servingUnitLabel ?? "serving"
    }

    /// Grams represented by one `.count` unit — the food's own default serving size, or
    /// 100g if it doesn't have one (matches how a plain OFF/manual entry is stored).
    private var gramsPerCountUnit: Double {
        selectedFoodItem?.defaultServingSizeG ?? 100
    }

    /// The brand this food came from, or "My Meals" for one created locally — same
    /// convention as the Daily Log and Choose Food screens.
    private var sourceLabel: String {
        guard let brand = selectedFoodItem?.brand, !brand.isEmpty else { return "My Meals" }
        return brand
    }

    private func gramsPerUnit(_ unit: ServingAmountUnit) -> Double {
        unit.fixedGramsPerUnit ?? gramsPerCountUnit
    }

    private var servingSizeG: Double? {
        guard let amount = AmountParsing.parseAmount(servingAmountText) else { return nil }
        return amount * gramsPerUnit(servingUnit)
    }

    /// A meal (has ingredients) has no separate serving-size control — logging it always
    /// logs its current ingredient composition in full, so there's nothing to scale by.
    private var isMeal: Bool {
        !ingredients.isEmpty
    }

    private var isValid: Bool {
        if isMeal { return mealTotalGrams > 0 }
        guard selectedFoodItem != nil, let servingSizeG else { return false }
        return servingSizeG > 0
    }

    /// Keeps the represented amount continuous across a unit switch — e.g. 200g becomes "2"
    /// when switching to a 100g-per-unit food, rather than resetting to some fixed default.
    private func convertServingAmount(from oldUnit: ServingAmountUnit, to newUnit: ServingAmountUnit) {
        guard oldUnit != newUnit, let amount = AmountParsing.parseAmount(servingAmountText) else { return }
        let grams = amount * gramsPerUnit(oldUnit)
        servingAmountText = Self.formatAmount(grams / gramsPerUnit(newUnit))
    }

    private static func formatAmount(_ value: Double) -> String {
        String(format: "%g", value)
    }

    private var servingAmountLabel: String {
        servingUnit == .count ? "Number of Servings" : servingUnit.amountFieldLabel
    }

    /// This entry's serving as a fraction of the food's per-100g macros — 0 while the
    /// serving size field is empty/invalid, so the header shows 0 rather than stale values.
    private var servingScale: Double {
        (servingSizeG ?? 0) / 100
    }

    private var caloriesForServing: Double {
        isMeal ? mealCalories : (selectedFoodItem?.caloriesPer100g ?? 0) * servingScale
    }

    private var proteinForServing: Double {
        isMeal ? mealProtein : (selectedFoodItem?.proteinG ?? 0) * servingScale
    }

    private var carbForServing: Double {
        isMeal ? mealCarb : (selectedFoodItem?.carbG ?? 0) * servingScale
    }

    private var fatForServing: Double {
        isMeal ? mealFat : (selectedFoodItem?.fatG ?? 0) * servingScale
    }

    /// Sum of the current ingredients' amounts — what actually gets logged as this entry's
    /// `servingSizeG` for a meal, since there's no separate serving-size control for one.
    private var mealTotalGrams: Double {
        ingredients.reduce(0) { $0 + $1.quantityG }
    }

    private var mealCalories: Double {
        ingredients.reduce(0) { $0 + $1.caloriesPer100gSnapshot * $1.quantityG / 100 }
    }

    private var mealProtein: Double {
        ingredients.reduce(0) { $0 + $1.proteinPer100gSnapshot * $1.quantityG / 100 }
    }

    private var mealCarb: Double {
        ingredients.reduce(0) { $0 + $1.carbPer100gSnapshot * $1.quantityG / 100 }
    }

    private var mealFat: Double {
        ingredients.reduce(0) { $0 + $1.fatPer100gSnapshot * $1.quantityG / 100 }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Kept out of the Form/List below — a Button nested inside a List row that
            // later changes its own content (placeholder text -> chosen food name) can
            // have its gesture recognizer permanently detached by SwiftUI's List cell
            // reuse. A plain sibling view doesn't hit that.
            HStack(alignment: .firstTextBaseline) {
                Text(selectedFoodItem?.name ?? "")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text("\(Int(caloriesForServing.rounded())) kcal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 8)

            Form {
                if isMeal {
                    // A meal has no serving-size control (see `isMeal`), so Macronutrients
                    // and Ingredients lead instead of Serving, which here is just
                    // Brand/Meal/Date — per feedback that this reads better than
                    // Serving-first when there's no amount to actually set.
                    Section("Macronutrients") {
                        macrosRow
                    }
                    Section("Ingredients") {
                        ForEach(ingredients) { ingredient in
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
                    }
                    Section("Serving") {
                        brandMealDateRows
                    }
                } else {
                    Section("Serving") {
                        HStack {
                            Text("Serving Size")
                            Spacer()
                            Picker("", selection: $servingUnit) {
                                Text("Grams").tag(ServingAmountUnit.grams)
                                Text("Ounces").tag(ServingAmountUnit.ounces)
                                Text("Cups").tag(ServingAmountUnit.cups)
                                Text("Tbsp").tag(ServingAmountUnit.tablespoons)
                                Text("Tsp").tag(ServingAmountUnit.teaspoons)
                                Text(countUnitLabel.capitalized).tag(ServingAmountUnit.count)
                            }
                            .labelsHidden()
                            .onChange(of: servingUnit) { oldUnit, newUnit in
                                convertServingAmount(from: oldUnit, to: newUnit)
                            }
                        }
                        // The "≈Xg" hint stays inside this same row (rather than its own
                        // conditionally-appearing row) so the Section's row count never
                        // changes shape when toggling units — a List whose row/section
                        // structure changes shape between states can permanently detach a
                        // row's controls from their gesture recognizers (bit us before with
                        // the meal carousel and date navigator; this field going untappable
                        // after a unit switch was the same bug).
                        HStack {
                            Text(servingAmountLabel)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                TextField("Amount", text: $servingAmountText)
                                    .keyboardType(.numbersAndPunctuation)
                                    .multilineTextAlignment(.trailing)
                                if servingUnit != .grams, let servingSizeG {
                                    Text("≈ \(Int(servingSizeG.rounded()))g")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        brandMealDateRows
                    }
                    // Not pinned above with the name/calories header — it scrolls with the
                    // rest, same as the Daily Log's own macro card.
                    Section("Macronutrients") {
                        macrosRow
                    }
                }
            }
        }
        .navigationTitle(isMeal ? "Log Meal" : "Log Food")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .disabled(!isValid)
            }
        }
    }

    /// Brand, meal-type picker, and date — shared between the meal and plain-food layouts of
    /// the Serving section (a meal's just drops the Serving Size/Amount rows above these).
    @ViewBuilder
    private var brandMealDateRows: some View {
        HStack {
            Text("Brand")
            Spacer()
            Text(sourceLabel)
                .foregroundStyle(.secondary)
        }
        Picker("Meal", selection: $mealType) {
            ForEach(MealType.allCases) { type in
                Text(type.displayName).tag(type)
            }
        }
        DatePicker("Date", selection: $date)
    }

    /// Removes `ingredient` from this meal — from the catalog recipe (`selectedFoodItem`)
    /// when logging fresh, or from this entry's own snapshot when editing one already
    /// logged — and recomputes totals to match.
    private func deleteIngredient(_ ingredient: MealIngredient) {
        ingredients.removeAll { $0 === ingredient }
        if editingEntry != nil {
            editingEntry?.ingredientSnapshots.removeAll { $0 === ingredient }
        } else {
            selectedFoodItem?.ingredients.removeAll { $0 === ingredient }
        }
        modelContext.delete(ingredient)
        handleIngredientsChanged()
    }

    /// Re-derives this meal's stored totals from its current ingredients — called after
    /// adding, editing, or deleting one. For a not-yet-logged meal, updates the real catalog
    /// `FoodItem` so every other screen that reads its macros stays correct. For an
    /// already-logged entry, updates the entry's own fields directly rather than going
    /// through `NutritionViewModel.updateEntry` — that re-derives macros from `foodItem`,
    /// but here `foodItem` is `init(entry:)`'s synthetic, stale-at-init rebuild that doesn't
    /// track live ingredient edits (see that initializer).
    private func handleIngredientsChanged() {
        if let editingEntry {
            editingEntry.servingSizeG = mealTotalGrams
            editingEntry.caloriesKcal = mealCalories
            editingEntry.proteinG = mealProtein
            editingEntry.carbG = mealCarb
            editingEntry.fatG = mealFat
        } else {
            selectedFoodItem?.recomputeAggregateFromIngredients()
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Protein/carb/fat for this entry's serving, styled to match the colored-dot macro
    /// rows already used on the Daily Log screen (`FoodHistoryView.macroBar`).
    private var macrosRow: some View {
        HStack(spacing: 12) {
            macroChip(name: "Protein", color: .orange, grams: proteinForServing)
            macroChip(name: "Carbs", color: .green, grams: carbForServing)
            macroChip(name: "Fat", color: .purple, grams: fatForServing)
        }
    }

    private func macroChip(name: String, color: Color, grams: Double) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            Text("\(Int(grams.rounded()))g")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }

    private func save() {
        guard let selectedFoodItem else { return }
        if isMeal {
            // Ingredient edits already kept `selectedFoodItem`/`editingEntry` fully current
            // via `handleIngredientsChanged` — there's no separate serving size to apply on
            // top, just the meal-type/date the rest of this screen controls.
            guard mealTotalGrams > 0 else { return }
            if let editingEntry {
                editingEntry.mealType = mealType
                editingEntry.date = date
                try? modelContext.save()
                WidgetCenter.shared.reloadAllTimelines()
            } else {
                viewModel.logEntry(
                    foodItem: selectedFoodItem,
                    servingSizeG: mealTotalGrams,
                    mealType: mealType,
                    date: date,
                    context: modelContext
                )
            }
        } else {
            guard let servingSizeG else { return }
            if let editingEntry {
                viewModel.updateEntry(
                    editingEntry,
                    foodItem: selectedFoodItem,
                    servingSizeG: servingSizeG,
                    mealType: mealType,
                    date: date,
                    context: modelContext
                )
            } else {
                viewModel.logEntry(
                    foodItem: selectedFoodItem,
                    servingSizeG: servingSizeG,
                    mealType: mealType,
                    date: date,
                    context: modelContext
                )
            }
        }
        onSaved()
    }
}

/// Entry point for logging food: search/pick a food first, then land on `LogFoodEntryView`
/// to set its serving size, meal, and date. Present this (not `LogFoodEntryView` directly)
/// from a "Log Food" button/icon.
///
/// The food picker is the root and `LogFoodEntryView` is a genuine `navigationDestination`
/// push, not a manual content swap — swapping between two structurally different root views
/// (no toolbar vs. one with toolbar items) inside the same `NavigationStack` left the new
/// view's toolbar buttons visually present but permanently unresponsive to taps, the same
/// class of gesture-recognizer-detachment bug documented for List rows whose section
/// structure changes shape. A real push avoids it and gets a native back button for free.
struct LogFoodFlowView: View {
    @Environment(\.dismiss) private var dismiss

    let initialMealType: MealType
    let initialDate: Date

    @State private var selectedFoodItem: FoodItem?
    @State private var isShowingEntry = false

    init(initialMealType: MealType = .breakfast, initialDate: Date = .now) {
        self.initialMealType = initialMealType
        self.initialDate = initialDate
    }

    var body: some View {
        FoodItemPickerView(dismissesAfterSelection: false) { item in
            selectedFoodItem = item
            isShowingEntry = true
        }
        .navigationDestination(isPresented: $isShowingEntry) {
            if let selectedFoodItem {
                LogFoodEntryView(
                    foodItem: selectedFoodItem,
                    initialMealType: initialMealType,
                    initialDate: initialDate,
                    onSaved: { dismiss() }
                )
            }
        }
    }
}

/// Detail for one ingredient inside a logged (or about-to-be-logged) meal — its serving
/// within the recipe and the individual macros that contributes. Its amount is editable
/// (toggled via the trailing Edit/Done button) and it can be removed from the meal entirely;
/// both call back to the owning `LogFoodEntryView` to keep the meal's totals in sync, since
/// this view only owns the one ingredient, not the recipe it belongs to.
private struct MealIngredientDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var ingredient: MealIngredient
    let onDelete: () -> Void
    let onChange: () -> Void

    @State private var isEditing = false
    @State private var amountText: String
    @State private var unit: ServingAmountUnit = .grams

    /// Units offered for editing an ingredient's amount — no `.count`, since a `MealIngredient`
    /// doesn't carry its own named unit the way a `FoodItem` can.
    private static let editableUnits: [ServingAmountUnit] = [.grams, .ounces, .cups, .tablespoons, .teaspoons]

    init(ingredient: MealIngredient, onDelete: @escaping () -> Void, onChange: @escaping () -> Void) {
        self.ingredient = ingredient
        self.onDelete = onDelete
        self.onChange = onChange
        _amountText = State(initialValue: String(format: "%g", ingredient.quantityG))
    }

    /// The ingredient's own brand, or "My Meals" for one created locally — same convention
    /// as `LogFoodEntryView.sourceLabel`.
    private var sourceLabel: String {
        guard let brand = ingredient.brandSnapshot, !brand.isEmpty else { return "My Meals" }
        return brand
    }

    private var scale: Double {
        ingredient.quantityG / 100
    }

    private var calories: Double {
        ingredient.caloriesPer100gSnapshot * scale
    }

    private var protein: Double {
        ingredient.proteinPer100gSnapshot * scale
    }

    private var carb: Double {
        ingredient.carbPer100gSnapshot * scale
    }

    private var fat: Double {
        ingredient.fatPer100gSnapshot * scale
    }

    var body: some View {
        Form {
            // Macronutrients above Serving — same ordering as Log Food and New Meal.
            Section("Macronutrients") {
                HStack(spacing: 12) {
                    macroChip(name: "Protein", color: .orange, grams: protein)
                    macroChip(name: "Carbs", color: .green, grams: carb)
                    macroChip(name: "Fat", color: .purple, grams: fat)
                }
            }
            Section("Serving") {
                HStack {
                    Text("Amount")
                    Spacer()
                    if isEditing {
                        TextField("Amount", text: $amountText)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                        Picker("", selection: $unit) {
                            ForEach(Self.editableUnits, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .labelsHidden()
                        .onChange(of: unit) { oldUnit, newUnit in
                            convertAmount(from: oldUnit, to: newUnit)
                        }
                    } else {
                        Text("\(Int(ingredient.quantityG.rounded()))g")
                            .foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Text("Calories")
                    Spacer()
                    Text("\(Int(calories.rounded())) kcal")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Brand")
                    Spacer()
                    Text(sourceLabel)
                        .foregroundStyle(.secondary)
                }
            }
            if isEditing {
                Section {
                    Button("Delete Ingredient", role: .destructive) {
                        onDelete()
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(ingredient.nameSnapshot)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        commitAmount()
                    }
                    isEditing.toggle()
                }
            }
        }
    }

    /// Keeps the represented amount continuous across a unit switch — same reasoning as
    /// `LogFoodEntryView.convertServingAmount`.
    private func convertAmount(from oldUnit: ServingAmountUnit, to newUnit: ServingAmountUnit) {
        guard oldUnit != newUnit,
              let amount = AmountParsing.parseAmount(amountText),
              let oldGramsPerUnit = oldUnit.fixedGramsPerUnit,
              let newGramsPerUnit = newUnit.fixedGramsPerUnit else { return }
        let grams = amount * oldGramsPerUnit
        amountText = String(format: "%g", grams / newGramsPerUnit)
    }

    private func commitAmount() {
        guard let amount = AmountParsing.parseAmount(amountText),
              let gramsPerUnit = unit.fixedGramsPerUnit else { return }
        let grams = amount * gramsPerUnit
        guard grams > 0, grams != ingredient.quantityG else { return }
        ingredient.quantityG = grams
        try? modelContext.save()
        onChange()
    }

    private func macroChip(name: String, color: Color, grams: Double) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            Text("\(Int(grams.rounded()))g")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        LogFoodFlowView()
    }
    .modelContainer(for: [FoodItem.self, FoodEntry.self], inMemory: true)
}
