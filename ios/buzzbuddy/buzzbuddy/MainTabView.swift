//
//  MainTabView.swift
//  buzzbuddy
//
//  Created by Max DeWeese on 7/10/26.
//

import SwiftUI

// Tab bar height plumbing (TabBarHeightPreferenceKey, TabBarHeightEnvironmentKey,
// EnvironmentValues.tabBarHeight) now lives in Components/BuzzBuddyTabBar.swift,
// alongside the BuzzBuddyTab enum and the tab bar itself.

struct MainTabView: View {

    @State private var selectedTab: BuzzBuddyTab
    @State private var tabBarHeight: CGFloat = 0

    // Debug-only screenshot helper: BUZZBUDDY_INITIAL_TAB lets a launch
    // environment variable pick the starting tab, so screenshots of each
    // tab can be scripted without simulating taps. No-op in normal use.
    init() {
        #if DEBUG
        switch ProcessInfo.processInfo.environment["BUZZBUDDY_INITIAL_TAB"] {
        case "contacts": _selectedTab = State(initialValue: .contacts)
        case "quiz": _selectedTab = State(initialValue: .quiz)
        case "baseline": _selectedTab = State(initialValue: .baseline)
        case "settings": _selectedTab = State(initialValue: .settings)
        default: _selectedTab = State(initialValue: .events)
        }
        #else
        _selectedTab = State(initialValue: .events)
        #endif
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .events:
                    EventsView()
                case .contacts:
                    ContactsView()
                case .quiz:
                    HomeView()
                case .baseline:
                    BaselineView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(\.tabBarHeight, tabBarHeight)

            BuzzBuddyTabBar(selectedTab: $selectedTab) { height in
                tabBarHeight = height
            }
        }
        .background(BuzzBuddyTheme.Colors.background.ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#Preview {
    MainTabView()
}
