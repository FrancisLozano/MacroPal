//
//  WeightLoggingTests.swift
//  MacroPalTests
//

import Foundation
import Testing
import SwiftData
@testable import MacroPal

@MainActor
struct WeightLoggingTests {
    private let container = try! ModelContainer(
        for: AppSchema.schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    private let viewModel = WeightViewModel()

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }

    private func date(day: Int, hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    private func entries() throws -> [WeightEntry] {
        try container.mainContext.fetch(FetchDescriptor<WeightEntry>(sortBy: [SortDescriptor(\.date)]))
    }

    @Test func relogOnTheSameDayReplacesTheEntry() throws {
        let context = container.mainContext
        viewModel.log(weightKg: 80, on: date(day: 5, hour: 7), in: context, calendar: calendar)
        viewModel.log(weightKg: 79.5, on: date(day: 5, hour: 21), in: context, calendar: calendar)

        let logged = try entries()
        #expect(logged.map(\.weightKg) == [79.5])
        #expect(logged.first?.date == date(day: 5, hour: 21))
    }

    @Test func otherDaysAreLeftAlone() throws {
        let context = container.mainContext
        viewModel.log(weightKg: 80, on: date(day: 4, hour: 23), in: context, calendar: calendar)
        viewModel.log(weightKg: 79, on: date(day: 5, hour: 0), in: context, calendar: calendar)

        #expect(try entries().map(\.weightKg) == [80, 79])
    }

    @Test func relogClearsEarlierDuplicatesForTheDay() throws {
        let context = container.mainContext
        context.insert(WeightEntry(date: date(day: 5, hour: 7), weightKg: 81))
        context.insert(WeightEntry(date: date(day: 5, hour: 9), weightKg: 80.5))
        viewModel.log(weightKg: 80, on: date(day: 5, hour: 12), in: context, calendar: calendar)

        #expect(try entries().map(\.weightKg) == [80])
    }
}
