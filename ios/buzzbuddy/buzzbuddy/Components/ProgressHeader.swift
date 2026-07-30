//
//  ProgressHeader.swift
//  buzzbuddy
//

import SwiftUI

struct ProgressHeader: View {
    let step: Int
    let totalSteps: Int
    let currentIcon: String
    let currentLabel: String

    private var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(step) / Double(totalSteps)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BuzzBuddyTheme.Spacing.sm) {
            Text("Step \(step) of \(totalSteps)")
                .font(BuzzBuddyTheme.Typography.caption)
                .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(BuzzBuddyTheme.Colors.surfaceElevated2)
                    Capsule()
                        .fill(BuzzBuddyTheme.Colors.accentYellow)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 4)

            HStack(spacing: BuzzBuddyTheme.Spacing.xs) {
                Image(systemName: currentIcon)
                Text(currentLabel)
                    .font(BuzzBuddyTheme.Typography.headline)
            }
            .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(step) of \(totalSteps): \(currentLabel)")
    }
}

#Preview {
    ZStack {
        BuzzBuddyTheme.Colors.background.ignoresSafeArea()
        ProgressHeader(step: 2, totalSteps: 4, currentIcon: "figure.stand", currentLabel: "Balance")
            .padding()
    }
}
