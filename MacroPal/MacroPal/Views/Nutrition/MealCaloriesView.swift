//
//  MealCaloriesView.swift
//  MacroPal
//

import SwiftUI
import SwiftData
import Charts

extension MealType {
    /// Light, mid and dark blue for Breakfast, Lunch and Dinner in the pie chart — shades of
    /// the Daily Log's calories bar blue, so the split reads as calories rather than as a
    /// macro. Snacks aren't on the Daily Log, so they're only given a color to be complete.
    var calorieColor: Color {
        switch self {
        case .breakfast: Color.blue.mix(with: .white, by: 0.5)
        case .lunch: .blue
        case .dinner: Color.blue.mix(with: .black, by: 0.45)
        case .snack: .gray
        }
    }
}

/// How a day's calories split across Breakfast, Lunch and Dinner, as a pie chart, then the
/// total against the goal. Reached by tapping the calories bar on the Daily Log.
struct MealCaloriesView: View {
    @Query(sort: \FoodEntry.date) private var allEntries: [FoodEntry]
    @Query private var profiles: [UserProfile]

    let date: Date

    private let viewModel = NutritionViewModel()

    private var entriesForDate: [FoodEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        let entries = entriesForDate
        let meals = viewModel.mealCalories(from: entries)
        let eaten = viewModel.dailyTotals(for: entries).calories

        List {
            Section {
                VStack(spacing: 20) {
                    Text(Calendar.current.isDateInToday(date) ? "Today" : date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    pie(meals)
                    legend(meals)
                }
                .padding(.vertical, 8)
            }

            Section {
                totalRow("Total Calories", value: eaten)
                if let profile = profiles.first {
                    let goal = Double(profile.calorieTarget)
                    totalRow("Goal", value: goal)
                    let remaining = goal - eaten
                    totalRow(remaining >= 0 ? "Left" : "Over", value: abs(remaining), isOver: remaining < 0)
                }
            }
        }
        .navigationTitle("Calories by Meal")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pie

    @ViewBuilder
    private func pie(_ meals: [MealCalories]) -> some View {
        if meals.allSatisfy({ $0.calories == 0 }) {
            Circle()
                .fill(Color.secondary.opacity(0.15))
                .overlay {
                    Text("Nothing logged")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(height: 200)
        } else {
            Chart(meals.filter { $0.calories > 0 }, id: \.meal) { meal in
                SectorMark(angle: .value("Calories", meal.calories), angularInset: 1)
                    .foregroundStyle(meal.meal.calorieColor)
                    // Slices too thin to hold a label are named in the legend below instead.
                    .annotation(position: .overlay) {
                        if meal.share >= 0.08 {
                            Text(percent(meal.share))
                                .font(.caption.bold())
                                .foregroundStyle(meal.meal == .breakfast ? Color.black : Color.white)
                        }
                    }
            }
            .frame(height: 200)
        }
    }

    // MARK: - Legend

    private func legend(_ meals: [MealCalories]) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(meals, id: \.meal) { meal in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(meal.meal.calorieColor)
                        .frame(width: 12, height: 12)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.meal.displayName)
                            .font(.subheadline)
                        Text("\(percent(meal.share)) · \(Int(meal.calories.rounded())) kcal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            // A third of the width is tight for "99% · 1,790 kcal": shrink, don't wrap.
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func percent(_ share: Double) -> String {
        "\(Int((share * 100).rounded()))%"
    }

    // MARK: - Totals

    private func totalRow(_ title: String, value: Double, isOver: Bool = false) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(Int(value.rounded())) kcal")
                .foregroundStyle(isOver ? Color.red : Color.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        MealCaloriesView(date: .now)
    }
    .modelContainer(for: [FoodEntry.self, FoodItem.self, UserProfile.self], inMemory: true)
}
