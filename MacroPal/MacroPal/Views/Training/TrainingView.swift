//
//  TrainingView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// One surface for training: progress body map, current plan, goals, and shortcuts to past
/// sessions. Replaces the separate Body and Workouts tabs.
struct TrainingView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isPresentingLogWorkoutSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BodyMapCard()
                CurrentPlanCard()
                GoalsCard()
                moreCard
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Training")
        .sheet(isPresented: $isPresentingLogWorkoutSheet) {
            UnplannedWorkoutView()
        }
        .task {
            _ = UserProfile.current(in: modelContext)
        }
    }

    private var moreCard: some View {
        TrainingSection(nil) {
            VStack(spacing: 0) {
                NavigationLink {
                    WorkoutHistoryView()
                } label: {
                    moreRow("Workout History", systemImage: "clock.arrow.circlepath")
                }
                Divider().padding(.leading, 44)
                NavigationLink {
                    ExerciseProgressView()
                } label: {
                    moreRow("Exercise Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                Divider().padding(.leading, 44)
                Button {
                    isPresentingLogWorkoutSheet = true
                } label: {
                    moreRow("Log an Unplanned Workout", systemImage: "plus.circle", showsChevron: false)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func moreRow(_ title: String, systemImage: String, showsChevron: Bool = true) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)
            Text(title)
            Spacer()
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .contentShape(Rectangle())
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
