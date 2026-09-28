//
//  TrainingView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// One surface for training: progress body map, current plan, goals, and logging an unplanned
/// workout. Each exercise's history lives in its Progress tab. Replaces the separate Body and
/// Workouts tabs.
struct TrainingView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isPresentingLogWorkoutSheet = false

    var body: some View {
        // Title laid out like Nutrition's (see `DailySummaryView.header`): an empty inline
        // navigation title and our own large title pinned above the cards, so it sits at the
        // same height on both tabs and no small "Training" appears in the bar on scroll. It's a
        // safe-area bar rather than a stack sibling, so cards scroll under it with the system's
        // soft edge instead of being cut off in a hard line below the title.
        ScrollView {
            VStack(spacing: 20) {
                BodyMapCard()
                CurrentPlanCard()
                GoalsCard()
                unplannedWorkoutCard
            }
            .padding(.vertical)
        }
        .scrollIndicators(.hidden)
        .safeAreaBar(edge: .top) {
            Text("Training")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingLogWorkoutSheet) {
            UnplannedWorkoutView()
        }
        .task {
            _ = UserProfile.current(in: modelContext)
        }
    }

    private var unplannedWorkoutCard: some View {
        TrainingSection(nil) {
            Button {
                isPresentingLogWorkoutSheet = true
            } label: {
                // Baseline-aligned, so the + stays by the first line when the text wraps.
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    PlusCircle()
                    Text("Log an Unplanned Workout")
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
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
