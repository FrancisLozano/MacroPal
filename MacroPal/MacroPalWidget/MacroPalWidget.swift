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
    let schema = AppSchema.schema
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

    // Same macro colors as the Daily Log, so the coding reads the same in both places.
    private static let proteinColor = Color.orange
    private static let carbColor = Color.green
    private static let fatColor = Color.purple
    private static let calorieColor = Color.teal
    private static let trackOpacity = 0.15

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
        VStack(spacing: 8) {
            Image(systemName: "fork.knife")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Open MacroPal to set up your profile")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    private var remainingCalories: Double { entry.target.calories - entry.eaten.calories }
    private var isOverCalories: Bool { remainingCalories < 0 }

    private var macros: [(name: String, short: String, eaten: Double, target: Double, color: Color)] {
        [
            ("Protein", "P", entry.eaten.proteinG, entry.target.proteinG, Self.proteinColor),
            ("Carbs", "C", entry.eaten.carbG, entry.target.carbG, Self.carbColor),
            ("Fat", "F", entry.eaten.fatG, entry.target.fatG, Self.fatColor),
        ]
    }

    // MARK: Small

    /// The ring is the headline; three short bars underneath hint at where the macros stand
    /// without competing with it for attention.
    private var smallView: some View {
        VStack(spacing: 12) {
            calorieRing(diameter: 92, lineWidth: 9)
            HStack(spacing: 8) {
                ForEach(macros, id: \.name) { macro in
                    VStack(spacing: 4) {
                        progressBar(eaten: macro.eaten, target: macro.target, color: macro.color, height: 4)
                        Text(macro.short)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(macro.name)
                    .accessibilityValue(macroAccessibilityValue(eaten: macro.eaten, target: macro.target))
                }
            }
            .padding(.horizontal, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Medium

    private var mediumView: some View {
        HStack(spacing: 20) {
            VStack(spacing: 8) {
                calorieRing(diameter: 96, lineWidth: 9)
                calorieTotalCaption
            }
            VStack(alignment: .leading, spacing: 12) {
                ForEach(macros, id: \.name) { macro in
                    macroRow(name: macro.name, eaten: macro.eaten, target: macro.target, color: macro.color)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var calorieTotalCaption: some View {
        HStack(spacing: 0) {
            Text(Int(entry.eaten.calories.rounded()), format: .number)
                .foregroundStyle(.primary)
            Text(" / ")
            Text(Int(entry.target.calories.rounded()), format: .number)
        }
        .font(.caption2.weight(.medium))
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(entry.eaten.calories.rounded())) of \(Int(entry.target.calories.rounded())) calories eaten")
    }

    private func macroRow(name: String, eaten: Double, target: Double, color: Color) -> some View {
        let isOver = target > 0 && eaten > target
        return VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(name)
                    .font(.caption.weight(.semibold))
                Spacer(minLength: 8)
                HStack(spacing: 0) {
                    Text(Int(eaten.rounded()), format: .number)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isOver ? Color.red : Color.primary)
                    Text(" / \(Int(target.rounded())) g")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .monospacedDigit()
                .lineLimit(1)
            }
            progressBar(eaten: eaten, target: target, color: color, height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityValue(macroAccessibilityValue(eaten: eaten, target: target))
    }

    // MARK: Shared pieces

    /// Calories left in the middle; past the goal it flips to "over" in red, and the overshoot
    /// is drawn as a second red lap the way the Daily Log's gauge does it.
    private func calorieRing(diameter: CGFloat, lineWidth: CGFloat) -> some View {
        let target = entry.target.calories
        let fraction = target > 0 ? min(1, max(0, entry.eaten.calories / target)) : 0
        let overFraction = target > 0 ? min(1, max(0, entry.eaten.calories / target - 1)) : 0
        let value = Int(abs(remainingCalories).rounded())

        return ZStack {
            Circle()
                .stroke(Color.secondary.opacity(Self.trackOpacity), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Self.calorieColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .widgetAccentable()
            if overFraction > 0 {
                Circle()
                    .trim(from: 0, to: overFraction)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            VStack(spacing: 1) {
                Text(value, format: .number)
                    .font(.system(size: diameter * 0.26, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(isOverCalories ? "kcal over" : "kcal left")
                    .font(.system(size: diameter * 0.12, weight: .medium))
                    .foregroundStyle(isOverCalories ? Color.red : Color.secondary)
            }
            .padding(.horizontal, lineWidth + 4)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Calories")
        .accessibilityValue(isOverCalories ? "\(value) over goal" : "\(value) left")
    }

    private func progressBar(eaten: Double, target: Double, color: Color, height: CGFloat) -> some View {
        let fraction = target > 0 ? min(1, max(0, eaten / target)) : 0
        let isOver = target > 0 && eaten > target
        return Capsule()
            .fill(Color.secondary.opacity(Self.trackOpacity))
            .frame(height: height)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(isOver ? Color.red : color)
                        .frame(width: max(fraction > 0 ? height : 0, proxy.size.width * fraction))
                        .widgetAccentable()
                }
            }
    }

    private func macroAccessibilityValue(eaten: Double, target: Double) -> String {
        let eatenG = Int(eaten.rounded())
        let targetG = Int(target.rounded())
        guard eaten > target, target > 0 else { return "\(eatenG) of \(targetG) grams" }
        return "\(eatenG) of \(targetG) grams, \(eatenG - targetG) over"
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

#Preview("Over goal", as: .systemMedium) {
    MacroPalWidget()
} timeline: {
    MacroWidgetEntry(
        eaten: MacroTotals(calories: 2240, proteinG: 162, carbG: 210, fatG: 58),
        target: MacroTotals(calories: 2000, proteinG: 150, carbG: 200, fatG: 65),
        hasProfile: true
    )
}
