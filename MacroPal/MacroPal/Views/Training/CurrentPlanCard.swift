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

    @AppStorage("trainingShowWeek") private var showWeek = false
    @State private var isPresentingRoutineEditor = false
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
                            .accessibilityHint(showWeek ? "Hides the week" : "Shows the week")
                            if showWeek {
                                week(plan: plan)
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
            .presentationDetents([.medium, .large])
        }
    }

    private func summary(plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Gym Workout")
                    .font(.title3.bold())
                Text(daysPerWeek(plan.days.count))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            // The expanded week already marks today, so the line would repeat it.
            if !showWeek {
                separator
                Text(today.map { "Today: \($0.name)" } ?? "Today: Rest day")
                    .font(.subheadline.bold())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    /// Every workout of the week under the summary, one line each ("Monday: Push", today in
    /// bold); tapping one opens its exercises.
    private func week(plan: WorkoutPlan) -> some View {
        let todayWeekday = Calendar.current.component(.weekday, from: .now)
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(plan.sortedDays) { day in
                separator
                    .padding(.vertical, 14)
                NavigationLink {
                    PlanDayDetailView(day: day)
                } label: {
                    Text("\(Calendar.current.weekdaySymbols[day.weekday - 1]): \(day.name)")
                        .font(.subheadline)
                        .fontWeight(day.weekday == todayWeekday ? .bold : .regular)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
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
