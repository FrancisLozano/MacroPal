//
//  RoutineEditorView.swift
//  MacroPal
//

import SwiftUI
import SwiftData

/// Pick which weekdays you train and a split (Push/Pull/Legs, Upper/Lower, …), or let
/// Recommended pick one from how many days you train. With Apple Intelligence you can also
/// describe the routine in a message, which fills in the same form. Used both to create the
/// first plan and to change it later.
struct RoutineEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let plan: WorkoutPlan?

    @State private var selectedWeekdays: Set<Int>
    @State private var split: RoutineTemplate.Split
    @State private var message = ""
    @State private var isInterpreting = false
    @State private var messageHint: String?

    init(plan: WorkoutPlan?) {
        self.plan = plan
        let existing = Set(plan?.days.map(\.weekday) ?? [])
        // Mon / Wed / Fri until the user chooses otherwise.
        _selectedWeekdays = State(initialValue: existing.isEmpty ? RoutineTemplate.defaultWeekdays(count: 3) : existing)
        _split = State(initialValue: RoutineTemplate.inferredSplit(fromDayNames: plan?.sortedDays.map(\.name) ?? []))
    }

    private var isValid: Bool {
        RoutineTemplate.daysPerWeekRange.contains(selectedWeekdays.count)
    }

    private var preview: [(weekday: Int, slot: RoutineTemplate.Slot)] {
        RoutineTemplate.split(for: selectedWeekdays, split: split)
    }

    var body: some View {
        // Scrolls so the half-height sheet keeps its spacing instead of squeezing it.
        ScrollView {
            form
        }
        .scrollBounceBehavior(.basedOnSize)
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

    private var form: some View {
        VStack(alignment: .leading, spacing: 20) {
            if RoutineAssistant.isAvailable {
                messageField
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Training days")
                    .font(.headline)
                HStack(spacing: 6) {
                    ForEach(1...7, id: \.self) { weekday in
                        dayToggle(weekday)
                    }
                }
            }

            // A menu rather than segments: "Recommended" doesn't fit a quarter of the width.
            HStack {
                Text("Split")
                    .font(.headline)
                Spacer()
                Picker("Split", selection: $split) {
                    ForEach(RoutineTemplate.Split.allCases) { split in
                        Text(split.displayName).tag(split)
                    }
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Your week")
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
        }
        .padding([.horizontal, .bottom])
        .padding(.top, 8)
    }

    private var messageField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                TextField("Describe it, e.g. 4 days, upper/lower", text: $message)
                    .submitLabel(.send)
                    .onSubmit(interpretMessage)
                if isInterpreting {
                    ProgressView()
                } else {
                    Button("Fill In", systemImage: "arrow.up.circle.fill", action: interpretMessage)
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .disabled(message.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemFill), in: Capsule())

            if let messageHint {
                Text(messageHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 12)
            }
        }
    }

    /// Fills in the days and split from the message. Never saves: the user checks the form
    /// and taps Save. On failure the form is left as it was.
    private func interpretMessage() {
        let text = message.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !isInterpreting else { return }
        guard RoutineRequest.looksLikeARoutine(text) else {
            messageHint = "Say how many days or which split. Try: 3 days, full body."
            return
        }
        isInterpreting = true
        messageHint = nil
        Task {
            defer { isInterpreting = false }
            do {
                let request = try await RoutineAssistant.interpret(text)
                let resolved = request.resolve(message: text, currentWeekdays: selectedWeekdays)
                withAnimation {
                    selectedWeekdays = resolved.weekdays
                    split = resolved.split
                }
                messageHint = "Filled in below. Check it, then Save."
            } catch {
                messageHint = "Couldn't read that. Try: 3 days, full body."
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
        RoutineTemplate.apply(weekdays: selectedWeekdays, split: split, to: plan, in: modelContext)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        RoutineEditorView(plan: nil)
    }
    .modelContainer(for: [WorkoutPlan.self, PlanDay.self, PlanExercise.self, Exercise.self], inMemory: true)
}
