//
//  BuzzBuddyTabBar.swift
//  buzzbuddy
//

import SwiftUI

enum BuzzBuddyTab: CaseIterable {
    case events, contacts, quiz, baseline, settings

    var icon: String {
        switch self {
        case .events: return "calendar"
        case .contacts: return "person.2.fill"
        case .quiz: return "bolt.fill"
        case .baseline: return "waveform.path.ecg"
        case .settings: return "gearshape.fill"
        }
    }

    var title: String {
        switch self {
        case .events: return "Events"
        case .contacts: return "Contacts"
        case .quiz: return "Check"
        case .baseline: return "Baseline"
        case .settings: return "Settings"
        }
    }
}

// MARK: - Tab bar height plumbing

private struct TabBarHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct TabBarHeightEnvironmentKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    /// The tab bar's measured content height (not the safe-area inset, just
    /// the visible bar row). Any screen can read this to pad bottom-pinned
    /// content so it clears the bar, without guessing a magic number.
    var tabBarHeight: CGFloat {
        get { self[TabBarHeightEnvironmentKey.self] }
        set { self[TabBarHeightEnvironmentKey.self] = newValue }
    }
}

// MARK: - Tab bar

struct BuzzBuddyTabBar: View {
    @Binding var selectedTab: BuzzBuddyTab
    var onHeightChange: (CGFloat) -> Void = { _ in }

    /// Everything else in the bar derives from this single anchor.
    private let barContentHeight: CGFloat = 64

    var body: some View {
        HStack(spacing: 0) {
            ForEach(BuzzBuddyTab.allCases, id: \.self) { tab in
                if tab == .quiz {
                    middleButton(for: tab)
                } else {
                    standardButton(for: tab)
                }
            }
        }
        .frame(height: barContentHeight)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: TabBarHeightPreferenceKey.self, value: geo.size.height)
            }
        )
        .background(BuzzBuddyTheme.Colors.surfaceElevated1, ignoresSafeAreaEdges: .bottom)
        .onPreferenceChange(TabBarHeightPreferenceKey.self, perform: onHeightChange)
    }

    private func standardButton(for tab: BuzzBuddyTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22))
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isSelected ? BuzzBuddyTheme.Colors.accentYellow : BuzzBuddyTheme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func middleButton(for tab: BuzzBuddyTab) -> some View {
        let circleDiameter = barContentHeight * 0.72
        let ringPadding = circleDiameter * 0.07
        let iconSize = circleDiameter * 0.44
        return Button {
            selectedTab = tab
        } label: {
            ZStack {
                Circle()
                    .stroke(BuzzBuddyTheme.Colors.accentYellow.opacity(0.25), lineWidth: ringPadding)
                    .frame(width: circleDiameter + ringPadding * 2, height: circleDiameter + ringPadding * 2)
                Circle()
                    .fill(BuzzBuddyTheme.Colors.accentYellow)
                    .frame(width: circleDiameter, height: circleDiameter)
                Image(systemName: tab.icon)
                    .font(.system(size: iconSize, weight: .semibold))
                    // Black, not white -- yellow is bright enough that white
                    // fails contrast; black reads far more clearly on it.
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        BuzzBuddyTheme.Colors.background.ignoresSafeArea()
        BuzzBuddyTabBar(selectedTab: .constant(.quiz))
    }
}
