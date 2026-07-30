//
//  Theme.swift
//  buzzbuddy
//
//  Created by Max DeWeese on 7/10/26.
//

import SwiftUI

enum BuzzBuddyTheme {

    enum Colors {
        static let background = Color(hex: 0x090A0D)
        static let surfaceElevated1 = Color(hex: 0x15171C)
        static let surfaceElevated2 = Color(hex: 0x1C1F25)
        static let border = Color.white.opacity(0.08)

        static let accentYellow = Color(hex: 0xFFD21C)
        static let accentAmber = Color(hex: 0xFFB800)

        static let textPrimary = Color.white.opacity(0.95)
        static let textSecondary = Color.white.opacity(0.6)

        static let statusGreen = Color(hex: 0x34C759)
        static let statusAmber = accentAmber
        static let statusRed = Color(hex: 0xFF453A)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 22
        static let pill: CGFloat = 999
    }

    enum Typography {
        static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
        static let title = Font.system(.title2, design: .rounded, weight: .bold)
        static let headline = Font.system(.headline, design: .default, weight: .semibold)
        static let body = Font.system(.body, design: .default)
        static let subheadline = Font.system(.subheadline, design: .default)
        static let caption = Font.system(.caption, design: .default, weight: .semibold)

        /// For measurements, percentages, and timers only -- never prose.
        static func numeric(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
            .system(size: size, weight: weight, design: .rounded).monospacedDigit()
        }
    }

    enum Shadow {
        static let soft = (color: Color.black.opacity(0.35), radius: CGFloat(16), y: CGFloat(6))
        static let subtle = (color: Color.black.opacity(0.25), radius: CGFloat(8), y: CGFloat(3))
    }

    enum Motion {
        static let quick = Animation.easeOut(duration: 0.18)
        static let standard = Animation.easeInOut(duration: 0.28)
        static let spring = Animation.spring(response: 0.35, dampingFraction: 0.75)

        /// Returns `nil` (no animation) when Reduce Motion is on, so callers write
        /// `withAnimation(Motion.respecting(reduceMotion, .standard)) { ... }` once
        /// instead of branching on the environment value at every call site.
        static func respecting(_ reduceMotion: Bool, _ animation: Animation) -> Animation? {
            reduceMotion ? nil : animation
        }
    }
}

/// What a status/verdict category means, decoupled from any specific screen.
/// The single place status meaning maps to a color (and default icon) -- every
/// status-bearing view should go through this rather than picking colors ad
/// hoc, so "never convey meaning through color alone" holds structurally.
enum StatusColorRole {
    case green
    case amber
    case red
    case neutral

    var color: Color {
        switch self {
        case .green: return BuzzBuddyTheme.Colors.statusGreen
        case .amber: return BuzzBuddyTheme.Colors.statusAmber
        case .red: return BuzzBuddyTheme.Colors.statusRed
        case .neutral: return BuzzBuddyTheme.Colors.textSecondary
        }
    }

    var defaultIconSystemName: String {
        switch self {
        case .green: return "checkmark.seal.fill"
        case .amber: return "exclamationmark.triangle.fill"
        case .red: return "exclamationmark.octagon.fill"
        case .neutral: return "questionmark.circle.fill"
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
