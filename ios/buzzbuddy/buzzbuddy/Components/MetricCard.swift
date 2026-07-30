//
//  MetricCard.swift
//  buzzbuddy
//

import SwiftUI

/// One baseline metric (reaction / balance / memory / walking). Shows only the
/// current value -- only ever one value is stored per metric, so no trend or
/// history is fabricated; `detail` is honest static copy, not a computed trend.
struct MetricCard: View {
    let icon: String
    let title: String
    let value: String?
    var detail: String? = nil
    let isRetest: Bool
    let action: () -> Void

    var body: some View {
        BuzzBuddyCard {
            HStack(spacing: BuzzBuddyTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(BuzzBuddyTheme.Colors.accentYellow)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(BuzzBuddyTheme.Typography.headline)
                        .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                    Text(value ?? "Not yet measured")
                        .font(BuzzBuddyTheme.Typography.numeric(15, weight: .medium))
                        .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                    if let detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                    }
                }

                Spacer(minLength: BuzzBuddyTheme.Spacing.sm)

                BuzzBuddyButton(title: isRetest ? "Retest" : "Run test", kind: .secondary, fullWidth: false, action: action)
            }
        }
    }
}

#Preview {
    ZStack {
        BuzzBuddyTheme.Colors.background.ignoresSafeArea()
        VStack(spacing: 12) {
            MetricCard(icon: "bolt.fill", title: "Reaction Time", value: "715 ms", detail: "Retest to update this value", isRetest: true) {}
            MetricCard(icon: "figure.walk", title: "Walking", value: nil, isRetest: false) {}
        }
        .padding()
    }
}
