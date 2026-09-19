//
//  WorkoutProgressChart.swift
//  MacroPal
//

import SwiftUI
import Charts

struct WorkoutProgressChart: View {
    let points: [ExerciseProgressPoint]
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb

    var body: some View {
        let topSetLabel = "Top Set (\(unit.symbol))"
        let oneRepMaxLabel = "Est. 1RM (\(unit.symbol))"
        Chart {
            ForEach(points) { point in
                LineMark(x: .value("Date", point.date), y: .value("Value", unit.fromKg(point.topSetWeightKg)))
                    .foregroundStyle(by: .value("Metric", topSetLabel))
                    .symbol(by: .value("Metric", topSetLabel))
            }
            ForEach(points) { point in
                LineMark(x: .value("Date", point.date), y: .value("Value", unit.fromKg(point.estimated1RM)))
                    .foregroundStyle(by: .value("Metric", oneRepMaxLabel))
                    .symbol(by: .value("Metric", oneRepMaxLabel))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .frame(height: 220)
        .padding(.vertical, 4)
    }
}

#Preview {
    WorkoutProgressChart(points: [
        ExerciseProgressPoint(date: .now.addingTimeInterval(-86400 * 14), topSetWeightKg: 60, topSetReps: 8, estimated1RM: OneRepMaxEstimator.epley(weightKg: 60, reps: 8)),
        ExerciseProgressPoint(date: .now.addingTimeInterval(-86400 * 7), topSetWeightKg: 62.5, topSetReps: 8, estimated1RM: OneRepMaxEstimator.epley(weightKg: 62.5, reps: 8)),
        ExerciseProgressPoint(date: .now, topSetWeightKg: 65, topSetReps: 6, estimated1RM: OneRepMaxEstimator.epley(weightKg: 65, reps: 6)),
    ])
    .padding()
}
