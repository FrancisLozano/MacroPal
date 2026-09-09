//
//  DailySummaryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData
import WidgetKit

struct DailySummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var todaysEntries: [FoodEntry]
    @Query private var profiles: [UserProfile]

    @State private var isPresentingLogSheet = false
    @AppStorage("nutritionShowFullMacros") private var showFullMacros = true

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

                Section {
                    macroRow(name: "Calories", eaten: totals.calories, target: Double(profile.calorieTarget), remaining: remaining.calories, unit: "kcal")
                    if showFullMacros {
                        compactMacroRow([
                            (name: "Protein", eaten: totals.proteinG, target: Double(profile.proteinTargetG), unit: "g"),
                            (name: "Carbs", eaten: totals.carbG, target: Double(profile.carbTargetG), unit: "g"),
                            (name: "Fat", eaten: totals.fatG, target: Double(profile.fatTargetG), unit: "g"),
                        ])
                    } else {
                        compactMacroRow([
                            (name: "Protein", eaten: totals.proteinG, target: Double(profile.proteinTargetG), unit: "g"),
                        ])
                    }
                } header: {
                    HStack {
                        Text("Today")
                        Spacer()
                        Button(showFullMacros ? "Show Less" : "Show More") {
                            showFullMacros.toggle()
                        }
                        .font(.caption)
                        .textCase(nil)
                    }
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
                    .onDelete(perform: deleteEntries)
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

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(todaysEntries[index])
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
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

    private func compactMacroRow(_ macros: [(name: String, eaten: Double, target: Double, unit: String)]) -> some View {
        HStack(alignment: .top, spacing: 20) {
            ForEach(macros, id: \.name) { macro in
                compactMacroColumn(name: macro.name, eaten: macro.eaten, target: macro.target, unit: macro.unit)
            }
        }
        .padding(.vertical, 4)
    }

    private func compactMacroColumn(name: String, eaten: Double, target: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(Int(eaten))/\(Int(target))\(unit)")
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            ProgressView(value: min(eaten, target), total: max(target, 1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        DailySummaryView()
    }
    .modelContainer(for: [FoodEntry.self, FoodItem.self, UserProfile.self], inMemory: true)
}
