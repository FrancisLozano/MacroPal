//
//  WeightEntry.swift
//  MacroPal
//

import Foundation
import SwiftData

@Model
final class WeightEntry {
    var date: Date
    var weightKg: Double
    var notes: String?

    init(date: Date, weightKg: Double, notes: String? = nil) {
        self.date = date
        self.weightKg = weightKg
        self.notes = notes
    }
}
