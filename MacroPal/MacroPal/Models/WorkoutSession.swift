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
}
