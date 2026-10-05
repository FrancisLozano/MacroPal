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

/// Logging weight (one entry per day, replaced on re-log), updating the goal weight and
/// computing the trend chart's data points.
@Observable
final class WeightViewModel {
    /// Sets `day`'s weight to `weightKg`, updating that day's entry if there is one, like
    /// steps. Any older duplicates for the day go, so the day keeps a single weigh-in.
    func log(weightKg: Double, on day: Date, in context: ModelContext, calendar: Calendar = .current) {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return }
        let descriptor = FetchDescriptor<WeightEntry>(predicate: #Predicate { $0.date >= start && $0.date < end })
        let existing = (try? context.fetch(descriptor)) ?? []
        if let entry = existing.first {
            entry.date = day
            entry.weightKg = weightKg
            existing.dropFirst().forEach(context.delete)
        } else {
            context.insert(WeightEntry(date: day, weightKg: weightKg))
        }
    }

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
