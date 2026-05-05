import Foundation

/// Represents a detected risk or warning that should alert the user.
public struct RiskFlag: Identifiable {
    public let id: UUID
    public let riskType: String
    public let severity: Severity
    public let message: String
    public let recommendedAction: String
    public let timestamp: Date

    public init(
        riskType: String,
        severity: Severity,
        message: String,
        recommendedAction: String
    ) {
        self.id = UUID()
        self.riskType = riskType
        self.severity = severity
        self.message = message
        self.recommendedAction = recommendedAction
        self.timestamp = Date()
    }

    public enum Severity: String, Codable {
        case low, medium, high, critical

        public var displayColor: String {
            switch self {
            case .low:
                return "yellow"
            case .medium:
                return "orange"
            case .high, .critical:
                return "red"
            }
        }
    }
}
