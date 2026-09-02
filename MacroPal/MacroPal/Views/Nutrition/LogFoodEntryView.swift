//
//  LogFoodEntryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

struct LogFoodEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFoodItem: FoodItem?
    @State private var servingSizeText = ""
    @State private var mealType: MealType = .breakfast
    @State private var date: Date = .now
    @State private var isPresentingPicker = false

    private let viewModel = NutritionViewModel()

    private var servingSizeG: Double? {
        Double(servingSizeText)
    }

    private var isValid: Bool {
        guard selectedFoodItem != nil, let servingSizeG else { return false }
        return servingSizeG > 0
    }

    var body: some View {
        Form {
            Section("Food") {
                Button {
                    isPresentingPicker = true
                } label: {
                    HStack {
                        Text(selectedFoodItem?.name ?? "Choose a food")
                            .foregroundStyle(selectedFoodItem == nil ? Color.secondary : Color.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            Section("Serving") {
                HStack {
                    TextField("Serving size", text: $servingSizeText)
                        .keyboardType(.decimalPad)
                    Text("g")
                        .foregroundStyle(.secondary)
                }
                Picker("Meal", selection: $mealType) {
                    ForEach(MealType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                DatePicker("Date", selection: $date)
            }
        }
        .navigationTitle("Log Food")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!isValid)
            }
        }
        .sheet(isPresented: $isPresentingPicker) {
            NavigationStack {
                FoodItemPickerView { item in
                    selectedFoodItem = item
                    if servingSizeText.isEmpty {
                        servingSizeText = String(format: "%.0f", item.defaultServingSizeG)
                    }
                }
            }
        }
    }

    private func save() {
        guard let selectedFoodItem, let servingSizeG else { return }
        viewModel.logEntry(
            foodItem: selectedFoodItem,
            servingSizeG: servingSizeG,
            mealType: mealType,
            date: date,
            context: modelContext
        )
        dismiss()
    }
}

#Preview {
    NavigationStack {
        LogFoodEntryView()
    }
    .modelContainer(for: [FoodItem.self, FoodEntry.self], inMemory: true)
}
