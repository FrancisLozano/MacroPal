//
//  CurrentPlanCard.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Current-plan section of the Training page: "Gym Workout", days a week and today's workout.
/// Tapping the card expands it in place to list the whole week, like the Macros card's pie
/// toggle; tapping a workout opens its exercises. The ellipsis reorders the workouts by drag
/// right here in the card (saved or cancelled from the card) or opens the routine editor.
struct CurrentPlanCard: View {
    @Query private var plans: [WorkoutPlan]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb

    @AppStorage("trainingShowWeek") private var showWeek = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isPresentingRoutineEditor = false
    @State private var isPresentingUnplannedWorkout = false
    /// The workouts in their new order while reordering; `nil` when not reordering.
    @State private var reorderDraft: [PlanDay]?

    private var plan: WorkoutPlan? { plans.first }

    private var today: PlanDay? {
        plan?.day(on: Calendar.current.component(.weekday, from: .now))
    }

    var body: some View {
        TrainingSection("Current Plan") {
            if let plan, reorderDraft == nil {
                Menu {
                    Button("Reorder Workouts", systemImage: "arrow.up.arrow.down") {
                        withAnimation { reorderDraft = plan.sortedDays }
                    }
                    Button("Edit Routine", systemImage: "slider.horizontal.3") {
                        isPresentingRoutineEditor = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .headingButtonTarget()
                }
                .accessibilityLabel("Plan options")
            }
        } content: {
            Group {
                if let plan {
                    if let reorderDraft {
                        reorderContent(plan: plan, draft: reorderDraft)
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            Button {
                                withAnimation { showWeek.toggle() }
                            } label: {
                                summary(plan: plan)
                            }
                            .buttonStyle(.plain)
                            .accessibilityValue(showWeek ? "Week shown" : "Week hidden")
                            .accessibilityHint(showWeek ? "Hides the week" : "Shows the week")
                            // The expanded week marks today and its progress, so the today line
                            // would repeat it.
                            if showWeek {
                                week(plan: plan)
                            } else {
                                todayRow
                            }
                        }
                    }
                } else {
                    Button {
                        isPresentingRoutineEditor = true
                    } label: {
                        Label("Create your plan", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .sheet(isPresented: $isPresentingRoutineEditor) {
            NavigationStack {
                RoutineEditorView(plan: plan)
            }
            // Taller than .medium so a 6-day week fits under the message field.
            .presentationDetents([.fraction(0.62), .large])
        }
        .sheet(isPresented: $isPresentingUnplannedWorkout) {
            UnplannedWorkoutView()
        }
    }

    private func summary(plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Gym Workout")
                .font(.title3.bold())
            Text(daysPerWeek(plan.days.count))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    /// Today's workout, the card's main action: "Today: Push" over how far it has got ("5
    /// exercises", "2 of 5 exercises done", "Done · 15 sets"), opening the day. On a rest day
    /// it opens an unplanned workout instead. No chevron, like the rest of the card.
    @ViewBuilder
    private var todayRow: some View {
        separator
            .padding(.vertical, 14)
        if let today {
            let progress = todaysProgress(today)
            NavigationLink {
                PlanDayDetailView(day: today)
            } label: {
                todayLabel(title: "Today: \(today.name)", status: status(of: progress), isDone: progress.isComplete)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                isPresentingUnplannedWorkout = true
            } label: {
                todayLabel(title: "Today: Rest day", status: "Log an unplanned workout", isDone: false)
            }
            .buttonStyle(.plain)
        }
    }

    private func todayLabel(title: String, status: String, isDone: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            // As large as the card's heading: today's workout is what the page is opened for.
            Text(title)
                .font(.title3.weight(.semibold))
            HStack(spacing: 4) {
                if isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                Text(status)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var todaysSession: WorkoutSession? {
        sessions.first { Calendar.current.isDateInToday($0.date) }
    }

    private func todaysProgress(_ day: PlanDay) -> DayProgress {
        DayProgress(day: day, session: todaysSession, bodyweightKg: weightEntries.first?.weightKg)
    }

    /// "5 exercises" → "2 of 5 exercises done" → "Done · 15 sets · 4,860 lb" (volume counted
    /// like Workout Complete).
    private func status(of progress: DayProgress) -> String {
        if progress.exercises == 0 { return "No exercises yet" }
        if progress.isComplete {
            let sets = progress.setsLogged == 1 ? "1 set" : "\(progress.setsLogged) sets"
            let volume = unit.fromKg(progress.volumeKg).formatted(.number.precision(.fractionLength(0)))
            return "Done · \(sets) · \(volume) \(unit.symbol)"
        }
        if progress.setsLogged > 0 {
            return "\(progress.exercisesDone) of \(progress.exercises) exercises done"
        }
        return progress.exercises == 1 ? "1 exercise" : "\(progress.exercises) exercises"
    }

    /// Every workout of the week under the summary, one line each ("Monday: Push"), today's in
    /// semibold. Days so far this week end with how they went ("✓ Done", "1 of 2 done"), and
    /// today's with where it stands ("Today · 2 exercises"); tapping one opens its exercises.
    private func week(plan: WorkoutPlan) -> some View {
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: .now)
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(plan.sortedDays) { day in
                let progress = Self.dateThisWeek(weekday: day.weekday).map { date in
                    DayProgress(
                        day: day,
                        session: sessions.first { calendar.isDate($0.date, inSameDayAs: date) },
                        bodyweightKg: weightEntries.first?.weightKg
                    )
                }
                separator
                    .padding(.vertical, 14)
                dayLink(
                    day,
                    title: "\(calendar.weekdaySymbols[day.weekday - 1]): \(day.name)",
                    progress: progress,
                    isToday: day.weekday == todayWeekday
                )
            }
        }
    }

    /// A line of the week; `progress` is how the day went, for days up to today.
    private func dayLink(_ day: PlanDay, title: String, progress: DayProgress?, isToday: Bool) -> some View {
        NavigationLink {
            PlanDayDetailView(day: day)
        } label: {
            // At accessibility sizes the status goes under the day, not squeezed beside it.
            let stacked = dynamicTypeSize.isAccessibilitySize
            let layout = stacked
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
                : AnyLayout(HStackLayout(spacing: 4))
            layout {
                Text(title)
                    .fontWeight(isToday ? .semibold : .regular)
                if !stacked { Spacer() }
                if let progress, progress.isComplete {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Done")
                            .foregroundStyle(.secondary)
                    }
                } else if let status = weekStatus(of: progress, isToday: isToday) {
                    Text(status)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.subheadline)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.plain)
    }

    /// The end of a week line short of done: "1 of 2 done" for a day started, today's with
    /// "Today · " in front ("Today · 2 exercises" before its first set); nothing for a day missed
    /// or still to come.
    private func weekStatus(of progress: DayProgress?, isToday: Bool) -> String? {
        guard let progress else { return nil }
        if progress.setsLogged > 0 {
            let done = "\(progress.exercisesDone) of \(progress.exercises) done"
            return isToday ? "Today · \(done)" : done
        }
        return isToday ? "Today · \(status(of: progress))" : nil
    }

    /// The date `weekday` (1 = Sunday) falls on in the week holding `now`, or `nil` when that's
    /// still to come, so the week only reports on days that have happened.
    static func dateThisWeek(weekday: Int, now: Date = .now, calendar: Calendar = .current) -> Date? {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return nil }
        let offset = (weekday - calendar.component(.weekday, from: week.start) + 7) % 7
        guard let date = calendar.date(byAdding: .day, value: offset, to: week.start),
              calendar.startOfDay(for: date) <= calendar.startOfDay(for: now) else { return nil }
        return date
    }

    /// A 1-pt line rather than `Divider()`: the system hairline blurs away at some row
    /// positions, so a few of the week's lines went missing.
    private var separator: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(height: 1)
    }

    private func weekdayLabel(_ weekday: Int) -> some View {
        let isToday = weekday == Calendar.current.component(.weekday, from: .now)
        return Text(Calendar.current.shortWeekdaySymbols[weekday - 1])
            .font(.subheadline.bold())
            .foregroundStyle(isToday ? Color.primary : Color.secondary)
            .frame(width: 36, alignment: .leading)
    }

    private func daysPerWeek(_ count: Int) -> String {
        count == 1 ? "1 Day a Week" : "\(count) Days a Week"
    }

    /// The workouts with drag handles. Drags only change the draft, so Cancel leaves the plan
    /// untouched; the weekdays stay put and the workouts swap between them on Save.
    ///
    /// A `List` just for this mode, since it gives the native drag handles; it holds no buttons
    /// (Cancel and Save sit below it), so the List button-detachment bug can't reach them.
    private func reorderContent(plan: WorkoutPlan, draft: [PlanDay]) -> some View {
        let weekdays = plan.sortedDays.map(\.weekday)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Reorder Workouts")
                .font(.title3.bold())
            List {
                ForEach(Array(draft.enumerated()), id: \.element.persistentModelID) { index, day in
                    HStack(spacing: 12) {
                        weekdayLabel(weekdays[index])
                        Text(day.name)
                    }
                    .frame(height: Self.reorderRowHeight)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                .onMove { source, destination in
                    reorderDraft?.move(fromOffsets: source, toOffset: destination)
                }
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, Self.reorderRowHeight)
            .contentMargins(.vertical, 0, for: .scrollContent)
            .scrollDisabled(true)
            .environment(\.editMode, .constant(.active))
            .frame(height: Self.reorderRowHeight * CGFloat(draft.count))
            HStack {
                Button("Cancel") {
                    withAnimation { reorderDraft = nil }
                }
                .buttonStyle(.bordered)
                Spacer()
                Button("Save") {
                    plan.reorderDays(draft)
                    withAnimation { reorderDraft = nil }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private static let reorderRowHeight: CGFloat = 44
}

#Preview {
    NavigationStack {
        CurrentPlanCard()
    }
    .modelContainer(
        for: [WorkoutPlan.self, PlanDay.self, PlanExercise.self, Exercise.self],
        inMemory: true
    )
}
