//
//  MacroPalWidget.swift
//  MacroPalWidget
//

import WidgetKit
import SwiftUI
import SwiftData

private let appGroupID = "group.francislozano.MacroPal"

/// Builds a `ModelContainer` pointed at the same on-disk store the main app uses (see
/// `MacroPalApp.swift`), so the widget reads live data without needing its own copy.
private func makeSharedModelContainer() -> ModelContainer? {
    guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
        return nil
    }
    let storeURL = groupURL.appendingPathComponent("MacroPal.sqlite")
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
    let configuration = ModelConfiguration(schema: schema, url: storeURL)
    return try? ModelContainer(for: schema, configurations: [configuration])
}

struct MacroWidgetEntry: TimelineEntry {
    let date: Date
    let eaten: MacroTotals
    let target: MacroTotals
    /// False when no `UserProfile` exists yet (widget added before the app's ever been
    /// opened) — the widget only reads, it never creates one itself.
    let hasProfile: Bool
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MacroWidgetEntry {
        MacroWidgetEntry(
            eaten: MacroTotals(calories: 1200, proteinG: 80, carbG: 100, fatG: 40),
            target: MacroTotals(calories: 2000, proteinG: 150, carbG: 200, fatG: 65),
            hasProfile: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MacroWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MacroWidgetEntry>) -> Void) {
        let entry = currentEntry()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: entry.date)
        let nextMidnight = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? entry.date.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func currentEntry() -> MacroWidgetEntry {
        guard let container = makeSharedModelContainer() else {
            return MacroWidgetEntry(eaten: MacroTotals(), target: MacroTotals(), hasProfile: false)
        }
        let context = ModelContext(container)

        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else {
            return MacroWidgetEntry(eaten: MacroTotals(), target: MacroTotals(), hasProfile: false)
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        let descriptor = FetchDescriptor<FoodEntry>(predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay })
        let todaysEntries = (try? context.fetch(descriptor)) ?? []

        let viewModel = NutritionViewModel()
        let eaten = viewModel.dailyTotals(for: todaysEntries)
        let target = MacroTotals(
            calories: Double(profile.calorieTarget),
            proteinG: Double(profile.proteinTargetG),
            carbG: Double(profile.carbTargetG),
            fatG: Double(profile.fatTargetG)
        )
        return MacroWidgetEntry(eaten: eaten, target: target, hasProfile: true)
    }
}

extension MacroWidgetEntry {
    init(eaten: MacroTotals, target: MacroTotals, hasProfile: Bool) {
        self.init(date: .now, eaten: eaten, target: target, hasProfile: hasProfile)
    }
}

struct MacroPalWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    var body: some View {
        if !entry.hasProfile {
            emptyState
        } else if family == .systemMedium {
            mediumView
        } else {
            smallView
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "fork.knife")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Open MacroPal to set up your profile")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // Descriptive breakdown of what today's eaten calories came from — not tied to
    // targets, so it stays meaningful even if someone hasn't set targets that match how
    // they actually want to eat.
    private var totalMacroCalories: Double {
        entry.eaten.carbG * 4 + entry.eaten.fatG * 9 + entry.eaten.proteinG * 4
    }
    private var carbPercent: Double { totalMacroCalories > 0 ? (entry.eaten.carbG * 4) / totalMacroCalories : 0 }
    private var fatPercent: Double { totalMacroCalories > 0 ? (entry.eaten.fatG * 9) / totalMacroCalories : 0 }
    private var proteinPercent: Double { totalMacroCalories > 0 ? (entry.eaten.proteinG * 4) / totalMacroCalories : 0 }

    private var remainingCalories: Double { entry.target.calories - entry.eaten.calories }
    private var calorieFraction: Double {
        entry.target.calories > 0 ? min(1, max(0, entry.eaten.calories / entry.target.calories)) : 0
    }

    private var smallView: some View {
        calorieRing(diameter: 90)
            .padding()
    }

    private var mediumView: some View {
        HStack(spacing: 14) {
            calorieRing(diameter: 74)
            Spacer(minLength: 4)
            macroColumn(name: "Carbs", percent: carbPercent, grams: entry.eaten.carbG, color: .green)
            macroColumn(name: "Fat", percent: fatPercent, grams: entry.eaten.fatG, color: .purple)
            macroColumn(name: "Protein", percent: proteinPercent, grams: entry.eaten.proteinG, color: .orange)
        }
        .padding()
    }

    private func calorieRing(diameter: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
            Circle()
                .trim(from: 0, to: calorieFraction)
                .stroke(Color.teal, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(Int(remainingCalories))")
                    .font(.system(size: diameter * 0.3, weight: .bold))
                    .minimumScaleFactor(0.5)
                Text("cal")
                    .font(.system(size: diameter * 0.15))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: diameter, height: diameter)
    }

    private func macroColumn(name: String, percent: Double, grams: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(Int((percent * 100).rounded()))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(String(format: "%.1f g", grams))
                .font(.system(size: 13, weight: .bold))
                .minimumScaleFactor(0.7)
            Text(name)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct MacroPalWidget: Widget {
    let kind: String = "MacroPalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MacroPalWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Macros Remaining")
        .description("See how many calories and macros you have left today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    MacroPalWidget()
} timeline: {
    MacroWidgetEntry(
        eaten: MacroTotals(calories: 1200, proteinG: 80, carbG: 100, fatG: 40),
        target: MacroTotals(calories: 2000, proteinG: 150, carbG: 200, fatG: 65),
        hasProfile: true
    )
}

#Preview(as: .systemMedium) {
    MacroPalWidget()
} timeline: {
    MacroWidgetEntry(
        eaten: MacroTotals(calories: 1200, proteinG: 80, carbG: 100, fatG: 40),
        target: MacroTotals(calories: 2000, proteinG: 150, carbG: 200, fatG: 65),
        hasProfile: true
    )
}
