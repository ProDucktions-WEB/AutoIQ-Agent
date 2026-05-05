# Auto IQ — Intelligent Automotive Agent

> **Auto IQ** is the core intelligence layer of AutomatchIA — a Colombian automotive marketplace iOS app. It's not just a chatbot; it's a dual-axis expert system that simultaneously acts as a trusted automotive advisor, behavioral profiling engine, and real-time recommendation algorithm.

---

## Features

✨ **Conversational AI**
- Multilingual support (Spanish, English, Portuguese, French)
- Adaptive tone based on user expertise level
- Deep Colombian automotive market knowledge
- Real-time streaming responses

🧠 **Behavioral Profiling**
- Silent, non-intrusive signal processing
- Learns from swipes, dwell time, filter changes, and chat topics
- Updates user profile with every interaction
- 9 buyer archetypes with confidence scoring

🛡️ **Buyer Protection**
- Fraud detection and risk flagging
- Legal expertise (RUNT, SOAT, traspaso, regulatory compliance)
- Financial safety prioritized over quick sales
- Hidden cost analysis for vehicles

📊 **Market Intelligence**
- Colombian automotive pricing data
- Regional variations (Bogotá, Medellín, Cali, etc.)
- Seasonal demand patterns
- Depreciation and resale value analysis

---

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
.package(url: "https://github.com/ProDucktions-WEB/AutoIQ-Agent.git", from: "1.0.0")
```

Or in Xcode: **File → Add Packages → Enter repo URL**

---

## Quick Start

### 1. Initialize the Service

```swift
import AutoIQ

@main
struct MyApp: App {
    @StateObject private var autoIQ = AutoIQService(
        apiKey: "sk-ant-...",  // Your Anthropic API key
        userId: "user_12345"
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(autoIQ)
        }
    }
}
```

### 2. Stream Chat

```swift
struct ChatView: View {
    @EnvironmentObject var autoIQ: AutoIQService
    @State private var userMessage = ""

    var body: some View {
        VStack {
            // Display streaming response
            Text(autoIQ.streamingText)
                .padding()

            // Input field
            HStack {
                TextField("Ask Auto IQ...", text: $userMessage)
                Button("Send") {
                    Task {
                        await autoIQ.chat(userMessage)
                        userMessage = ""
                    }
                }
            }
            .padding()
        }
    }
}
```

### 3. Record Behavioral Signals

```swift
struct CarCardView: View {
    let car: Car
    @EnvironmentObject var autoIQ: AutoIQService
    @State private var cardAppearTime = Date()

    var body: some View {
        VStack {
            // Car card UI
            Text("\(car.marca) \(car.modelo)")
        }
        .onAppear {
            cardAppearTime = Date()
        }
    }

    func handleSwipe(direction: SwipeDirection) {
        let dwell = Date().timeIntervalSince(cardAppearTime)
        let snapshot = BehavioralSignal.CarSnapshot(
            id: car.id,
            marca: car.marca,
            modelo: car.modelo,
            año: car.year,
            precio: Double(car.price),
            tipo: car.type,
            combustible: car.fuel,
            transmision: car.transmission,
            nivelLujo: car.luxuryLevel
        )

        let signalType: BehavioralSignal.SignalType
        switch direction {
        case .right:
            signalType = .swipeRight
        case .left:
            signalType = dwell < 1.5 ? .swipeLeftFast : .swipeLeftSlow
        case .up:
            signalType = .swipeUp
        }

        autoIQ.recordSignal(BehavioralSignal(
            signalType: signalType,
            sessionId: UUID().uuidString,
            carSnapshot: snapshot,
            dwellDurationSeconds: dwell
        ))
    }
}
```

### 4. Display Risk Flags

```swift
struct RiskFlagView: View {
    let flag: RiskFlag
    @EnvironmentObject var autoIQ: AutoIQService

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(flag.message)
                    .font(.headline)
            }
            Text(flag.recommendedAction)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("Understood") {
                autoIQ.dismissRiskFlag(flag)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}
```

---

## API Reference

### AutoIQService

**Main service class. Inject as `@EnvironmentObject`.**

#### Published Properties

```swift
@Published var isStreaming: Bool
@Published var streamingText: String
@Published var currentProfile: AutoIQProfile?
@Published var activeRiskFlags: [RiskFlag]
```

#### Methods

**Chat & Conversation**
```swift
func chat(_ text: String, context: CarContext? = nil) async
func resetConversation()
```

**Behavioral Signals**
```swift
func recordSignal(_ signal: BehavioralSignal)
```

**Risk Management**
```swift
func dismissRiskFlag(_ flag: RiskFlag)
```

### AutoIQProfile

**The living user profile that grows with every interaction.**

```swift
public struct AutoIQProfile: Codable {
    public let userId: String
    public var lastUpdated: Date
    public var totalSignalsProcessed: Int

    // Preferences
    public var budgetRange: BudgetRange
    public var preferredBodyTypes: [WeightedPreference]
    public var preferredBrands: [WeightedPreference]
    public var rejectedBrands: [String]
    public var luxuryAffinity: Double              // 0.0–1.0
    public var priceSensitivity: Double           // 0.0–1.0
    public var practicalityWeight: Double         // 0.0–1.0

    // Archetypes
    public var archetypes: [ArchetypeScore]

    // Purchase Readiness
    public var purchaseIntentScore: Double        // 0.0–1.0
    public var decisionStage: DecisionStage       // exploring|comparing|deciding|ready_to_buy

    // Behavioral Data
    public var totalSwipes: Int
    public var rightSwipeRate: Double             // 0.0–1.0
    public var savedCarIds: [String]

