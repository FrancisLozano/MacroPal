//
//  WorkoutProgressChart.swift
//  MacroPal
//

import SwiftUI
import Charts

struct WorkoutProgressChart: View {
    let points: [ExerciseProgressPoint]

    var body: some View {
        Chart {
            ForEach(points) { point in
                LineMark(x: .value("Date", point.date), y: .value("Value", point.topSetWeightKg))
                    .foregroundStyle(by: .value("Metric", "Top Set (kg)"))
                    .symbol(by: .value("Metric", "Top Set (kg)"))
            }
            ForEach(points) { point in
                LineMark(x: .value("Date", point.date), y: .value("Value", point.estimated1RM))
                    .foregroundStyle(by: .value("Metric", "Est. 1RM (kg)"))
                    .symbol(by: .value("Metric", "Est. 1RM (kg)"))
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
