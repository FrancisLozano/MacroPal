//
//  WorkoutSession.swift
//  MacroPal
//

import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var date: Date
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSetEntry.session)
    var setEntries: [WorkoutSetEntry] = []

    init(date: Date, notes: String? = nil) {
        self.date = date
        self.notes = notes
    }

    /// Each exercise's name once, in the order it was first logged.
    var exerciseNames: [String] {
        distinct(setsInLoggedOrder.compactMap { $0.exercise?.name })
    }

    /// The plan days the session's sets were logged from — "Pull", or "Push + Pull" on a mixed
    /// day. Nil when every set is unplanned or predates recording it.
    var planDayName: String? {
        let names = distinct(setsInLoggedOrder.compactMap(\.planDayName))
        return names.isEmpty ? nil : names.joined(separator: " + ")
    }

    private var setsInLoggedOrder: [WorkoutSetEntry] {
        setEntries.sorted { $0.setNumber < $1.setNumber }
    }

    /// Each value once, first occurrence kept.
    private func distinct(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
}
