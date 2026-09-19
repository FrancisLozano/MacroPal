//
//  PlanExerciseRow.swift
//  MacroPal
//

import SwiftUI

/// One exercise in a plan day: thumbnail, name, and a "3 sets x 10 reps" chip. Tapping opens
/// set tracking; the ellipsis menu edits the target or removes it from the plan.
struct PlanExerciseRow: View {
    let planExercise: PlanExercise
    let setsLoggedToday: Int
    let onRemove: () -> Void

    @State private var isPresentingTargetEditor = false

    private var isComplete: Bool {
        setsLoggedToday >= planExercise.targetSets
    }

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink {
                ExerciseTrackView(planExercise: planExercise)
            } label: {
                HStack(spacing: 12) {
                    ExerciseThumbnail(exercise: planExercise.exercise)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(planExercise.exercise?.name ?? "Unknown exercise")
                            .font(.headline)
                            .multilineTextAlignment(.leading)
                        HStack(spacing: 6) {
                            Text("\(planExercise.targetSets) sets x \(planExercise.targetReps) reps")
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
            .presentationDetents([.height(260)])
        }
    }
}

private struct TargetEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var planExercise: PlanExercise

    var body: some View {
        Form {
            Stepper("Sets: \(planExercise.targetSets)", value: $planExercise.targetSets, in: 1...10)
            Stepper("Reps: \(planExercise.targetReps)", value: $planExercise.targetReps, in: 1...30)
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
