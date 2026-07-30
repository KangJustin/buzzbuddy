//
//  SectionHeader.swift
//  buzzbuddy
//

import SwiftUI

struct SectionHeader: View {
    enum Style {
        case page      // large page title + optional subtitle
        case section   // small uppercase group label
    }

    let title: String
    var subtitle: String? = nil
    var style: Style = .page

    var body: some View {
        switch style {
        case .page:
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(BuzzBuddyTheme.Typography.largeTitle)
                    .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(BuzzBuddyTheme.Typography.subheadline)
                        .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                }
            }
        case .section:
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .tracking(0.8)
                .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
        }
    }
}

#Preview {
    ZStack {
        BuzzBuddyTheme.Colors.background.ignoresSafeArea()
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Your Baseline", subtitle: "Your typical performance when you feel normal and unimpaired.")
            SectionHeader(title: "Tests", style: .section)
        }
        .padding()
    }
}
