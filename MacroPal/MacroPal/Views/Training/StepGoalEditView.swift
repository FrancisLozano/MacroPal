//
//  StepGoalEditView.swift
//  MacroPal
//

import SwiftUI

struct StepGoalEditView: View {
    @Bindable var profile: UserProfile
    @Environment(\.dismiss) private var dismiss

    @State private var goalText: String

    private let viewModel = StepsViewModel()

    init(profile: UserProfile) {
        self.profile = profile
        _goalText = State(initialValue: String(profile.stepGoal))
    }

    private var goal: Int? {
        Int(goalText)
    }

    private var isValid: Bool {
        guard let goal else { return false }
        return goal > 0 && goal < 200_000
    }

    var body: some View {
        Form {
            Section("Daily Steps Goal") {
                TextField("Steps", text: $goalText)
                    .keyboardType(.numberPad)
            }
        }
        .navigationTitle("Edit Goal")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    guard let goal else { return }
                    viewModel.updateStepGoal(goal, on: profile)
                    dismiss()
                }
                .disabled(!isValid)
            }
        }
    }
}
