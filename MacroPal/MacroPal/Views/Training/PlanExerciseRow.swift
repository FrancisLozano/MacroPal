//
//  PlanExerciseRow.swift
//  MacroPal
//

import SwiftUI

/// One exercise in a plan day: thumbnail, name, and a "3 sets x 8–10 reps" chip. Tapping opens
/// set tracking; the ellipsis menu edits the target, moves it within the day, or removes it.
struct PlanExerciseRow: View {
    let planExercise: PlanExercise
    let setsLoggedToday: Int
    let canMoveUp: Bool
    let canMoveDown: Bool
    /// -1 moves up one place, +1 down.
    let onMove: (Int) -> Void
    let onRemove: () -> Void

    @State private var isPresentingTargetEditor = false

    private var isComplete: Bool {
        setsLoggedToday >= planExercise.targetSets
    }

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink {
                ExerciseScreen(planExercise: planExercise)
            } label: {
                HStack(spacing: 12) {
                    ExerciseThumbnail(exercise: planExercise.exercise)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(planExercise.exercise?.name ?? "Unknown exercise")
                            .font(.headline)
                            .multilineTextAlignment(.leading)
                        HStack(spacing: 6) {
                            Text("\(planExercise.targetSets) sets x \(planExercise.repsLabel) reps")
                                .font(.subheadline)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 6))
                            if isComplete {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .accessibilityLabel("Done for today")
                            } else if setsLoggedToday > 0 {
                                Text("\(setsLoggedToday)/\(planExercise.targetSets)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .foregroundStyle(Color.primary)
            }
            .buttonStyle(.plain)

            Menu {
                Button("Edit Sets & Reps", systemImage: "slider.horizontal.3") {
                    isPresentingTargetEditor = true
                }
                Button("Move Up", systemImage: "arrow.up") { onMove(-1) }
                    .disabled(!canMoveUp)
                Button("Move Down", systemImage: "arrow.down") { onMove(1) }
                    .disabled(!canMoveDown)
                Button("Remove from Plan", systemImage: "trash", role: .destructive, action: onRemove)
            } label: {
                Image(systemName: "ellipsis")
                    .padding(10)
                    .background(Color(.tertiarySystemFill), in: Circle())
                    .foregroundStyle(Color.primary)
            }
            .accessibilityLabel("More options")
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
        .sheet(isPresented: $isPresentingTargetEditor) {
            NavigationStack {
                TargetEditorView(planExercise: planExercise)
            }
            .presentationDetents([.height(380)])
        }
    }
}

private struct TargetEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var planExercise: PlanExercise

    /// On: a range starting two above the bottom (8 → 8–10), a common double-progression spread.
    private var isRange: Binding<Bool> {
        Binding(
            get: { planExercise.targetRepsMax != nil },
            set: { planExercise.targetRepsMax = $0 ? planExercise.targetReps + 2 : nil }
        )
    }

    var body: some View {
        Form {
            Stepper("Sets: \(planExercise.targetSets)", value: $planExercise.targetSets, in: 1...10)
            Toggle("Rep Range", isOn: isRange)
            if let repsMax = planExercise.targetRepsMax {
                Stepper("From: \(planExercise.targetReps) reps", value: $planExercise.targetReps, in: 1...29)
                Stepper(
                    "To: \(repsMax) reps",
                    value: Binding(get: { repsMax }, set: { planExercise.targetRepsMax = $0 }),
                    in: (planExercise.targetReps + 1)...30
                )
            } else {
                Stepper("Reps: \(planExercise.targetReps)", value: $planExercise.targetReps, in: 1...30)
            }
        }
        // Keep the range the right way round when the bottom is stepped up past the top.
        .onChange(of: planExercise.targetReps) { _, reps in
            if let repsMax = planExercise.targetRepsMax, repsMax <= reps {
                planExercise.targetRepsMax = reps + 1
            }
        }
        .navigationTitle(planExercise.exercise?.name ?? "Sets & Reps")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
