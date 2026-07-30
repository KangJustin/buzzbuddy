import SwiftUI
import UIKit

/// One completed round of the check-in: which test it was, and the AI's
/// real reasoning text for that round. Local, ephemeral (`@State`, never
/// persisted) -- `SessionOut` only exposes free-form `reasoningLog` strings,
/// not a structured per-test result array, and this naturally resets every
/// time a fresh check-in is presented. Powers the "Step X of 4" progress
/// header and the results-summary list on the verdict screen.
struct TestRunEntry: Identifiable {
    let id = UUID()
    let testType: String
    let reasoningLines: [String]
}

/// The full BuzzBuddy safety-check flow: onboarding, starting an event,
/// taking whichever test the AI examiner requests, and the final verdict.
/// Sober baselines are captured separately, from the Baseline tab.
/// Observes the app-wide AppState injected by BuzzBuddyApp -- never creates
/// its own, so every tab that embeds this shares one session.
struct SafetyCheckFlowView: View {
    @EnvironmentObject var appState: AppState
    @State private var runLog: [TestRunEntry] = []

    var body: some View {
        switch appState.phase {
        case .onboarding:
            NeedsProfileView()
        case .restoring:
            loadingState("Restoring your check-in...")
        case .restoreFailed:
            RestoreFailedView()
        case .readyToStartEvent:
            StartEventView()
        case .startingEvent:
            loadingState("Starting your check-in...")
        case .takingTest(let pendingTest):
            TestPromptView(pendingTest: pendingTest)
        case .reviewingTest(let pendingTest):
            ReviewingTestView(pendingTest: pendingTest, stepNumber: runLog.count + 1) { testType, lines in
                runLog.append(TestRunEntry(testType: testType, reasoningLines: lines))
            }
        case .submissionFailed(let pendingTest, _, _):
            SubmissionFailedView(pendingTest: pendingTest)
        case .unsupportedTest(let pendingTest):
            UnsupportedTestView(pendingTest: pendingTest)
        case .verdict:
            VerdictView(runLog: runLog)
        }
    }

    private func loadingState(_ message: String) -> some View {
        VStack {
            ProgressView(message)
                .tint(BuzzBuddyTheme.Colors.accentYellow)
                .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BuzzBuddyTheme.Colors.background.ignoresSafeArea())
    }
}

/// Routes a `pendingTest` string to its test view. Only reaction, gyro/
/// balance, and memory are recognized -- anything else is a controlled
/// error, never a silent fallback to the reaction test.
private struct TestPromptView: View {
    @EnvironmentObject var appState: AppState
    let pendingTest: String

    var body: some View {
        switch TestKind(pendingTest: pendingTest) {
        case .reaction:
            ReactionGame { ms in
                Task { await appState.submitTestResult(testType: pendingTest, rawValue: Double(ms)) }
            }
        case .balance:
            GyroBalanceTestView { variance in
                Task { await appState.submitTestResult(testType: pendingTest, rawValue: variance) }
            }
        case .memory:
            MemoryGame { accuracy in
                Task { await appState.submitTestResult(testType: pendingTest, rawValue: Double(accuracy)) }
            }
        case .gait:
            GaitTestView { score in
                Task { await appState.submitTestResult(testType: pendingTest, rawValue: score) }
            }
        case .unknown:
            UnsupportedTestView(pendingTest: pendingTest)
        }
    }
}

/// Human-readable name for a `pendingTest`/`test_type` string, used on the
/// Continue button so it says what's coming up next instead of just "Continue".
func testDisplayName(_ pendingTest: String) -> String {
    switch TestKind(pendingTest: pendingTest) {
    case .reaction: return "Reaction Test"
    case .balance: return "Balance Test"
    case .memory: return "Memory Test"
    case .gait: return "Walking Test"
    case .unknown: return "Next Test"
    }
}

/// SF Symbol for a `pendingTest`/`test_type` string, matching the icons used
/// on the Baseline and Home tabs.
private func testIconName(_ pendingTest: String) -> String {
    switch TestKind(pendingTest: pendingTest) {
    case .reaction: return "bolt.fill"
    case .balance: return "figure.stand"
    case .memory: return "brain.head.profile"
    case .gait: return "figure.walk"
    case .unknown: return "questionmark.circle"
    }
}

