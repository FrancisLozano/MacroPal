//
//  ExerciseOverviewTab.swift
//  MacroPal
//

import SwiftUI

/// The exercise screen's Overview tab: Muscles Involved — a body figure with the worked
/// muscles highlighted (primary solid, secondary light, as on the exercise thumbnail), the
/// Primary / Secondary muscles by name beside it, and Flip View under it for the other side.
/// Opens on the side where most of the primary muscles are. Below it, How to Do It and Common
/// Mistakes (each with its fix) from `ExerciseGuides`, for the starter exercises. No exercise
/// media for now (no licensed source).
struct ExerciseOverviewTab: View {
    let exercise: Exercise

    @State private var side: BodySide?

    private var profile: ExerciseProfile {
        ExerciseMuscleData.profile(forName: exercise.name, group: exercise.muscleGroup)
    }

    /// The side showing more of the primary muscles; front on a tie.
    private var startingSide: BodySide {
        let primary = profile.primaryMuscles
        let back = BodyFigure.muscles(on: .back)
        let front = BodyFigure.muscles(on: .front)
        let backOnly = primary.filter { back.contains($0) && !front.contains($0) }.count
        let frontOnly = primary.filter { front.contains($0) && !back.contains($0) }.count
        return backOnly > frontOnly ? .back : .front
    }

    var body: some View {
        let shownSide = side ?? startingSide
        ScrollView {
            VStack(spacing: 20) {
                TrainingSection("Muscles Involved") {
                    VStack(spacing: 16) {
                        HStack(alignment: .center, spacing: 16) {
                            BodyFigure(side: shownSide, colors: ExerciseThumbnail.colors(for: profile))
                                .frame(width: 140, height: 280)
                                .id(shownSide)
                                .transition(.opacity)
                                .accessibilityLabel(shownSide == .front ? "Front view" : "Back view")

                            VStack(alignment: .leading, spacing: 20) {
                                muscleList("Primary", profile.primaryMuscles, color: ExerciseThumbnail.primaryColor)
                                muscleList("Secondary", profile.secondaryMuscles, color: ExerciseThumbnail.secondaryColor)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                side = shownSide == .front ? .back : .front
                            }
                        } label: {
                            Label("Flip View", systemImage: "arrow.left.arrow.right")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                        .frame(width: 140)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }

                if let guide = ExerciseGuides.guide(forName: exercise.name) {
                    TrainingSection("How to Do It") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .firstTextBaseline, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(Color.accentColor)
                                        .frame(width: 16, alignment: .trailing)
                                    Text(step)
                                        .font(.subheadline)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding()
                    }

                    TrainingSection("Common Mistakes") {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(guide.mistakes.enumerated()), id: \.offset) { index, item in
                                if index > 0 {
                                    Rectangle()
                                        .fill(Color(.separator))
                                        .frame(height: 1)
                                        .padding(.vertical, 12)
                                }
                                mistakeRow(item)
                            }
                        }
                        .padding()
                    }
                } else {
                    Text("There's no how-to for exercises you've added yourself.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, 4)
            .padding(.bottom)
        }
    }

    /// What goes wrong, then how to fix it.
    private func mistakeRow(_ item: ExerciseGuide.Mistake) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(item.mistake)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
            Label {
                Text(item.fix)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    private func muscleList(_ title: String, _ muscles: [Muscle], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            if muscles.isEmpty {
                Text("None")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(muscles) { muscle in
                    Text(muscle.displayName)
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ExerciseOverviewTab(exercise: Exercise(name: "Deadlift", muscleGroup: .back, equipment: "Barbell"))
        .background(Color(.systemGroupedBackground))
}
