//
//  TrainingView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// One surface for a gym session: weigh in, start a workout, and browse past sessions
/// without leaving the tab. Replaces the separate Body and Workouts tabs.
///
/// The action buttons live in a plain `VStack` above the session `List` on purpose — buttons
/// nested in a `List` whose sections change shape can go dead (see the Daily Log chevrons).
struct TrainingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @Query private var profiles: [UserProfile]

    @State private var isPresentingLogWorkoutSheet = false
    @State private var isPresentingLogWeightSheet = false

    var body: some View {
        VStack(spacing: 12) {
            weightCard
            actionRow
            WorkoutHistoryView()
        }
        .navigationTitle("Training")
        .sheet(isPresented: $isPresentingLogWorkoutSheet) {
            NavigationStack {
                LogWorkoutSessionView()
            }
        }
        .sheet(isPresented: $isPresentingLogWeightSheet) {
            NavigationStack {
                LogWeightEntryView()
            }
        }
        .task {
            _ = UserProfile.current(in: modelContext)
        }
    }

    private var weightCard: some View {
        HStack {
            NavigationLink {
                WeightHistoryView()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let latest = weightEntries.first {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(latest.weightKg, format: .number.precision(.fractionLength(1)))
                                .font(.title2.bold())
                            Text("kg")
                                .foregroundStyle(.secondary)
                        }
                        if let goal = profiles.first?.goalWeightKg {
                            Text("Goal \(goal.formatted(.number.precision(.fractionLength(1)))) kg")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Not logged yet")
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(Color.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button {
                isPresentingLogWeightSheet = true
            } label: {
                Label("Log", systemImage: "plus")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
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
        for: [WeightEntry.self, UserProfile.self, WorkoutSession.self, WorkoutSetEntry.self, Exercise.self],
        inMemory: true
    )
}
