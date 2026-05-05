import Foundation
import Combine

/// Main service for the Auto IQ agent.
/// Handles streaming chat, behavioral signal processing, and profile management.
@MainActor
public final class AutoIQService: ObservableObject {

    // MARK: - Published State
    @Published public var isStreaming: Bool = false
    @Published public var streamingText: String = ""
    @Published public var currentProfile: AutoIQProfile?
    @Published public var activeRiskFlags: [RiskFlag] = []

    // MARK: - Private Properties
    private let apiKey: String
    private let chatModel = "claude-opus-4-5"
    private let signalModel = "claude-haiku-4-5-20251001"
    private let client: AnthropicClient
    private var conversationHistory: [APIMessage] = []
    private let profileStore: AutoIQProfileStore
    private var signalBuffer: [BehavioralSignal] = []
    private let signalFlushThreshold = 3

    // MARK: - Public Init
    public init(apiKey: String, userId: String) {
        self.apiKey = apiKey
        self.client = AnthropicClient(apiKey: apiKey)
        self.profileStore = AutoIQProfileStore(userId: userId)
        self.currentProfile = profileStore.load() ?? profileStore.createEmpty()
    }

    // MARK: - Public: Streaming Chat

    /// Send a message and stream the response.
    public func chat(_ text: String, context: CarContext? = nil) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isStreaming = true
        streamingText = ""

        let enriched = context.map {
            "[CONTEXT: Viewing \($0.marca) \($0.modelo) \($0.año) @ $\(Int($0.precio).formattedCOP) COP]\n\(text)"
        } ?? text

        conversationHistory.append(APIMessage(role: "user", content: enriched))

        do {
            let request = buildChatRequest()
            var fullText = ""

            try await client.streamMessage(request) { event in
                if let text = event.delta?.text {
                    fullText += text
                    self.streamingText = fullText
                }
            }

            conversationHistory.append(APIMessage(role: "assistant", content: fullText))
        } catch {
            streamingText = "Auto IQ no está disponible en este momento. Intenta de nuevo."
        }

