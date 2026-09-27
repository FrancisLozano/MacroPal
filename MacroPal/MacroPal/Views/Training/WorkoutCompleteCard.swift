//
//  WorkoutCompleteCard.swift
//  MacroPal
//

import SwiftUI

/// Shown on a plan day's list once its last exercise is done, in place of a rest: what the
/// workout added up to — exercises, sets and volume. Stays until Done.
struct WorkoutCompleteCard: View {
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .lb

    let exercises: Int
    let sets: Int
    let volumeKg: Double
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("Workout Complete")
                    .font(.title3.bold())
                Spacer(minLength: 0)
            }
            HStack {
                stat("\(exercises)", exercises == 1 ? "exercise" : "exercises")
                stat("\(sets)", sets == 1 ? "set" : "sets")
                stat(unit.fromKg(volumeKg).formatted(.number.precision(.fractionLength(0))), "\(unit.symbol) moved")
            }
            Button(action: onDone) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 2)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    Color.clear
        .safeAreaInset(edge: .bottom) {
            WorkoutCompleteCard(exercises: 5, sets: 15, volumeKg: 6_200) {}
        }
}
