//
//  FoodHistoryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData
import WidgetKit

/// A single day's full diary — every meal, every entry. The initial date comes from the
/// caller (DailySummaryView owns the main date navigator), but this screen can also step
/// day-by-day on its own via the chevrons in its header.
struct FoodHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FoodEntry.date, order: .reverse) private var allEntries: [FoodEntry]
    @Query private var profiles: [UserProfile]

    @State private var date: Date
    @State private var isPresentingCalendar = false
    @AppStorage("foodHistoryShowPercent") private var showPercent = false

    private let viewModel = NutritionViewModel()
    private static let mealOrder: [MealType] = [.breakfast, .lunch, .dinner, .snack]

    init(date: Date) {
        _date = State(initialValue: date)
    }

    private var profile: UserProfile? { profiles.first }

    /// Mirrors the main Nutrition screen's date label, plus "Yesterday"/"Tomorrow" for the
    /// two days immediately adjacent to today — this screen is reached one tap away from
    /// "today", so those two neighbors come up often enough to spell out.
    private var dateHeaderText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        return date.formatted(.dateTime.weekday(.wide))
    }

    private var entriesForDate: [FoodEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        VStack(spacing: 0) {
            backButton

            Text("Daily Log")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)

            dateNavigator

            historyList
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $isPresentingCalendar) {
            NavigationStack {
                DatePicker(
                    "Select a day",
                    selection: $date,
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

    /// Replaces the system nav bar (hidden via `.navigationBarHidden`) with a small leading
    /// chevron directly above the title — the standard nav bar reserves a fixed strip of
    /// empty space above the title purely to host the back button, which is the bulk of the
    /// whitespace this screen doesn't need.
    private var backButton: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    /// "‹ [Today/Yesterday/Tomorrow/weekday, date] ›" — a plain row under the "Daily Log"
    /// title, same shape as the main screen's own title + chevron row. Tapping the date opens
    /// the same jump-to-date calendar sheet as the main Nutrition screen.
    private var dateNavigator: some View {
        HStack(spacing: 24) {
            Button {
                changeDay(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Button {
                isPresentingCalendar = true
            } label: {
                VStack(spacing: 2) {
                    Text(dateHeaderText)
                        .fontWeight(.semibold)
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            Button {
                changeDay(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func changeDay(by delta: Int) {
        guard let newDate = Calendar.current.date(byAdding: .day, value: delta, to: date) else { return }
        date = newDate
    }

    private var historyList: some View {
        List {
            if let profile {
                let totals = viewModel.dailyTotals(for: entriesForDate)
                Section {
                    caloriesCard(totals: totals, profile: profile)
                } header: {
                    HStack {
                        Text("Calories and Macronutrients")
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showPercent.toggle()
                            }
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        .accessibilityLabel(showPercent ? "Show amounts" : "Show percent")
                        .textCase(nil)
                    }
                }
                .listSectionSpacing(.custom(4))

                Section {
                    macroTotalsCard(totals: totals, profile: profile)
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

    // One full-width bar spanning the same total width as the three macro bars combined —
    // color matches the main Nutrition screen's calorie ring (`Color.blue`, its solo-macro
    // color) so it reads as the same quantity across both screens.
    private func caloriesCard(totals: MacroTotals, profile: UserProfile) -> some View {
        let target = Double(profile.calorieTarget)
        let eaten = totals.calories
        let remaining = target - eaten
        // The bar's fill can't visually exceed its own width, but the percent label should
        // still say 195% rather than capping at 100% — they're computed separately.
        let barFraction = target > 0 ? min(1, max(0, eaten / target)) : 0
        let percent = target > 0 ? max(0, eaten / target) * 100 : 0

        return VStack(spacing: 6) {
            HStack {
                ZStack(alignment: .leading) {
                    if showPercent {
                        Text("\(Int(percent.rounded()))%")
                            .fontWeight(.regular)
                            .transition(.opacity)
                    } else {
                        // Only the amount actually eaten is bold — the "/2,000 kcal" target
                        // is supporting context, not the headline number.
                        (Text("\(Int(eaten))").fontWeight(.bold)
                            + Text("/\(Int(target)) kcal").fontWeight(.regular))
                            .transition(.opacity)
                    }
                }
                .font(.caption)
                Spacer()
                Text(remaining >= 0 ? "\(Int(remaining)) left" : "\(Int(-remaining)) over")
                    .font(.caption2)
                    .foregroundStyle(remaining >= 0 ? Color.secondary : Color.red)
            }
            Capsule()
                .fill(Color.secondary.opacity(0.15))
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    GeometryReader { geometry in
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * barFraction)
                    }
                }
        }
        .padding(.vertical, 4)
    }

    // Calories are intentionally left out here — still figuring out how that should be
    // presented, so for now this card is just the three macros. The grams/percent toggle
    // lives in the section header above, not in here — see the "Macros" header.
    private func macroTotalsCard(totals: MacroTotals, profile: UserProfile) -> some View {
        HStack(alignment: .top, spacing: 12) {
            macroBar(name: "Protein", color: .orange, eaten: totals.proteinG, target: Double(profile.proteinTargetG))
            macroBar(name: "Carbs", color: .green, eaten: totals.carbG, target: Double(profile.carbTargetG))
            macroBar(name: "Fat", color: .purple, eaten: totals.fatG, target: Double(profile.fatTargetG))
        }
        .padding(.vertical, 4)
    }

    private func macroBar(name: String, color: Color, eaten: Double, target: Double) -> some View {
        // Same split as the calories bar: the fill can't exceed its own width, but the
        // percent label should still say e.g. 195% rather than capping at 100%.
        let barFraction = target > 0 ? min(1, max(0, eaten / target)) : 0
        let percent = target > 0 ? max(0, eaten / target) * 100 : 0
        return VStack(spacing: 6) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            Capsule()
                .fill(Color.secondary.opacity(0.15))
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    GeometryReader { geometry in
                        Capsule()
                            .fill(color)
                            .frame(width: geometry.size.width * barFraction)
                    }
                }
            ZStack {
                if showPercent {
                    Text("\(Int(percent.rounded()))%")
                        .transition(.opacity)
                } else {
                    Text("\(Int(eaten))/\(Int(target))g")
                        .transition(.opacity)
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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