/// Shown while `submitTestResult` is in flight and after it resolves. Once
/// the result is in, this deliberately does NOT auto-advance -- it reveals
/// the AI's reasoning for this round word by word and waits for the user to
/// tap the bottom button (AppState.continueAfterReview()) before moving to
/// the next test or the verdict.
private struct ReviewingTestView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let pendingTest: String
    let stepNumber: Int
    /// Fires once, when this round's reveal finishes, so the parent can
    /// record it into the run log that powers the verdict's results summary.
    let onRoundComplete: (String, [String]) -> Void

    @State private var baselineReasoningCount = 0
    @State private var revealFinished = false
    @State private var hasRecordedRound = false

    private var newReasoningLines: [String] {
        guard let log = appState.session?.reasoningLog, log.count > baselineReasoningCount else { return [] }
        return Array(log.suffix(log.count - baselineReasoningCount))
    }

    private var nextStepLabel: String {
        guard let nextTest = appState.session?.pendingTest else { return "See Your Results" }
        return "Continue to \(testDisplayName(nextTest))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BuzzBuddyTheme.Spacing.lg) {
            if appState.isLoading {
                Spacer()
                ProgressView("Reviewing your result...")
                    .tint(BuzzBuddyTheme.Colors.accentYellow)
                    .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ProgressHeader(
                    step: stepNumber,
                    totalSteps: 4,
                    currentIcon: testIconName(pendingTest),
                    currentLabel: testDisplayName(pendingTest)
                )

                BuzzBuddyCard {
                    VStack(alignment: .leading, spacing: BuzzBuddyTheme.Spacing.sm) {
                        Text("\(testDisplayName(pendingTest)) complete")
                            .font(BuzzBuddyTheme.Typography.headline)
                            .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                        AIReasoningText(
                            lines: newReasoningLines,
                            onRevealFinished: {
                                revealFinished = true
                                if !hasRecordedRound {
                                    hasRecordedRound = true
                                    onRoundComplete(pendingTest, newReasoningLines)
                                }
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                            }
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))

                Spacer()

                if revealFinished {
                    VStack(spacing: BuzzBuddyTheme.Spacing.sm) {
                        BuzzBuddyButton(title: nextStepLabel, kind: .primary) {
                            appState.continueAfterReview()
                        }
                        // The session is persisted server-side and already
                        // resumable on relaunch (AppState.bootstrap()), so
                        // "pausing" is just dismissing without discarding --
                        // the existing restore flow picks it back up.
                        BuzzBuddyButton(title: "Pause Check", kind: .tertiary) {
                            dismiss()
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .padding(BuzzBuddyTheme.Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(BuzzBuddyTheme.Colors.background.ignoresSafeArea())
        .animation(BuzzBuddyTheme.Motion.respecting(reduceMotion, BuzzBuddyTheme.Motion.standard), value: revealFinished)
        .onAppear {
            baselineReasoningCount = appState.session?.reasoningLog.count ?? 0
        }
    }
}

/// Reveals `lines` word by word as they arrive (simulating the AI "thinking"
/// live, even though the backend actually returns the full text in one
/// shot). Calls `onRevealFinished` once every line has finished animating in.
private struct AIReasoningText: View {
    let lines: [String]
    var onRevealFinished: () -> Void

    @State private var revealedLineCount = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if lines.isEmpty {
                Text("Analyzing your result…")
                    .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
            } else {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    if index < revealedLineCount {
                        Text(line)
                    } else if index == revealedLineCount {
                        TypewriterLine(text: line) {
                            revealedLineCount += 1
                            if revealedLineCount == lines.count {
                                onRevealFinished()
                            }
                        }
                    }
                }
            }
        }
        .font(.system(.body, design: .monospaced))
        .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .onAppear {
            if lines.isEmpty { onRevealFinished() }
        }
    }
}

/// Reveals `text` a word at a time, then calls `onFinished` once the whole
/// line is visible.
private struct TypewriterLine: View {
    let text: String
    var onFinished: () -> Void

    @State private var visibleWordCount = 0

    private var words: [String] { text.split(separator: " ").map(String.init) }

    var body: some View {
        Text(words.prefix(visibleWordCount).joined(separator: " "))
            .onAppear { revealNext() }
    }

    private func revealNext() {
        guard visibleWordCount < words.count else {
            onFinished()
            return
        }
        visibleWordCount += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            revealNext()
        }
    }
}

/// Profile setup (name/weight/height/DD contact) lives on the Baseline tab
/// alongside sober test capture -- one page, not a form embedded here.
private struct NeedsProfileView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: BuzzBuddyTheme.Spacing.md) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 36))
                .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                .accessibilityHidden(true)
            Text("Set up your profile before starting a check-in.")
                .font(.title3)
                .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            Text("Your name, weight, height, and designated driver contact live on the Baseline tab, alongside your sober test results.")
                .font(.footnote)
                .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            BuzzBuddyButton(title: "Go to the Baseline tab", kind: .primary, fullWidth: false) {
                dismiss()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BuzzBuddyTheme.Colors.background.ignoresSafeArea())
    }
}

private struct UnsupportedTestView: View {
    let pendingTest: String

    var body: some View {
        VStack(spacing: BuzzBuddyTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(StatusColorRole.amber.color)
                .accessibilityHidden(true)
            Text("The examiner requested a test type this app version doesn't support (\"\(pendingTest)\").")
                .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            Text("Update the app, or contact support if this keeps happening.")
                .font(.caption)
                .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BuzzBuddyTheme.Colors.background.ignoresSafeArea())
    }
}

private struct SubmissionFailedView: View {
    @EnvironmentObject var appState: AppState
    let pendingTest: String

    var body: some View {
        VStack(spacing: BuzzBuddyTheme.Spacing.md) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(StatusColorRole.red.color)
                .accessibilityHidden(true)
            if let error = appState.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            BuzzBuddyButton(title: "Retry", kind: .primary, fullWidth: false, isLoading: appState.isLoading) {
                Task { await appState.retrySubmission() }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BuzzBuddyTheme.Colors.background.ignoresSafeArea())
    }
}

private struct RestoreFailedView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: BuzzBuddyTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(StatusColorRole.amber.color)
                .accessibilityHidden(true)
            Text("Couldn't restore your active check-in.")
                .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            if let error = appState.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            BuzzBuddyButton(title: "Retry", kind: .primary, fullWidth: false, isLoading: appState.isLoading) {
                Task { await appState.retryRestore() }
            }
            BuzzBuddyButton(title: "Start a new check-in", kind: .destructive, fullWidth: false) {
                appState.discardSession()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BuzzBuddyTheme.Colors.background.ignoresSafeArea())
    }
}

#Preview {
    SafetyCheckFlowView().environmentObject(AppState())
}
