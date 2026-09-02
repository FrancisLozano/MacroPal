//
//  FoodHistoryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

struct FoodHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodEntry.date, order: .reverse) private var entries: [FoodEntry]
    @Query private var profiles: [UserProfile]

    private let viewModel = NutritionViewModel()

    private var profile: UserProfile? { profiles.first }

    private var entriesByDay: [(day: Date, entries: [FoodEntry])] {
        let grouped = Dictionary(grouping: entries) { Calendar.current.startOfDay(for: $0.date) }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (day: $0.key, entries: $0.value) }
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Food Logged",
                    systemImage: "fork.knife",
                    description: Text("Log a meal to see your history here.")
                )
            } else {
                List {
                    if let profile {
                        Section {
                            MacroAdherenceChart(
                                dailyTotals: viewModel.calorieAdherence(for: entries, calorieTarget: profile.calorieTarget),
                                calorieTarget: profile.calorieTarget
                            )
                        }
                    }
                    ForEach(entriesByDay, id: \.day) { group in
                        Section(group.day.formatted(date: .abbreviated, time: .omitted)) {
                            ForEach(group.entries) { entry in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(entry.nameSnapshot)
                                        Text(entry.mealType.displayName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\(Int(entry.caloriesKcal)) kcal")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .onDelete { offsets in
                                deleteEntries(group.entries, at: offsets)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Food History")
    }

    private func deleteEntries(_ entries: [FoodEntry], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
    }
}

#Preview {
    NavigationStack {
        FoodHistoryView()
    }
    .modelContainer(for: [FoodEntry.self, UserProfile.self], inMemory: true)
}