        isStreaming = false
    }

    // MARK: - Public: Behavioral Signal Recording

    /// Record a behavioral signal from any UI interaction.
    public func recordSignal(_ signal: BehavioralSignal) {
        signalBuffer.append(signal)
        updateProfileLocally(signal)

        let highPriority: [BehavioralSignal.SignalType] = [
            .repeatedView, .saveAction, .contactAction, .compareAction
        ]
        if highPriority.contains(signal.signalType) || signalBuffer.count >= signalFlushThreshold {
            Task { await flushSignals() }
        }
    }

    /// Dismiss a risk flag from the active list.
    public func dismissRiskFlag(_ flag: RiskFlag) {
        activeRiskFlags.removeAll { $0.id == flag.id }
    }

    /// Reset conversation history.
    public func resetConversation() {
        conversationHistory.removeAll()
        streamingText = ""
    }

    // MARK: - Private: Signal Processing

    private func flushSignals() async {
        guard !signalBuffer.isEmpty else { return }
        let signals = signalBuffer
        signalBuffer.removeAll()

        let payload = signals.map { s -> String in
            var line = "- \(s.signalType.rawValue)"
            if let car = s.carSnapshot {
                line += " · \(car.marca) \(car.modelo) \(car.año) @ $\(Int(car.precio).formattedCOP)"
            }
            if let dwell = s.dwellDurationSeconds {
                line += " · dwell \(String(format: "%.1f", dwell))s"
            }
            return line
        }.joined(separator: "\n")

        let silentMessage = """
        [BEHAVIORAL_SIGNALS — Silent profile update only. Call update_user_profile tool.]
        Processing \(signals.count) new signal(s):
        \(payload)
        Current profile confidence: \(String(format: "%.2f", currentProfile?.overallConfidence ?? 0))
        Total signals so far: \(currentProfile?.totalSignalsProcessed ?? 0)
        """

        await processToolsOnly(message: silentMessage, model: signalModel)
    }

    private func processToolsOnly(message: String, model: String) async {
        let request = MessagesRequest(
            model: model,
            maxTokens: 512,
            system: AutoIQPrompts.systemPrompt + profileContextString(),
            messages: [APIMessage(role: "user", content: message)],
            tools: nil,
            stream: false
        )

        do {
            let response = try await client.sendMessage(request)
            for block in response.content where block.type == "tool_use" {
                await handleTool(name: block.name ?? "", input: block.input?.value as? [String: Any] ?? [:])
            }
        } catch {
            print("[AutoIQ] Error processing tools: \(error.localizedDescription)")
        }
    }

    // MARK: - Private: Tool Handling

    private func handleTool(name: String, input: [String: Any]) async {
        switch name {
        case "update_user_profile":
            applyProfileUpdate(input)
        case "flag_risk":
            applyRiskFlag(input)
        default:
            break
        }
    }

    private func applyProfileUpdate(_ input: [String: Any]) {
        var profile = currentProfile ?? profileStore.createEmpty()

        // Update purchase intent
        if let intent = input["purchase_intent_score"] as? Double {
            profile.purchaseIntentScore = intent
            profile.decisionStage = intent > 0.85 ? .readyToBuy :
                                    intent > 0.65 ? .deciding :
                                    intent > 0.35 ? .comparing : .exploring
        }

        // Update archetypes
        if let signals = input["archetype_signals"] as? [[String: Any]] {
            for s in signals {
                guard let key = s["archetype"] as? String,
                      let delta = s["confidence_delta"] as? Double else { continue }
                if let idx = profile.archetypes.firstIndex(where: { $0.id == key }) {
                    profile.archetypes[idx].confidence = max(0, min(1, profile.archetypes[idx].confidence + delta))
                } else if delta > 0 {
                    profile.archetypes.append(.init(
                        id: key,
                        displayName: ArchetypeNames.display(key),
                        confidence: delta,
                        isPrimary: false
                    ))
                }
            }
            // Recalculate primary archetype
            let maxConf = profile.archetypes.map(\.confidence).max() ?? 0
            for i in profile.archetypes.indices {
                profile.archetypes[i].isPrimary = profile.archetypes[i].confidence == maxConf
            }
        }

        profile.totalSignalsProcessed += 1
        profile.lastUpdated = Date()
        profile.overallConfidence = min(1.0, Double(profile.totalSignalsProcessed) / 50.0)

        currentProfile = profile
        profileStore.save(profile)
    }

    private func applyRiskFlag(_ input: [String: Any]) {
        guard let riskType = input["risk_type"] as? String,
              let severity = input["severity"] as? String,
              let message = input["message_es"] as? String,
              let action = input["recommended_action"] as? String else { return }

        activeRiskFlags.append(RiskFlag(
            riskType: riskType,
            severity: .init(rawValue: severity) ?? .medium,
            message: message,
            recommendedAction: action
        ))
    }

    private func updateProfileLocally(_ signal: BehavioralSignal) {
        guard var profile = currentProfile ?? profileStore.createEmpty() else { return }
        profile.totalSwipes += [.swipeRight, .swipeLeftFast, .swipeLeftSlow].contains(signal.signalType) ? 1 : 0

        if signal.signalType == .swipeRight, let car = signal.carSnapshot {
            if !profile.savedCarIds.contains(car.id) {
                profile.savedCarIds.append(car.id)
            }
            // Bump brand weight
            if let idx = profile.preferredBrands.firstIndex(where: { $0.id == car.marca }) {
                profile.preferredBrands[idx].weight = min(1, profile.preferredBrands[idx].weight + 0.1)
                profile.preferredBrands[idx].signalCount += 1
            } else {
                profile.preferredBrands.append(.init(id: car.marca, weight: 0.3, signalCount: 1))
            }
        }

        if signal.signalType == .swipeLeftFast, let car = signal.carSnapshot {
            if !profile.rejectedBrands.contains(car.marca) {
                let rejectCount = signalBuffer.filter {
                    $0.signalType == .swipeLeftFast && $0.carSnapshot?.marca == car.marca
                }.count
                if rejectCount >= 2 { profile.rejectedBrands.append(car.marca) }
            }
        }

        let total = profile.totalSwipes
        let rights = profile.savedCarIds.count
        profile.rightSwipeRate = total > 0 ? Double(rights) / Double(total) : 0

        currentProfile = profile
        profileStore.save(profile)
    }

    // MARK: - Private: Request Builder

    private func buildChatRequest() -> MessagesRequest {
        MessagesRequest(
            model: chatModel,
            maxTokens: 1024,
            system: AutoIQPrompts.systemPrompt + profileContextString(),
            messages: conversationHistory,
            tools: nil,
            stream: true
        )
    }

    private func profileContextString() -> String {
        guard let p = currentProfile else { return "" }
        let primary = p.archetypes.first(where: { $0.isPrimary })?.displayName ?? "Desconocido"
        let brands = p.preferredBrands.prefix(3).map(\.id).joined(separator: ", ")
        let budget = p.budgetRange.isUnlimited ? "Sin límite" : "$\(Int(p.budgetRange.min).formattedCOP)–$\(Int(p.budgetRange.max).formattedCOP)"
        return """

        [USER PROFILE — Confidence: \(Int(p.overallConfidence * 100))% · Signals: \(p.totalSignalsProcessed)]
        Stage: \(p.decisionStage.rawValue) · Intent: \(Int(p.purchaseIntentScore * 100))%
        Primary archetype: \(primary)
        Budget: \(budget) COP · Luxury affinity: \(String(format: "%.2f", p.luxuryAffinity))
        Preferred brands: \(brands.isEmpty ? "none yet" : brands)
        Rejected brands: \(p.rejectedBrands.isEmpty ? "none" : p.rejectedBrands.joined(separator: ", "))
        Saved cars: \(p.savedCarIds.count) · Right swipe rate: \(Int(p.rightSwipeRate * 100))%
        Visual/Rational ratio: \(String(format: "%.2f", p.photoVsSpecsRatio))
        [END PROFILE]
        """
    }
}

// MARK: - Supporting Types

public struct CarContext {
    public let marca: String
    public let modelo: String
    public let año: Int
    public let precio: Double

    public init(marca: String, modelo: String, año: Int, precio: Double) {
        self.marca = marca
        self.modelo = modelo
        self.año = año
        self.precio = precio
    }
}
