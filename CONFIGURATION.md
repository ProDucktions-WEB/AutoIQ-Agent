# Configuration Guide

## Environment Variables

### Required

```bash
ANTHROPIC_API_KEY=sk-ant-...  # Your Anthropic API key
```

### Optional

```bash
AUTOIQ_LOG_LEVEL=debug         # debug|info|warning|error (default: warning)
AUTOIQ_MODEL=claude-opus-4-5   # Model override for testing
AUTOIQ_BACKEND_URL=...         # Backend proxy URL (if using)
```

---

## Info.plist Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- API Configuration -->
    <key>ANTHROPIC_API_KEY</key>
    <string>$(ANTHROPIC_API_KEY)</string>
    
    <!-- App Information -->
    <key>CFBundleName</key>
    <string>AutomatchIA</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleIdentifier</key>
    <string>com.producktions.automatchia</string>
    
    <!-- Auto IQ Configuration -->
    <key>AutoIQModelChat</key>
    <string>claude-opus-4-5</string>
    <key>AutoIQModelSignals</key>
    <string>claude-haiku-4-5-20251001</string>
    <key>AutoIQLogLevel</key>
    <string>warning</string>
    
    <!-- Security -->
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSLocalNetworkUsageDescription</key>
    <string>Auto IQ needs network access for market data and conversational AI.</string>
    <key>NSBonjourServices</key>
    <array/>
</dict>
</plist>
```

---

## Build Phases Setup

### Phase 1: Inject Environment Variables

In Xcode: Target → Build Phases → New Run Script Phase

```bash
#!/bin/bash

# Inject API key from environment into Info.plist
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "warning: ANTHROPIC_API_KEY not set. Auto IQ will not work."
fi

# Or use a configuration file
if [ -f "$SRCROOT/.env" ]; then
    source "$SRCROOT/.env"
fi
```

### Phase 2: Run Tests

```bash
swift test --enable-code-coverage
```

### Phase 3: Code Coverage Report

```bash
#!/bin/bash

# Generate coverage report
xcrun llvm-cov report \
    -instr-profile .build/default/codecov/default.profdata \
    .build/default/AutoIQ.build/Objects-normal/arm64e/AutoIQ.o
```

---

## Scheme Configuration

### Development Scheme

```
Product → Scheme → Edit Scheme → Run

Build Configuration: Debug
Environment Variables:
  ANTHROPIC_API_KEY = sk-ant-...
  AUTOIQ_LOG_LEVEL = debug
```

### Release Scheme

```
Build Configuration: Release

Environment Variables:
  (Load from GitHub Secrets or backend proxy)
  AUTOIQ_LOG_LEVEL = warning
```

---

## Swift Package Manager

### Declare Dependencies

In your app's `Package.swift`:

```swift
let package = Package(
    name: "AutomatchIA",
    dependencies: [
        .package(
            url: "https://github.com/ProDucktions-WEB/AutoIQ-Agent.git",
            from: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "AutomatchIA",
            dependencies: ["AutoIQ"]
        )
    ]
)
```

### Or in Xcode

File → Add Packages → `https://github.com/ProDucktions-WEB/AutoIQ-Agent.git`

---

## Memory & Performance Tuning

### Signal Buffer Optimization

```swift
// In AutoIQService.swift

private let signalFlushThreshold = 3        // Batch signals
private let signalFlushTimeout = 30.0       // Flush every 30s
private var signalBuffer: [BehavioralSignal] = []
```

**Tuning Guide:**
- **Low Memory (~2GB)**: Threshold = 2, Timeout = 20s
- **Normal (~4GB)**: Threshold = 3, Timeout = 30s (default)
- **High Memory (≥6GB)**: Threshold = 5, Timeout = 60s

### Profile Persistence

```swift
// UserDefaults vs. on-demand fetch

// Smaller profiles (<100KB): UserDefaults
let store = AutoIQProfileStore(userId: userId)
let profile = store.load()  // ~5ms

// Larger datasets: Implement custom caching
let cache = NSCache<NSString, NSData>()
```

---

## Network Configuration

### URLSession Configuration

```swift
let config = URLSessionConfiguration.default
config.waitsForConnectivity = true
config.timeoutIntervalForRequest = 30.0    // 30 second timeout
config.timeoutIntervalForResource = 300.0  // 5 minute total
config.httpMaximumConnectionsPerHost = 6
config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData

let session = URLSession(configuration: config)
```

### Certificate Pinning (Optional)

```swift
let pinning = ServerTrustPolicy.pinCertificates(
    withNames: ["api.anthropic.com"],
    validateCertificateChain: true,
    validateHost: true
)
```

---

## Logging Configuration

### Development

```swift
enum AutoIQConfig {
    static let logLevel = LogLevel.debug
    static let logToConsole = true
    static let logToFile = false
}
```

### Production

```swift
enum AutoIQConfig {
    static let logLevel = LogLevel.error
    static let logToConsole = false
    static let logToFile = true  // Send to backend
}
```

---

## Feature Flags

```swift
enum FeatureFlags {
    static let enableBehavioralProfiling = true
    static let enableRiskDetection = true
    static let enableStreamingChat = true
    static let enableCaching = true
    
    // For A/B testing
    static func isExperimentalModel(for userId: String) -> Bool {
        return userId.hashValue % 100 < 10  // 10% of users
    }
}
```

---

## System Requirements

### Minimum
- iOS 15.0+
- Swift 5.9+
- Xcode 15.0+
- 50 MB app storage (profiles + cache)

### Recommended
- iOS 17.0+
- Swift 6.0+
- Xcode 16.0+
- 100+ MB free device storage

---

## Troubleshooting

### API Key Not Found

```swift
// Check Info.plist
if let key = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String {
    print("✓ Key found in Info.plist")
} else {
    print("✗ Key not in Info.plist")
}

// Check environment
if let key = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] {
    print("✓ Key found in environment")
} else {
    print("✗ Key not in environment")
}
```

### Rate Limiting

```swift
// If seeing 429 errors:
// 1. Increase signal flush threshold
// 2. Reduce concurrent chat requests
// 3. Implement queue-based request throttling
```

### Memory Issues

```swift
// Profile store consuming too much memory?
// → Reduce `fieldConfidences` dictionary size
// → Archive old signals to backend
// → Implement LRU cache eviction
```

---

## See Also

- [DEPLOYMENT.md](./DEPLOYMENT.md) — Production deployment
- [README.md](./README.md) — Quick start and API reference
- [Anthropic Docs](https://docs.anthropic.com) — API documentation
