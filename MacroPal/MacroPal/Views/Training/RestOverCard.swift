//
//  RestOverCard.swift
//  MacroPal
//

import SwiftUI

/// The in-app "Rest over" pop-up: slides up from the bottom, just above the tab bar, when a
/// rest ends with the app open (`RootView` buzzes once), and slides away after a few seconds
/// or when tapped or swiped down. In the background the system banner says it instead.
struct RestOverCard: View {
    static let visibleDuration: Duration = .seconds(4)

    @Environment(RestTimerModel.self) private var restTimer

    var body: some View {
        ZStack {
            if let finishedAt = restTimer.finishedAt {
                card
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task(id: finishedAt) {
                        try? await Task.sleep(for: Self.visibleDuration)
                        guard !Task.isCancelled else { return }
                        restTimer.dismissFinished()
                    }
            }
        }
        .animation(.spring(duration: 0.35), value: restTimer.finishedAt)
    }

    private var card: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Rest over")
                    .font(.headline)
                Text("Time for your next set.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .contentShape(Rectangle())
        .onTapGesture { restTimer.dismissFinished() }
        .gesture(
            DragGesture(minimumDistance: 10).onEnded { value in
                if value.translation.height > 20 { restTimer.dismissFinished() }
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Dismisses")
    }
}

extension View {
    /// Shows the "Rest over" card at the bottom of this screen when a rest ends.
    func restOverCard() -> some View {
        overlay(alignment: .bottom) { RestOverCard() }
    }
}
