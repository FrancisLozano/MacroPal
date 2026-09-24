//
//  MacroPalApp.swift
//  MacroPal
//
//  Created by Francis Luigi Lozano on 9/1/26.
//

import SwiftUI
import SwiftData
import os
import UserNotifications

private let storeLog = Logger(subsystem: "com.francislozano.MacroPal", category: "Store")

@main
struct MacroPalApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = AppSchema.schema
        // Stored in the App Group container (not the app's private sandbox) so the
        // MacroPalWidgetExtension can read the same on-disk store to build its timeline.
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.francislozano.MacroPal") else {
            fatalError("Could not find App Group container for group.francislozano.MacroPal")
        }
        let storeURL = groupURL.appendingPathComponent("MacroPal.sqlite")
        let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // The widget extension opens this same store. After an update that changes the
            // schema, it can start migrating the store at the same moment as the app, and the
            // loser fails with "store version hashes didn't migrate" (seen 2026-09-22 when
            // `PlanExercise.targetRepsMax` was added). By the time it fails the other process
            // is nearly done, so wait briefly and try once more before giving up.
            storeLog.error("Opening the store failed, retrying: \(error, privacy: .public)")
            Thread.sleep(forTimeInterval: 0.5)
            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                storeLog.notice("Opening the store succeeded on retry")
                return container
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    /// Held here so it lives as long as the app; the notification center keeps only a weak
    /// reference to its delegate.
    private let notificationDelegate = RestNotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
