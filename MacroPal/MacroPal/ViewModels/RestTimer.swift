//
//  RestTimer.swift
//  MacroPal
//

import Foundation
import Observation

/// A rest countdown between sets. A value type with the clock passed in, so it's testable.
struct RestTimer: Equatable {
    let startedAt: Date
    private(set) var endsAt: Date

    init(seconds: Int, now: Date = .now) {
        startedAt = now
        endsAt = now.addingTimeInterval(TimeInterval(seconds))
    }

    func remaining(at now: Date) -> TimeInterval {
        max(0, endsAt.timeIntervalSince(now))
    }

    func isFinished(at now: Date) -> Bool {
        remaining(at: now) == 0
    }

    /// Adds (or with a negative value, takes off) time, never ending before `now`.
    mutating func adjust(by seconds: Int, now: Date = .now) {
        endsAt = max(now, endsAt.addingTimeInterval(TimeInterval(seconds)))
    }
}

/// The one rest timer for the app, shared through the environment so a countdown started on
/// one exercise keeps running while you go back to the day's list and on to the next.
@MainActor
@Observable
final class RestTimerModel {
    private(set) var timer: RestTimer?

    func start(seconds: Int) {
        timer = RestTimer(seconds: seconds)
    }

    func adjust(by seconds: Int) {
        timer?.adjust(by: seconds)
    }

    func stop() {
        timer = nil
    }
}
