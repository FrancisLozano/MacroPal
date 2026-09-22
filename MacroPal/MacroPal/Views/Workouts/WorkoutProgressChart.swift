//
//  WorkoutProgressChart.swift
//  MacroPal
//

import SwiftUI
import Charts

/// Estimated 1RM per session, with an optional dashed target line (the next strength level) so
/// the chart shows where the lift is heading, not just where it's been. Tap a session to see it;
/// tap it again to clear.
struct WorkoutProgressChart: View {
    struct Target {
        let name: String
        let weightKg: Double
    }

    let points: [ExerciseProgressPoint]
    var target: Target?

    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb
    @State private var selectedDate: Date?

    private static let day: TimeInterval = 86_400

    private var selectedPoint: ExerciseProgressPoint? {
        guard let selectedDate else { return nil }
        return points.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }

    /// Padded so the end points aren't clipped, and at least a week wide — with one session
    /// (or several on nearby days) an automatic domain has no width and the axis loses its labels.
    private var xDomain: ClosedRange<Date> {
        let first = points.first?.date ?? .now
        let last = points.last?.date ?? .now
        let span = last.timeIntervalSince(first)
        let pad = max(span * 0.05, (7 * Self.day - span) / 2)
        return first.addingTimeInterval(-pad)...last.addingTimeInterval(pad)
    }

    /// Always includes the target, so the gap to it is visible.
    private var yDomain: ClosedRange<Double> {
        var values = points.map { unit.fromKg($0.estimated1RM) }
        if let target { values.append(unit.fromKg(target.weightKg)) }
        let low = values.min() ?? 0
        let high = values.max() ?? 1
        let pad = max((high - low) * 0.15, high * 0.05, 1)
        return max(0, low - pad)...(high + pad)
    }

    var body: some View {
        Chart {
            if let target {
                RuleMark(y: .value("Target", unit.fromKg(target.weightKg)))
                    .foregroundStyle(Color.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .annotation(position: .top, alignment: .leading, spacing: 2) {
                        Text("\(target.name) · \(unit.formattedLift(fromKg: target.weightKg)) \(unit.symbol)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
            }

            ForEach(points) { point in
                LineMark(x: .value("Date", point.date), y: .value("Est. 1RM", unit.fromKg(point.estimated1RM)))
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                PointMark(x: .value("Date", point.date), y: .value("Est. 1RM", unit.fromKg(point.estimated1RM)))
                    .symbolSize(point.id == selectedPoint?.id ? 110 : 60)
                    .accessibilityLabel(point.date.formatted(date: .abbreviated, time: .omitted))
                    .accessibilityValue("\(unit.formattedLift(fromKg: point.estimated1RM)) \(unit.symbol) estimated one-rep max")
            }

            if let selectedPoint {
                RuleMark(x: .value("Selected", selectedPoint.date))
                    .foregroundStyle(Color.secondary.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .annotation(position: .top, spacing: 4, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        callout(for: selectedPoint)
                    }
            }
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: yDomain)
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
                let previous = selectedPoint?.id
                proxy.selectXValue(at: tap.location.x)
                if selectedPoint?.id == previous { selectedDate = nil }
            }
        }
        .frame(height: 220)
        .padding(.top, 52) // room for the selection callout above the plot
        .padding(.vertical, 4)
    }

    private func callout(for point: ExerciseProgressPoint) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(point.date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(unit.formattedLift(fromKg: point.estimated1RM)) \(unit.symbol) est. 1RM")
                .font(.caption.weight(.semibold))
            Text("Top set \(unit.formattedLift(fromKg: point.topSetWeightKg)) \(unit.symbol) × \(point.topSetReps)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator))
    }
}

#Preview {
    WorkoutProgressChart(
        points: [
            ExerciseProgressPoint(date: .now.addingTimeInterval(-86400 * 14), topSetWeightKg: 60, topSetReps: 8, estimated1RM: OneRepMaxEstimator.epley(weightKg: 60, reps: 8)),
            ExerciseProgressPoint(date: .now.addingTimeInterval(-86400 * 7), topSetWeightKg: 62.5, topSetReps: 8, estimated1RM: OneRepMaxEstimator.epley(weightKg: 62.5, reps: 8)),
            ExerciseProgressPoint(date: .now, topSetWeightKg: 65, topSetReps: 6, estimated1RM: OneRepMaxEstimator.epley(weightKg: 65, reps: 6)),
        ],
        target: .init(name: "Intermediate", weightKg: 105)
    )
    .padding()
}
