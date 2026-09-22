//
//  LogStepsView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Enter a day's step total. Picking a day that already has one shows it, and saving
/// replaces it — steps are a daily count, not separate readings.
struct LogStepsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var entries: [StepEntry]

    @State private var date: Date = .now
    @State private var stepsText: String = ""
    @FocusState private var isStepsFocused: Bool

    private let viewModel = StepsViewModel()

    private var steps: Int? {
        Int(stepsText)
    }

    private var isValid: Bool {
        guard let steps else { return false }
        return steps >= 0 && steps < 200_000
    }

    var body: some View {
        Form {
            Section("Steps") {
                TextField("Steps", text: $stepsText)
                    .keyboardType(.numberPad)
                    .focused($isStepsFocused)
                DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
            }
        }
        .navigationTitle("Log Steps")
        .navigationBarTitleDisplayMode(.inline)
        .presentationDetents([.height(260)])
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!isValid)
            }
        }
        .onAppear {
            showExistingTotal()
            isStepsFocused = true
        }
        .onChange(of: date) { showExistingTotal() }
    }

    private func showExistingTotal() {
        let existing = viewModel.steps(on: date, in: entries)
        stepsText = existing > 0 ? String(existing) : ""
    }

    private func save() {
        guard let steps else { return }
        viewModel.log(steps: steps, on: date, in: modelContext)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        LogStepsView()
    }
    .modelContainer(for: StepEntry.self, inMemory: true)
}
