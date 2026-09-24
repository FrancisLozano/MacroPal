//
//  RoutineEditorView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Pick which weekdays you train; the split (Push/Pull/Legs, Upper/Lower, …) follows from how
/// many you pick. Used both to create the first plan and to change days per week later.
struct RoutineEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let plan: WorkoutPlan?

    @State private var selectedWeekdays: Set<Int>

    init(plan: WorkoutPlan?) {
        self.plan = plan
        let existing = Set(plan?.days.map(\.weekday) ?? [])
        // Mon / Wed / Fri until the user chooses otherwise.
        _selectedWeekdays = State(initialValue: existing.isEmpty ? [2, 4, 6] : existing)
    }

    private var isValid: Bool {
        RoutineTemplate.daysPerWeekRange.contains(selectedWeekdays.count)
    }

    private var preview: [(weekday: Int, slot: RoutineTemplate.Slot)] {
        RoutineTemplate.split(for: selectedWeekdays)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Training days")
                    .font(.headline)
                HStack(spacing: 6) {
                    ForEach(1...7, id: \.self) { weekday in
                        dayToggle(weekday)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Your split")
                    .font(.headline)
                if isValid {
                    ForEach(preview, id: \.weekday) { item in
                        HStack {
                            Text(Calendar.current.weekdaySymbols[item.weekday - 1])
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(item.slot.name)
                        }
                    }
                } else {
                    Text("Pick between \(RoutineTemplate.daysPerWeekRange.lowerBound) and \(RoutineTemplate.daysPerWeekRange.upperBound) days.")
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .navigationTitle(plan == nil ? "Create Plan" : "Edit Routine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!isValid)
            }
        }
    }

    private func dayToggle(_ weekday: Int) -> some View {
        let isOn = selectedWeekdays.contains(weekday)
        return Button {
            if isOn {
                selectedWeekdays.remove(weekday)
            } else {
                selectedWeekdays.insert(weekday)
            }
        } label: {
            Text(Calendar.current.veryShortWeekdaySymbols[weekday - 1])
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity, minHeight: 40)
                .foregroundStyle(isOn ? Color.white : Color.primary)
                .background(isOn ? Color.accentColor : Color(.secondarySystemFill), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Calendar.current.weekdaySymbols[weekday - 1])
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func save() {
        RoutineTemplate.apply(weekdays: selectedWeekdays, to: plan, in: modelContext)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        RoutineEditorView(plan: nil)
    }
    .modelContainer(for: [WorkoutPlan.self, PlanDay.self, PlanExercise.self, Exercise.self], inMemory: true)
}
