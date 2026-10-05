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
    case logWeight
    case logSteps
}

/// The short sheet the + beside the tab bar opens: log food (today's Daily Log), today's
/// planned workout, a weigh-in or the day's steps. The rows look the same whatever the day; on
/// a rest day the workout row opens an unplanned workout, and with no plan yet it explains
/// itself in an alert.
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

            Button {
                onChoose(.logWeight)
            } label: {
                row(title: "Log Weight", detail: "Today's weigh-in", systemImage: "scalemass.fill")
            }

            Button {
                onChoose(.logSteps)
            } label: {
                row(title: "Log Steps", detail: "Today's total", systemImage: "figure.walk")
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
        .presentationDetents([.height(380)])
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
