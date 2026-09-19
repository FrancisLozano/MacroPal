//
//  LogWeightEntryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

struct LogWeightEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb

    @State private var date: Date = .now
    @State private var weightText: String = ""

    private var weightKg: Double? {
        Double(weightText).map(unit.toKg)
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
                    Text(unit.symbol)
                        .foregroundStyle(.secondary)
                }
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
        }
        .navigationTitle("Log Weight")
        .navigationBarTitleDisplayMode(.inline)
        .presentationDetents([.height(260)])
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!isValid)
            }
        }
    }

    private func save() {
        guard let weightKg else { return }
        let entry = WeightEntry(date: date, weightKg: weightKg, notes: nil)
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
