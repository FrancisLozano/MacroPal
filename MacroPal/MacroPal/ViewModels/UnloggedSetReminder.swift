//
//  UnloggedSetReminder.swift
//  MacroPal
//

import Foundation
import UserNotifications

/// A nudge when a workout stalls: a set logs, then nothing for five minutes while that exercise
/// still has sets left (usability.md, 2026-10-16: "did set 1 but never did set 2"). One pending
/// notification for the whole app, replaced by every set logged anywhere and removed once the
/// exercise is done, so it only fires for the most recent exercise. Shown as a banner in the
/// app too (`RestNotificationDelegate` hides only the rest one).
@MainActor
enum UnloggedSetReminder {
    static let identifier = "unlogged-set"
    /// Long enough to cover a normal rest (up to the 5 min choice) plus the set itself.
    static let delay: TimeInterval = 5 * 60
    /// Bumped by every schedule and cancel, so a schedule still waiting on the settings check
    /// can't land after a later cancel.
    private static var generation = 0

    /// "Set 2 isn't logged yet" / "Single-Arm Triceps Extension: log it when you're done, or
    /// tap Complete Exercise." Neutral wording, like the other reminders.
    static func content(exerciseName: String, setNumber: Int) -> (title: String, body: String) {
        ("Set \(setNumber) isn't logged yet",
         "\(exerciseName): log it when you're done, or tap Complete Exercise.")
    }

    /// Replaces any pending reminder with one for `setNumber` (1-based) of `exerciseName`,
    /// `delay` from now. Permission was already asked for by the rest timer; without it this
    /// does nothing.
    static func schedule(exerciseName: String, setNumber: Int) {
        let center = UNUserNotificationCenter.current()
        generation += 1
        let mine = generation
        Task {
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized, generation == mine else { return }
            let text = content(exerciseName: exerciseName, setNumber: setNumber)
            let content = UNMutableNotificationContent()
            content.title = text.title
            content.body = text.body
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }
    }

    static func cancel() {
        generation += 1
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
