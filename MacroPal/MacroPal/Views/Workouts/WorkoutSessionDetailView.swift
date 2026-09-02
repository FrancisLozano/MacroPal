//
//  WorkoutSessionDetailView.swift
//  MacroPal
//

import SwiftUI

struct WorkoutSessionDetailView: View {
    let session: WorkoutSession

    private var sortedSets: [WorkoutSetEntry] {
        session.setEntries.sorted { $0.setNumber < $1.setNumber }
    }

    var body: some View {
        List {
            if let notes = session.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }
            Section("Sets") {
                ForEach(sortedSets, id: \.persistentModelID) { set in
                    HStack {
                        Text("\(set.setNumber).")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading) {
                            Text(set.exercise?.name ?? "Unknown Exercise")
                            Text(setSummary(set))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(session.date.formatted(date: .abbreviated, time: .omitted))
    }

    private func setSummary(_ set: WorkoutSetEntry) -> String {
        var parts = ["\(set.weightKg.formatted()) kg × \(set.reps)"]
        if let rpe = set.rpe {
            parts.append("RPE \(rpe.formatted())")
        }
        return parts.joined(separator: " · ")
    }
}
