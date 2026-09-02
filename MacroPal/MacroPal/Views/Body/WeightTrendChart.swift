//
//  WeightTrendChart.swift
//  MacroPal
//

import SwiftUI
import Charts

struct WeightTrendChart: View {
    let points: [WeightTrendPoint]
    let goalWeightKg: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(points) { point in
                    PointMark(x: .value("Date", point.date), y: .value("Weight", point.weightKg))
                        .foregroundStyle(.secondary)
                        .symbolSize(30)
                }
                ForEach(points) { point in
                    LineMark(x: .value("Date", point.date), y: .value("7-day Avg", point.rollingAverageKg))
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                }
                RuleMark(y: .value("Goal", goalWeightKg))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.green)
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 200)

            HStack(spacing: 16) {
                legendItem(color: .secondary, label: "Daily")
                legendItem(color: .blue, label: "7-day Avg")
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    WeightTrendChart(
        points: [
            WeightTrendPoint(date: .now.addingTimeInterval(-86400 * 6), weightKg: 83.1, rollingAverageKg: 83.1),
            WeightTrendPoint(date: .now.addingTimeInterval(-86400 * 4), weightKg: 82.6, rollingAverageKg: 82.85),
            WeightTrendPoint(date: .now.addingTimeInterval(-86400 * 2), weightKg: 82.9, rollingAverageKg: 82.87),
            WeightTrendPoint(date: .now, weightKg: 82.4, rollingAverageKg: 82.75),
        ],
        goalWeightKg: 78
    )
    .padding()
}
