# Deployment Guide

## Overview

This guide covers deploying Auto IQ to production environments, managing API keys securely, and monitoring agent performance.

---

## 1. API Key Management

### Development

**Option A: Environment Variables (Recommended for local development)**

```bash
# In terminal before running Xcode
export ANTHROPIC_API_KEY="sk-ant-..."
xed .  # Opens Xcode with environment variables
```

**Option B: Xcode Scheme**

1. Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables
3. Add: `ANTHROPIC_API_KEY = sk-ant-...`

### Staging & Production

**❌ NEVER commit API keys to Git**

**✅ Use one of these approaches:**

#### Option 1: Backend Proxy (Recommended)

Create a lightweight backend service that:
- Holds the Anthropic API key server-side
- Exposes a custom endpoint for Auto IQ requests
- Authenticates iOS clients with a session token

```swift
// In AutoIQService.swift
private let proxyURL = URL(string: "https://api.yourdomain.com/autoiq/chat")!

public func chat(_ text: String) async {
    var request = URLRequest(url: proxyURL)
    request.httpMethod = "POST"
    request.setValue(userSessionToken, forHTTPHeaderField: "Authorization")
    request.httpBody = try? JSONEncoder().encode(["message": text])
    
    let (data, _) = try await URLSession.shared.data(for: request)
    // Parse response
}
```

#### Option 2: GitHub Secrets (for CI/CD)

Store in your GitHub repository settings:

```bash
Settings → Secrets and variables → Actions → New repository secret
Name: ANTHROPIC_API_KEY
Value: sk-ant-...
```

Access in workflows:

```yaml
- name: Build & Test
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
  run: swift test
```

#### Option 3: Xcode Cloud

1. Xcode → Product → Publish to Xcode Cloud
2. Environment → Add Secret
3. Reference: `${ANTHROPIC_API_KEY}`

---

## 2. Build Configuration

### Info.plist

```xml
<dict>
    <!-- API Key placeholder -->
    <key>ANTHROPIC_API_KEY</key>
    <string>$(ANTHROPIC_API_KEY)</string>
    
    <!-- App Info -->
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
</dict>
```

### Secrets.swift (Swift)

Create but **DO NOT COMMIT**:

```swift
import Foundation

enum Secrets {
    static let anthropicKey: String = {
        // Priority: Environment → Info.plist → empty
        if let env = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"],
           !env.isEmpty {
            return env
        }
        
        if let bundleKey = Bundle.main.object(
            forInfoDictionaryKey: "ANTHROPIC_API_KEY"
        ) as? String, !bundleKey.isEmpty {
            return bundleKey
        }
        
        return ""  // Fallback to empty
    }()
}
```

Add to `.gitignore`:

```
Secrets.swift
.env
.env.local
```

---

## 3. Anthropic API Configuration

### Model Selection

```swift
// In AutoIQService.swift

private let chatModel = "claude-opus-4-5"              // ~$15/MTok
private let signalModel = "claude-haiku-4-5-20251001" // ~$0.80/MTok
```

| Environment | Chat | Signals | Cost Estimate |
|-------------|------|---------|----------------|
| Dev/Test | Opus | Haiku | ~$0.50/day |
| Staging | Opus | Haiku | ~$3-5/day |
| Production | Opus | Haiku | ~$10-20/day |

### Rate Limiting

AnthropicAPI rate limits (as of 2025):
- **Free Tier**: 40 requests/min, 4 concurrent
- **Pro**: 500 requests/min, 10 concurrent
- **Enterprise**: Custom limits

Implement exponential backoff:

```swift
private func sendWithRetry(_ request: MessagesRequest, maxAttempts: Int = 3) async throws -> MessagesResponse {
    for attempt in 1...maxAttempts {
        do {
            return try await client.sendMessage(request)
        } catch AnthropicError.httpError(429) {  // Rate limited
            let delay = pow(2.0, Double(attempt - 1))  // 1s, 2s, 4s
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }
    throw AnthropicError.httpError(429)
}
```

---

## 4. Database & Persistence

### User Profiles

**Current:** UserDefaults (local, single device)

```swift
let store = AutoIQProfileStore(userId: "user_123")
let profile = store.load()  // From device storage
store.save(profile)         // To device storage
```

**For Multi-Device Sync:**

**Option A: CloudKit (Apple ecosystem)**

```swift
import CloudKit

final class CloudAutoIQProfileStore {
    let container = CKContainer.default()
    
    func save(_ profile: AutoIQProfile) async throws {
        let record = CKRecord(recordType: "AutoIQProfile")
        record["userId"] = profile.userId
        record["data"] = try JSONEncoder().encode(profile)
        try await container.privateCloudDatabase.save(record)
    }
}
```

**Option B: Firebase Firestore**

