//
//  SafetyDisclaimerCard.swift
//  buzzbuddy
//

import SwiftUI

struct SafetyDisclaimerCard: View {
    var body: some View {
        BuzzBuddyCard {
            HStack(alignment: .top, spacing: BuzzBuddyTheme.Spacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                    .accessibilityHidden(true)
                Text("BuzzBuddy does not measure blood alcohol concentration, determine sobriety, or tell you whether it is safe or legal to drive. When in doubt, choose another way home.")
                    .font(.footnote)
                    .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
            }
        }
    }
}

#Preview {
    ZStack {
        BuzzBuddyTheme.Colors.background.ignoresSafeArea()
        SafetyDisclaimerCard().padding()
    }
}
