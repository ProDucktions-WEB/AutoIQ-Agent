import XCTest
@testable import AutoIQ

final class AutoIQProfileTests: XCTestCase {

    func testProfileCreation() {
        let profile = AutoIQProfile(userId: "test_user")
        XCTAssertEqual(profile.userId, "test_user")
        XCTAssertEqual(profile.decisionStage, .exploring)
        XCTAssertEqual(profile.purchaseIntentScore, 0)
        XCTAssertEqual(profile.totalSignalsProcessed, 0)
    }

    func testBudgetRange() {
        let budget = AutoIQProfile.BudgetRange(
            min: 10_000_000,
            max: 500_000_000,
            isUnlimited: false,
            confidence: 0.8
        )
        XCTAssertEqual(budget.min, 10_000_000)
        XCTAssertEqual(budget.max, 500_000_000)
        XCTAssertFalse(budget.isUnlimited)
        XCTAssertEqual(budget.confidence, 0.8)
    }

    func testWeightedPreference() {
        let pref = AutoIQProfile.WeightedPreference(
            id: "Toyota",
            weight: 0.85,
            signalCount: 5
        )
        XCTAssertEqual(pref.id, "Toyota")
        XCTAssertEqual(pref.weight, 0.85)
        XCTAssertEqual(pref.signalCount, 5)
    }

    func testArchetypeScore() {
        let archetype = AutoIQProfile.ArchetypeScore(
            id: "RATIONAL",
            displayName: "Racional",
            confidence: 0.9,
            isPrimary: true
        )
        XCTAssertEqual(archetype.id, "RATIONAL")
        XCTAssertEqual(archetype.displayName, "Racional")
        XCTAssertEqual(archetype.confidence, 0.9)
        XCTAssertTrue(archetype.isPrimary)
    }

    func testDecisionStage() {
        XCTAssertEqual(AutoIQProfile.DecisionStage.exploring.rawValue, "exploring")
        XCTAssertEqual(AutoIQProfile.DecisionStage.comparing.rawValue, "comparing")
        XCTAssertEqual(AutoIQProfile.DecisionStage.deciding.rawValue, "deciding")
        XCTAssertEqual(AutoIQProfile.DecisionStage.readyToBuy.rawValue, "ready_to_buy")
    }

    func testProfileCodable() throws {
        let profile = AutoIQProfile(userId: "test_user")
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(AutoIQProfile.self, from: data)
        XCTAssertEqual(decoded.userId, profile.userId)
        XCTAssertEqual(decoded.decisionStage, profile.decisionStage)
    }
}
