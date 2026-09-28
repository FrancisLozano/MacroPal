//
//  QuickAddSheet.swift
//  MacroPal
//

import SwiftUI

/// What the + beside the tab bar can open.
enum QuickAddChoice {
    case logFood
    case logWorkout(PlanDay)
    case logUnplannedWorkout
}

/// The short sheet the + beside the tab bar opens: log food (today's Daily Log) or log today's
/// planned workout. Both rows look the same whatever the day; on a rest day the workout row
/// opens an unplanned workout, and with no plan yet it explains itself in an alert.
struct QuickAddSheet: View {
    /// Today's planned workout, or `nil` on a rest day or without a plan.
    let workout: PlanDay?
    let hasPlan: Bool
    let onChoose: (QuickAddChoice) -> Void

    @State private var isShowingNoWorkout = false

    var body: some View {
        List {
            Button {
                onChoose(.logFood)
            } label: {
                row(title: "Log Food", detail: "Today's Daily Log", systemImage: "fork.knife")
            }

            Button {
                if let workout {
                    onChoose(.logWorkout(workout))
                } else if hasPlan {
                    onChoose(.logUnplannedWorkout)
                } else {
                    isShowingNoWorkout = true
                }
            } label: {
                row(title: "Log Workout", detail: workoutDetail, systemImage: "dumbbell.fill")
            }
        }
        // Plain black rows, like a menu, rather than the List's blue button tint.
        .tint(.primary)
        .alert("No Training Plan", isPresented: $isShowingNoWorkout) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Create a plan on the Training tab to log a workout from here.")
        }
        .listStyle(.insetGrouped)
        .scrollDisabled(true)
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
    }

    private var workoutDetail: String {
        if let workout { return workout.name }
        return hasPlan ? "Rest day · log an unplanned workout" : "No training plan yet"
    }

    private func row(title: String, detail: String, systemImage: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
        }
        .padding(.vertical, 4)
    }
}
