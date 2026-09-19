//
//  WorkoutHistoryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Past-session list, embedded in `TrainingView` (which owns the navigation title and the
/// log/progress actions).
struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
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
