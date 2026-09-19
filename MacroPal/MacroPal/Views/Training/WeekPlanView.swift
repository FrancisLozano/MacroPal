//
//  WeekPlanView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// The expanded week: every training day, reorderable, with the routine editor behind the
/// ellipsis button.
struct WeekPlanView: View {
    let plan: WorkoutPlan

    @State private var editMode: EditMode = .inactive
    @State private var isPresentingRoutineEditor = false

    var body: some View {
        List {
            ForEach(plan.sortedDays) { day in
                NavigationLink {
                    PlanDayDetailView(day: day)
                } label: {
                    HStack {
                        Text(Calendar.current.shortWeekdaySymbols[day.weekday - 1])
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(day.name)
                            Text(day.focus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onMove { source, destination in
                plan.moveDays(from: source, to: destination)
            }
        }
        .environment(\.editMode, $editMode)
        .navigationTitle("This Week")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    withAnimation {
                        editMode = editMode.isEditing ? .inactive : .active
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .accessibilityLabel(editMode.isEditing ? "Done reordering" : "Reorder workouts")

                Button {
                    isPresentingRoutineEditor = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Edit routine")
            }
        }
        .sheet(isPresented: $isPresentingRoutineEditor) {
            NavigationStack {
                RoutineEditorView(plan: plan)
            }
        }
    }
}
