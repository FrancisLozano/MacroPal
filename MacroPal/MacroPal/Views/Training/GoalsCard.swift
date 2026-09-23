//
//  GoalsCard.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Goals section of the Training page. Each row shows the current value against its goal,
/// tapping the value edits the goal, and the chart icon opens that goal's progress graph.
struct GoalsCard: View {
    @Query private var profiles: [UserProfile]
    @Query private var stepEntries: [StepEntry]
    @Query private var weightEntries: [WeightEntry]
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb

    @State private var isPresentingGoalWeightSheet = false
    @State private var isPresentingLogWeightSheet = false
    @State private var isPresentingStepGoalSheet = false
    @State private var isPresentingLogStepsSheet = false

    private let stepsViewModel = StepsViewModel()

    private var profile: UserProfile? { profiles.first }

    /// A plateau while cutting, or the goal weight reached — shown under the weight row.
    private var weightFindings: [InsightFinding] {
        guard let profile else { return [] }
        let snapshot = AnalysisSnapshot(
            profile: profile, weightEntries: weightEntries, foodEntries: [], workoutSessions: [], weightUnit: unit
        )
        return GoalWeightReachedRule.evaluate(snapshot) + WeightPlateauRule.evaluate(snapshot)
    }

    var body: some View {
        // lb/kg lives in Profile → Units & Measurements.
        TrainingSection("Goals") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Goal weight")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button {
                            isPresentingGoalWeightSheet = true
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(goalText)
                                    .font(.title3.bold())
                                Text(unit.symbol)
                                    .foregroundStyle(.secondary)
                            }
                            .foregroundStyle(Color.primary)
                        }
                    }
                    Spacer()
                    Button {
                        isPresentingLogWeightSheet = true
                    } label: {
                        Label("Log", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                    NavigationLink {
                        WeightHistoryView()
                    } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .padding(8)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Weight progress")
                }

                ForEach(weightFindings) { finding in
                    InsightCallout(finding: finding)
                }

                Divider()

                stepsRow
            }
            .padding()
        }
        .sheet(isPresented: $isPresentingGoalWeightSheet) {
            if let profile {
                NavigationStack {
                    GoalWeightEditView(profile: profile)
                }
            }
        }
        .sheet(isPresented: $isPresentingLogWeightSheet) {
            NavigationStack {
                LogWeightEntryView()
            }
        }
        .sheet(isPresented: $isPresentingStepGoalSheet) {
            if let profile {
                NavigationStack {
                    StepGoalEditView(profile: profile)
                }
            }
        }
        .sheet(isPresented: $isPresentingLogStepsSheet) {
            NavigationStack {
                LogStepsView()
            }
        }
    }

    /// Today's steps against the goal; tapping the numbers edits the goal.
    private var stepsRow: some View {
        let today = stepsViewModel.steps(on: .now, in: stepEntries)
        let goal = profile?.stepGoal ?? 10_000
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Steps today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    isPresentingStepGoalSheet = true
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(today, format: .number)
                            .font(.title3.bold())
                        Text("/ \(goal.formatted())")
                            .foregroundStyle(.secondary)
                        if today >= goal {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .foregroundStyle(Color.primary)
                }
                .accessibilityLabel("\(today) of \(goal) steps today. Edit steps goal")
            }
            Spacer()
            Button {
                isPresentingLogStepsSheet = true
            } label: {
                Label("Log", systemImage: "plus")
            }
            .buttonStyle(.bordered)
            NavigationLink {
                StepsHistoryView()
            } label: {
                Image(systemName: "chart.bar.fill")
                    .padding(8)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Steps progress")
        }
    }

    private var goalText: String {
        guard let profile else { return "—" }
        return unit.formatted(fromKg: profile.goalWeightKg)
    }
}

#Preview {
    NavigationStack {
        GoalsCard()
    }
    .modelContainer(for: [WeightEntry.self, StepEntry.self, UserProfile.self], inMemory: true)
}
