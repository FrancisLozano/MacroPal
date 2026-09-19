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
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb

    @State private var isPresentingGoalWeightSheet = false
    @State private var isPresentingLogWeightSheet = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Goals")
                    .font(.headline)
                Spacer()
                Picker("Weight unit", selection: $unit) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.symbol).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }

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

    private var goalText: String {
        guard let profile else { return "—" }
        return unit.formatted(fromKg: profile.goalWeightKg)
    }
}

#Preview {
    NavigationStack {
        GoalsCard()
    }
    .modelContainer(for: [WeightEntry.self, UserProfile.self], inMemory: true)
}
