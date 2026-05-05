# Contributing to Auto IQ

Thanks for your interest in contributing to Auto IQ! This guide will help you get started.

## Code Style

### Swift
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use 4-space indentation
- Use descriptive variable and function names
- Document public APIs with inline comments

```swift
/// Updates the user profile based on behavioral signals.
/// - Parameters:
///   - signal: The behavioral signal to process
/// - Returns: Updated confidence score
public func recordSignal(_ signal: BehavioralSignal) {
    // Implementation
}
```

### File Organization

```
Sources/AutoIQ/
├── AutoIQService.swift         # Main public API
├── Models/                     # Data structures
├── Store/                      # Persistence
├── API/                        # External integrations
├── Prompts/                    # Agent instructions
└── Utils/                      # Helpers
```

## Testing Requirements

All new features must include tests:

```bash
swift test --enable-code-coverage
```

Target: **>80% code coverage**

```swift
final class MyFeatureTests: XCTestCase {
    func testFeatureBehavior() {
        let result = feature(input)
        XCTAssertEqual(result, expected)
    }
}
```

## Commit Messages

Format: `<type>: <description>`

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `refactor:` Code refactoring
- `test:` Tests
- `docs:` Documentation
- `perf:` Performance improvement

**Examples:**
```
feat: Add profile export functionality
fix: Correct dwell time calculation in signal processing
refactor: Extract API client into separate class
test: Add comprehensive signal processing tests
docs: Update README with configuration guide
```

## Pull Request Process

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make changes with tests
4. Ensure all tests pass: `swift test`
5. Update documentation
6. Commit with meaningful messages
7. Push to your fork
8. Open a Pull Request with description of changes

## Areas for Contribution

### High Priority
- [ ] Backend proxy implementation guide
- [ ] CloudKit integration example
- [ ] Analytics integration
- [ ] Enhanced error handling
- [ ] Performance optimizations

### Medium Priority
- [ ] Additional buyer archetypes
- [ ] Regional market data expansion
- [ ] UI components library
- [ ] Internationalization (i18n)
- [ ] Accessibility improvements

### Low Priority
- [ ] Documentation improvements
- [ ] Example apps
- [ ] Community feedback features

## Reporting Issues

Use GitHub Issues with template:

```markdown
## Description
Clear, concise description of the issue

## Steps to Reproduce
1. Step one
2. Step two

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- iOS Version: 17.0
- Xcode Version: 15.0
- Auto IQ Version: 1.0.0
```

## Questions?

Open a discussion: [GitHub Discussions](https://github.com/ProDucktions-WEB/AutoIQ-Agent/discussions)

---

**Made with ❤️ for the Colombian automotive market 🇨🇴**
