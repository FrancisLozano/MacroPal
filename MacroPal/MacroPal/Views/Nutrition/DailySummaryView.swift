//
//  DailySummaryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

struct DailySummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var todaysEntries: [FoodEntry]
    @Query private var profiles: [UserProfile]

    @State private var isPresentingLogSheet = false

    private let viewModel = NutritionViewModel()

    init() {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        _todaysEntries = Query(
            filter: #Predicate<FoodEntry> { $0.date >= startOfDay && $0.date < endOfDay },
            sort: \FoodEntry.date
        )
    }

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        List {
            if let profile {
                let totals = viewModel.dailyTotals(for: todaysEntries)
                let remaining = viewModel.remaining(totals: totals, profile: profile)

                Section("Today") {
                    macroRow(name: "Calories", eaten: totals.calories, target: Double(profile.calorieTarget), remaining: remaining.calories, unit: "kcal")
                    macroRow(name: "Protein", eaten: totals.proteinG, target: Double(profile.proteinTargetG), remaining: remaining.proteinG, unit: "g")
                    macroRow(name: "Carbs", eaten: totals.carbG, target: Double(profile.carbTargetG), remaining: remaining.carbG, unit: "g")
                    macroRow(name: "Fat", eaten: totals.fatG, target: Double(profile.fatTargetG), remaining: remaining.fatG, unit: "g")
                }
            }

            Section("Logged Today") {
                if todaysEntries.isEmpty {
                    Text("Nothing logged yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(todaysEntries) { entry in
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
                }
            }

            Section {
                NavigationLink("Food History") {
                    FoodHistoryView()
                }
            }
        }
        .navigationTitle("Nutrition")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingLogSheet = true
                } label: {
                    Label("Log Food", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingLogSheet) {
            NavigationStack {
                LogFoodEntryView()
            }
        }
        .task {
            _ = UserProfile.current(in: modelContext)
        }
    }

    @ViewBuilder
    private func macroRow(name: String, eaten: Double, target: Double, remaining: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.headline)
                Spacer()
                Text("\(Int(eaten)) / \(Int(target)) \(unit)")
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: min(eaten, target), total: max(target, 1))
            Text(remaining >= 0 ? "\(Int(remaining)) \(unit) remaining" : "\(Int(-remaining)) \(unit) over")
                .font(.caption)
                .foregroundStyle(remaining >= 0 ? Color.secondary : Color.red)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        DailySummaryView()
    }
    .modelContainer(for: [FoodEntry.self, FoodItem.self, UserProfile.self], inMemory: true)
}
