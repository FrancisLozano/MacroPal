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
        VStack(spacing: 0) {
            if let profile {
                calorieHeader(profile: profile)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
            }

            macroList(profile: profile)
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

    /// The macro breakdown list and the rest of the screen — kept as a plain `List` (its
    /// own card styling) separate from `calorieHeader`, which sits directly on the screen
    /// background with no card around it.
    private func macroList(profile: UserProfile?) -> some View {
        List {
            if let profile {
                let totals = viewModel.dailyTotals(for: todaysEntries)
                let remaining = viewModel.remaining(totals: totals, profile: profile)

                Section {
                    macroStat(name: "Protein", color: Self.proteinColor, eaten: totals.proteinG, target: Double(profile.proteinTargetG), remaining: remaining.proteinG)
                    if showFullMacros {
                        macroStat(name: "Carbs", color: Self.carbColor, eaten: totals.carbG, target: Double(profile.carbTargetG), remaining: remaining.carbG)
                        macroStat(name: "Fat", color: Self.fatColor, eaten: totals.fatG, target: Double(profile.fatTargetG), remaining: remaining.fatG)
                    }
                } header: {
                    HStack {
                        Text("Macros")
                        Spacer()
                        Button {
                            showFullMacros.toggle()
                        } label: {
                            Image(systemName: showFullMacros ? "chart.pie.fill" : "chart.pie")
                        }
                        .accessibilityLabel(showFullMacros ? "Show protein only" : "Show all macros")
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
        .scrollIndicators(.hidden)
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(todaysEntries[index])
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // Matches the colors already used for these macros in the home-screen widget, so the
    // color coding reads the same across the app.
    private static let proteinColor = Color.orange
    private static let carbColor = Color.green
    private static let fatColor = Color.purple
    private static let ringLineWidth: CGFloat = 16
    private static let ringDiameter: CGFloat = 260

    /// The calorie gauge, standalone on the screen background (no card) so it isn't
    /// squeezed into the same box as the macro list below it.
    private func calorieHeader(profile: UserProfile) -> some View {
        let totals = viewModel.dailyTotals(for: todaysEntries)
        return calorieHalfRing(totals: totals, profile: profile)
            .frame(maxWidth: .infinity)
    }

    /// A half-circle calorie gauge whose filled arc is itself split into colored segments —
    /// one per macro, sized by that macro's share of calories eaten today — rather than a
    /// plain single-color fill. In protein-only mode the non-protein calories collapse into
    /// one neutral segment instead of three colored ones.
    private func calorieHalfRing(totals: MacroTotals, profile: UserProfile) -> some View {
        let target = Double(profile.calorieTarget)
        let fraction = target > 0 ? min(1, max(0, totals.calories / target)) : 0
        let remainingCalories = target - totals.calories
        let breakdown = viewModel.macroCalorieBreakdown(for: totals)

        let segments: [(color: Color, length: Double)]
        if showFullMacros {
            segments = [
                (Self.proteinColor, breakdown.proteinPercent * fraction),
                (Self.carbColor, breakdown.carbPercent * fraction),
                (Self.fatColor, breakdown.fatPercent * fraction),
            ]
        } else {
            segments = [
                (Self.proteinColor, breakdown.proteinPercent * fraction),
                (Color.secondary.opacity(0.35), (1 - breakdown.proteinPercent) * fraction),
            ]
        }

        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: Self.ringLineWidth)
                    .rotationEffect(.degrees(180))
                halfRingSegments(segments)
            }
            .frame(width: Self.ringDiameter, height: Self.ringDiameter, alignment: .top)
            .frame(height: Self.ringDiameter / 2 + Self.ringLineWidth, alignment: .top)
            .clipped()

            VStack(spacing: 2) {
                Text("\(Int(abs(remainingCalories)))")
                    .font(.system(size: 44, weight: .bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(remainingCalories >= 0 ? "kcal left" : "kcal over")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Draws each macro segment as its own trimmed arc within the top half of the circle
    /// (trim range 0...0.5), back-to-back in order, then rotates the whole thing 180° so
    /// the visible arc sits over the top like a gauge instead of the bottom.
    private func halfRingSegments(_ segments: [(color: Color, length: Double)]) -> some View {
        ForEach(Array(ringSegmentRanges(segments).enumerated()), id: \.offset) { _, segment in
            Circle()
                .trim(from: segment.start * 0.5, to: max(segment.start, segment.end) * 0.5)
                .stroke(segment.color, style: StrokeStyle(lineWidth: Self.ringLineWidth, lineCap: .round))
                .rotationEffect(.degrees(180))
        }
    }

    /// Converts consecutive segment lengths (each a fraction of the full circle) into
    /// absolute start/end trim values, so segments draw back-to-back around the ring
    /// instead of all starting from zero.
    private func ringSegmentRanges(_ segments: [(color: Color, length: Double)]) -> [(color: Color, start: Double, end: Double)] {
        var ranges: [(color: Color, start: Double, end: Double)] = []
        var cumulative: Double = 0
        for segment in segments {
            let end = min(1, cumulative + segment.length)
            ranges.append((segment.color, cumulative, end))
            cumulative = end
        }
        return ranges
    }

    private func macroStat(name: String, color: Color, eaten: Double, target: Double, remaining: Double) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(eaten))/\(Int(target))g")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(remaining >= 0 ? "\(Int(remaining))g remaining" : "\(Int(-remaining))g over")
                .font(.caption2)
                .foregroundStyle(remaining >= 0 ? Color.secondary : Color.red)
        }
    }
}

#Preview {
    NavigationStack {
        DailySummaryView()
    }
    .modelContainer(for: [FoodEntry.self, FoodItem.self, UserProfile.self], inMemory: true)
}
