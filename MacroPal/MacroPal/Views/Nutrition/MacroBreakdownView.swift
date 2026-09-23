//
//  MacroBreakdownView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Which foods a day's protein (or carbs, or fat) came from, biggest share first. Reached by
/// tapping a macro row on the Nutrition screen.
struct MacroBreakdownView: View {
    @Query(sort: \FoodEntry.date) private var allEntries: [FoodEntry]
    @Query private var profiles: [UserProfile]

    let macro: Macro
    let date: Date
    let color: Color

    private let viewModel = NutritionViewModel()

    private var entriesForDate: [FoodEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        let entries = entriesForDate
        let contributions = viewModel.contributions(to: macro, from: entries)
        let total = macro.grams(in: viewModel.dailyTotals(for: entries))

        List {
            Section {
                summary(total: total)
            }

            if contributions.isEmpty {
                Section {
                    Text("No \(macro.displayName.lowercased()) logged \(dayPhrase).")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Where it came from") {
                    ForEach(contributions, id: \.entry.persistentModelID) { contribution in
                        row(contribution)
                    }
                }
            }
        }
        .navigationTitle(macro.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var dayPhrase: String {
        Calendar.current.isDateInToday(date) ? "today" : "on \(date.formatted(.dateTime.month(.abbreviated).day()))"
    }

    // MARK: - Summary

    @ViewBuilder
    private func summary(total: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Calendar.current.isDateInToday(date) ? "Today" : date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                .font(.caption)
                .foregroundStyle(.secondary)
            if let profile = profiles.first {
                let target = macro.targetGrams(for: profile)
                let remaining = target - total
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(total.rounded()))")
                        .font(.title.bold())
                    Text("of \(Int(target.rounded()))g")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(remaining >= 0 ? "\(Int(remaining.rounded()))g remaining" : "\(Int(-remaining.rounded()))g over")
                        .font(.subheadline)
                        .foregroundStyle(remaining >= 0 ? Color.secondary : Color.red)
                }
                ProgressView(value: target > 0 ? min(total / target, 1) : 0)
                    .tint(color)
            } else {
                Text("\(Int(total.rounded()))g")
                    .font(.title.bold())
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Rows

    private func row(_ contribution: MacroContribution) -> some View {
        let entry = contribution.entry
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.nameSnapshot)
                    Text(entry.mealType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(formattedGrams(contribution.grams))g")
                        .fontWeight(.semibold)
                    Text("\(Int((contribution.share * 100).rounded()))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            // Share of the day's total, so the biggest sources stand out at a glance.
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule().fill(color).frame(width: proxy.size.width * contribution.share)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    /// Whole grams, except under 10 g where a decimal still means something (0.4 g of fat).
    private func formattedGrams(_ grams: Double) -> String {
        grams < 10 ? grams.formatted(.number.precision(.fractionLength(0...1))) : "\(Int(grams.rounded()))"
    }
}

#Preview {
    NavigationStack {
        MacroBreakdownView(macro: .protein, date: .now, color: .orange)
    }
    .modelContainer(for: [FoodEntry.self, FoodItem.self, UserProfile.self], inMemory: true)
}
