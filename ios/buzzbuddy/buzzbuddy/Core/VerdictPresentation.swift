//
//  VerdictPresentation.swift
//  buzzbuddy
//

import Foundation

/// Maps the backend's raw `AgentSession.status` string to neutral, non-clinical
/// language for the UI. `AppState`/`SessionOut.status` themselves are untouched
/// -- this is purely a presentation-layer translation, kept Foundation-only
/// (no SwiftUI import) so it's unit-testable without a view hierarchy.
enum VerdictCategory: Equatable {
    case closeToBaseline
    case someChangesDetected
    case significantChangesDetected
    case unableToDetermine

    init(backendStatus: String) {
        switch backendStatus {
        case "CLEAR":
            self = .closeToBaseline
        case "MILDLY_IMPAIRED":
            self = .someChangesDetected
        case "SEVERELY_IMPAIRED":
            self = .significantChangesDetected
        default:
            self = .unableToDetermine
        }
    }

    var title: String {
        switch self {
        case .closeToBaseline: return "Close to Your Baseline"
        case .someChangesDetected: return "Some Changes Detected"
        case .significantChangesDetected: return "Significant Changes Detected"
        case .unableToDetermine: return "Unable to Determine"
        }
    }

    var oneSentenceSummary: String {
        switch self {
        case .closeToBaseline:
            return "Tonight's results were generally close to your personal baseline."
        case .someChangesDetected:
            return "A few of tonight's results were different from your personal baseline."
        case .significantChangesDetected:
            return "Tonight's results showed notable changes from your personal baseline."
        case .unableToDetermine:
            return "We weren't able to reach a clear comparison against your baseline tonight."
        }
    }

    var iconSystemName: String {
        switch self {
        case .closeToBaseline: return "checkmark.seal.fill"
        case .someChangesDetected: return "exclamationmark.triangle.fill"
        case .significantChangesDetected: return "exclamationmark.octagon.fill"
        case .unableToDetermine: return "questionmark.circle.fill"
        }
    }
}
