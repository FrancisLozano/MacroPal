//
//  InsightCallout.swift
//  MacroPal
//

import SwiftUI

/// One rule finding shown inline where it's relevant: a one-line headline with an info
/// button. Tapping it opens the recommendation and where it comes from — the numbers it's
/// based on and the rule that produced it. Replaces the old Insights tab.
struct InsightCallout: View {
    let finding: InsightFinding

    @State private var isShowingDetail = false

    private var icon: String {
        finding.ruleIdentifier == .goalWeightReached ? "flag.checkered" : "lightbulb.fill"
    }

    private var tint: Color {
        finding.ruleIdentifier == .goalWeightReached ? .green : .orange
    }

    var body: some View {
        Button {
            isShowingDetail = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                Text(finding.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.accentColor)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Shows the recommendation and where it comes from")
        .sheet(isPresented: $isShowingDetail) {
            NavigationStack {
                detail
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var detail: some View {
        List {
            Section {
                Text(finding.message)
            }
            Section("Where this comes from") {
                Text(finding.supportingMetric)
                    .fontWeight(.medium)
                Text(finding.ruleIdentifier.explanation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(finding.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { isShowingDetail = false }
            }
        }
    }
}

#Preview {
    InsightCallout(finding: InsightFinding(
        category: .nutrition,
        severity: .suggestion,
        message: "You've been under-eating protein — averaging 96g/day against a 150g target.",
        supportingMetric: "7-day avg protein: 96g (64% of 150g target)",
        ruleIdentifier: .underEatingProtein
    ))
    .padding()
}
