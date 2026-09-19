//
//  GoalsCard.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Goals section of the Training page. Each row shows the current value against its goal,
/// tapping the value edits the goal, and the chart icon opens that goal's progress graph.
struct GoalsCard: View {
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @Query private var profiles: [UserProfile]

    @State private var isPresentingGoalWeightSheet = false
    @State private var isPresentingLogWeightSheet = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goals")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Goal weight")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button {
                        isPresentingGoalWeightSheet = true
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(weightText)
                                .font(.title3.bold())
                            Text("→")
                                .foregroundStyle(.secondary)
                            Text(goalText)
                                .font(.title3.bold())
                            Text("kg")
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
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
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
    }

    private var weightText: String {
        guard let latest = weightEntries.first else { return "—" }
        return latest.weightKg.formatted(.number.precision(.fractionLength(1)))
    }

    private var goalText: String {
        guard let profile else { return "—" }
        return profile.goalWeightKg.formatted(.number.precision(.fractionLength(1)))
    }
}

#Preview {
    NavigationStack {
        GoalsCard()
    }
    .modelContainer(for: [WeightEntry.self, UserProfile.self], inMemory: true)
}