```swift
import FirebaseFirestore

final class FirebaseAutoIQProfileStore {
    let db = Firestore.firestore()
    
    func save(_ profile: AutoIQProfile) async throws {
        try await db
            .collection("users")
            .document(profile.userId)
            .setData(from: profile)
    }
}
```

**Option C: Custom Backend**

```swift
final class BackendAutoIQProfileStore {
    let baseURL = URL(string: "https://api.yourdomain.com")!
    
    func save(_ profile: AutoIQProfile) async throws {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("/profiles/\(profile.userId)")
        )
        request.httpMethod = "PUT"
        request.httpBody = try JSONEncoder().encode(profile)
        try await URLSession.shared.data(for: request)
    }
}
```

---

## 5. Monitoring & Analytics

### Telemetry

Track key metrics:

```swift
final class AutoIQAnalytics {
    static let shared = AutoIQAnalytics()
    
    func logChatMessage(model: String, tokensUsed: Int, duration: TimeInterval) {
        // Send to analytics service (Firebase, Mixpanel, etc.)
        print("[AutoIQ] Chat: \(model) | \(tokensUsed) tokens | \(duration)ms")
    }
    
    func logSignalProcessed(_ signalType: BehavioralSignal.SignalType) {
        print("[AutoIQ] Signal: \(signalType.rawValue)")
    }
    
    func logError(_ error: Error) {
        print("[AutoIQ] Error: \(error.localizedDescription)")
    }
}
```

### Logging Levels

```swift
enum LogLevel: Int {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
}

let productionLogLevel = LogLevel.warning
```

---

## 6. Testing in Production

### A/B Testing Model Versions

```swift
final class AutoIQService {
    let chatModel: String
    
    init(apiKey: String, userId: String, variant: String = "stable") {
        self.apiKey = apiKey
        // Route to different models based on variant
        self.chatModel = variant == "experimental" 
            ? "claude-opus-4-5-next"
            : "claude-opus-4-5"
    }
}
```

### Canary Deployments

```swift
// Gradually route percentage of users to new implementation
let isEarlyAdopter = Int.random(in: 1...100) <= 10  // 10%
let useNewVersion = isEarlyAdopter || userProfile.isTestUser
```

---

## 7. Incident Response

### Circuit Breaker Pattern

```swift
final class ResilientAutoIQService {
    private var failureCount = 0
    private let failureThreshold = 5
    private var isCircuitOpen = false
    
    func chat(_ text: String) async {
        if isCircuitOpen {
            streamingText = "Auto IQ está en mantenimiento. Intenta en unos minutos."
            return
        }
        
        do {
            try await autoIQ.chat(text)
            failureCount = 0  // Reset on success
        } catch {
            failureCount += 1
            if failureCount >= failureThreshold {
                isCircuitOpen = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                    self.isCircuitOpen = false
                }
            }
        }
    }
}
```

### Error Budget

- **SLA**: 99.5% uptime (3.6 hours downtime/month)
- **Error Budget**: 43 minutes/month of acceptable failures
- **Monitor**: Anthropic status page + timeout tracking

---

## 8. GDPR & Data Privacy

### User Data Handling

```swift
// Auto IQ processes:
// - User queries (chat messages)
// - Behavioral signals (swipes, dwell times)
// - User profile data (preferences, archetypes)

// Best practices:
// ✅ Store profiles encrypted at rest (FileProtection)
// ✅ Transmit over HTTPS only
// ✅ Implement user data export/deletion
// ✅ Keep audit logs of API calls
```

### Right to Deletion

```swift
final class DataPrivacy {
    static func deleteUserData(userId: String) async throws {
        // 1. Delete local profile
        let store = AutoIQProfileStore(userId: userId)
        store.reset()
        
        // 2. Delete from backend
        var request = URLRequest(
            url: URL(string: "https://api.yourdomain.com/users/\(userId)")!
        )
        request.httpMethod = "DELETE"
        _ = try await URLSession.shared.data(for: request)
        
        // 3. Request deletion from Anthropic (if messages stored)
        // Anthropic doesn't retain messages by default
    }
}
```

---

## Checklist

- [ ] API key stored securely (not in code)
- [ ] Info.plist configured with placeholder
- [ ] .gitignore excludes Secrets.swift
- [ ] Error handling implemented
- [ ] Rate limiting handled
- [ ] Analytics integrated
- [ ] Data privacy policy reviewed
- [ ] Test API quota sufficient
- [ ] Monitoring/alerting configured
- [ ] Backup strategy for user profiles
- [ ] Data retention policy defined
- [ ] GDPR compliance verified

---

## Support

- **Anthropic Docs**: https://docs.anthropic.com
- **Status**: https://status.anthropic.com
- **Support**: https://support.anthropic.com
