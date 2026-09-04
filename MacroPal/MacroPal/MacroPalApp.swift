//
//  MacroPalApp.swift
//  MacroPal
//
//  Created by Francis Luigi Lozano on 9/1/26.
//

import SwiftUI
import SwiftData

@main
struct MacroPalApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            FoodItem.self,
            FoodEntry.self,
            WeightEntry.self,
            Exercise.self,
            WorkoutSession.self,
            WorkoutSetEntry.self,
            Insight.self,
        ])
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
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
