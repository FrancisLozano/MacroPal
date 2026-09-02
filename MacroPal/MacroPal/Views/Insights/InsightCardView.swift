//
//  InsightCardView.swift
//  MacroPal
//

import SwiftUI

struct InsightCardView: View {
    let insight: Insight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.category.systemImage)
                .foregroundStyle(severityColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(insight.category.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(insight.severity.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(severityColor.opacity(0.15))
                        .foregroundStyle(severityColor)
                        .clipShape(Capsule())
                }
                Text(insight.message)
                    .font(.subheadline)
                Text(insight.supportingMetric)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var severityColor: Color {
        switch insight.severity {
        case .info: .blue
        case .suggestion: .orange
        case .actionNeeded: .red
        }
    }
}

#Preview {
    List {
        InsightCardView(insight: Insight(
            dateGenerated: .now,
            category: .body,
            severity: .info,
            message: "You've gone quiet — no weigh-in in 6 days.",
            supportingMetric: "no weigh-in in 6 days",
            ruleIdentifier: .missedLoggingStreak
        ))
    }
}
