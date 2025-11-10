//
//  RuleSimilarityCheckerTests.swift
//  ShadowsocksX-NGTests
//
//  Created by Codex on 2024/12/08.
//

import XCTest
@testable import ShadowsocksX_NG

final class RuleSimilarityCheckerTests: XCTestCase {

    func testDetectsExactMatch() {
        let checker = RuleSimilarityChecker(rulesText: "||example.com")

        let similarity = checker.findSimilarity(for: "example.com")

        XCTAssertEqual(similarity?.relation, .exactMatch)
        XCTAssertEqual(similarity?.existingRule, "||example.com")
    }

    func testDetectsCoveringRule() {
        let checker = RuleSimilarityChecker(rulesText: "||example.com")

        let similarity = checker.findSimilarity(for: "shop.example.com")

        XCTAssertEqual(similarity?.relation, .existingRuleCoversDomain)
        XCTAssertEqual(similarity?.existingRule, "||example.com")
    }

    func testDetectsNarrowerExistingRule() {
        let checker = RuleSimilarityChecker(rulesText: "||shop.example.com")

        let similarity = checker.findSimilarity(for: "example.com")

        XCTAssertEqual(similarity?.relation, .existingRuleMoreSpecific)
        XCTAssertEqual(similarity?.existingRule, "||shop.example.com")
    }

    func testDetectsExceptionConflict() {
        let checker = RuleSimilarityChecker(rulesText: "@@||example.com")

        let similarity = checker.findSimilarity(for: "example.com")

        XCTAssertEqual(similarity?.relation, .conflictsWithException)
        XCTAssertEqual(similarity?.existingRule, "@@||example.com")
    }

    func testDetectsWildcardCoverage() {
        let checker = RuleSimilarityChecker(rulesText: "||*.example.com")

        let similarity = checker.findSimilarity(for: "blog.example.com")

        XCTAssertEqual(similarity?.relation, .existingRuleCoversDomain)
        XCTAssertEqual(similarity?.existingRule, "||*.example.com")
    }
}
