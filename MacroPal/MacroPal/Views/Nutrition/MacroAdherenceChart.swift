//
//  MacroAdherenceChart.swift
//  MacroPal
//

import SwiftUI
import Charts

struct MacroAdherenceChart: View {
    let dailyTotals: [DailyCalorieTotal]
    let calorieTarget: Int

    var body: some View {
        Chart {
            ForEach(dailyTotals) { day in
                BarMark(x: .value("Day", day.date, unit: .day), y: .value("Calories", day.caloriesKcal))
                    .foregroundStyle(by: .value("Status", day.status.rawValue))
            }
            RuleMark(y: .value("Target", Double(calorieTarget)))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(.secondary)
                .annotation(position: .top, alignment: .trailing) {
                    Text("Target")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
        }
        .chartForegroundStyleScale([
            CalorieAdherenceStatus.under.rawValue: Color.orange,
            CalorieAdherenceStatus.onTarget.rawValue: Color.green,
            CalorieAdherenceStatus.over.rawValue: Color.red,
        ])
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day())
            }
        }
        .frame(height: 200)
        .padding(.vertical, 4)
    }
}

#Preview {
    MacroAdherenceChart(
        dailyTotals: (0..<14).map { offset in
            DailyCalorieTotal(
                date: Calendar.current.date(byAdding: .day, value: -offset, to: .now) ?? .now,
                caloriesKcal: Double.random(in: 1500...2400),
                status: [.under, .onTarget, .over].randomElement()!
            )
        }.reversed(),
        calorieTarget: 2000
    )
    .padding()
}
