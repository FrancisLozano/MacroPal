//
//  ExerciseVolumeChart.swift
//  MacroPal
//

import SwiftUI
import Charts

/// Volume (weight × reps, summed) per session of one exercise, as bars. Tap a session to see
/// its sets; tap it again to clear.
struct ExerciseVolumeChart: View {
    /// Any order; drawn by date.
    let days: [ExerciseHistoryDay]

    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb
    @State private var selectedDate: Date?

    private static let day: TimeInterval = 86_400

    private var selectedDay: ExerciseHistoryDay? {
        guard let selectedDate else { return nil }
        return days.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }

    /// At least two weeks wide, so a single session is a bar rather than the whole chart, and
    /// padded by a day so the end bars aren't clipped.
    private var xDomain: ClosedRange<Date> {
        let dates = days.map { Calendar.current.startOfDay(for: $0.date) }
        let first = dates.min() ?? Calendar.current.startOfDay(for: .now)
        let last = dates.max() ?? first
        let span = last.timeIntervalSince(first)
        let pad = max(Self.day, (14 * Self.day - span) / 2)
        return first.addingTimeInterval(-pad)...last.addingTimeInterval(pad + Self.day)
    }

    var body: some View {
        Chart {
            ForEach(days) { day in
                BarMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Volume", unit.fromKg(day.volumeKg))
                )
                .foregroundStyle(day.id == selectedDay?.id ? Color.accentColor : Color.accentColor.opacity(0.7))
                .cornerRadius(3)
                .accessibilityLabel(day.date.formatted(date: .abbreviated, time: .omitted))
                .accessibilityValue("\(unit.formattedLift(fromKg: day.volumeKg)) \(unit.symbol) volume")
            }

            if let selectedDay {
                RuleMark(x: .value("Selected", selectedDay.date, unit: .day))
                    .foregroundStyle(Color.clear)
                    .annotation(position: .top, spacing: 4, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        callout(for: selectedDay)
                    }
            }
        }
        .chartXScale(domain: xDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartXSelection(value: $selectedDate)
        // A tap instead of the default press-and-drag: inside a scrolling List the drag fights
        // the scroll, and the selection would vanish the moment the finger lifts.
        .chartGesture { proxy in
            SpatialTapGesture().onEnded { tap in
                let previous = selectedDay?.id
                proxy.selectXValue(at: tap.location.x)
                if selectedDay?.id == previous { selectedDate = nil }
            }
        }
        .frame(height: 200)
        .padding(.top, 52) // room for the selection callout above the plot
        .padding(.vertical, 4)
    }

    private func callout(for day: ExerciseHistoryDay) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(day.date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(unit.formattedLift(fromKg: day.volumeKg)) \(unit.symbol)")
                .font(.caption.weight(.semibold))
            Text(day.sets.count == 1 ? "1 set" : "\(day.sets.count) sets")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator))
    }
}
