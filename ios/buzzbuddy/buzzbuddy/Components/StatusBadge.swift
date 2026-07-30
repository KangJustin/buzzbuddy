//
//  StatusBadge.swift
//  buzzbuddy
//

import SwiftUI

/// SwiftUI-facing color for a `VerdictCategory` -- kept here rather than on the
/// pure `Core/VerdictPresentation.swift` type, so that file stays Foundation-only
/// and unit-testable without a view hierarchy.
extension VerdictCategory {
    var statusColorRole: StatusColorRole {
        switch self {
        case .closeToBaseline: return .green
        case .someChangesDetected: return .amber
        case .significantChangesDetected: return .red
        case .unableToDetermine: return .neutral
        }
    }
}

/// Always renders an icon alongside the color -- status is never conveyed by
/// color alone.
struct StatusBadge: View {
    let label: String
    let role: StatusColorRole
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: BuzzBuddyTheme.Spacing.xs) {
            Image(systemName: systemImage ?? role.defaultIconSystemName)
            Text(label)
                .font(BuzzBuddyTheme.Typography.caption)
        }
        .foregroundStyle(role.color)
        .padding(.horizontal, BuzzBuddyTheme.Spacing.sm)
        .padding(.vertical, BuzzBuddyTheme.Spacing.xs)
        .background(Capsule().fill(role.color.opacity(0.14)))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusBadge(label: "Close to Baseline", role: .green)
        StatusBadge(label: "Some Changes", role: .amber)
        StatusBadge(label: "Significant Changes", role: .red)
        StatusBadge(label: "Unable to Determine", role: .neutral)
    }
    .padding()
    .background(BuzzBuddyTheme.Colors.background)
}
