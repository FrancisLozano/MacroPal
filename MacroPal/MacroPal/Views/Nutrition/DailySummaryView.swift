//
//  DailySummaryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

struct DailySummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodEntry.date, order: .reverse) private var allEntries: [FoodEntry]
    @Query private var profiles: [UserProfile]

    @State private var isPresentingLogSheet = false
    @AppStorage("nutritionShowFullMacros") private var showFullMacros = true
    @State private var showTotalCalories = false
    @State private var selectedMeal: MealType = MealType.current()
    @State private var mealScrollPosition: MealType?
    @State private var isPresentingMealInfo = false
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var isPresentingCalendar = false
    @State private var weekSlideForward = true

    private let viewModel = NutritionViewModel()

    private var profile: UserProfile? { profiles.first }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var entriesForSelectedDate: [FoodEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            macroList(profile: profile)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottomTrailing) {
            logFoodButton
        }
        .sheet(isPresented: $isPresentingLogSheet) {
            NavigationStack {
                LogFoodEntryView(initialMealType: selectedMeal, initialDate: selectedDate)
            }
        }
        .sheet(isPresented: $isPresentingCalendar) {
            NavigationStack {
                DatePicker(
                    "Select a day",
                    selection: $selectedDate,
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
        .task {
            _ = UserProfile.current(in: modelContext)
        }
        .onAppear {
            let current = MealType.current()
            selectedMeal = current
            mealScrollPosition = current
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            weekSlideForward = newValue >= oldValue
        }
    }

    /// The title plus the date navigator (chevrons + week strip). Kept as a plain stack
    /// sibling to the `List` below — not a row inside it — for the same reason
    /// `FoodHistoryView`'s old date navigator was kept out of its `List`: a `List` whose
    /// section/row structure changes shape between states can permanently detach buttons
    /// inside it from their gesture recognizers (bit us once with the meal carousel and the
    /// original date navigator). A plain stack above the List never has that problem.
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nutrition")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)

            dateChevronRow
            weekStrip
        }
        .padding(.top, 8)
    }

    /// "‹ [Today / weekday, date] ›" — tapping the date opens a calendar picker to jump
    /// straight to any day; the chevrons step one day at a time, in either direction —
    /// future days are fair game too, e.g. for planning a meal ahead of time.
    private var dateChevronRow: some View {
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
        }
        .padding(.horizontal)
    }

    /// The calendar week (locale-defined, e.g. Sun–Sat) containing `selectedDate`, for one-tap
    /// jumps to a nearby day (past or future) plus a small dot on any day that has at least
    /// one logged entry. Stepping day-by-day with the chevrons stays within this same block
    /// and doesn't move it — the strip only jumps, as a whole, once `selectedDate` crosses into
    /// a different week, sliding the whole row off in the direction of travel and the new week
    /// in from the opposite edge (`weekSlideForward`, set from the sign of each `selectedDate`
    /// change) rather than each day quietly fading. `.id(currentWeekStart)` is what makes
    /// SwiftUI treat a week change as a wholesale swap it can transition, instead of diffing
    /// day-by-day. Always 7 fixed slots for a given week — only which week, and each circle's
    /// selected/dot state, changes — so this never changes shape the way a List row/section can.
    ///
    /// Also used as the List's top content margin (see `macroList`) so the gap between the
    /// dots and the calorie ring below them matches the gap above the dots (between the day
    /// number and its dot) exactly, instead of two independently-chosen numbers that happen to
    /// look close.
    private static let weekStripDotSpacing: CGFloat = 4

    /// A horizontal swipe (`weekSwipeGesture`) jumps a whole week too, same as one full pass of
    /// the day chevrons would eventually reach — swipe left to advance, right to go back. It's
    /// attached with `.simultaneousGesture` rather than `.gesture` so it never steals a tap from
    /// the day circles underneath: a plain tap has no meaningful translation and only the
    /// circle's own `Button` action fires, while a drag past the minimum distance also fires
    /// this one independently.
    private var weekStrip: some View {
        HStack {
            ForEach(visibleWeekDays, id: \.self) { day in
                weekDayCircle(day)
            }
        }
        .padding(.horizontal)
        .id(currentWeekStart)
        .transition(.asymmetric(
            insertion: .move(edge: weekSlideForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: weekSlideForward ? .leading : .trailing).combined(with: .opacity)
        ))
        .animation(.easeInOut, value: currentWeekStart)
        .simultaneousGesture(weekSwipeGesture)
    }

    private var weekSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical), abs(horizontal) > 40 else { return }
                changeDay(by: horizontal < 0 ? 7 : -7)
            }
    }

    private var currentWeekStart: Date {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start
            ?? calendar.startOfDay(for: selectedDate)
    }

    private var visibleWeekDays: [Date] {
        let calendar = Calendar.current
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: currentWeekStart)
        }
    }

    private var loggedDaysInVisibleWeek: Set<Date> {
        let calendar = Calendar.current
        let visible = Set(visibleWeekDays.map { calendar.startOfDay(for: $0) })
        var result: Set<Date> = []
        for entry in allEntries {
            let day = calendar.startOfDay(for: entry.date)
            if visible.contains(day) {
                result.insert(day)
            }
        }
        return result
    }

    private func weekDayCircle(_ day: Date) -> some View {
        let calendar = Calendar.current
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let hasEntries = loggedDaysInVisibleWeek.contains(calendar.startOfDay(for: day))

        return Button {
            selectedDate = calendar.startOfDay(for: day)
        } label: {
            VStack(spacing: Self.weekStripDotSpacing) {
                Text(day.formatted(.dateTime.weekday(.narrow)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(day.formatted(.dateTime.day()))
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Color.accentColor.opacity(0.15) : .clear, in: Circle())
                Circle()
                    .fill(hasEntries ? Color.accentColor : .clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func changeDay(by delta: Int) {
        guard let newDate = Calendar.current.date(byAdding: .day, value: delta, to: selectedDate) else { return }
        selectedDate = newDate
    }

    /// A floating card in the bottom-right corner (rather than a toolbar item) for logging
    /// food — a more prominent, thumb-reachable "add" affordance.
    private var logFoodButton: some View {
        Button {
            isPresentingLogSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor, in: Circle())
                .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
        }
        .accessibilityLabel("Log Food")
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }

    /// The calorie ring plus the macro breakdown and the rest of the screen, all one plain
    /// `List` now, so the ring scrolls away with everything else instead of sitting pinned
    /// above it. The ring's own section has no header and is stripped of the List's row
    /// insets/background so it still reads as sitting on the plain screen background, not
    /// boxed into a card, matching how it looked before it moved in here.
    private func macroList(profile: UserProfile?) -> some View {
        List {
            if let profile {
                Section {
                    calorieHeader(profile: profile)
                        .padding(.bottom, 4)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                let totals = viewModel.dailyTotals(for: entriesForSelectedDate)
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
                    Text("Logged Today")
                    Spacer()
                    Button {
                        isPresentingMealInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("About Logged Today")
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
        }
        .contentMargins(.top, Self.weekStripDotSpacing, for: .scrollContent)
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
                        NavigationLink {
                            FoodHistoryView(date: selectedDate)
                        } label: {
                            mealCard(meal)
                        }
                        .buttonStyle(.plain)
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
        let entries = entriesForSelectedDate.filter { $0.mealType == meal }
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Self.mealCardHeight)
        .contentShape(Rectangle())
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

    /// The calorie gauge. Lives in its own header-less `List` section (see `macroList`) with
    /// row insets/background stripped out, so it still reads as sitting plainly on the screen
    /// rather than boxed into a card like the sections below it — it just scrolls now too.
    private func calorieHeader(profile: UserProfile) -> some View {
        let totals = viewModel.dailyTotals(for: entriesForSelectedDate)
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
