//
//  LogFoodEntryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// What the serving-amount field's number represents: grams or ounces directly, or a count
/// of the food's named unit (e.g. "2 medium apples") scaled by its `defaultServingSizeG`.
private enum ServingUnit: Hashable {
    case grams
    case ounces
    case count

    /// Grams in exactly one of this unit — the international avoirdupois ounce (used on US
    /// nutrition labels) for `.ounces`; `.count`'s is food-specific, so it's handled outside
    /// this enum.
    var gramsPerUnit: Double? {
        switch self {
        case .grams: return 1
        case .ounces: return 28.349523125
        case .count: return nil
        }
    }
}

struct LogFoodEntryView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var selectedFoodItem: FoodItem?
    @State private var servingAmountText = ""
    @State private var servingUnit: ServingUnit = .grams
    @State private var mealType: MealType
    @State private var date: Date

    /// Set only when editing an already-logged entry (tapped from the Daily Log) rather than
    /// creating a new one — `save()` updates this entry in place instead of inserting one.
    private let editingEntry: FoodEntry?

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
        self.onSaved = onSaved
    }

    /// Edits an already-logged `FoodEntry` — reached by tapping a row in the Daily Log. Always
    /// rebuilds a per-100g `FoodItem` from the entry's own snapshot rather than reading
    /// `entry.foodItem` — that relationship can point at a `FoodItem` whose backing data is
    /// gone (deleted from "My Foods" independently of its log entries), and merely *touching*
    /// an invalidated SwiftData model's property is a hard crash, not a catchable nil. The
    /// snapshot is self-sufficient for editing (name + macros + serving size), so there's no
    /// need to risk it.
    init(entry: FoodEntry, onSaved: @escaping () -> Void) {
        let foodItem = FoodItem(
            name: entry.nameSnapshot,
            caloriesPer100g: entry.servingSizeG > 0 ? entry.caloriesKcal / entry.servingSizeG * 100 : 0,
            proteinG: entry.servingSizeG > 0 ? entry.proteinG / entry.servingSizeG * 100 : 0,
            carbG: entry.servingSizeG > 0 ? entry.carbG / entry.servingSizeG * 100 : 0,
            fatG: entry.servingSizeG > 0 ? entry.fatG / entry.servingSizeG * 100 : 0,
            defaultServingSizeG: entry.servingSizeG
        )
        _selectedFoodItem = State(initialValue: foodItem)
        _servingAmountText = State(initialValue: Self.formatAmount(entry.servingSizeG))
        _mealType = State(initialValue: entry.mealType)
        _date = State(initialValue: entry.date)
        self.editingEntry = entry
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

    private func gramsPerUnit(_ unit: ServingUnit) -> Double {
        unit.gramsPerUnit ?? gramsPerCountUnit
    }

    private var servingSizeG: Double? {
        guard let amount = Double(servingAmountText) else { return nil }
        return amount * gramsPerUnit(servingUnit)
    }

    private var isValid: Bool {
        guard selectedFoodItem != nil, let servingSizeG else { return false }
        return servingSizeG > 0
    }

    /// Keeps the represented amount continuous across a unit switch — e.g. 200g becomes "2"
    /// when switching to a 100g-per-unit food, rather than resetting to some fixed default.
    private func convertServingAmount(from oldUnit: ServingUnit, to newUnit: ServingUnit) {
        guard oldUnit != newUnit, let amount = Double(servingAmountText) else { return }
        let grams = amount * gramsPerUnit(oldUnit)
        servingAmountText = Self.formatAmount(grams / gramsPerUnit(newUnit))
    }

    private static func formatAmount(_ value: Double) -> String {
        String(format: "%g", value)
    }

    private var servingAmountLabel: String {
        switch servingUnit {
        case .grams: return "Amount (g)"
        case .ounces: return "Amount (oz)"
        case .count: return "Number of Servings"
        }
    }

    /// This entry's serving as a fraction of the food's per-100g macros — 0 while the
    /// serving size field is empty/invalid, so the header shows 0 rather than stale values.
    private var servingScale: Double {
        (servingSizeG ?? 0) / 100
    }

    private var caloriesForServing: Double {
        (selectedFoodItem?.caloriesPer100g ?? 0) * servingScale
    }

    private var proteinForServing: Double {
        (selectedFoodItem?.proteinG ?? 0) * servingScale
    }

    private var carbForServing: Double {
        (selectedFoodItem?.carbG ?? 0) * servingScale
    }

    private var fatForServing: Double {
        (selectedFoodItem?.fatG ?? 0) * servingScale
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
                Text("\(Int(caloriesForServing)) kcal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 8)

            Form {
                Section("Serving") {
                    HStack {
                        Text("Serving Size")
                        Spacer()
                        Picker("", selection: $servingUnit) {
                            Text("Grams").tag(ServingUnit.grams)
                            Text("Ounces").tag(ServingUnit.ounces)
                            Text(countUnitLabel.capitalized).tag(ServingUnit.count)
                        }
                        .labelsHidden()
                        .onChange(of: servingUnit) { oldUnit, newUnit in
                            convertServingAmount(from: oldUnit, to: newUnit)
                        }
                    }
                    // The "≈Xg" hint stays inside this same row (rather than its own
                    // conditionally-appearing row) so the Section's row count never changes
                    // shape when toggling units — a List whose row/section structure changes
                    // shape between states can permanently detach a row's controls from
                    // their gesture recognizers (bit us before with the meal carousel and
                    // date navigator; this field going untappable after a unit switch was
                    // the same bug).
                    HStack {
                        Text(servingAmountLabel)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            TextField("Amount", text: $servingAmountText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            if servingUnit != .grams, let servingSizeG {
                                Text("≈ \(Int(servingSizeG))g")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Picker("Meal", selection: $mealType) {
                        ForEach(MealType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    DatePicker("Date", selection: $date)
                }
                // Not pinned above with the name/calories header — it scrolls with the rest,
                // same as the Daily Log's own macro card.
                Section("Macronutrients") {
                    macrosRow
                }
            }
        }
        .navigationTitle("Log Food")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .disabled(!isValid)
            }
        }
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
            Text("\(Int(grams))g")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }

    private func save() {
        guard let selectedFoodItem, let servingSizeG else { return }
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

#Preview {
    NavigationStack {
        LogFoodFlowView()
    }
    .modelContainer(for: [FoodItem.self, FoodEntry.self], inMemory: true)
}
