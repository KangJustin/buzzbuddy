//
//  BuzzBuddyButton.swift
//  buzzbuddy
//

import SwiftUI

struct BuzzBuddyButton: View {
    enum Kind {
        case primary
        case secondary
        case tertiary
        case destructive
    }

    let title: String
    var systemImage: String? = nil
    var kind: Kind = .primary
    var fullWidth: Bool = true
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isInteractive: Bool { isEnabled && !isLoading }

    var body: some View {
        Button(action: action) {
            HStack(spacing: BuzzBuddyTheme.Spacing.sm) {
                if isLoading {
                    ProgressView().tint(foregroundColor)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(BuzzBuddyTheme.Typography.headline)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(minHeight: 44)
            .padding(.horizontal, BuzzBuddyTheme.Spacing.lg)
            .foregroundStyle(foregroundColor)
            .background(background)
            .clipShape(Capsule())
            .overlay(border)
        }
        .buttonStyle(PressableButtonStyle(reduceMotion: reduceMotion))
        .disabled(!isInteractive)
        .opacity(isInteractive ? 1 : 0.5)
    }

    @ViewBuilder private var background: some View {
        switch kind {
        case .primary:
            Capsule().fill(BuzzBuddyTheme.Colors.accentYellow)
        case .secondary:
            Capsule().fill(BuzzBuddyTheme.Colors.surfaceElevated2)
        case .tertiary:
            Color.clear
        case .destructive:
            Capsule().fill(StatusColorRole.red.color.opacity(0.16))
        }
    }

    @ViewBuilder private var border: some View {
        if kind == .secondary {
            Capsule().stroke(BuzzBuddyTheme.Colors.border, lineWidth: 1)
        }
    }

    /// Yellow is a bright/light color -- black foreground on it reads with far
    /// better contrast than white, so `.primary` deliberately uses black.
    private var foregroundColor: Color {
        switch kind {
        case .primary: return .black
        case .secondary: return BuzzBuddyTheme.Colors.textPrimary
        case .tertiary: return BuzzBuddyTheme.Colors.accentYellow
        case .destructive: return StatusColorRole.red.color
        }
    }
}

private struct PressableButtonStyle: ButtonStyle {
    let reduceMotion: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(BuzzBuddyTheme.Motion.respecting(reduceMotion, .easeOut(duration: 0.12)), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        BuzzBuddyButton(title: "Begin Safety Check", systemImage: "bolt.fill", kind: .primary) {}
        BuzzBuddyButton(title: "Pause Check", kind: .secondary) {}
        BuzzBuddyButton(title: "View Full Results", kind: .tertiary) {}
        BuzzBuddyButton(title: "Loading", kind: .primary, isLoading: true) {}
        BuzzBuddyButton(title: "Disabled", kind: .primary, isEnabled: false) {}
        BuzzBuddyButton(title: "Retest", kind: .secondary, fullWidth: false) {}
    }
    .padding()
    .background(BuzzBuddyTheme.Colors.background)
}
