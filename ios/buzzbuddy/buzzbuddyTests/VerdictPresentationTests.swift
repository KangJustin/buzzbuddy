//
//  VerdictPresentationTests.swift
//  buzzbuddyTests
//

import Testing
@testable import buzzbuddy

struct VerdictCategoryTests {

    @Test func clearMapsToCloseToBaseline() {
        #expect(VerdictCategory(backendStatus: "CLEAR") == .closeToBaseline)
    }

    @Test func mildlyImpairedMapsToSomeChangesDetected() {
        #expect(VerdictCategory(backendStatus: "MILDLY_IMPAIRED") == .someChangesDetected)
    }

    @Test func severelyImpairedMapsToSignificantChangesDetected() {
        #expect(VerdictCategory(backendStatus: "SEVERELY_IMPAIRED") == .significantChangesDetected)
    }

    @Test("unrecognized status strings map to unableToDetermine", arguments: ["in_progress", "", "unknown"])
    func unrecognizedStatusMapsToUnableToDetermine(status: String) {
        #expect(VerdictCategory(backendStatus: status) == .unableToDetermine)
    }

    @Test func everyCategoryHasNonEmptyTitleSummaryAndIcon() {
        let categories: [VerdictCategory] = [.closeToBaseline, .someChangesDetected, .significantChangesDetected, .unableToDetermine]
        for category in categories {
            #expect(!category.title.isEmpty)
            #expect(!category.oneSentenceSummary.isEmpty)
            #expect(!category.iconSystemName.isEmpty)
        }
    }
}
