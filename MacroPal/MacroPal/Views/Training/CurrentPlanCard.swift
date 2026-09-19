//
//  CurrentPlanCard.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Current-plan section of the Training page: the plan summary and today's workout. The
/// calendar icon opens the expanded week; tapping today's workout opens its exercises.
struct CurrentPlanCard: View {
    @Query private var plans: [WorkoutPlan]

    @State private var isPresentingRoutineEditor = false

    private var plan: WorkoutPlan? { plans.first }

    private var today: PlanDay? {
        plan?.day(on: Calendar.current.component(.weekday, from: .now))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Plan")
                        .font(.headline)
                    if let plan {
                        Text("Workout · \(plan.days.count) days a week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let plan {
                    NavigationLink {
                        WeekPlanView(plan: plan)
                    } label: {
                        Image(systemName: "calendar")
                            .padding(8)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Week plan")
                }
            }

            if plan == nil {
                Button {
                    isPresentingRoutineEditor = true
                } label: {
                    Label("Create your plan", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else if let today {
                NavigationLink {
                    PlanDayDetailView(day: today)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Today: \(today.name)")
                                .font(.title3.bold())
                            Text(today.focus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(Color.primary)
                }
            } else {
                Text("Rest day")
                    .font(.title3.bold())
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .sheet(isPresented: $isPresentingRoutineEditor) {
            NavigationStack {
                RoutineEditorView(plan: nil)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CurrentPlanCard()
    }
    .modelContainer(
        for: [WorkoutPlan.self, PlanDay.self, PlanExercise.self, Exercise.self],
        inMemory: true
    )
}
