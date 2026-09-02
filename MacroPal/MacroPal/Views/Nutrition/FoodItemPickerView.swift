//
//  FoodItemPickerView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Search an existing `FoodItem` catalog, or create a new one inline. Calls `onSelect`
/// with the chosen/created item and dismisses itself.
struct FoodItemPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let onSelect: (FoodItem) -> Void

    @State private var searchText = ""
    @State private var isPresentingNewFoodForm = false

    private let viewModel = NutritionViewModel()

    private var results: [FoodItem] {
        viewModel.searchFoodItems(matching: searchText, in: modelContext)
    }

    var body: some View {
        List {
            ForEach(results) { item in
                Button {
                    onSelect(item)
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .foregroundStyle(Color.primary)
                        Text("\(Int(item.caloriesPer100g)) kcal / 100g")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search foods")
        .navigationTitle("Choose Food")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingNewFoodForm = true
                } label: {
                    Label("New Food", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingNewFoodForm) {
            NavigationStack {
                NewFoodItemView { newItem in
                    onSelect(newItem)
                    dismiss()
                }
            }
        }
    }
}

/// Inline "create new food" form, used when the desired food isn't in the catalog yet.
private struct NewFoodItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let onCreate: (FoodItem) -> Void

    @State private var name = ""
    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var carbText = ""
    @State private var fatText = ""
    @State private var servingSizeText = "100"

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && Double(caloriesText) != nil
            && Double(proteinText) != nil
            && Double(carbText) != nil
            && Double(fatText) != nil
            && Double(servingSizeText) != nil
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Food name", text: $name)
            }
            Section("Macros per 100g") {
                HStack {
                    Text("Calories")
                    Spacer()
                    TextField("kcal", text: $caloriesText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Protein")
                    Spacer()
                    TextField("g", text: $proteinText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Carbs")
                    Spacer()
                    TextField("g", text: $carbText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Fat")
                    Spacer()
                    TextField("g", text: $fatText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            Section("Default Serving Size") {
                HStack {
                    TextField("Serving size", text: $servingSizeText)
                        .keyboardType(.decimalPad)
                    Text("g")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("New Food")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!isValid)
            }
        }
    }

    private func save() {
        guard let calories = Double(caloriesText),
              let protein = Double(proteinText),
              let carb = Double(carbText),
              let fat = Double(fatText),
              let servingSize = Double(servingSizeText) else { return }

        let item = FoodItem(
            name: name.trimmingCharacters(in: .whitespaces),
            caloriesPer100g: calories,
            proteinG: protein,
            carbG: carb,
            fatG: fat,
            defaultServingSizeG: servingSize
        )
        modelContext.insert(item)
        onCreate(item)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        FoodItemPickerView { _ in }
    }
    .modelContainer(for: FoodItem.self, inMemory: true)
}
