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
    @State private var isPresentingLogSheet = false
    @State private var mealTypeToLog: MealType = .breakfast
    @State private var selectedMacro: Macro?
    @State private var isShowingMealCalories = false
    @AppStorage("foodHistoryShowPercent") private var showPercent = false

    private let viewModel = NutritionViewModel()
    private static let mealOrder: [MealType] = [.breakfast, .lunch, .dinner]

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
        .sheet(isPresented: $isPresentingLogSheet) {
            NavigationStack {
                LogFoodFlowView(initialMealType: mealTypeToLog, initialDate: date)
            }
        }
        .navigationDestination(item: $selectedMacro) { macro in
            MacroBreakdownView(macro: macro, date: date, color: Self.color(for: macro))
        }
        .navigationDestination(isPresented: $isShowingMealCalories) {
            MealCaloriesView(date: date)
        }
    }

    /// The same macro colors as the Nutrition screen, so the breakdown looks the same from
    /// either place.
    private static func color(for macro: Macro) -> Color {
        switch macro {
        case .protein: .orange
        case .carbs: .green
        case .fat: .purple
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
                    // Opens the day's calories by meal, as a pie chart.
                    Button {
                        isShowingMealCalories = true
                    } label: {
                        caloriesCard(totals: totals, profile: profile)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
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
                Section {
                    if mealEntries.isEmpty {
                        Text("No items logged")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(mealEntries) { entry in
                            NavigationLink {
                                EditFoodEntryDestination(entry: entry)
                            } label: {
                                entryRow(entry)
                            }
                        }
                        .onDelete { offsets in
                            deleteEntries(mealEntries, at: offsets)
                        }
                    }
                } header: {
                    HStack {
                        Text(meal.displayName)
                        Spacer()
                        // The meal's macros as "26p · 18c · 4f". The rows below leave macros out (tap a
                        // food for them), so this is the only macro line per meal.
                        if !mealEntries.isEmpty {
                            let mealTotals = viewModel.dailyTotals(for: mealEntries)
                            Text("\(Int(mealTotals.proteinG.rounded()))p · \(Int(mealTotals.carbG.rounded()))c · \(Int(mealTotals.fatG.rounded()))f")
                                .font(.subheadline)
                                .monospacedDigit()
                                .textCase(nil)
                        }
                        Button {
                            mealTypeToLog = meal
                            isPresentingLogSheet = true
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                        .accessibilityLabel("Add food to \(meal.displayName)")
                        .textCase(nil)
                    }
                }
            }
        }
    }

    // One full-width bar spanning the same total width as the three macro bars combined —
    // color matches the main Nutrition screen's calorie ring (`Color.blue`, its solo-macro
    // color) so it reads as the same quantity across both screens. The split by meal is left
    // to the pie chart it opens: colored here, it competed with the macro bars below.
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
                        HStack(spacing: 0) {
                            Text("\(Int(eaten.rounded()))")
                                .fontWeight(.bold)
                            Text("/\(Int(target.rounded())) kcal")
                                .fontWeight(.regular)
                        }
                        .transition(.opacity)
                    }
                }
                .font(.caption)
                Spacer()
                Text(remaining >= 0 ? "\(Int(remaining.rounded())) left" : "\(Int(-remaining.rounded())) over")
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
    // lives in the section header above, not in here — see the "Macros" header. Each macro
    // opens which foods it came from, like the Macros rows on the Nutrition screen.
    private func macroTotalsCard(totals: MacroTotals, profile: UserProfile) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(Macro.allCases) { macro in
                Button {
                    selectedMacro = macro
                } label: {
                    macroBar(name: macro.displayName, color: Self.color(for: macro), eaten: macro.grams(in: totals), target: macro.targetGrams(for: profile))
                        .contentShape(Rectangle())
                }
                // Not the row-wide default style: each of the three is its own tap target.
                .buttonStyle(.plain)
            }
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
                    Text("\(Int(eaten.rounded()))/\(Int(target.rounded()))g")
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
                Text(sourceLabel(for: entry))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(entry.caloriesKcal.rounded())) kcal")
                .foregroundStyle(.secondary)
        }
    }

    /// The brand this entry was logged under, "My Meals" for a recipe (it carried its own
    /// ingredient snapshots at log time), or "Manually Added" for a plain food typed in by
    /// hand — lets someone tell apart, say, a Fairtrade banana from one they created
    /// themselves under the same name.
    private func sourceLabel(for entry: FoodEntry) -> String {
        if let brand = entry.brandSnapshot, !brand.isEmpty { return brand }
        return entry.ingredientSnapshots.isEmpty ? "Manually Added" : "My Meals"
    }

    private func deleteEntries(_ entries: [FoodEntry], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

/// Wraps `LogFoodEntryView` in edit mode for a `NavigationLink` push from the diary list.
/// `LogFoodEntryView` itself takes `onSaved` rather than owning `@Environment(\.dismiss)` (it
/// also gets pushed from the "add new food" flow, where dismissing needs to close a sheet
/// several levels up, not just pop) — here, reached by a plain push, popping via this view's
/// own `dismiss` is exactly the right behavior after a save.
private struct EditFoodEntryDestination: View {
    @Environment(\.dismiss) private var dismiss
    let entry: FoodEntry

    var body: some View {
        LogFoodEntryView(entry: entry, onSaved: { dismiss() })
    }
}

#Preview {
    NavigationStack {
        FoodHistoryView(date: .now)
    }
    .modelContainer(for: [FoodEntry.self, UserProfile.self], inMemory: true)
}
