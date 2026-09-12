//
//  FoodHistoryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData
import WidgetKit

/// A single day's full diary — every meal, every entry. The date itself is chosen by the
/// caller (DailySummaryView owns the date navigator); this view just renders whichever day
/// it's handed.
struct FoodHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodEntry.date, order: .reverse) private var allEntries: [FoodEntry]
    @Query private var profiles: [UserProfile]

    let date: Date

    private let viewModel = NutritionViewModel()
    private static let mealOrder: [MealType] = [.breakfast, .lunch, .dinner, .snack]

    private var profile: UserProfile? { profiles.first }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var navigationTitleText: String {
        isToday ? "Today" : date.formatted(date: .abbreviated, time: .omitted)
    }

    private var entriesForDate: [FoodEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        historyList
            .navigationTitle(navigationTitleText)
            .navigationBarTitleDisplayMode(.inline)
    }

    private var historyList: some View {
        List {
            if let profile {
                let totals = viewModel.dailyTotals(for: entriesForDate)
                Section("Totals") {
                    dailyTotalsSummary(totals: totals, profile: profile)
                }
            }

            ForEach(Self.mealOrder) { meal in
                let mealEntries = entriesForDate.filter { $0.mealType == meal }
                if !mealEntries.isEmpty {
                    Section(meal.displayName) {
                        ForEach(mealEntries) { entry in
                            NavigationLink {
                                FoodEntryDetailView(entry: entry)
                            } label: {
                                entryRow(entry)
                            }
                        }
                        .onDelete { offsets in
                            deleteEntries(mealEntries, at: offsets)
                        }
                    }
                }
            }

            if entriesForDate.isEmpty {
                Section {
                    Text("Nothing logged on this day.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func dailyTotalsSummary(totals: MacroTotals, profile: UserProfile) -> some View {
        let remaining = viewModel.remaining(totals: totals, profile: profile)
        return VStack(alignment: .leading, spacing: 8) {
            totalsRow(name: "Calories", eaten: totals.calories, target: Double(profile.calorieTarget), remaining: remaining.calories, unit: "")
            totalsRow(name: "Protein", eaten: totals.proteinG, target: Double(profile.proteinTargetG), remaining: remaining.proteinG, unit: "g")
            totalsRow(name: "Carbs", eaten: totals.carbG, target: Double(profile.carbTargetG), remaining: remaining.carbG, unit: "g")
            totalsRow(name: "Fat", eaten: totals.fatG, target: Double(profile.fatTargetG), remaining: remaining.fatG, unit: "g")
        }
    }

    private func totalsRow(name: String, eaten: Double, target: Double, remaining: Double, unit: String) -> some View {
        HStack {
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            Text("\(Int(eaten))/\(Int(target))\(unit)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(remaining >= 0 ? "\(Int(remaining))\(unit) left" : "\(Int(-remaining))\(unit) over")
                .font(.caption2)
                .foregroundStyle(remaining >= 0 ? Color.secondary : Color.red)
                .frame(width: 70, alignment: .trailing)
        }
    }

    private func entryRow(_ entry: FoodEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.nameSnapshot)
                Text("\(Int(entry.proteinG))p · \(Int(entry.carbG))c · \(Int(entry.fatG))f")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(entry.caloriesKcal)) kcal")
                .foregroundStyle(.secondary)
        }
    }

    private func deleteEntries(_ entries: [FoodEntry], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    NavigationStack {
        FoodHistoryView(date: .now)
    }
    .modelContainer(for: [FoodEntry.self, UserProfile.self], inMemory: true)
}
