//
//  HomeView.swift
//  buzzbuddy
//
//  Created by Max DeWeese on 7/10/26.
//

import SwiftUI

struct HomeView: View {
    @State private var showSafetyCheck: Bool
    @StateObject private var lastCheckStore = LastCheckStore()

    // Debug-only screenshot helper: auto-presents the check-in cover when
    // AppState's matching BUZZBUDDY_DEBUG_PHASE seed is active, so the
    // reviewing/verdict screens are reachable without tapping the CTA.
    init() {
        #if DEBUG
        _showSafetyCheck = State(initialValue: ProcessInfo.processInfo.environment["BUZZBUDDY_DEBUG_PHASE"] != nil)
        #else
        _showSafetyCheck = State(initialValue: false)
        #endif
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BuzzBuddyTheme.Spacing.lg) {
                    header
                    safetyCheckCard
                    SafetyDisclaimerCard()
                    if let lastCheck = lastCheckStore.lastCheck {
                        lastCheckCard(lastCheck)
                    }
                }
                .padding(BuzzBuddyTheme.Spacing.md)
            }
            .background(BuzzBuddyTheme.Colors.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $showSafetyCheck) {
            NavigationStack {
                SafetyCheckFlowView()
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hey there")
                .font(.subheadline)
                .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
            Text("How are you feeling?")
                .font(BuzzBuddyTheme.Typography.largeTitle)
                .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
            Text("Run a quick check against your personal baseline.")
                .font(.subheadline)
                .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
        }
        .padding(.top, BuzzBuddyTheme.Spacing.md)
    }

    private var safetyCheckCard: some View {
        BuzzBuddyCard(elevated: true) {
            VStack(alignment: .leading, spacing: BuzzBuddyTheme.Spacing.md) {
                HStack {
                    Text("Safety Check")
                        .font(BuzzBuddyTheme.Typography.headline)
                        .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                    Spacer()
                    Label("~2 min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                }

                HStack(spacing: BuzzBuddyTheme.Spacing.md) {
                    testIndicator(icon: "bolt.fill", label: "Reaction")
                    testIndicator(icon: "figure.stand", label: "Balance")
                    testIndicator(icon: "brain.head.profile", label: "Memory")
                    testIndicator(icon: "figure.walk", label: "Walking")
                }

                BuzzBuddyButton(title: "Begin Safety Check", systemImage: "bolt.fill", kind: .primary) {
                    showSafetyCheck = true
                }
            }
        }
    }

    private func testIndicator(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(BuzzBuddyTheme.Colors.accentYellow)
                .frame(width: 40, height: 40)
                .background(Circle().fill(BuzzBuddyTheme.Colors.surfaceElevated2))
            Text(label)
                .font(.caption2)
                .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func lastCheckCard(_ lastCheck: LastCheck) -> some View {
        BuzzBuddyCard {
            HStack(spacing: BuzzBuddyTheme.Spacing.sm) {
                Image(systemName: lastCheck.category.iconSystemName)
                    .foregroundStyle(lastCheck.category.statusColorRole.color)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last check: \(lastCheck.category.title)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                    Text(relativeDateText(lastCheck.date))
                        .font(.caption)
                        .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                }
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func relativeDateText(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    HomeView()
}
