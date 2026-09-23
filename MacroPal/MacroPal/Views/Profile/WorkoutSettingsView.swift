//
//  WorkoutSettingsView.swift
//  MacroPal
//

import SwiftUI

/// Profile → Workout: how set rows read on the tracking screen, the targets new exercises start
/// with, and the rest timer. All device preferences (see `WorkoutPreferences`).
struct WorkoutSettingsView: View {
    @AppStorage(WorkoutPreferences.weightFirstKey) private var weightFirst = WorkoutPreferences.weightFirstDefault
    @AppStorage(WorkoutPreferences.showPRsKey) private var showPRs = WorkoutPreferences.showPRsDefault
    @AppStorage(WorkoutPreferences.defaultSetsKey) private var defaultSets = WorkoutPreferences.defaultSetsDefault
    @AppStorage(WorkoutPreferences.defaultRepsKey) private var defaultReps = WorkoutPreferences.defaultRepsDefault
    @AppStorage(WorkoutPreferences.defaultRepsMaxKey) private var defaultRepsMax = WorkoutPreferences.defaultRepsMaxDefault
    @AppStorage(WorkoutPreferences.restSecondsKey) private var restSeconds = WorkoutPreferences.restSecondsDefault
    @AppStorage(WorkoutPreferences.autoRestTimerKey) private var autoRestTimer = WorkoutPreferences.autoRestTimerDefault

    /// On: a range starting two above the bottom (8 → 8–10), same as the plan's Sets & Reps editor.
    private var isRange: Binding<Bool> {
        Binding(
            get: { defaultRepsMax > defaultReps },
            set: { defaultRepsMax = $0 ? defaultReps + 2 : 0 }
        )
    }

    var body: some View {
        Form {
            Section("Display") {
                orderRow("Show Reps First", isSelected: !weightFirst) { weightFirst = false }
                orderRow("Show Weight First", isSelected: weightFirst) { weightFirst = true }
                Toggle(isOn: $showPRs) {
                    InfoLabel(
                        "Show PRs During Workout",
                        info: "Shows each set's weight as a % of your best estimated one-rep max from earlier days, with a bar that turns from green to red as it gets heavier."
                    )
                }
            }

            Section {
                Stepper("Default Sets: \(defaultSets)", value: $defaultSets, in: 1...10)
                Toggle("Rep Range", isOn: isRange)
                if defaultRepsMax > defaultReps {
                    Stepper("From: \(defaultReps) reps", value: $defaultReps, in: 1...29)
                    Stepper("To: \(defaultRepsMax) reps", value: $defaultRepsMax, in: (defaultReps + 1)...30)
                } else {
                    Stepper("Default Reps: \(defaultReps)", value: $defaultReps, in: 1...30)
                }
                Picker("Default Rest", selection: $restSeconds) {
                    ForEach(WorkoutPreferences.restChoices, id: \.self) { seconds in
                        Text(WorkoutPreferences.restLabel(seconds: seconds)).tag(seconds)
                    }
                }
            } header: {
                InfoLabel(
                    "Exercise Targets",
                    info: "What a newly added exercise starts with — the sets × reps on a plan day, and how many rows an unplanned exercise opens with. Exercises already in your plan keep their own targets. Default Rest is how long the rest timer counts down."
                )
                .textCase(nil)
            }
            // Keep a range the right way round when the bottom is stepped up past the top.
            .onChange(of: defaultReps) { _, reps in
                if defaultRepsMax != 0, defaultRepsMax <= reps {
                    defaultRepsMax = reps + 1
                }
            }

            Section("Timer") {
                Toggle(isOn: $autoRestTimer) {
                    InfoLabel(
                        "Automatic Rest Timer",
                        info: "Starts the rest countdown as soon as you check off a set. With it off, start one from the timer button on the tracking screen."
                    )
                }
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func orderRow(_ title: String, isSelected: Bool, select: @escaping () -> Void) -> some View {
        Button(action: select) {
            HStack {
                Text(title)
                    .foregroundStyle(Color.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .fontWeight(.semibold)
                }
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A title with an ⓘ that pops up a short explanation.
private struct InfoLabel: View {
    let title: String
    let info: String

    @State private var isShowingInfo = false

    init(_ title: String, info: String) {
        self.title = title
        self.info = info
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
            Button {
                isShowingInfo = true
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("About \(title)")
            .popover(isPresented: $isShowingInfo) {
                // A fixed width lets the popover size itself to the wrapped text; with only a
                // max width it came up short and clipped the first and last lines.
                Text(info)
                    .font(.subheadline)
                    .frame(width: 280, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
                    .presentationCompactAdaptation(.popover)
            }
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutSettingsView()
    }
}
