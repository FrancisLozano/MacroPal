//
//  LogWeightEntryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

struct LogWeightEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = .now
    @State private var weightText: String = ""
    @State private var notes: String = ""

    private var weightKg: Double? {
        Double(weightText)
    }

    private var isValid: Bool {
        guard let weightKg else { return false }
        return weightKg > 0 && weightKg < 500
    }

    var body: some View {
        Form {
            Section("Weight") {
                HStack {
                    TextField("Weight", text: $weightText)
                        .keyboardType(.decimalPad)
                    Text("kg")
                        .foregroundStyle(.secondary)
                }
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            Section("Notes") {
                TextField("Optional", text: $notes, axis: .vertical)
            }
        }
        .navigationTitle("Log Weight")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!isValid)
            }
        }
    }

    private func save() {
        guard let weightKg else { return }
        let entry = WeightEntry(
            date: date,
            weightKg: weightKg,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        )
        modelContext.insert(entry)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        LogWeightEntryView()
    }
    .modelContainer(for: WeightEntry.self, inMemory: true)
}
