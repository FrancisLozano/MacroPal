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

/// The span one page of the steps history covers.
enum StepsPeriod: String, CaseIterable, Identifiable {
    case day, week, month

    var id: Self { self }

    /// "D" / "W" / "M", as in the Health app's picker.
    var shortLabel: String {
        switch self {
        case .day: "D"
        case .week: "W"
        case .month: "M"
        }
    }

    var component: Calendar.Component {
        switch self {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        }
    }
}

struct StepsPeriodSummary: Equatable {
    let period: DateInterval
    let days: [DailySteps]
    let total: Int
    let loggedDays: Int
    let averagePerLoggedDay: Int
    let daysGoalMet: Int
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
    static func dailyTotals(_ totals: [(day: Date, steps: Int)], days: Int, endingOn endDay: Date, calendar: Calendar) -> [DailySteps] {
        let byDay = Dictionary(totals.map { (calendar.startOfDay(for: $0.day), $0.steps) }, uniquingKeysWith: max)
        let lastDay = calendar.startOfDay(for: endDay)
        return (0..<max(days, 0)).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: lastDay) else { return nil }
            return DailySteps(day: day, steps: byDay[day] ?? 0)
        }
    }

    /// Every calendar day / week / month from the one holding `earliest` through the one
    /// holding `now`, oldest first — the pages the steps history swipes between. Weeks start on
    /// the calendar's first weekday, like the Nutrition week strip.
    static func periods(_ kind: StepsPeriod, from earliest: Date, through now: Date, calendar: Calendar) -> [DateInterval] {
        let component = kind.component
        guard let first = calendar.dateInterval(of: component, for: min(earliest, now)),
              let last = calendar.dateInterval(of: component, for: now) else { return [] }
        var periods = [first]
        while let current = periods.last, current.start < last.start,
              let next = calendar.dateInterval(of: component, for: current.end) {
            periods.append(next)
        }
        return periods
    }

    /// One page's numbers: a bar per day in `period` (0 where nothing was logged), the total,
    /// and — counting only logged days, since a blank day usually means "didn't log" — the
    /// daily average and how many days met `goal`.
    static func summary(of period: DateInterval, _ totals: [(day: Date, steps: Int)], goal: Int, calendar: Calendar) -> StepsPeriodSummary {
        let dayCount = calendar.dateComponents([.day], from: period.start, to: period.end).day ?? 0
        let lastDay = calendar.date(byAdding: .day, value: -1, to: period.end) ?? period.start
        let days = dailyTotals(totals, days: dayCount, endingOn: lastDay, calendar: calendar)
        let logged = days.filter { $0.steps > 0 }
        return StepsPeriodSummary(
            period: period,
            days: days,
            total: days.map(\.steps).reduce(0, +),
            loggedDays: logged.count,
            averagePerLoggedDay: logged.isEmpty ? 0 : logged.map(\.steps).reduce(0, +) / logged.count,
            daysGoalMet: logged.filter { $0.steps >= goal }.count
        )
    }

    func steps(on day: Date, in entries: [StepEntry], calendar: Calendar = .current) -> Int {
        entries.first { calendar.isDate($0.day, inSameDayAs: day) }?.steps ?? 0
    }
}
