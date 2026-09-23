//
//  WorkoutHistoryView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Past sessions, newest first: the plan day (or the date, for unplanned and older sessions),
/// the set count and the exercises done.
struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

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
                                Text(session.planDayName ?? dateText(session))
                                    .font(.headline)
                                Text(subtitle(session))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if !session.exerciseNames.isEmpty {
                                    Text(session.exerciseNames.joined(separator: ", "))
                                        .font(.subheadline)
                                        .lineLimit(2)
                                }
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
        .navigationTitle("Workout History")
    }

    private func dateText(_ session: WorkoutSession) -> String {
        session.date.formatted(date: .abbreviated, time: .omitted)
    }

    /// "Sep 22, 2026 · 7 sets" under a plan day's name; just the set count when the date is
    /// already the headline.
    private func subtitle(_ session: WorkoutSession) -> String {
        let count = session.setEntries.count
        let sets = count == 1 ? "1 set" : "\(count) sets"
        return session.planDayName == nil ? sets : "\(dateText(session)) · \(sets)"
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
