//
//  BuzzBuddyCard.swift
//  buzzbuddy
//

import SwiftUI

struct BuzzBuddyCard<Content: View>: View {
    var elevated: Bool = false
    var padding: CGFloat = BuzzBuddyTheme.Spacing.md
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: BuzzBuddyTheme.Radius.md, style: .continuous)
                    .fill(elevated ? BuzzBuddyTheme.Colors.surfaceElevated2 : BuzzBuddyTheme.Colors.surfaceElevated1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BuzzBuddyTheme.Radius.md, style: .continuous)
                    .stroke(BuzzBuddyTheme.Colors.border, lineWidth: 1)
            )
            .shadow(
                color: BuzzBuddyTheme.Shadow.subtle.color,
                radius: BuzzBuddyTheme.Shadow.subtle.radius,
                y: BuzzBuddyTheme.Shadow.subtle.y
            )
    }
}

#Preview {
    ZStack {
        BuzzBuddyTheme.Colors.background.ignoresSafeArea()
        VStack(spacing: 16) {
            BuzzBuddyCard {
                Text("Standard card").foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
            }
            BuzzBuddyCard(elevated: true) {
                Text("Elevated card").foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
            }
        }
        .padding()
    }
}
