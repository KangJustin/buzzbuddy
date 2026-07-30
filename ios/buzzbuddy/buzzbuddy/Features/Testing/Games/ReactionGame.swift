//
//  ReactionGame.swift
//  buzzbuddy
//
//  Created by Max DeWeese on 7/10/26.
//

import SwiftUI

struct ReactionGame: View {
    @EnvironmentObject var engine: TestEngine

    /// When set, the finished score is reported here instead of to
    /// `TestEngine` -- lets an AI-requested test (SafetyCheckFlowView) drive
    /// this same game UI without going through the local game shuffle.
    var onComplete: ((Int) -> Void)? = nil

    @State private var boxColor: Color = BuzzBuddyTheme.Colors.surfaceElevated2
    @State private var boxText = "Press Start"

    @State private var isPlaying = false
    @State private var waiting = false
    @State private var measuring = false

    @State private var startTime = Date()

    @State private var round = 0
    @State private var reactionTimes: [Int] = []

    let totalRounds = 2

    init(onComplete: ((Int) -> Void)? = nil) {
        self.onComplete = onComplete
        // Debug-only screenshot helper: lands straight on the "TAP!" moment
        // instead of the idle "Press Start" state, gated behind the same
        // BUZZBUDDY_DEBUG_PHASE=game flag AppState checks. No-op otherwise.
        #if DEBUG
        if ProcessInfo.processInfo.environment["BUZZBUDDY_DEBUG_PHASE"] == "game" {
            _boxColor = State(initialValue: StatusColorRole.green.color)
            _boxText = State(initialValue: "TAP!")
            _isPlaying = State(initialValue: true)
            _measuring = State(initialValue: true)
            _round = State(initialValue: 1)
        }
        #endif
    }

    var body: some View {
        VStack(spacing: BuzzBuddyTheme.Spacing.lg) {
            Text("Reaction Time")
                .font(BuzzBuddyTheme.Typography.largeTitle)
                .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)

            Spacer()

            Button {
                boxTapped()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: BuzzBuddyTheme.Radius.lg, style: .continuous)
                        .fill(boxColor)
                        .frame(width: 320, height: 320)

                    Text(boxText)
                        .font(BuzzBuddyTheme.Typography.numeric(30, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .disabled(isPlaying && !waiting && !measuring)
            .accessibilityLabel(boxText)

            Spacer()

            if isPlaying {
                Text("Round \(round)/\(totalRounds)")
                    .font(BuzzBuddyTheme.Typography.headline)
                    .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BuzzBuddyTheme.Colors.background.ignoresSafeArea())
    }

    func boxTapped() {

        // First tap starts the test
        if !isPlaying {
            startGame()
            return
        }

        // Tap too early
        if waiting {
            waiting = false

            boxColor = BuzzBuddyTheme.Colors.surfaceElevated2
            boxText = "Too Early!"

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                nextRound()
            }

            return
        }

        // Correct reaction
        if measuring {

            let reactionTime = Int(
                Date().timeIntervalSince(startTime) * 1000
            )

            reactionTimes.append(reactionTime)

            measuring = false

            boxColor = BuzzBuddyTheme.Colors.accentYellow
            boxText = "\(reactionTime) ms"

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                nextRound()
            }
        }
    }

    func startGame() {
        round = 0
        reactionTimes.removeAll()
        isPlaying = true

        nextRound()
    }

    func nextRound() {

        if round >= totalRounds {
            finishGame()
            return
        }

        round += 1

        waiting = true
        measuring = false

        boxColor = StatusColorRole.red.color
        boxText = "Wait..."

        let delay = Double.random(in: 1.5...4)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {

            guard waiting else {
                return
            }

            waiting = false
            measuring = true

            boxColor = StatusColorRole.green.color
            boxText = "TAP!"

            startTime = Date()
        }
    }

    func finishGame() {

        isPlaying = false
        waiting = false
        measuring = false

        let average = reactionTimes.reduce(0, +) / max(reactionTimes.count, 1)

        if let onComplete {
            onComplete(average)
        } else {
            engine.completeGame(
                gameType: "ReactionTime",
                gameScore: average
            )
        }

        boxColor = BuzzBuddyTheme.Colors.accentYellow
        boxText = "\(average) ms"
    }
}
