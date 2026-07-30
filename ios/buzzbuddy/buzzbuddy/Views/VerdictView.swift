import SwiftUI

struct VerdictView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var eventStore = EventStore.shared
    @State private var showDDCompanionPreview = false
    @State private var iconAppeared = false

    /// This check-in's rounds, in order -- powers the results-summary list.
    /// Local/ephemeral, threaded down from `SafetyCheckFlowView` (see
    /// `TestRunEntry`), since `SessionOut` has no structured per-test array.
    let runLog: [TestRunEntry]

    /// The closest real proxy for "a trusted contact for tonight": the most
    /// recently saved Events-tab entry with a contact attached. This is a
    /// different, purely local feature from the backend check-in session --
    /// there's no real ID linkage between the two -- so this is a deliberate
    /// best-effort repurposing, not an exact match to "tonight's" event.
    private var trustedContact: Contact? {
        eventStore.events.last(where: { $0.contact?.phoneNumber != nil })?.contact
    }

    private var category: VerdictCategory? {
        appState.session.map { VerdictCategory(backendStatus: $0.status) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BuzzBuddyTheme.Spacing.lg) {
                if let session = appState.session, let category {
                    statusHeader(category)

                    if let summary = session.finalSummary, !summary.isEmpty {
                        BuzzBuddyCard(elevated: true) {
                            Text(summary)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                        }
                    }

                    if !runLog.isEmpty {
                        resultsSummary
                    }

                    DisclosureGroup("How this was determined") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(session.reasoningLog, id: \.self) { line in
                                Text("• \(line)")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                    }
                    .font(BuzzBuddyTheme.Typography.headline)
                    .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                    .tint(BuzzBuddyTheme.Colors.accentYellow)

                    SafetyDisclaimerCard()

                    actions(category: category, session: session)
                }
            }
            .padding(BuzzBuddyTheme.Spacing.md)
        }
        .background(BuzzBuddyTheme.Colors.background.ignoresSafeArea())
        .onAppear {
            withAnimation(BuzzBuddyTheme.Motion.respecting(reduceMotion, BuzzBuddyTheme.Motion.spring)) {
                iconAppeared = true
            }
            if let session = appState.session {
                LastCheckStore().record(backendStatus: session.status)
            }
        }
        .sheet(isPresented: $showDDCompanionPreview) {
            if let sessionId = appState.session?.id {
                DDCompanionPreviewView(sessionId: sessionId)
            }
        }
    }

    private func statusHeader(_ category: VerdictCategory) -> some View {
        VStack(alignment: .leading, spacing: BuzzBuddyTheme.Spacing.sm) {
            Image(systemName: category.iconSystemName)
                .font(.system(size: 40))
                .foregroundStyle(category.statusColorRole.color)
                .scaleEffect(iconAppeared ? 1 : 0.6)
                .opacity(iconAppeared ? 1 : 0)
                .accessibilityHidden(true)

            Text(category.title)
                .font(BuzzBuddyTheme.Typography.largeTitle)
                .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)

            Text(category.oneSentenceSummary)
                .font(.subheadline)
                .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
        }
    }

    private var resultsSummary: some View {
        BuzzBuddyCard {
            VStack(spacing: BuzzBuddyTheme.Spacing.md) {
                ForEach(runLog) { entry in
                    ResultMetricRow(
                        icon: iconName(for: entry.testType),
                        title: testDisplayName(entry.testType),
                        detail: entry.reasoningLines.first ?? "Reviewed.",
                        role: .neutral
                    )
                }
            }
        }
    }

    private func iconName(for testType: String) -> String {
        switch TestKind(pendingTest: testType) {
        case .reaction: return "bolt.fill"
        case .balance: return "figure.stand"
        case .memory: return "brain.head.profile"
        case .gait: return "figure.walk"
        case .unknown: return "questionmark.circle"
        }
    }

    private func actions(category: VerdictCategory, session: SessionOut) -> some View {
        VStack(spacing: BuzzBuddyTheme.Spacing.sm) {
            if category != .closeToBaseline, let contact = trustedContact, let phone = contact.phoneNumber {
                BuzzBuddyButton(title: "Contact \(contact.name)", systemImage: "phone.fill", kind: .primary) {
                    if let url = URL(string: "tel:\(phone)") {
                        UIApplication.shared.open(url)
                    }
                }
            }

            // fullScreenCover has no built-in dismiss (no swipe-down, no back
            // button) -- without this, finishing a check-in leaves the user
            // stuck here with no way back to the tabs.
            BuzzBuddyButton(title: "Finish Check", kind: category == .closeToBaseline ? .primary : .secondary) {
                appState.discardSession()
                dismiss()
            }
        }
        .padding(.top, BuzzBuddyTheme.Spacing.xs)
    }
}

#Preview {
    VerdictView(runLog: []).environmentObject(AppState())
}
