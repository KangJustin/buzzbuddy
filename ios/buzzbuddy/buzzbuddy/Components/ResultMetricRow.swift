//
//  ResultMetricRow.swift
//  buzzbuddy
//

import SwiftUI

struct ResultMetricRow: View {
    let icon: String
    let title: String
    let detail: String
    var role: StatusColorRole = .neutral

    var body: some View {
        HStack(spacing: BuzzBuddyTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                .frame(width: 22)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(BuzzBuddyTheme.Typography.headline)
                    .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: role.defaultIconSystemName)
                .foregroundStyle(role.color)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        BuzzBuddyTheme.Colors.background.ignoresSafeArea()
        BuzzBuddyCard {
            VStack(spacing: 14) {
                ResultMetricRow(icon: "bolt.fill", title: "Reaction", detail: "11.7% faster than baseline", role: .green)
                ResultMetricRow(icon: "figure.stand", title: "Balance", detail: "Close to baseline", role: .green)
            }
        }
        .padding()
    }
}
