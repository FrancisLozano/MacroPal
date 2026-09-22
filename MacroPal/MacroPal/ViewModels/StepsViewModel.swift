//
//  StepsViewModel.swift
//  MacroPal
//

import Foundation
import SwiftData

struct DailySteps: Identifiable, Equatable {
    let day: Date
    let steps: Int

    var id: Date { day }
}

/// Logging steps (one total per day, replaced on re-log) and shaping entries for the bar chart.
@Observable
final class StepsViewModel {
    /// Sets `day`'s total to `steps`, updating that day's entry if there is one.
    func log(steps: Int, on day: Date, in context: ModelContext, calendar: Calendar = .current) {
        let start = calendar.startOfDay(for: day)
        let descriptor = FetchDescriptor<StepEntry>(predicate: #Predicate { $0.day == start })
        if let existing = try? context.fetch(descriptor).first {
            existing.steps = steps
        } else {
            context.insert(StepEntry(day: start, steps: steps))
        }
    }

    func updateStepGoal(_ goal: Int, on profile: UserProfile) {
        profile.stepGoal = goal
    }

    /// The last `days` days ending on `endDay`, oldest first, with 0 for days nothing was
    /// logged — so the chart keeps one bar slot per day instead of closing up the gaps.
    func dailyTotals(_ entries: [StepEntry], days: Int, endingOn endDay: Date = .now, calendar: Calendar = .current) -> [DailySteps] {
        Self.dailyTotals(entries.map { (day: $0.day, steps: $0.steps) }, days: days, endingOn: endDay, calendar: calendar)
    }

    static func dailyTotals(_ totals: [(day: Date, steps: Int)], days: Int, endingOn endDay: Date, calendar: Calendar) -> [DailySteps] {
        let byDay = Dictionary(totals.map { (calendar.startOfDay(for: $0.day), $0.steps) }, uniquingKeysWith: max)
        let lastDay = calendar.startOfDay(for: endDay)
        return (0..<max(days, 0)).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: lastDay) else { return nil }
            return DailySteps(day: day, steps: byDay[day] ?? 0)
        }
    }

    func steps(on day: Date, in entries: [StepEntry], calendar: Calendar = .current) -> Int {
        entries.first { calendar.isDate($0.day, inSameDayAs: day) }?.steps ?? 0
    }
}
