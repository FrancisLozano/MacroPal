//
//  RestNotifications.swift
//  MacroPal
//

import Foundation
import UserNotifications

/// Schedules the "Rest over" notification. A protocol so `RestTimerModel` can be tested
/// without touching the real notification center.
@MainActor
protocol RestNotificationScheduling {
    /// Replaces any pending rest notification with one at `date`.
    func schedule(at date: Date)
    func cancel()
}

/// The real scheduler: one pending local notification, replaced whenever the rest changes.
/// Asks for permission the first time a rest starts — the moment it's obviously useful.
@MainActor
final class RestNotifications: RestNotificationScheduling {
    static let identifier = "rest-timer"

    private let center = UNUserNotificationCenter.current()
    /// The end time most recently asked for. Scheduling waits on the permission prompt, so
    /// quick −15s / +15s taps could otherwise land out of order.
    private var latestDate: Date?

    func schedule(at date: Date) {
        latestDate = date
        Task {
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true,
                  latestDate == date else { return }
            let interval = date.timeIntervalSinceNow
            guard interval > 0 else { return }

            let content = UNMutableNotificationContent()
            content.title = "Rest over"
            content.body = "Time for your next set."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            // The same identifier replaces the earlier request instead of adding a second one.
            try? await center.add(UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger))
        }
    }

    func cancel() {
        latestDate = nil
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
    }
}

/// Keeps the system banner out of the way while the app is open: the in-app "Rest over" card
/// announces the end there instead. Set as the notification center's delegate at launch.
final class RestNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        notification.request.identifier == RestNotifications.identifier ? [] : [.banner, .sound]
    }
}
