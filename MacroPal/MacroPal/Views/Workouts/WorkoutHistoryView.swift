//
//  WorkoutHistoryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @State private var isPresentingLogSheet = false

    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No Workouts Logged",
                    systemImage: "dumbbell",
                    description: Text("Log a session to start tracking your training.")
                )
            } else {
                List {
                    ForEach(sessions) { session in
                        NavigationLink {
                            WorkoutSessionDetailView(session: session)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.headline)
                                Text(session.setEntries.count == 1 ? "1 set" : "\(session.setEntries.count) sets")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let notes = session.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteSessions)
                }
            }
        }
        .navigationTitle("Workouts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingLogSheet = true
                } label: {
                    Label("Log Workout", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingLogSheet) {
            NavigationStack {
                LogWorkoutSessionView()
            }
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutHistoryView()
    }
    .modelContainer(for: [WorkoutSession.self, WorkoutSetEntry.self, Exercise.self], inMemory: true)
}
