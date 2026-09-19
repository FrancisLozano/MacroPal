//
//  TrainingView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// One surface for training: goals, starting a workout, and past sessions. Replaces the
/// separate Body and Workouts tabs. Progress body map and the current-plan card slot in above
/// the goals as they're built.
///
/// The action buttons live in a plain `VStack` above the session `List` on purpose — buttons
/// nested in a `List` whose sections change shape can go dead (see the Daily Log chevrons).
struct TrainingView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isPresentingLogWorkoutSheet = false

    var body: some View {
        VStack(spacing: 12) {
            CurrentPlanCard()
            GoalsCard()
            actionRow
            WorkoutHistoryView()
        }
        .navigationTitle("Training")
        .sheet(isPresented: $isPresentingLogWorkoutSheet) {
            NavigationStack {
                LogWorkoutSessionView()
            }
        }
        .task {
            _ = UserProfile.current(in: modelContext)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                isPresentingLogWorkoutSheet = true
            } label: {
                Label("Start Workout", systemImage: "dumbbell")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            NavigationLink {
                ExerciseProgressView()
            } label: {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        TrainingView()
    }
    .modelContainer(
        for: [WeightEntry.self, UserProfile.self, WorkoutSession.self, WorkoutSetEntry.self, Exercise.self, WorkoutPlan.self, PlanDay.self, PlanExercise.self],
        inMemory: true
    )
}
