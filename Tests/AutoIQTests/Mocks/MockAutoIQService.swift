import Foundation
import AutoIQ

/// Mock AutoIQService for testing UI components without live API calls.
public final class MockAutoIQService: ObservableObject {
    @Published public var isStreaming = false
    @Published public var streamingText = ""
    @Published public var currentProfile: AutoIQProfile?
    @Published public var activeRiskFlags: [RiskFlag] = []

    public init() {
        self.currentProfile = AutoIQProfile(userId: "mock_user")
    }

    public func chat(_ text: String, context: CarContext? = nil) async {
        isStreaming = true
        streamingText = "Mock response: \(text)"
        try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
        isStreaming = false
    }

    public func recordSignal(_ signal: BehavioralSignal) {
        var profile = currentProfile ?? AutoIQProfile(userId: "mock_user")
        profile.totalSignalsProcessed += 1
        currentProfile = profile
    }

    public func dismissRiskFlag(_ flag: RiskFlag) {
        activeRiskFlags.removeAll { $0.id == flag.id }
    }

    public func resetConversation() {
        streamingText = ""
    }

    // Helper: Add test risk flag
    public func addTestRiskFlag(_ riskType: String = "test") {
        activeRiskFlags.append(
            RiskFlag(
                riskType: riskType,
                severity: .medium,
                message: "Test risk flag",
                recommendedAction: "Test action"
            )
        )
    }
}
