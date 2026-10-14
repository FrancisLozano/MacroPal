//
//  QuickAddFoodView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Calories, and optionally protein / carbs / fat, typed straight into a meal — for food
/// nothing in the catalog fits (a buffet, takeout, a dish cooked without measuring). Opened
/// from the top of Choose Food to log, or from the Daily Log to edit an existing Quick Add.
struct QuickAddFoodView: View {
    @Environment(\.modelContext) private var modelContext

    /// Set when editing a Quick Add already in the log.
    private let editingEntry: FoodEntry?
    private let date: Date
    private let onSaved: () -> Void

    @State private var name: String
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var carbText: String
    @State private var fatText: String
    @State private var mealType: MealType
    @FocusState private var focusedField: Field?

    private enum Field { case calories, protein, carbs, fat, name }

    private let viewModel = NutritionViewModel()

    init(mealType: MealType, date: Date, onSaved: @escaping () -> Void) {
        editingEntry = nil
        self.date = date
        self.onSaved = onSaved
        _name = State(initialValue: "")
        _caloriesText = State(initialValue: "")
        _proteinText = State(initialValue: "")
        _carbText = State(initialValue: "")
        _fatText = State(initialValue: "")
        _mealType = State(initialValue: mealType)
    }

    init(editing entry: FoodEntry, onSaved: @escaping () -> Void) {
        editingEntry = entry
        date = entry.date
        self.onSaved = onSaved
        _name = State(initialValue: entry.nameSnapshot == FoodEntry.quickAddName ? "" : entry.nameSnapshot)
        _caloriesText = State(initialValue: Self.format(entry.caloriesKcal))
        _proteinText = State(initialValue: Self.format(entry.proteinG))
        _carbText = State(initialValue: Self.format(entry.carbG))
        _fatText = State(initialValue: Self.format(entry.fatG))
        _mealType = State(initialValue: entry.mealType)
    }

    private var calories: Double? {
        AmountParsing.parseAmount(caloriesText).flatMap { $0 > 0 ? $0 : nil }
    }

    /// Blank is 0; anything typed has to be a number.
    private func grams(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? 0 : AmountParsing.parseAmount(trimmed)
    }

    private var isValid: Bool {
        calories != nil && grams(proteinText) != nil && grams(carbText) != nil && grams(fatText) != nil
    }

    var body: some View {
        Form {
            Section {
                numberField("Calories", text: $caloriesText, unit: "kcal", field: .calories)
            } footer: {
                Text("For food you can't look up, like a party plate or takeout. A rough number is fine.")
            }

            Section("Macros (optional)") {
                numberField("Protein", text: $proteinText, unit: "g", field: .protein)
                numberField("Carbs", text: $carbText, unit: "g", field: .carbs)
                numberField("Fat", text: $fatText, unit: "g", field: .fat)
            }

            Section {
                TextField("Name (optional)", text: $name, prompt: Text(FoodEntry.quickAddName))
                    .focused($focusedField, equals: .name)
                    .submitLabel(.done)
                Picker("Meal", selection: $mealType) {
                    ForEach(MealType.logged) { meal in
                        Text(meal.displayName).tag(meal)
                    }
                }
            }
        }
        .navigationTitle("Quick Add")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!isValid)
            }
            // The number pad has no return key.
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .onAppear {
            if editingEntry == nil { focusedField = .calories }
        }
    }

    private func numberField(_ title: String, text: Binding<String>, unit: String, field: Field) -> some View {
        HStack {
            Text(title)
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: field)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }

    private func save() {
        guard let calories, let protein = grams(proteinText), let carbs = grams(carbText), let fat = grams(fatText) else { return }
        if let editingEntry {
            viewModel.updateQuickAdd(
                editingEntry, name: name, caloriesKcal: calories, proteinG: protein, carbG: carbs, fatG: fat,
                mealType: mealType, context: modelContext
            )
        } else {
            viewModel.quickAdd(
                name: name, caloriesKcal: calories, proteinG: protein, carbG: carbs, fatG: fat,
                mealType: mealType, date: date, context: modelContext
            )
        }
        ReminderScheduler.didLog(Reminder(meal: mealType), on: date, in: modelContext)
        onSaved()
    }

    /// "350", "12.5"; blank for 0 so the optional fields read as empty.
    private static func format(_ value: Double) -> String {
        guard value != 0 else { return "" }
        return value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
    }
}

#Preview {
    NavigationStack {
        QuickAddFoodView(mealType: .lunch, date: .now, onSaved: {})
    }
    .modelContainer(for: AppSchema.models, inMemory: true)
}
