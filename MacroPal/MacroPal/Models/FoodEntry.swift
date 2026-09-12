//
//  FoodEntry.swift
//  MacroPal
//

import Foundation
import SwiftData

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack

    var id: Self { self }

    var displayName: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snack: "Snack"
        }
    }

    /// SF Symbol shown on the "Log Today" meal card.
    var icon: String {
        switch self {
        case .breakfast: "cup.and.saucer.fill"
        case .lunch: "takeoutbag.and.cup.and.straw.fill"
        case .dinner: "fork.knife"
        case .snack: "leaf.fill"
        }
    }

    /// Suggested daily time range for this meal — used only to pick which meal card the
    /// "Log Today" carousel opens on. Hardcoded for now; a future profile setting could make
    /// these user-configurable.
    var defaultTimeWindow: MealTimeWindow {
        switch self {
        case .breakfast: MealTimeWindow(startHour: 6, startMinute: 30, endHour: 10, endMinute: 0)
        case .lunch: MealTimeWindow(startHour: 11, startMinute: 0, endHour: 17, endMinute: 0)
        case .dinner: MealTimeWindow(startHour: 17, startMinute: 0, endHour: 23, endMinute: 59)
        case .snack: MealTimeWindow(startHour: 0, startMinute: 0, endHour: 23, endMinute: 59)
        }
    }

    /// Picks whichever of breakfast/lunch/dinner best matches the time of day, by dividing
    /// the day at each meal's suggested start time.
    static func current(at date: Date = .now) -> MealType {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let minuteOfDay = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        if minuteOfDay < MealType.lunch.defaultTimeWindow.startMinuteOfDay { return .breakfast }
        if minuteOfDay < MealType.dinner.defaultTimeWindow.startMinuteOfDay { return .lunch }
        return .dinner
    }
}

struct MealTimeWindow {
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int

    var startMinuteOfDay: Int { startHour * 60 + startMinute }

    var displayText: String {
        "\(Self.formattedTime(hour: startHour, minute: startMinute)) – \(Self.formattedTime(hour: endHour, minute: endMinute))"
    }

    private static func formattedTime(hour: Int, minute: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }
}

/// One logged instance of eating a food. Macros are snapshotted at log time from the
/// `FoodItem` (scaled by `servingSizeG`) rather than derived live, so editing a `FoodItem`
/// later doesn't retroactively change already-logged history.
@Model
final class FoodEntry {
    var date: Date
    var mealType: MealType
    var servingSizeG: Double
    var nameSnapshot: String
    var caloriesKcal: Double
    var proteinG: Double
    var carbG: Double
    var fatG: Double

    /// Convenience link back to the source food, e.g. for "log again". Not the source of
    /// truth for this entry's macros — see snapshot fields above.
    @Relationship(deleteRule: .nullify)
    var foodItem: FoodItem?

    init(
        date: Date,
        mealType: MealType,
        servingSizeG: Double,
        nameSnapshot: String,
        caloriesKcal: Double,
        proteinG: Double,
        carbG: Double,
        fatG: Double,
        foodItem: FoodItem? = nil
    ) {
        self.date = date
        self.mealType = mealType
        self.servingSizeG = servingSizeG
        self.nameSnapshot = nameSnapshot
        self.caloriesKcal = caloriesKcal
        self.proteinG = proteinG
        self.carbG = carbG
        self.fatG = fatG
        self.foodItem = foodItem
    }
}
