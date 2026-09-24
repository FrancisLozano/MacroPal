//
//  RestTimerBar.swift
//  MacroPal
//

import SwiftUI

/// The running rest countdown, pinned above the tab bar on the workout screens: time left,
/// a draining bar, −15 s / +15 s and Skip. Disappears when the rest is over, as the
/// `RestOverCard` slides up in its place.
struct RestTimerBar: View {
    @Environment(RestTimerModel.self) private var restTimer

    var body: some View {
        if let timer = restTimer.timer {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                if !timer.isFinished(at: context.date) {
                    bar(timer)
                }
            }
        }
    }

    private func bar(_ timer: RestTimer) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                    Text("Rest")
                    Text(timerInterval: Date.now...timer.endsAt, countsDown: true)
                        .monospacedDigit()
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                ProgressView(timerInterval: timer.startedAt...timer.endsAt, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            }
            Button("−15s") { restTimer.adjust(by: -15) }
                .buttonStyle(.bordered)
            Button("+15s") { restTimer.adjust(by: 15) }
                .buttonStyle(.bordered)
            Button("Skip") { restTimer.stop() }
                .buttonStyle(.borderedProminent)
        }
        .font(.subheadline)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
