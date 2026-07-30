//
//  SettingsView.swift
//  buzzbuddy
//
//  Created by Max DeWeese on 7/10/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.tabBarHeight) private var tabBarHeight

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SectionHeader(title: "Settings")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, BuzzBuddyTheme.Spacing.lg)
                    .padding(.bottom, BuzzBuddyTheme.Spacing.md)
                    .padding(.horizontal, BuzzBuddyTheme.Spacing.md)

                ScrollView {
                    content
                        .padding(.horizontal, BuzzBuddyTheme.Spacing.md)
                        .padding(.top, BuzzBuddyTheme.Spacing.sm)
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            Color.clear.frame(height: tabBarHeight)
                        }
                }
            }
            .background(BuzzBuddyTheme.Colors.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: BuzzBuddyTheme.Spacing.lg) {
            sectionGroup(title: "Profile") {
                stepperRow(icon: "scalemass.fill", title: "Weight", value: settings.weight, unit: "kg") {
                    settings.weight -= 1
                } onIncrement: {
                    settings.weight += 1
                }
                stepperRow(icon: "ruler.fill", title: "Height", value: settings.height, unit: "cm") {
                    settings.height -= 1
                } onIncrement: {
                    settings.height += 1
                }
            }

            sectionGroup(title: "Notifications") {
                toggleRow(icon: "speaker.wave.2.fill", title: "Sound Effects", isOn: $settings.soundEffects)
            }

            sectionGroup(title: "Safety preferences") {
                toggleRow(
                    icon: "phone.fill",
                    title: "Automatically Call Emergency Contact",
                    isOn: $settings.enableAutoCallContact
                )
            }

            sectionGroup(title: "Data and privacy") {
                BuzzBuddyCard {
                    Text("BuzzBuddy stores your baseline test results and check-in history so it can compare future check-ins against your own personal baseline.")
                        .font(.footnote)
                        .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                }
            }

            sectionGroup(title: "About BuzzBuddy") {
                BuzzBuddyCard {
                    VStack(alignment: .leading, spacing: BuzzBuddyTheme.Spacing.sm) {
                        Text("Version \(appVersion)")
                            .font(.footnote)
                            .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                        SafetyDisclaimerCard()
                    }
                }
            }
        }
        .padding(.bottom, BuzzBuddyTheme.Spacing.lg)
    }

    // MARK: - Section Group

    private func sectionGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: BuzzBuddyTheme.Spacing.sm) {
            SectionHeader(title: title, style: .section)
                .padding(.leading, 4)

            VStack(spacing: BuzzBuddyTheme.Spacing.sm) {
                content()
            }
        }
    }

    // MARK: - Toggle Row

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        BuzzBuddyCard {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                    .frame(width: 20)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)

                Spacer()

                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(BuzzBuddyTheme.Colors.accentYellow)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Stepper Row

    private func stepperRow(
        icon: String,
        title: String,
        value: Int,
        unit: String,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) -> some View {
        BuzzBuddyCard {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                    .frame(width: 20)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)

                Spacer()

                Text("\(value) \(unit)")
                    .font(BuzzBuddyTheme.Typography.numeric(15, weight: .medium))
                    .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)

                HStack(spacing: 0) {
                    Button(action: onDecrement) {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Decrease \(title)")

                    Divider()
                        .overlay(BuzzBuddyTheme.Colors.border)
                        .frame(height: 16)

                    Button(action: onIncrement) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Increase \(title)")
                }
                .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                .background(
                    RoundedRectangle(cornerRadius: BuzzBuddyTheme.Radius.sm)
                        .fill(BuzzBuddyTheme.Colors.surfaceElevated2)
                )
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
}
