//
//  RestTimerBar.swift
//  MacroPal
//

import SwiftUI

/// The running rest countdown, pinned above the tab bar on the workout screens: a card with
/// the time left in large type, "Next up" between exercises, a draining bar, and −15 s / +15 s
/// / Skip big enough to hit one-handed. `compact` shrinks it to one line while the keyboard is
/// up. Disappears when the rest is over, as the `RestOverCard` slides up in its place.
struct RestTimerBar: View {
    @Environment(RestTimerModel.self) private var restTimer

    var compact = false

    var body: some View {
        if let timer = restTimer.timer {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                if !timer.isFinished(at: context.date) {
                    Group {
                        if compact { compactBar(timer) } else { card(timer) }
                    }
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private func card(_ timer: RestTimer) -> some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label("Rest", systemImage: "timer")
                    .font(.headline)
                Spacer()
                if let nextUp = restTimer.nextUp {
                    Text("Next up: \(nextUp)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Text(timerInterval: Date.now...timer.endsAt, countsDown: true)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .monospacedDigit()
                .frame(maxWidth: .infinity)
            progress(timer)
            HStack(spacing: 10) {
                adjustButtons
                Button { restTimer.stop() } label: { wide("Skip") }
                    .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
        }
    }

    private func compactBar(_ timer: RestTimer) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                    Text("Rest")
                    Text(timerInterval: Date.now...timer.endsAt, countsDown: true)
                        .monospacedDigit()
                        .fontWeight(.semibold)
                }
                progress(timer)
            }
            adjustButtons
            Button("Skip") { restTimer.stop() }
                .buttonStyle(.borderedProminent)
        }
        .font(.subheadline)
    }

    @ViewBuilder
    private var adjustButtons: some View {
        Button { restTimer.adjust(by: -15) } label: { wide("−15s") }
            .buttonStyle(.bordered)
        Button { restTimer.adjust(by: 15) } label: { wide("+15s") }
            .buttonStyle(.bordered)
    }

    /// A button label that shares the card's width evenly; its natural size in the compact bar.
    private func wide(_ title: String) -> some View {
        Text(title).frame(maxWidth: compact ? nil : .infinity)
    }

    private func progress(_ timer: RestTimer) -> some View {
        ProgressView(timerInterval: timer.startedAt...timer.endsAt, countsDown: true) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
    }
}
