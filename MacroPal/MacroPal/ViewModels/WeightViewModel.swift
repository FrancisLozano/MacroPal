//
//  WeightViewModel.swift
//  MacroPal
//

import Foundation
import SwiftData

struct WeightTrendPoint: Identifiable {
    let date: Date
    let weightKg: Double
    let rollingAverageKg: Double

    var id: Date { date }
}

/// Logging a `WeightEntry` is simple enough to live directly in its View. The real logic
/// here is updating the goal weight and computing the trend chart's data points.
@Observable
final class WeightViewModel {
    func updateGoalWeight(_ goalWeightKg: Double, on profile: UserProfile) {
        profile.goalWeightKg = goalWeightKg
    }

    /// Collapses same-day entries to one average, then computes a rolling average over
    /// `windowDays`. Uses a partial window for the earliest points so the average line
    /// still appears with sparse history rather than waiting for a full window to fill.
    func trendPoints(for entries: [WeightEntry], windowDays: Int = 7, calendar: Calendar = .current) -> [WeightTrendPoint] {
        let byDay = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
        let dailyAverages = byDay
            .map { day, entries in (date: day, weightKg: entries.map(\.weightKg).reduce(0, +) / Double(entries.count)) }
            .sorted { $0.date < $1.date }

        var points: [WeightTrendPoint] = []
        for index in dailyAverages.indices {
            let windowStart = max(0, index - windowDays + 1)
            let window = dailyAverages[windowStart...index]
            let rollingAverage = window.map(\.weightKg).reduce(0, +) / Double(window.count)
            points.append(WeightTrendPoint(date: dailyAverages[index].date, weightKg: dailyAverages[index].weightKg, rollingAverageKg: rollingAverage))
        }
        return points
    }
}
