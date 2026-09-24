//
//  GoalsCard.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Goals section of the Training page. Each row shows the current value against its goal;
/// tapping the value opens that goal's history (where the goal itself is edited), and the +
/// logs a new value.
struct GoalsCard: View {
    @Query private var profiles: [UserProfile]
    @Query private var stepEntries: [StepEntry]
    @Query private var weightEntries: [WeightEntry]
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb

    @State private var isPresentingLogWeightSheet = false
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
                        NavigationLink {
                            WeightHistoryView()
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(goalText)
                                    .font(.title3.bold())
                                Text(unit.symbol)
                                    .foregroundStyle(.secondary)
                            }
                            .foregroundStyle(Color.primary)
                        }
                        .accessibilityLabel("Goal weight \(goalText) \(unit.symbol). Weight history")
                    }
                    Spacer()
                    logButton("Log weight") { isPresentingLogWeightSheet = true }
                }

                ForEach(weightFindings) { finding in
                    InsightCallout(finding: finding)
                }

                Divider()

                stepsRow
            }
            .padding()
        }
        .sheet(isPresented: $isPresentingLogWeightSheet) {
            NavigationStack {
                LogWeightEntryView()
            }
        }
        .sheet(isPresented: $isPresentingLogStepsSheet) {
            NavigationStack {
                LogStepsView()
            }
        }
    }

    /// Today's steps against the goal; tapping the numbers opens the steps history.
    private var stepsRow: some View {
        let today = stepsViewModel.steps(on: .now, in: stepEntries)
        let goal = profile?.stepGoal ?? 10_000
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Steps today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                NavigationLink {
                    StepsHistoryView()
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
                .accessibilityLabel("\(today) of \(goal) steps today. Steps history")
            }
            Spacer()
            logButton("Log steps") { isPresentingLogStepsSheet = true }
        }
    }

    private func logButton(_ accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "plus")
                .fontWeight(.semibold)
                .padding(4)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .accessibilityLabel(accessibilityLabel)
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
