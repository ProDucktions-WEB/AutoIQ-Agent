import Foundation

/// Handles persistent storage and retrieval of user profiles.
/// Uses UserDefaults for simplicity; easily swappable with CoreData or Realm.
public final class AutoIQProfileStore {
    public let userId: String
    private let defaults = UserDefaults.standard
    private var key: String { "autoiq_profile_v1_\(userId)" }

    public init(userId: String) {
        self.userId = userId
    }

    /// Save profile to persistent storage.
    public func save(_ profile: AutoIQProfile) {
        guard let data = try? JSONEncoder().encode(profile) else {
            print("[AutoIQ] Failed to encode profile")
            return
        }
        defaults.set(data, forKey: key)
    }

    /// Load profile from persistent storage.
    public func load() -> AutoIQProfile? {
        guard let data = defaults.data(forKey: key),
              let profile = try? JSONDecoder().decode(AutoIQProfile.self, from: data) else {
            return nil
        }
        return profile
    }

    /// Create an empty profile with sensible defaults.
    public func createEmpty() -> AutoIQProfile {
        AutoIQProfile(
            userId: userId,
            lastUpdated: Date(),
            totalSignalsProcessed: 0,
            budgetRange: AutoIQProfile.BudgetRange(
                min: 10_000_000,
                max: 500_000_000,
                isUnlimited: false,
                confidence: 0
            ),
            preferredBodyTypes: [],
            preferredBrands: [],
            rejectedBrands: [],
            fuelPreference: [],
            transmissionPreference: nil,
            luxuryAffinity: 0.5,
            practicalityWeight: 0.5,
            priceSensitivity: 0.5,
            brandLoyaltyScore: 0,
            archetypes: [],
            purchaseIntentScore: 0,
            decisionStage: .exploring,
            averageSwipeSpeedSeconds: 0,
            photoVsSpecsRatio: 1,
            peakActivityHours: [],
            sessionCount: 1,
            totalSwipes: 0,
            rightSwipeRate: 0,
            savedCarIds: [],
            viewedCarIds: [],
            topInterestCarId: nil,
            inferredUseCase: nil,
            inferredHouseholdSize: nil,
            inferredExperience: nil,
            overallConfidence: 0,
            fieldConfidences: [:],
            topRecommendedCarIds: [],
            lastRecommendationReason: nil
        )
    }

    /// Clear all stored profile data.
    public func reset() {
        defaults.removeObject(forKey: key)
    }
}
