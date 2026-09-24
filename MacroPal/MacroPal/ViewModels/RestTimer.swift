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
///
/// Every start or adjustment also schedules a local notification for the end time, so the rest
/// ending is announced by a banner when the app is in the background. With the app open, the
/// end sets `finishedAt` instead and the "Rest over" card slides up from the bottom.
@MainActor
@Observable
final class RestTimerModel {
    /// A rest that ended more than this long ago was missed in the background, where the
    /// banner already announced it, so it doesn't also get the in-app card.
    static let lateFinishTolerance: TimeInterval = 2

    private(set) var timer: RestTimer?
    /// When the last rest ended with the app open; the card shows while this is set.
    private(set) var finishedAt: Date?

    @ObservationIgnored private let notifications: RestNotificationScheduling
    @ObservationIgnored private var finishTask: Task<Void, Never>?

    /// `nil` uses the real notification center. (Not a default argument: those are evaluated
    /// off the main actor, and `RestNotifications` is main-actor.)
    init(notifications: RestNotificationScheduling? = nil) {
        self.notifications = notifications ?? RestNotifications()
    }

    func start(seconds: Int, now: Date = .now) {
        timer = RestTimer(seconds: seconds, now: now)
        finishedAt = nil
        scheduleEnd()
    }

    func adjust(by seconds: Int, now: Date = .now) {
        timer?.adjust(by: seconds, now: now)
        scheduleEnd()
    }

    /// Ends the rest early (Skip): no card, no notification.
    func stop() {
        timer = nil
        finishTask?.cancel()
        notifications.cancel()
    }

    func dismissFinished() {
        finishedAt = nil
    }

    /// Ends the rest if its time is up. Called by the countdown task; takes the clock so the
    /// on-time vs. missed-in-the-background rule can be tested.
    func finishIfDue(now: Date = .now) {
        guard let timer, timer.isFinished(at: now) else { return }
        self.timer = nil
        let lateBy = now.timeIntervalSince(timer.endsAt)
        finishedAt = lateBy <= Self.lateFinishTolerance ? now : nil
    }

    private func scheduleEnd() {
        guard let timer else { return }
        notifications.schedule(at: timer.endsAt)
        finishTask?.cancel()
        finishTask = Task { [weak self] in
            // A suspended app wakes here late, which `finishIfDue` spots.
            try? await Task.sleep(for: .seconds(timer.remaining(at: .now)))
            guard !Task.isCancelled else { return }
            self?.finishIfDue()
        }
    }
}