    // Confidence
    public var overallConfidence: Double          // 0.0–1.0
}
```

### BehavioralSignal

**Represents any user interaction in the app.**

```swift
public struct BehavioralSignal: Codable {
    public let signalType: SignalType
    public let timestamp: Date
    public let sessionId: String
    public let carSnapshot: CarSnapshot?
    public let dwellDurationSeconds: Double?
    public let filterState: FilterState?

    public enum SignalType: String, Codable {
        case swipeRight, swipeLeftFast, swipeLeftSlow
        case swipeUp
        case dwellPhoto, dwellSpecs, dwellPrice
        case compareAction, repeatedView, saveAction, contactAction
        case chatMessage, filterChange
    }
}
```

### RiskFlag

**Alerts user to fraud, legal, or financial risks.**

```swift
public struct RiskFlag: Identifiable {
    public let id: UUID
    public let riskType: String
    public let severity: Severity                 // low|medium|high|critical
    public let message: String
    public let recommendedAction: String
    public let timestamp: Date
}
```

---

## Buyer Archetypes

Auto IQ automatically classifies users into one or more of these profiles:

| Archetype | Traits | Example |
|-----------|--------|----------|
| **Rational** | Specs-driven, wants data & reliability | Engineer comparing TCO |
| **Aspirational** | Status-conscious, identity-driven | Executive buying prestige |
| **Family** | Safety, space, practicality | Parent of 3 kids |
| **First-Time** | Overwhelmed, needs education | First car buyer |
| **Upgrader** | Has a car, wants better | Trading up for newer model |
| **Investor** | Depreciation & resale focused | Car flip / rental investor |
| **Eco** | Electric/hybrid, emissions-aware | Sustainability-minded buyer |
| **Adventurer** | 4x4, towing, off-road | Weekend trip enthusiast |
| **Urban Commuter** | Low km, fuel economy, pico y placa | City dweller, daily commute |

---

## Colombian Market Expertise

### Legal & Regulatory
- ✅ RUNT (gravámenes, estado del vehículo)
- ✅ SOAT & RTM requirements
- ✅ Traspaso process & costs
- ✅ Pico y placa restrictions
- ✅ Impuesto vehicular calculations
- ✅ Normativa de emisiones

### Pricing & Markets
- ✅ Regional variations (Bogotá, Medellín, Cali, Barranquilla, Bucaramanga)
- ✅ Seasonal demand patterns
- ✅ Used car pricing (2018–2025 models)
- ✅ Platform comparisons (OLX, TuCarro, Mercado Libre)

### Fraud Detection
- 🚨 Price anomalies (too cheap)
- 🚨 VIN inconsistencies
- 🚨 Odometer fraud signals
- 🚨 Hidden liens or flood damage
- 🚨 Seller pressure tactics

---

## Configuration

### Environment Setup

**1. Secure API Key**

```swift
// Secrets.swift
import Foundation

enum Secrets {
    static let anthropicKey: String = {
        // Priority: Environment → Info.plist → empty
        if let key = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !key.isEmpty {
            return key
        }
        return Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String ?? ""
    }()
}
```

**2. Info.plist**

```xml
<key>ANTHROPIC_API_KEY</key>
<string>$(ANTHROPIC_API_KEY)</string>
```

**3. Xcode Scheme (Development)**

`Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables`

Add: `ANTHROPIC_API_KEY = sk-ant-...`

**4. Production (Recommended)**

Use a **backend proxy** that holds the API key server-side. Never ship the raw key in the binary.

---

## Model Routing Strategy

| Layer | Model | Why |
|-------|-------|-----|
| Chat (user-visible) | `claude-opus-4-5` | Best Colombian market reasoning, nuanced profiling |
| Background signal flush | `claude-haiku-4-5-20251001` | 20x cheaper, sub-second latency |
| Deep analysis | `claude-opus-4-5` | Complex multi-factor reasoning |

---

## Testing

```swift
import XCTest
@testable import AutoIQ

final class AutoIQProfileTests: XCTestCase {
    func testProfileCreation() {
        let profile = AutoIQProfile(userId: "test_user")
        XCTAssertEqual(profile.userId, "test_user")
        XCTAssertEqual(profile.decisionStage, .exploring)
        XCTAssertEqual(profile.purchaseIntentScore, 0)
    }

    func testSignalRecording() {
        let signal = BehavioralSignal(
            signalType: .swipeRight,
            sessionId: UUID().uuidString
        )
        XCTAssertEqual(signal.signalType, .swipeRight)
    }
}
```

---

## License

MIT — AutomatchIA · Auto IQ Agent System  
Built for the Colombian automotive market 🇨🇴

---

## Support

For issues, questions, or contributions, visit:

**GitHub:** [ProDucktions-WEB/AutoIQ-Agent](https://github.com/ProDucktions-WEB/AutoIQ-Agent)

---

## Architecture

```
AutoIQ/
├── Sources/AutoIQ/
│   ├── AutoIQService.swift          # Main service
│   ├── Models/                      # Core data structures
│   │   ├── AutoIQProfile.swift
│   │   ├── BehavioralSignal.swift
│   │   └── RiskFlag.swift
│   ├── Store/                       # Persistence
│   │   └── AutoIQProfileStore.swift
│   ├── API/                         # Anthropic integration
│   │   └── AnthropicClient.swift
│   ├── Prompts/                     # System prompt
│   │   └── AutoIQPrompts.swift
│   └── Utils/                       # Helpers
│       ├── Extensions.swift
│       └── AnyCodable.swift
├── Tests/AutoIQTests/
│   ├── ProfileTests.swift
│   └── SignalProcessingTests.swift
└── Package.swift                    # Package manifest
```

---

**Happy buying! 🚗**
