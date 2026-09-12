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
    @AppStorage("nutritionShowFullMacros") private var showFullMacros = true
    @State private var showTotalCalories = false
    @State private var selectedMeal: MealType = MealType.current()
    @State private var mealScrollPosition: MealType?
    @State private var isPresentingMealInfo = false

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
                LogFoodEntryView(initialMealType: selectedMeal)
            }
        }
        .task {
            _ = UserProfile.current(in: modelContext)
        }
        .onAppear {
            let current = MealType.current()
            selectedMeal = current
            mealScrollPosition = current
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
                    macroStat(name: "Protein", color: Self.proteinColor, eaten: totals.proteinG, target: Double(profile.proteinTargetG), remaining: remaining.proteinG, hideDot: !showFullMacros)
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

            Section {
                mealCarousel
                    .listRowInsets(EdgeInsets())
            } header: {
                HStack {
                    Text("Log Today")
                    Spacer()
                    Button {
                        isPresentingMealInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("About Log Today")
                    .textCase(nil)
                    .popover(isPresented: $isPresentingMealInfo) {
                        Text("Log food under whichever card matches when you actually ate — not necessarily right now. Breakfast, Lunch, and Dinner together cover the whole day, so a snack at 4 PM still counts under Lunch and a meal after 9 PM still counts under Dinner. The card shown here just defaults to the current time; swipe to pick a different one.")
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()
                            .frame(maxWidth: 320)
                            .presentationCompactAdaptation(.sheet)
                            .presentationDetents([.fraction(0.3)])
                    }
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

    private static let loggableMealTypes: [MealType] = [.breakfast, .lunch, .dinner]
    private static let mealCardHeight: CGFloat = 68
    /// Matches the default List row's own leading/trailing margin (measured against the
    /// Protein row), reproduced by hand here since `mealCarousel`'s row insets are zeroed.
    private static let rowInset: CGFloat = 16

    /// A manually-paged `ScrollView` rather than `TabView(.page)` — the latter ignores an
    /// explicit `.frame(height:)` on this SDK and expands to fill all available vertical
    /// space instead of respecting a fixed card height, even with `.clipped()` added.
    ///
    /// `mealScrollPosition` is a plain `@State` synced to `selectedMeal` via `onChange`
    /// rather than a computed `Binding` wired directly to `selectedMeal` — the latter fights
    /// the live drag gesture every frame (it kept re-asserting the old position), which
    /// made the carousel impossible to swipe at all.
    ///
    /// Row insets are zeroed (`.listRowInsets(EdgeInsets())`) so the horizontal `ScrollView`
    /// spans the row's full width — with the default (non-zero) insets in place, the List's
    /// own row-level gesture handling wins over the ScrollView's pan and swiping stops
    /// working entirely. `mealCard` restores the usual List row's leading/trailing margin
    /// itself (`Self.rowInset`) purely for visual alignment with rows like Protein, and has
    /// no background of its own — no nested card look.
    private var mealCarousel: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(Self.loggableMealTypes) { meal in
                        mealCard(meal)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $mealScrollPosition)
            .onChange(of: mealScrollPosition) { _, newValue in
                if let newValue {
                    selectedMeal = newValue
                }
            }
            .scrollIndicators(.hidden)
            .frame(height: Self.mealCardHeight)

            pageDots
                .padding(.vertical, 8)
        }
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(Self.loggableMealTypes) { meal in
                Circle()
                    .fill(meal == selectedMeal ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }

    /// One swipeable page: meal name/icon + suggested time window on top, with a food
    /// summary (what's logged so far) under the name and that meal's total calories under
    /// the time — a compact two-line row rather than a per-entry list, so it stays a fixed,
    /// small size regardless of how much has been logged.
    private func mealCard(_ meal: MealType) -> some View {
        let entries = todaysEntries.filter { $0.mealType == meal }
        return VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    Image(systemName: meal.icon)
                        .foregroundStyle(.secondary)
                    Text(meal.displayName)
                        .fontWeight(.semibold)
                }
                Spacer()
                Text(meal.defaultTimeWindow.displayText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(foodSummary(for: entries))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                if !entries.isEmpty {
                    Text("\(Int(entries.reduce(0) { $0 + $1.caloriesKcal })) kcal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, Self.rowInset)
        .frame(height: Self.mealCardHeight)
    }

    /// "Nothing logged today" when empty, the food's name for a single entry, or the first
    /// entry's name plus a "and N more" count once there's more than one.
    private func foodSummary(for entries: [FoodEntry]) -> String {
        guard let first = entries.first else {
            return "Nothing logged today"
        }
        let additional = entries.count - 1
        guard additional > 0 else {
            return "Logged \(first.nameSnapshot)"
        }
        return "Logged \(first.nameSnapshot) and \(additional) more"
    }

    // Matches the colors already used for these macros in the home-screen widget, so the
    // color coding reads the same across the app.
    private static let proteinColor = Color.orange
    private static let carbColor = Color.green
    private static let fatColor = Color.purple
    private static let ringLineWidth: CGFloat = 20
    private static let ringDiameter: CGFloat = 284
    private static let soloColor = Color.blue

    /// The calorie gauge, standalone on the screen background (no card) so it isn't
    /// squeezed into the same box as the macro list below it.
    private func calorieHeader(profile: UserProfile) -> some View {
        let totals = viewModel.dailyTotals(for: todaysEntries)
        return calorieHalfRing(totals: totals, profile: profile)
            .frame(maxWidth: .infinity)
    }

    /// A half-circle calorie gauge whose filled arc is itself split into colored segments —
    /// one per macro, sized by that macro's share of calories eaten today — rather than a
    /// plain single-color fill. In protein-only mode, orange no longer means anything
    /// without the other macros to contrast against, so the whole eaten-calories fraction
    /// fills in one solid accent color instead of a protein slice plus a leftover one.
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
            segments = [(Self.soloColor, fraction)]
        }

        return ZStack {
            Circle()
                .trim(from: 0, to: 0.5)
                .stroke(Color.secondary.opacity(0.15), lineWidth: Self.ringLineWidth)
                .rotationEffect(.degrees(180))
            halfRingSegments(segments)
        }
        // A Circle sized to fill its frame gets stroked lineWidth/2 *past* that frame's
        // edge on every side. Insetting by lineWidth/2 here shrinks the circle so the
        // stroke's outer edge lands exactly on the frame boundary instead of past it —
        // otherwise .clipped() below (meant only to hide the bottom half) also slices the
        // left/right ends of the visible arc off.
        .padding(Self.ringLineWidth / 2)
        .frame(width: Self.ringDiameter, height: Self.ringDiameter, alignment: .top)
        .frame(height: Self.ringDiameter / 2 + Self.ringLineWidth, alignment: .top)
        .clipped()
        .overlay(alignment: .bottom) {
            calorieReadout(remainingCalories: remainingCalories, target: target)
        }
    }

    /// Shares the ring's own hollow interior instead of taking extra space below it —
    /// anchored to the half-circle's flat baseline via the `.bottom` overlay alignment.
    private func calorieReadout(remainingCalories: Double, target: Double) -> some View {
        let isOver = !showTotalCalories && remainingCalories < 0
        let value = showTotalCalories ? Int(target.rounded()) : Int(abs(remainingCalories).rounded())
        let caption = showTotalCalories ? "kcal / day" : (remainingCalories >= 0 ? "kcal left" : "kcal over")

        return VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 44, weight: .bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            HStack(spacing: 5) {
                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(isOver ? Color.red : Color.secondary)
                Button {
                    showTotalCalories.toggle()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                .accessibilityLabel(showTotalCalories ? "Show calories remaining" : "Show total daily calories")
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

    private func macroStat(name: String, color: Color, eaten: Double, target: Double, remaining: Double, hideDot: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack {
                if !hideDot {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
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
