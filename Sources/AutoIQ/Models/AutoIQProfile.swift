import Foundation

/// The living, evolving user profile that grows richer with every interaction.
/// Never static — continuously updated by behavioral signals.
public struct AutoIQProfile: Codable {
    public let userId: String
    public var lastUpdated: Date
    public var totalSignalsProcessed: Int

    // MARK: - Core Preferences
    public var budgetRange: BudgetRange
    public var preferredBodyTypes: [WeightedPreference]
    public var preferredBrands: [WeightedPreference]
    public var rejectedBrands: [String]
    public var fuelPreference: [WeightedPreference]
    public var transmissionPreference: String?  // "manual" | "automatica" | "neutral"
    public var luxuryAffinity: Double           // 0.0–1.0
    public var practicalityWeight: Double       // 0.0–1.0
    public var priceSensitivity: Double         // 0.0–1.0
    public var brandLoyaltyScore: Double        // 0.0–1.0

    // MARK: - Archetypes
    public var archetypes: [ArchetypeScore]

    // MARK: - Purchase Readiness
    public var purchaseIntentScore: Double      // 0.0–1.0
    public var decisionStage: DecisionStage

    // MARK: - Behavioral Patterns
    public var averageSwipeSpeedSeconds: Double
    public var photoVsSpecsRatio: Double        // >1 = visual buyer, <1 = rational buyer
    public var peakActivityHours: [Int]        // 0–23
    public var sessionCount: Int
    public var totalSwipes: Int
    public var rightSwipeRate: Double           // 0.0–1.0

    // MARK: - Top Interests
    public var savedCarIds: [String]
    public var viewedCarIds: [String]
    public var topInterestCarId: String?

    // MARK: - Derived Insights
    public var inferredUseCase: String?        // "ciudad"|"carretera"|"mixto"|"campo"
    public var inferredHouseholdSize: String?  // "individual"|"pareja"|"familia_pequeña"|"familia_grande"
    public var inferredExperience: String?     // "primera_vez"|"conocedor"|"experto"

    // MARK: - Profile Confidence
    public var overallConfidence: Double        // 0.0–1.0
    public var fieldConfidences: [String: Double]

    // MARK: - Recommendations Cache
    public var topRecommendedCarIds: [String]
    public var lastRecommendationReason: String?

    // MARK: - Initializer
    public init(
        userId: String,
        lastUpdated: Date = Date(),
        totalSignalsProcessed: Int = 0,
        budgetRange: BudgetRange = BudgetRange(min: 10_000_000, max: 500_000_000, isUnlimited: false, confidence: 0),
        preferredBodyTypes: [WeightedPreference] = [],
        preferredBrands: [WeightedPreference] = [],
        rejectedBrands: [String] = [],
        fuelPreference: [WeightedPreference] = [],
        transmissionPreference: String? = nil,
        luxuryAffinity: Double = 0.5,
        practicalityWeight: Double = 0.5,
        priceSensitivity: Double = 0.5,
        brandLoyaltyScore: Double = 0,
        archetypes: [ArchetypeScore] = [],
        purchaseIntentScore: Double = 0,
        decisionStage: DecisionStage = .exploring,
        averageSwipeSpeedSeconds: Double = 0,
        photoVsSpecsRatio: Double = 1,
        peakActivityHours: [Int] = [],
        sessionCount: Int = 1,
        totalSwipes: Int = 0,
        rightSwipeRate: Double = 0,
        savedCarIds: [String] = [],
        viewedCarIds: [String] = [],
        topInterestCarId: String? = nil,
        inferredUseCase: String? = nil,
        inferredHouseholdSize: String? = nil,
        inferredExperience: String? = nil,
        overallConfidence: Double = 0,
        fieldConfidences: [String: Double] = [:],
        topRecommendedCarIds: [String] = [],
        lastRecommendationReason: String? = nil
    ) {
        self.userId = userId
        self.lastUpdated = lastUpdated
        self.totalSignalsProcessed = totalSignalsProcessed
        self.budgetRange = budgetRange
        self.preferredBodyTypes = preferredBodyTypes
        self.preferredBrands = preferredBrands
        self.rejectedBrands = rejectedBrands
        self.fuelPreference = fuelPreference
        self.transmissionPreference = transmissionPreference
        self.luxuryAffinity = luxuryAffinity
        self.practicalityWeight = practicalityWeight
        self.priceSensitivity = priceSensitivity
        self.brandLoyaltyScore = brandLoyaltyScore
        self.archetypes = archetypes
        self.purchaseIntentScore = purchaseIntentScore
        self.decisionStage = decisionStage
        self.averageSwipeSpeedSeconds = averageSwipeSpeedSeconds
        self.photoVsSpecsRatio = photoVsSpecsRatio
        self.peakActivityHours = peakActivityHours
        self.sessionCount = sessionCount
        self.totalSwipes = totalSwipes
        self.rightSwipeRate = rightSwipeRate
        self.savedCarIds = savedCarIds
        self.viewedCarIds = viewedCarIds
        self.topInterestCarId = topInterestCarId
        self.inferredUseCase = inferredUseCase
        self.inferredHouseholdSize = inferredHouseholdSize
        self.inferredExperience = inferredExperience
        self.overallConfidence = overallConfidence
        self.fieldConfidences = fieldConfidences
        self.topRecommendedCarIds = topRecommendedCarIds
        self.lastRecommendationReason = lastRecommendationReason
    }

    // MARK: - Nested Types
    public struct BudgetRange: Codable {
        public var min: Double
        public var max: Double
        public var isUnlimited: Bool
        public var confidence: Double

        public init(min: Double, max: Double, isUnlimited: Bool, confidence: Double) {
            self.min = min
            self.max = max
            self.isUnlimited = isUnlimited
            self.confidence = confidence
        }
    }

    public struct WeightedPreference: Codable, Identifiable {
        public let id: String
        public var weight: Double      // 0.0–1.0
        public var signalCount: Int

        public init(id: String, weight: Double, signalCount: Int) {
            self.id = id
            self.weight = weight
            self.signalCount = signalCount
        }
    }

    public struct ArchetypeScore: Codable, Identifiable {
        public let id: String
        public let displayName: String
        public var confidence: Double  // 0.0–1.0
        public var isPrimary: Bool

        public init(id: String, displayName: String, confidence: Double, isPrimary: Bool) {
            self.id = id
            self.displayName = displayName
            self.confidence = confidence
            self.isPrimary = isPrimary
        }
    }

    public enum DecisionStage: String, Codable {
        case exploring   = "exploring"
        case comparing   = "comparing"
        case deciding    = "deciding"
        case readyToBuy  = "ready_to_buy"
    }
}
