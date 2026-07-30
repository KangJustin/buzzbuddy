import CoreMotion
import SwiftUI

/// Runs a single balance trial: hold the phone steady for 5 seconds while we
/// sample the gyroscope, then report a stability score (higher = steadier).
/// Reused both to capture the sober baseline and for each AI-requested test.
struct GyroBalanceTestView: View {
    var onComplete: (Double) -> Void

    private static let duration: Double = 5.0

    @State private var motionManager = CMMotionManager()
    @State private var samples: [Double] = []
    @State private var timeRemaining: Double = GyroBalanceTestView.duration
    @State private var isRunning = false
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: BuzzBuddyTheme.Spacing.lg) {
            Text(isRunning ? "Hold your phone as steady as possible" : "Ready to test your balance")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Stand on one leg to balance")
                .font(.title3)
                .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            ZStack {
                Circle().stroke(BuzzBuddyTheme.Colors.surfaceElevated2, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(timeRemaining / Self.duration))
                    .stroke(isRunning ? BuzzBuddyTheme.Colors.accentYellow : BuzzBuddyTheme.Colors.textSecondary, lineWidth: 8)
                    .rotationEffect(.degrees(-90))
                Text(String(format: "%.1f", timeRemaining))
                    .font(BuzzBuddyTheme.Typography.numeric(48, weight: .bold))
                    .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
            }
            .frame(width: 160, height: 160)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isRunning ? "\(String(format: "%.0f", timeRemaining)) seconds remaining" : "Balance test ready")

            if !isRunning {
                BuzzBuddyButton(title: "Start Balance Test", kind: .primary, fullWidth: false) { start() }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BuzzBuddyTheme.Colors.background.ignoresSafeArea())
        .onDisappear { stop() }
    }

    private func start() {
        guard motionManager.isDeviceMotionAvailable else {
            // No motion hardware (e.g. some Simulator configs) — report a
            // neutral score rather than blocking the flow.
            onComplete(1.0)
            return
        }

        samples = []
        timeRemaining = Self.duration
        isRunning = true

        motionManager.deviceMotionUpdateInterval = 0.05
        motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion else { return }
            let rate = motion.rotationRate
            samples.append(sqrt(rate.x * rate.x + rate.y * rate.y + rate.z * rate.z))
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeRemaining -= 0.1
            if timeRemaining <= 0 {
                finish()
            }
        }
    }

    private func finish() {
        let score = stabilityScore(from: samples)
        stop()
        onComplete(score)
    }

    private func stop() {
        motionManager.stopDeviceMotionUpdates()
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    /// Higher = steadier. Converts average rotation-rate magnitude (wobble)
    /// into a bounded score comparable across baseline and live tests.
    private func stabilityScore(from samples: [Double]) -> Double {
        guard !samples.isEmpty else { return 1.0 }
        let avgWobble = samples.reduce(0, +) / Double(samples.count)
        return 1.0 / (1.0 + avgWobble * 10)
    }
}

#Preview {
    GyroBalanceTestView { _ in }
}
