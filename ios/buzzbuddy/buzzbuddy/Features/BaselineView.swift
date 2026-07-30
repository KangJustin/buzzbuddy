//
//  BaselineView.swift
//  buzzbuddy
//
//  Created by Max DeWeese on 7/11/26.
//

import SwiftUI

/// The one page for everything about the user while sober: their profile
/// (name/weight/height/DD contact) and their sober baseline test results.
/// Unlike a check-in, this never gates the rest of the app -- a user can
/// navigate to Events, Contacts, etc. with any (or none) of this set, and
/// come back here later. Profile setup used to be a separate onboarding
/// screen and baseline capture used separate test views from the real
/// AI-requested tests; both are consolidated here so there's a single
/// source of truth and the baseline is measured with the same games used
/// for the real check-in.
struct BaselineView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.tabBarHeight) private var tabBarHeight

    // Profile fields -- only relevant before onboarding is complete.
    @State private var name = ""
    @State private var weightLbs = ""
    @State private var heightFeet = ""
    @State private var heightInches = ""
    @State private var ddName = ""
    @State private var ddPhone = ""

    @State private var showReactionBaselineTest = false
    @State private var showGyroBaselineTest = false
    @State private var showMemoryBaselineTest = false
    @State private var showGaitBaselineTest = false

    // Locally captured values not yet confirmed to exist server-side --
    // only used during first-ever capture, when the backend requires all
    // three fields in a single call (its Baseline row can't be created
    // partially, since the columns are non-nullable). Once a baseline
    // exists server-side, edits submit immediately as independent partial
    // updates (retests).
    @State private var pendingReactionMs: Double?
    @State private var pendingGyroScore: Double?
    @State private var pendingMemoryPercent: Double?

    private var needsProfile: Bool {
        if case .onboarding = appState.phase { return true }
        return false
    }

    private var hasServerBaseline: Bool {
        appState.reactionBaselineMs != nil
            || appState.gyroBaselineScore != nil
            || appState.memoryBaselinePercent != nil
    }

    private var displayedReactionMs: Double? { appState.reactionBaselineMs ?? pendingReactionMs }
    private var displayedGyroScore: Double? { appState.gyroBaselineScore ?? pendingGyroScore }
    private var displayedMemoryPercent: Double? { appState.memoryBaselinePercent ?? pendingMemoryPercent }
    private var displayedGaitScore: Double? { appState.gaitBaselineScore }

    /// Out of the 4 tests shown on this screen -- real count, nothing inferred.
    private var completedMetricsCount: Int {
        [displayedReactionMs, displayedGyroScore, displayedMemoryPercent, displayedGaitScore]
            .compactMap { $0 }
            .count
    }

    private var canSubmitProfile: Bool {
        OnboardingValidation.isNonEmpty(name)
            && OnboardingValidation.isValidWeightLbs(weightLbs)
            && OnboardingValidation.isValidHeight(feet: heightFeet, inches: heightInches)
            && OnboardingValidation.isNonEmpty(ddName)
            && OnboardingValidation.isNonEmpty(ddPhone)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SectionHeader(
                    title: "Baseline",
                    subtitle: needsProfile
                        ? "Set up your profile to get started."
                        : "Your typical performance when you feel normal and unimpaired."
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, BuzzBuddyTheme.Spacing.lg)
                .padding(.bottom, BuzzBuddyTheme.Spacing.md)
                .padding(.horizontal, BuzzBuddyTheme.Spacing.md)

                ScrollView {
                    content
                        .padding(.horizontal, BuzzBuddyTheme.Spacing.md)
                        .padding(.top, BuzzBuddyTheme.Spacing.sm)
                        .padding(.bottom, BuzzBuddyTheme.Spacing.lg)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: tabBarHeight)
                }
            }
            .background(BuzzBuddyTheme.Colors.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showReactionBaselineTest) {
            ReactionGame { ms in
                showReactionBaselineTest = false
                capture(reactionMs: Double(ms))
            }
        }
        .sheet(isPresented: $showGyroBaselineTest) {
            GyroBalanceTestView { score in
                showGyroBaselineTest = false
                capture(gyroScore: score)
            }
        }
        .sheet(isPresented: $showMemoryBaselineTest) {
            MemoryGame { accuracy in
                showMemoryBaselineTest = false
                capture(memoryPercent: Double(accuracy))
            }
        }
        .sheet(isPresented: $showGaitBaselineTest) {
            GaitTestView { score in
                showGaitBaselineTest = false
                Task { await appState.updateBaseline(gaitBaselineScore: score) }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if needsProfile {
            profileContent
        } else {
            baselineContent
        }
    }

    // MARK: - Profile (onboarding)

    private var profileContent: some View {
        VStack(alignment: .leading, spacing: BuzzBuddyTheme.Spacing.lg) {
            sectionGroup(title: "About you") {
                formField(icon: "person.fill", text: $name, placeholder: "Name")
                formField(icon: "scalemass.fill", text: $weightLbs, placeholder: "Weight (lbs)", keyboardType: .decimalPad)
                heightField
            }

            sectionGroup(title: "Designated driver") {
                formField(icon: "person.crop.circle", text: $ddName, placeholder: "Name")
                formField(icon: "phone.fill", text: $ddPhone, placeholder: "Phone", keyboardType: .phonePad)
            }

            if let error = appState.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(StatusColorRole.red.color)
                    .padding(.leading, 4)
            }

            saveProfileButton
        }
    }

    private var heightField: some View {
        BuzzBuddyCard {
            HStack(spacing: 10) {
                Image(systemName: "ruler.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)

                TextField("Height (ft)", text: $heightFeet)
                    .font(.system(size: 16))
                    .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                    .keyboardType(.numberPad)

                Divider()
                    .overlay(BuzzBuddyTheme.Colors.border)
                    .frame(height: 18)

                TextField("Height (in)", text: $heightInches)
                    .font(.system(size: 16))
                    .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                    .keyboardType(.numberPad)
            }
        }
    }

    private var saveProfileButton: some View {
        BuzzBuddyButton(
            title: appState.isLoading ? "Saving..." : "Save profile",
            kind: .primary,
            isLoading: appState.isLoading,
            isEnabled: canSubmitProfile,
            action: submitProfile
        )
        .padding(.top, BuzzBuddyTheme.Spacing.xs)
    }

    // MARK: - Baseline tests

    private var baselineContent: some View {
        VStack(alignment: .leading, spacing: BuzzBuddyTheme.Spacing.lg) {
            readinessCard

            sectionGroup(title: "Tests") {
                MetricCard(
                    icon: "bolt.fill",
                    title: "Reaction",
                    value: displayedReactionMs.map { "\(Int($0)) ms" },
                    detail: displayedReactionMs != nil ? "Retest to update this value" : nil,
                    isRetest: displayedReactionMs != nil
                ) {
                    showReactionBaselineTest = true
                }
                MetricCard(
                    icon: "figure.stand",
                    title: "Balance",
                    value: displayedGyroScore.map { String(format: "%.2f", $0) },
                    detail: displayedGyroScore != nil ? "Retest to update this value" : nil,
                    isRetest: displayedGyroScore != nil
                ) {
                    showGyroBaselineTest = true
                }
                MetricCard(
                    icon: "brain.head.profile",
                    title: "Memory",
                    value: displayedMemoryPercent.map { "\(Int($0))% accurate" },
                    detail: displayedMemoryPercent != nil ? "Retest to update this value" : nil,
                    isRetest: displayedMemoryPercent != nil
                ) {
                    showMemoryBaselineTest = true
                }
                MetricCard(
                    icon: "figure.walk",
                    title: "Walking",
                    value: displayedGaitScore.map { String(format: "%.2f", $0) },
                    detail: displayedGaitScore != nil ? "Retest to update this value" : nil,
                    isRetest: displayedGaitScore != nil
                ) {
                    showGaitBaselineTest = true
                }
            }

            if !hasServerBaseline
                && (pendingReactionMs != nil || pendingGyroScore != nil || pendingMemoryPercent != nil) {
                Text("All three are needed before your baseline is saved.")
                    .font(.footnote)
                    .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                    .padding(.leading, 4)
            }

            if let error = appState.baselineErrorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(StatusColorRole.red.color)
                    .padding(.leading, 4)
            }
        }
    }

    private var readinessCard: some View {
        BuzzBuddyCard(elevated: true) {
            HStack(spacing: BuzzBuddyTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .stroke(BuzzBuddyTheme.Colors.surfaceElevated2, lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: CGFloat(completedMetricsCount) / 4)
                        .stroke(BuzzBuddyTheme.Colors.accentYellow, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(completedMetricsCount)/4")
                        .font(BuzzBuddyTheme.Typography.numeric(13, weight: .semibold))
                        .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                }
                .frame(width: 48, height: 48)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Baseline readiness")
                        .font(BuzzBuddyTheme.Typography.headline)
                        .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                    Text(completedMetricsCount == 4 ? "All set." : "\(completedMetricsCount) of 4 tests recorded.")
                        .font(.caption)
                        .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                }

                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Baseline readiness: \(completedMetricsCount) of 4 tests recorded")
    }

    // MARK: - Shared row builders

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

    private func formField(
        icon: String,
        text: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        BuzzBuddyCard {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)

                TextField(placeholder, text: text)
                    .font(.system(size: 16))
                    .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                    .keyboardType(keyboardType)
            }
        }
    }

    // MARK: - Actions

    private func submitProfile() {
        guard OnboardingValidation.isValidWeightLbs(weightLbs),
              OnboardingValidation.isValidHeight(feet: heightFeet, inches: heightInches),
              let weightLbsValue = Double(weightLbs),
              let heightInValue = OnboardingValidation.totalHeightInches(feet: heightFeet, inches: heightInches)
        else { return }

        let weightKg = weightLbsValue * 0.453592
        let heightCm = heightInValue * 2.54
        let bmi = weightKg / pow(heightCm / 100, 2)

        Task {
            await appState.completeOnboarding(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                weightKg: weightKg,
                heightCm: heightCm,
                bmi: bmi,
                ddName: ddName.trimmingCharacters(in: .whitespacesAndNewlines),
                ddPhone: ddPhone.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
    }

    /// Retests (a baseline already exists server-side) submit immediately
    /// as a partial update. First-ever captures accumulate locally and
    /// only submit once all three are present, since the backend can't
    /// create a partial Baseline row.
    private func capture(reactionMs: Double? = nil, gyroScore: Double? = nil, memoryPercent: Double? = nil) {
        if hasServerBaseline {
            Task {
                await appState.updateBaseline(
                    reactionBaselineMs: reactionMs,
                    gyroBaselineScore: gyroScore,
                    memoryBaselinePercent: memoryPercent
                )
            }
            return
        }

        if let reactionMs { pendingReactionMs = reactionMs }
        if let gyroScore { pendingGyroScore = gyroScore }
        if let memoryPercent { pendingMemoryPercent = memoryPercent }

        guard let reaction = pendingReactionMs,
              let gyro = pendingGyroScore,
              let memory = pendingMemoryPercent
        else { return }

        Task {
            await appState.updateBaseline(
                reactionBaselineMs: reaction,
                gyroBaselineScore: gyro,
                memoryBaselinePercent: memory
            )
        }
    }
}

#Preview {
    BaselineView().environmentObject(AppState())
}
