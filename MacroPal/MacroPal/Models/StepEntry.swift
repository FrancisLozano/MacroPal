//
//  StepEntry.swift
//  MacroPal
//

import Foundation
import SwiftData

/// One day's step total. Unlike weigh-ins, steps are a running daily count, so there is at
/// most one entry per day and logging again replaces it (see `StepsViewModel.log`).
@Model
final class StepEntry {
    /// Start of the day this total is for.
    var day: Date
    var steps: Int

    init(day: Date, steps: Int) {
        self.day = day
        self.steps = steps
    }
}
