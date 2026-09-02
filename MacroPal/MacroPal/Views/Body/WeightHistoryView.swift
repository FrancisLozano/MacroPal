//
//  WeightHistoryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

struct WeightHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.date, order: .reverse) private var entries: [WeightEntry]
    @Query private var profiles: [UserProfile]

    @State private var isPresentingLogSheet = false
    @State private var isPresentingGoalWeightSheet = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Weight Logged",
                    systemImage: "figure.stand",
                    description: Text("Log your weight to start tracking your trend.")
                )
            } else {
                List {
                    if let profile {
                        Section {
                            Button {
                                isPresentingGoalWeightSheet = true
                            } label: {
                                HStack {
                                    Text("Goal Weight")
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    Text(profile.goalWeightKg, format: .number.precision(.fractionLength(1)))
                                    Text("kg")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(entry.weightKg, format: .number.precision(.fractionLength(1)))
                                    .font(.headline)
                                Text("kg")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(entry.date, format: .dateTime.month().day().year())
                                    .foregroundStyle(.secondary)
                            }
                            if let notes = entry.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteEntries)
                }
            }
        }
        .navigationTitle("Body")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingLogSheet = true
                } label: {
                    Label("Log Weight", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingLogSheet) {
            NavigationStack {
                LogWeightEntryView()
            }
        }
        .sheet(isPresented: $isPresentingGoalWeightSheet) {
            if let profile {
                NavigationStack {
                    GoalWeightEditView(profile: profile)
                }
            }
        }
        .task {
            _ = UserProfile.current(in: modelContext)
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
    }
}

#Preview {
    NavigationStack {
        WeightHistoryView()
    }
    .modelContainer(for: [WeightEntry.self, UserProfile.self], inMemory: true)
}
