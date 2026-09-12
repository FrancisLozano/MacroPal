//
//  FoodEntryDetailView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Read-only detail for a single logged `FoodEntry`. No edit/delete affordance here —
/// deletion stays on the diary list's swipe-to-delete, matching WorkoutSessionDetailView.
struct FoodEntryDetailView: View {
    let entry: FoodEntry

    var body: some View {
        List {
            Section {
                detailRow(label: "Meal", value: entry.mealType.displayName)
                detailRow(label: "Date", value: entry.date.formatted(date: .abbreviated, time: .shortened))
                detailRow(label: "Serving Size", value: "\(Int(entry.servingSizeG)) g")
            }
            Section("Nutrition") {
                detailRow(label: "Calories", value: "\(Int(entry.caloriesKcal)) kcal")
                detailRow(label: "Protein", value: "\(Int(entry.proteinG)) g")
                detailRow(label: "Carbs", value: "\(Int(entry.carbG)) g")
                detailRow(label: "Fat", value: "\(Int(entry.fatG)) g")
            }
        }
        .navigationTitle(entry.nameSnapshot)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        FoodEntryDetailView(
            entry: FoodEntry(
                date: .now,
                mealType: .lunch,
                servingSizeG: 150,
                nameSnapshot: "Grilled Chicken Breast",
                caloriesKcal: 248,
                proteinG: 46,
                carbG: 0,
                fatG: 5
            )
        )
    }
    .modelContainer(for: [FoodEntry.self], inMemory: true)
}
