//
//  GoalWeightEditView.swift
//  MacroPal
//

import SwiftUI

struct GoalWeightEditView: View {
    @Bindable var profile: UserProfile
    @Environment(\.dismiss) private var dismiss

    @State private var goalWeightText: String

    private let viewModel = WeightViewModel()

    init(profile: UserProfile) {
        self.profile = profile
        _goalWeightText = State(initialValue: String(format: "%.1f", profile.goalWeightKg))
    }

    private var goalWeightKg: Double? {
        Double(goalWeightText)
    }

    private var isValid: Bool {
        guard let goalWeightKg else { return false }
        return goalWeightKg > 0 && goalWeightKg < 500
    }

    var body: some View {
        Form {
            Section("Goal Weight") {
                HStack {
                    TextField("Goal Weight", text: $goalWeightText)
                        .keyboardType(.decimalPad)
                    Text("kg")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Edit Goal")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    guard let goalWeightKg else { return }
                    viewModel.updateGoalWeight(goalWeightKg, on: profile)
                    dismiss()
                }
                .disabled(!isValid)
            }
        }
    }
}
