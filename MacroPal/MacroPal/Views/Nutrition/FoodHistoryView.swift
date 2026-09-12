//
//  FoodHistoryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData
import WidgetKit

/// A MyFitnessPal-style diary: one day at a time, navigated with prev/next-day arrows or a
/// calendar picker, rather than an ever-growing flat list of every day ever logged.
struct FoodHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodEntry.date, order: .reverse) private var allEntries: [FoodEntry]
    @Query private var profiles: [UserProfile]

    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var isPresentingCalendar = false

    private let viewModel = NutritionViewModel()
    private static let mealOrder: [MealType] = [.breakfast, .lunch, .dinner, .snack]

    private var profile: UserProfile? { profiles.first }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var entriesForSelectedDate: [FoodEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        VStack(spacing: 0) {
            dateNavigator

            historyList
        }
        .navigationTitle("Food History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingCalendar) {
            NavigationStack {
                DatePicker(
                    "Select a day",
                    selection: $selectedDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Jump to Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { isPresentingCalendar = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    /// Pulled out of the `List` below on purpose — its row structure changes shape
    /// dramatically between a logged day (Totals + several meal sections) and an empty one
    /// (Totals + a single fallback message), and that swing confused SwiftUI's List diffing
    /// enough to permanently detach this row's buttons from their gesture recognizers after
    /// the first date change (same class of bug as the meal carousel earlier). Keeping the
    /// navigator as a plain, stable view above the List sidesteps that entirely.
    private var historyList: some View {
        List {
            if let profile {
                let totals = viewModel.dailyTotals(for: entriesForSelectedDate)
                Section("Totals") {
                    dailyTotalsSummary(totals: totals, profile: profile)
                }
            }

            ForEach(Self.mealOrder) { meal in
                let mealEntries = entriesForSelectedDate.filter { $0.mealType == meal }
                if !mealEntries.isEmpty {
                    Section(meal.displayName) {
                        ForEach(mealEntries) { entry in
                            entryRow(entry)
                        }
                        .onDelete { offsets in
                            deleteEntries(mealEntries, at: offsets)
                        }
                    }
                }
            }

            if entriesForSelectedDate.isEmpty {
                Section {
                    Text("Nothing logged on this day.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// "‹ [Today / weekday, date] ›" — tapping the date opens a calendar picker to jump
    /// straight to any day; the chevrons step one day at a time. Can't navigate past today.
    private var dateNavigator: some View {
        HStack {
            Button {
                changeDay(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Button {
                isPresentingCalendar = true
            } label: {
                VStack(spacing: 2) {
                    Text(isToday ? "Today" : selectedDate.formatted(.dateTime.weekday(.wide)))
                        .fontWeight(.semibold)
                    Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                changeDay(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(isToday)
        }
        .padding()
    }

    private func changeDay(by delta: Int) {
        guard let newDate = Calendar.current.date(byAdding: .day, value: delta, to: selectedDate) else { return }
        let today = Calendar.current.startOfDay(for: .now)
        selectedDate = min(newDate, today)
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
        FoodHistoryView()
    }
    .modelContainer(for: [FoodEntry.self, UserProfile.self], inMemory: true)
}
