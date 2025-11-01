# Testing Strategy

**ShadowsocksX-NG Project**

Version 1.0 | Last Updated: 2025-11-02

---

## Table of Contents

1. [Overview](#overview)
2. [Testing Philosophy](#testing-philosophy)
3. [Current State](#current-state)
4. [Testing Goals](#testing-goals)
5. [Testing Pyramid](#testing-pyramid)
6. [Test Infrastructure](#test-infrastructure)
7. [Unit Testing](#unit-testing)
8. [Integration Testing](#integration-testing)
9. [UI Testing](#ui-testing)
10. [Mock Objects](#mock-objects)
11. [Test Coverage](#test-coverage)
12. [Testing Patterns](#testing-patterns)
13. [Continuous Integration](#continuous-integration)
14. [Testing Roadmap](#testing-roadmap)
15. [Best Practices](#best-practices)

---

## Overview

This document defines the testing strategy for ShadowsocksX-NG, a macOS application for managing Shadowsocks proxy connections. The strategy aims to establish a comprehensive testing framework that ensures code quality, prevents regressions, and facilitates confident refactoring.

**Key Principles:**
- Test behavior, not implementation
- Write tests first for new features (TDD where appropriate)
- Maintain high test coverage (70%+ target)
- Fast, reliable, independent tests
- Tests as documentation

---

## Testing Philosophy

### Why We Test

1. **Prevent Regressions**: Catch bugs before they reach users
2. **Enable Refactoring**: Change code confidently
3. **Document Behavior**: Tests serve as living documentation
4. **Improve Design**: Testable code is better designed
5. **Reduce Debugging Time**: Find issues immediately, not later

### Testing Values

- **Fast**: Tests should run quickly (unit tests < 1s total)
- **Reliable**: No flaky tests; same result every time
- **Independent**: Tests don't depend on each other
- **Readable**: Tests are clear and easy to understand
- **Maintainable**: Tests are easy to update as code evolves

---

## Current State

### Test Coverage Analysis (Baseline)

| Component | Lines of Code | Tests | Coverage | Status |
|-----------|---------------|-------|----------|--------|
| AppDelegate | 692 | 0 | 0% | ❌ Not tested |
| ServerProfile | 389 | 0 | 0% | ❌ Not tested |
| LaunchAgentUtils | 350 | 0 | 0% | ❌ Not tested |
| PACUtils | 200 | 0 | 0% | ❌ Not tested |
| ProxyConfHelper | 150 | 0 | 0% | ❌ Not tested |
| Others | 1,700 | 0 | 0% | ❌ Not tested |
| **Total** | **~3,481** | **0** | **0%** | ❌ |

### Critical Gaps

1. **No Unit Tests**: Zero automated tests for business logic
2. **No Integration Tests**: No tests for component interactions
3. **No UI Tests**: No automated UI testing
4. **Hard to Test Code**: Tight coupling, no dependency injection
5. **No Mocking Infrastructure**: No test doubles for dependencies
6. **No CI Testing**: No automated test runs on commits

### Risks

- High risk of regressions when refactoring
- Bugs not caught until runtime
- Difficult to verify edge cases
- Time-consuming manual testing
- Fear of changing code

---

## Testing Goals

### Short-Term (Phase 1: Weeks 1-4)

- [ ] Set up testing infrastructure
- [ ] Create mock implementations for key dependencies
- [ ] Write tests for critical paths (connection, configuration)
- [ ] Achieve 30% code coverage
- [ ] Add tests to CI pipeline

### Medium-Term (Phase 2: Weeks 5-8)

- [ ] Refactor untestable code
- [ ] Add comprehensive unit tests
- [ ] Implement integration tests
- [ ] Achieve 70% code coverage
- [ ] Establish testing culture

### Long-Term (Phase 3: Weeks 9+)

- [ ] Add UI tests for critical flows
- [ ] Achieve 80%+ code coverage
- [ ] Performance testing
- [ ] Mutation testing
- [ ] Test-driven development for new features

### Coverage Targets

| Phase | Target Coverage | Timeline | Priority |
|-------|----------------|----------|----------|
| **Phase 1** | 30% | Weeks 1-4 | Critical paths only |
| **Phase 2** | 70% | Weeks 5-8 | All business logic |
| **Phase 3** | 80%+ | Weeks 9+ | Edge cases, UI flows |

---

## Testing Pyramid

We follow the testing pyramid strategy:

```
        /\
       /  \  UI Tests (10%)
      /____\
     /      \
    / Integr \  Integration Tests (20%)
   /__________\
  /            \
 /     Unit     \  Unit Tests (70%)
/________________\
```

### Distribution

- **70% Unit Tests**: Fast, isolated tests of individual components
- **20% Integration Tests**: Test component interactions
- **10% UI Tests**: End-to-end user flows

### Rationale

- Unit tests are fast, reliable, and pinpoint failures
- Integration tests catch component interaction issues
- UI tests verify end-user experience but are slower and more brittle
- Pyramid shape ensures fast feedback and maintainability

---

## Test Infrastructure

### XCTest Framework

Use Apple's XCTest framework:

```swift
import XCTest
@testable import ShadowsocksX_NG

class ServerProfileTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Setup before each test
    }

    override func tearDown() {
        // Cleanup after each test
        super.tearDown()
    }

    func testValidProfile() {
        // Test implementation
    }
}
```

### Project Structure

```
ShadowsocksX-NG/
├── ShadowsocksX-NG/          # Main app code
│   ├── AppDelegate.swift
│   ├── ServerProfile.swift
│   └── ...
├── ShadowsocksX-NGTests/     # Unit & Integration tests
│   ├── Unit/
│   │   ├── ServerProfileTests.swift
│   │   ├── ProxyManagerTests.swift
│   │   └── ...
│   ├── Integration/
│   │   ├── LaunchAgentIntegrationTests.swift
│   │   └── ...
│   └── Mocks/
│       ├── MockProfileRepository.swift
│       ├── MockNetworkService.swift
│       └── ...
└── ShadowsocksX-NGUITests/   # UI tests
    ├── ConnectionFlowTests.swift
    └── SettingsFlowTests.swift
```

### Test Target Configuration

**ShadowsocksX-NGTests** (Unit & Integration):
- Host Application: ShadowsocksX-NG
- Allows testing of internal code with `@testable import`

**ShadowsocksX-NGUITests** (UI):
- UI Testing Bundle
- Tests app as black box

### Dependencies

Add testing dependencies via CocoaPods:

```ruby
# Podfile

target 'ShadowsocksX-NGTests' do
  inherit! :search_paths
  # Testing frameworks
  pod 'Quick'          # BDD testing framework
  pod 'Nimble'         # Matcher framework
  pod 'OHHTTPStubs'    # HTTP stubbing
end
```

---

## Unit Testing

### What to Unit Test

Test individual components in isolation:

1. **Data Models**: Validation, serialization, parsing
2. **Business Logic**: Calculations, transformations, rules
3. **Utilities**: Helper functions, extensions
4. **View Models**: Presentation logic (if using MVVM)
5. **Services**: Network calls, file I/O (with mocks)

### Unit Test Structure (AAA Pattern)

```swift
func testServerProfileValidation() {
    // Arrange - Set up test data
    let profile = ServerProfile(
        host: "example.com",
        port: 8080,
        password: "secret",
        method: .aes256gcm
    )

    // Act - Execute the behavior
    let isValid = profile.validate()

    // Assert - Verify the result
    XCTAssertTrue(isValid, "Valid profile should pass validation")
}
```

### Example: ServerProfile Tests

```swift
// ServerProfileTests.swift

import XCTest
@testable import ShadowsocksX_NG

class ServerProfileTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitializationWithValidData() {
        // Given
        let host = "example.com"
        let port = 8080
        let password = "secret"
        let method = EncryptionMethod.aes256gcm

        // When
        let profile = ServerProfile(
            host: host,
            port: port,
            password: password,
            method: method
        )

        // Then
        XCTAssertEqual(profile.host, host)
        XCTAssertEqual(profile.port, port)
        XCTAssertEqual(profile.password, password)
        XCTAssertEqual(profile.method, method)
    }

    // MARK: - Validation Tests

    func testValidationWithValidProfile() {
        // Given
        let profile = makeValidProfile()

        // When
        let result = profile.validate()

        // Then
        XCTAssertTrue(result)
    }

    func testValidationRejectsEmptyHost() {
        // Given
        var profile = makeValidProfile()
        profile.host = ""

        // When
        let result = profile.validate()

        // Then
        XCTAssertFalse(result)
    }

    func testValidationRejectsInvalidPort() {
        // Given
        var profile = makeValidProfile()

        // When/Then
        profile.port = 0
        XCTAssertFalse(profile.validate())

        profile.port = -1
        XCTAssertFalse(profile.validate())

        profile.port = 70000
        XCTAssertFalse(profile.validate())
    }

    func testValidationRejectsEmptyPassword() {
        // Given
        var profile = makeValidProfile()
        profile.password = ""

        // When
        let result = profile.validate()

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - URL Parsing Tests

    func testParseValidSSURL() throws {
        // Given
        let urlString = "ss://YWVzLTI1Ni1nY206c2VjcmV0QGV4YW1wbGUuY29tOjgwODA="

        // When
        let profile = try ServerProfile.parse(ssURL: urlString)

        // Then
        XCTAssertEqual(profile.host, "example.com")
        XCTAssertEqual(profile.port, 8080)
        XCTAssertEqual(profile.password, "secret")
        XCTAssertEqual(profile.method, .aes256gcm)
    }

    func testParseInvalidSSURLThrowsError() {
        // Given
        let invalidURL = "not-a-valid-url"

        // When/Then
        XCTAssertThrowsError(try ServerProfile.parse(ssURL: invalidURL)) { error in
            XCTAssertTrue(error is ServerProfileError)
        }
    }

    // MARK: - Serialization Tests

    func testCodableRoundTrip() throws {
        // Given
        let original = makeValidProfile()

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ServerProfile.self, from: data)

        // Then
        XCTAssertEqual(decoded.host, original.host)
        XCTAssertEqual(decoded.port, original.port)
        XCTAssertEqual(decoded.password, original.password)
        XCTAssertEqual(decoded.method, original.method)
    }

    // MARK: - Helper Methods

    private func makeValidProfile() -> ServerProfile {
        return ServerProfile(
            host: "example.com",
            port: 8080,
            password: "secret",
            method: .aes256gcm
        )
    }
}
```

### Test Naming Convention

Use descriptive test names:

```swift
// Pattern: test[UnitOfWork]_[Scenario]_[ExpectedResult]

func testValidate_WithEmptyHost_ReturnsFalse() { }
func testValidate_WithValidData_ReturnsTrue() { }
func testParse_WithInvalidURL_ThrowsError() { }
func testEncode_WithUnicodePassword_PreservesCharacters() { }
```

### Assertions

Use appropriate XCTest assertions:

```swift
// Equality
XCTAssertEqual(actual, expected)
XCTAssertNotEqual(actual, unexpected)

// Boolean
XCTAssertTrue(condition)
XCTAssertFalse(condition)

// Nil checking
XCTAssertNil(value)
XCTAssertNotNil(value)

// Errors
XCTAssertThrowsError(try someFunction())
XCTAssertNoThrow(try someFunction())

// Floating point
XCTAssertEqual(actual, expected, accuracy: 0.001)

// Custom messages
XCTAssertTrue(isValid, "Profile should be valid with correct data")
```

---

## Integration Testing

### What to Integration Test

Test how components work together:

1. **Service Integration**: ProxyManager + LaunchAgentUtils
2. **Data Flow**: Profile changes → Configuration update → Service restart
3. **File System**: Reading/writing configuration files
4. **Network**: API calls (with stubbed responses)
5. **System Integration**: launchctl interaction (mocked)

### Example: Proxy Manager Integration Test

```swift
// ProxyManagerIntegrationTests.swift

import XCTest
@testable import ShadowsocksX_NG

class ProxyManagerIntegrationTests: XCTestCase {

    var proxyManager: ProxyManager!
    var mockLaunchAgent: MockLaunchAgentService!
    var mockFileManager: MockFileManager!

    override func setUp() {
        super.setUp()

        // Create mocks
        mockLaunchAgent = MockLaunchAgentService()
        mockFileManager = MockFileManager()

        // Inject dependencies
        proxyManager = ProxyManager(
            launchAgentService: mockLaunchAgent,
            fileManager: mockFileManager
        )
    }

    override func tearDown() {
        proxyManager = nil
        mockLaunchAgent = nil
        mockFileManager = nil
        super.tearDown()
    }

    func testStartProxy_WritesConfigurationAndStartsService() throws {
        // Given
        let profile = ServerProfile(
            host: "example.com",
            port: 8080,
            password: "secret",
            method: .aes256gcm
        )

        // When
        try proxyManager.start(with: profile)

        // Then
        // 1. Configuration file should be written
        XCTAssertTrue(mockFileManager.writtenFiles.contains { $0.contains("ss-local.json") })

        // 2. Launch agent should be started
        XCTAssertTrue(mockLaunchAgent.loadedAgents.contains("com.qiuyuzhou.shadowsocksX-NG.local"))

        // 3. Status should be running
        XCTAssertEqual(proxyManager.status, .running)
    }

    func testStopProxy_StopsServiceAndCleansUp() throws {
        // Given - Start proxy first
        let profile = makeValidProfile()
        try proxyManager.start(with: profile)

        // When
        proxyManager.stop()

        // Then
        // 1. Launch agent should be unloaded
        XCTAssertTrue(mockLaunchAgent.unloadedAgents.contains("com.qiuyuzhou.shadowsocksX-NG.local"))

        // 2. Status should be stopped
        XCTAssertEqual(proxyManager.status, .stopped)
    }

    func testProfileChange_RestartsProxyWithNewConfiguration() throws {
        // Given - Proxy is running
        let initialProfile = ServerProfile(host: "server1.com", port: 8080, password: "pass1", method: .aes256gcm)
        try proxyManager.start(with: initialProfile)

        mockLaunchAgent.reset()

        // When - Profile changes
        let newProfile = ServerProfile(host: "server2.com", port: 9090, password: "pass2", method: .chacha20)
        try proxyManager.updateProfile(newProfile)

        // Then
        // 1. Old service should be stopped
        XCTAssertTrue(mockLaunchAgent.unloadedAgents.contains("com.qiuyuzhou.shadowsocksX-NG.local"))

        // 2. New configuration should be written
        let writtenConfig = mockFileManager.writtenFiles.last
        XCTAssertNotNil(writtenConfig)
        XCTAssertTrue(writtenConfig!.contains("server2.com"))

        // 3. New service should be started
        XCTAssertTrue(mockLaunchAgent.loadedAgents.contains("com.qiuyuzhou.shadowsocksX-NG.local"))
    }

    func testStartProxy_WhenAlreadyRunning_DoesNothing() throws {
        // Given - Proxy already running
        let profile = makeValidProfile()
        try proxyManager.start(with: profile)

        mockLaunchAgent.reset()

        // When - Try to start again
        try proxyManager.start(with: profile)

        // Then - Should not call launch agent again
        XCTAssertTrue(mockLaunchAgent.loadedAgents.isEmpty)
    }

    // MARK: - Error Handling

    func testStartProxy_WhenLaunchAgentFails_ThrowsError() {
        // Given
        mockLaunchAgent.shouldFailOnLoad = true
        let profile = makeValidProfile()

        // When/Then
        XCTAssertThrowsError(try proxyManager.start(with: profile)) { error in
            XCTAssertTrue(error is ProxyError)
        }
    }

    // MARK: - Helpers

    private func makeValidProfile() -> ServerProfile {
        return ServerProfile(
            host: "example.com",
            port: 8080,
            password: "secret",
            method: .aes256gcm
        )
    }
}
```

### Integration Test Best Practices

1. **Use real objects where possible**, mock only external dependencies
2. **Test realistic scenarios** that users will encounter
3. **Keep tests independent** - don't rely on test execution order
4. **Clean up state** after each test
5. **Test error paths** as well as happy paths

---

## UI Testing

### UI Test Strategy

Focus UI tests on critical user flows:

1. **Connection Flow**: Add server → Enable proxy → Verify connection
2. **Configuration Flow**: Edit server settings → Save → Verify applied
3. **PAC Update Flow**: Download GFW list → Update PAC → Verify
4. **Mode Switching**: Auto → Global → Manual modes

### Example: Connection Flow UI Test

```swift
// ConnectionFlowUITests.swift

import XCTest

class ConnectionFlowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func testAddServerAndConnect() {
        // Given - App is launched
        XCTAssertTrue(app.menuBars.firstMatch.exists)

        // When - Click menu bar icon
        let statusItem = app.statusItems.firstMatch
        statusItem.click()

        // Then - Menu should appear
        let menu = app.menus.firstMatch
        XCTAssertTrue(menu.exists)

        // When - Click "Servers" submenu
        menu.menuItems["Servers"].click()

        // When - Click "Add Server"
        menu.menuItems["Add Server"].click()

        // Then - Server editor window should open
        let window = app.windows["Server Preferences"]
        XCTAssertTrue(window.exists)

        // When - Fill in server details
        let hostField = window.textFields["Server Host"]
        hostField.click()
        hostField.typeText("example.com")

        let portField = window.textFields["Server Port"]
        portField.click()
        portField.typeText("8080")

        let passwordField = window.secureTextFields["Password"]
        passwordField.click()
        passwordField.typeText("secret")

        // When - Click Save
        window.buttons["Save"].click()

        // Then - Window should close
        XCTAssertFalse(window.exists)

        // When - Enable proxy
        statusItem.click()
        menu.menuItems["Turn Shadowsocks On"].click()

        // Then - Status should show connected
        statusItem.click()
        let statusText = menu.staticTexts.firstMatch.label
        XCTAssertTrue(statusText.contains("Connected"))
    }

    func testSwitchProxyModes() {
        // Given - Proxy is running
        setupRunningProxy()

        let statusItem = app.statusItems.firstMatch

        // When - Switch to Global mode
        statusItem.click()
        app.menus.firstMatch.menuItems["Proxy Mode"].hover()
        app.menus.firstMatch.menuItems["Global Mode"].click()

        // Then - Global mode should be active
        statusItem.click()
        let globalMenuItem = app.menus.firstMatch.menuItems["Global Mode"]
        XCTAssertTrue(globalMenuItem.value as? String == "1")  // Checked

        // When - Switch to Manual mode
        app.menus.firstMatch.menuItems["Proxy Mode"].hover()
        app.menus.firstMatch.menuItems["Manual Mode"].click()

        // Then - Manual mode should be active
        statusItem.click()
        let manualMenuItem = app.menus.firstMatch.menuItems["Manual Mode"]
        XCTAssertTrue(manualMenuItem.value as? String == "1")  // Checked
    }

    // MARK: - Helpers

    private func setupRunningProxy() {
        // Setup code to get proxy into running state
        // This might involve pre-populating configuration files
    }
}
```

### UI Testing Best Practices

1. **Minimize UI tests** - They're slow and brittle
2. **Test user-facing behavior** - Not implementation details
3. **Use accessibility identifiers** for stable element selection
4. **Keep tests independent** - Each test should set up its own state
5. **Test critical paths only** - Happy path + major error cases
6. **Use Page Object pattern** for maintainability

### Page Object Pattern

```swift
// Page Object for Server Preferences Window

class ServerPreferencesPage {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    var window: XCUIElement {
        return app.windows["Server Preferences"]
    }

    var hostField: XCUIElement {
        return window.textFields["Server Host"]
    }

    var portField: XCUIElement {
        return window.textFields["Server Port"]
    }

    var passwordField: XCUIElement {
        return window.secureTextFields["Password"]
    }

    var saveButton: XCUIElement {
        return window.buttons["Save"]
    }

    var cancelButton: XCUIElement {
        return window.buttons["Cancel"]
    }

    func enterServerDetails(host: String, port: String, password: String) {
        hostField.click()
        hostField.typeText(host)

        portField.click()
        portField.typeText(port)

        passwordField.click()
        passwordField.typeText(password)
    }

    func save() {
        saveButton.click()
    }

    func cancel() {
        cancelButton.click()
    }
}

// Usage in test
func testAddServer() {
    let prefsPage = ServerPreferencesPage(app: app)

    openServerPreferences()

    prefsPage.enterServerDetails(
        host: "example.com",
        port: "8080",
        password: "secret"
    )

    prefsPage.save()

    XCTAssertFalse(prefsPage.window.exists)
}
```

---

## Mock Objects

### Why Mock?

Mocks replace real dependencies for testing:

1. **Isolation**: Test one component at a time
2. **Speed**: No actual network/file system operations
3. **Control**: Simulate errors and edge cases easily
4. **Determinism**: Same result every time

### Mock Strategy

```swift
// Define protocol for dependency
protocol ProfileRepository {
    func loadProfiles() throws -> [ServerProfile]
    func saveProfiles(_ profiles: [ServerProfile]) throws
    func deleteProfile(id: UUID) throws
}

// Real implementation
class UserDefaultsProfileRepository: ProfileRepository {
    func loadProfiles() throws -> [ServerProfile] {
        // Real implementation using UserDefaults
    }

    func saveProfiles(_ profiles: [ServerProfile]) throws {
        // Real implementation
    }

    func deleteProfile(id: UUID) throws {
        // Real implementation
    }
}

// Mock implementation for testing
class MockProfileRepository: ProfileRepository {
    // Control behavior
    var shouldThrowError = false
    var errorToThrow: Error?

    // Track calls
    var loadCallCount = 0
    var saveCallCount = 0
    var deleteCallCount = 0

    // Stub data
    var stubProfiles: [ServerProfile] = []
    var savedProfiles: [ServerProfile] = []

    func loadProfiles() throws -> [ServerProfile] {
        loadCallCount += 1

        if shouldThrowError {
            throw errorToThrow ?? RepositoryError.loadFailed
        }

        return stubProfiles
    }

    func saveProfiles(_ profiles: [ServerProfile]) throws {
        saveCallCount += 1

        if shouldThrowError {
            throw errorToThrow ?? RepositoryError.saveFailed
        }

        savedProfiles = profiles
    }

    func deleteProfile(id: UUID) throws {
        deleteCallCount += 1

        if shouldThrowError {
            throw errorToThrow ?? RepositoryError.deleteFailed
        }

        savedProfiles.removeAll { $0.id == id }
    }

    // Reset for next test
    func reset() {
        shouldThrowError = false
        errorToThrow = nil
        loadCallCount = 0
        saveCallCount = 0
        deleteCallCount = 0
        stubProfiles = []
        savedProfiles = []
    }
}
```

### Mock Examples for ShadowsocksX-NG

#### MockLaunchAgentService

```swift
class MockLaunchAgentService: LaunchAgentServicing {
    var loadedAgents: [String] = []
    var unloadedAgents: [String] = []
    var shouldFailOnLoad = false
    var shouldFailOnUnload = false

    func load(agentNamed name: String) throws {
        if shouldFailOnLoad {
            throw LaunchAgentError.loadFailed(name)
        }
        loadedAgents.append(name)
    }

    func unload(agentNamed name: String) throws {
        if shouldFailOnUnload {
            throw LaunchAgentError.unloadFailed(name)
        }
        unloadedAgents.append(name)
    }

    func isLoaded(agentNamed name: String) -> Bool {
        return loadedAgents.contains(name) && !unloadedAgents.contains(name)
    }

    func reset() {
        loadedAgents = []
        unloadedAgents = []
        shouldFailOnLoad = false
        shouldFailOnUnload = false
    }
}
```

#### MockFileManager

```swift
class MockFileManager: FileManaging {
    var files: [String: Data] = [:]
    var directories: Set<String> = []
    var writtenFiles: [String] = []
    var shouldFailOnWrite = false

    func fileExists(atPath path: String) -> Bool {
        return files[path] != nil
    }

    func createDirectory(atPath path: String) throws {
        if shouldFailOnWrite {
            throw FileError.createDirectoryFailed
        }
        directories.insert(path)
    }

    func write(_ data: Data, toFile path: String) throws {
        if shouldFailOnWrite {
            throw FileError.writeFailed
        }
        files[path] = data
        writtenFiles.append(path)
    }

    func read(fromFile path: String) throws -> Data {
        guard let data = files[path] else {
            throw FileError.fileNotFound
        }
        return data
    }

    func removeFile(atPath path: String) throws {
        files.removeValue(forKey: path)
    }

    func reset() {
        files = [:]
        directories = []
        writtenFiles = []
        shouldFailOnWrite = false
    }
}
```

#### MockNetworkService

```swift
class MockNetworkService: NetworkServicing {
    var stubbedResponses: [URL: Result<Data, Error>] = [:]

    func fetch(from url: URL) async throws -> Data {
        guard let result = stubbedResponses[url] else {
            throw NetworkError.notStubbed
        }

        switch result {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }

    func stubSuccess(for url: URL, data: Data) {
        stubbedResponses[url] = .success(data)
    }

    func stubFailure(for url: URL, error: Error) {
        stubbedResponses[url] = .failure(error)
    }

    func reset() {
        stubbedResponses = [:]
    }
}
```

### Using Mocks in Tests

```swift
class ProfileManagerTests: XCTestCase {
    var profileManager: ProfileManager!
    var mockRepository: MockProfileRepository!

    override func setUp() {
        super.setUp()

        mockRepository = MockProfileRepository()
        profileManager = ProfileManager(repository: mockRepository)
    }

    func testLoadProfiles_Success() throws {
        // Given
        let expectedProfiles = [
            ServerProfile(host: "server1.com", port: 8080, password: "pass1", method: .aes256gcm),
            ServerProfile(host: "server2.com", port: 9090, password: "pass2", method: .chacha20)
        ]
        mockRepository.stubProfiles = expectedProfiles

        // When
        let profiles = try profileManager.loadProfiles()

        // Then
        XCTAssertEqual(profiles.count, 2)
        XCTAssertEqual(profiles, expectedProfiles)
        XCTAssertEqual(mockRepository.loadCallCount, 1)
    }

    func testLoadProfiles_Failure() {
        // Given
        mockRepository.shouldThrowError = true

        // When/Then
        XCTAssertThrowsError(try profileManager.loadProfiles())
    }

    func testSaveProfile_Success() throws {
        // Given
        let profile = ServerProfile(host: "example.com", port: 8080, password: "secret", method: .aes256gcm)

        // When
        try profileManager.saveProfile(profile)

        // Then
        XCTAssertEqual(mockRepository.saveCallCount, 1)
        XCTAssertTrue(mockRepository.savedProfiles.contains(profile))
    }
}
```

---

## Test Coverage

### Measuring Coverage

**Xcode Coverage:**

1. Edit scheme → Test → Options → Gather coverage
2. Run tests (Cmd+U)
3. View coverage in Report Navigator

**Command Line:**

```bash
xcodebuild test \
  -workspace ShadowsocksX-NG.xcworkspace \
  -scheme ShadowsocksX-NG \
  -enableCodeCoverage YES

# Generate coverage report
xcrun xccov view --report DerivedData/Logs/Test/*.xcresult
```

### Coverage Targets by Component

| Component | Phase 1 (30%) | Phase 2 (70%) | Phase 3 (80%+) |
|-----------|---------------|---------------|----------------|
| ServerProfile | 60% | 90% | 95% |
| ProxyManager | 50% | 80% | 90% |
| LaunchAgentUtils | 40% | 70% | 85% |
| PACUtils | 30% | 60% | 75% |
| AppDelegate | 20% | 50% | 70% |
| UI Code | 10% | 30% | 50% |

### What to Cover

**High Priority (Must Cover):**
- Business logic
- Data validation
- Error handling
- Edge cases
- Critical user flows

**Medium Priority:**
- Utility functions
- Configuration parsing
- File I/O
- Network operations

**Low Priority:**
- UI layout code
- Logging statements
- Simple getters/setters
- Generated code

### Coverage ≠ Quality

100% coverage doesn't mean bug-free:

```swift
// ❌ Bad - 100% coverage but doesn't test correctness
func testValidate() {
    let profile = ServerProfile(host: "", port: 0, password: "", method: .aes256gcm)
    _ = profile.validate()  // Just call it, don't assert
}

// ✅ Good - Actually tests behavior
func testValidateRejectsEmptyHost() {
    let profile = ServerProfile(host: "", port: 8080, password: "pass", method: .aes256gcm)
    XCTAssertFalse(profile.validate(), "Should reject empty host")
}
```

---

## Testing Patterns

### Test Data Builders

Create fluent builders for test data:

```swift
class ServerProfileBuilder {
    private var host = "example.com"
    private var port = 8080
    private var password = "secret"
    private var method = EncryptionMethod.aes256gcm

    func with(host: String) -> ServerProfileBuilder {
        self.host = host
        return self
    }

    func with(port: Int) -> ServerProfileBuilder {
        self.port = port
        return self
    }

    func with(password: String) -> ServerProfileBuilder {
        self.password = password
        return self
    }

    func with(method: EncryptionMethod) -> ServerProfileBuilder {
        self.method = method
        return self
    }

    func build() -> ServerProfile {
        return ServerProfile(
            host: host,
            port: port,
            password: password,
            method: method
        )
    }
}

// Usage
let profile = ServerProfileBuilder()
    .with(host: "test.com")
    .with(port: 9090)
    .build()
```

### Parameterized Tests

Test multiple scenarios with same logic:

```swift
func testPortValidation() {
    let testCases: [(port: Int, shouldBeValid: Bool)] = [
        (0, false),          // Zero
        (-1, false),         // Negative
        (1, true),           // Minimum valid
        (8080, true),        // Common port
        (65535, true),       // Maximum valid
        (65536, false),      // Too large
        (100000, false)      // Way too large
    ]

    for (port, shouldBeValid) in testCases {
        let profile = ServerProfileBuilder()
            .with(port: port)
            .build()

        let isValid = profile.validate()

        XCTAssertEqual(
            isValid,
            shouldBeValid,
            "Port \(port) validation failed: expected \(shouldBeValid), got \(isValid)"
        )
    }
}
```

### Async Testing

Test async code with expectations:

```swift
func testFetchServerList() {
    // Given
    let expectation = expectation(description: "Fetch server list")
    let expectedProfiles = [makeValidProfile()]

    mockNetworkService.stubSuccess(
        for: serverListURL,
        data: try! JSONEncoder().encode(expectedProfiles)
    )

    // When
    var receivedProfiles: [ServerProfile]?

    service.fetchServerList { result in
        if case .success(let profiles) = result {
            receivedProfiles = profiles
        }
        expectation.fulfill()
    }

    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(receivedProfiles, expectedProfiles)
}
```

### Async/Await Testing

```swift
func testFetchServerListAsync() async throws {
    // Given
    let expectedProfiles = [makeValidProfile()]

    mockNetworkService.stubSuccess(
        for: serverListURL,
        data: try! JSONEncoder().encode(expectedProfiles)
    )

    // When
    let profiles = try await service.fetchServerList()

    // Then
    XCTAssertEqual(profiles, expectedProfiles)
}
```

---

## Continuous Integration

### CI Test Strategy

Run tests on every commit:

```yaml
# .github/workflows/tests.yml
name: Tests

on:
  push:
    branches: [ develop, main ]
  pull_request:
    branches: [ develop ]

jobs:
  test:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v3

    - name: Install dependencies
      run: pod install

    - name: Run unit tests
      run: |
        xcodebuild test \
          -workspace ShadowsocksX-NG.xcworkspace \
          -scheme ShadowsocksX-NG \
          -destination 'platform=macOS' \
          -enableCodeCoverage YES

    - name: Generate coverage report
      run: |
        xcrun xccov view --report \
          --json DerivedData/Logs/Test/*.xcresult \
          > coverage.json

    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: ./coverage.json

    - name: Check coverage threshold
      run: |
        # Fail if coverage drops below 70%
        ./scripts/check-coverage.sh 70
```

### Test Automation

**Pre-commit Hook:**

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running tests before commit..."

xcodebuild test \
  -workspace ShadowsocksX-NG.xcworkspace \
  -scheme ShadowsocksX-NG \
  -destination 'platform=macOS' \
  -quiet

if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Commit aborted."
    exit 1
fi

echo "✅ Tests passed."
```

### Coverage Reports

Use Codecov or similar for coverage tracking:

```yaml
# codecov.yml
coverage:
  status:
    project:
      default:
        target: 70%
        threshold: 5%
    patch:
      default:
        target: 80%
```

---

## Testing Roadmap

### Phase 1: Foundation (Weeks 1-4)

**Week 1: Infrastructure Setup**
- [ ] Create test targets (Unit, Integration, UI)
- [ ] Add testing dependencies (Quick, Nimble, OHHTTPStubs)
- [ ] Set up CI pipeline for automated testing
- [ ] Configure code coverage reporting
- [ ] Create mock infrastructure

**Week 2: Critical Path Testing**
- [ ] ServerProfile validation tests (50+ tests)
- [ ] ServerProfile URL parsing tests (20+ tests)
- [ ] LaunchAgentUtils basic tests (30+ tests)
- [ ] ProxyManager start/stop tests (20+ tests)
- **Target**: 30% coverage

**Week 3: Data Layer Testing**
- [ ] ProfileRepository tests (40+ tests)
- [ ] UserDefaults persistence tests (20+ tests)
- [ ] Configuration file I/O tests (30+ tests)
- [ ] KeychainManager tests (20+ tests)

**Week 4: Error Handling Testing**
- [ ] Network error scenarios (20+ tests)
- [ ] File system error scenarios (15+ tests)
- [ ] Launch agent failure scenarios (15+ tests)
- [ ] Invalid input scenarios (25+ tests)

**Deliverable**: 30% code coverage, CI pipeline running

---

### Phase 2: Comprehensive Coverage (Weeks 5-8)

**Week 5: Integration Tests**
- [ ] Profile change → Service restart flow (10+ tests)
- [ ] PAC update flow (15+ tests)
- [ ] Proxy mode switching (20+ tests)
- [ ] QR code import flow (10+ tests)

**Week 6: Service Testing**
- [ ] GFWListService tests (25+ tests)
- [ ] PACService tests (30+ tests)
- [ ] NetworkService tests (20+ tests)
- [ ] UpdateService tests (15+ tests)

**Week 7: UI Component Testing**
- [ ] MenuBarController tests (20+ tests)
- [ ] PreferencesWindowController tests (30+ tests)
- [ ] ServerProfileViewController tests (25+ tests)

**Week 8: Edge Cases & Refactoring**
- [ ] Concurrent operation tests (15+ tests)
- [ ] Memory leak tests (10+ tests)
- [ ] Performance tests (10+ tests)
- [ ] Refactor untestable code to be testable
- **Target**: 70% coverage

**Deliverable**: 70% code coverage, all major flows tested

---

### Phase 3: Excellence (Weeks 9+)

**Week 9-10: UI Testing**
- [ ] Connection flow UI test (5+ tests)
- [ ] Settings flow UI test (8+ tests)
- [ ] PAC update UI test (4+ tests)
- [ ] Server management UI test (10+ tests)

**Week 11-12: Advanced Testing**
- [ ] Mutation testing setup
- [ ] Performance benchmarking
- [ ] Snapshot testing for UI
- [ ] Security testing (input validation)
- **Target**: 80%+ coverage

**Ongoing: Maintenance**
- [ ] TDD for all new features
- [ ] Regular coverage monitoring
- [ ] Flaky test elimination
- [ ] Test performance optimization

**Deliverable**: 80%+ coverage, rock-solid test suite

---

## Best Practices

### Writing Good Tests

#### 1. Tests Should Be FIRST

- **Fast**: Run quickly (milliseconds)
- **Independent**: Don't depend on other tests
- **Repeatable**: Same result every time
- **Self-Validating**: Pass or fail clearly
- **Timely**: Written with (or before) production code

#### 2. One Assert Per Test (Guideline)

```swift
// ❌ Bad - Multiple unrelated assertions
func testServerProfile() {
    let profile = makeProfile()
    XCTAssertEqual(profile.host, "example.com")
    XCTAssertEqual(profile.port, 8080)
    XCTAssertTrue(profile.validate())
    XCTAssertNotNil(profile.toURL())
}

// ✅ Good - Focused tests
func testServerProfileHost() {
    let profile = makeProfile()
    XCTAssertEqual(profile.host, "example.com")
}

func testServerProfilePort() {
    let profile = makeProfile()
    XCTAssertEqual(profile.port, 8080)
}

func testServerProfileValidation() {
    let profile = makeProfile()
    XCTAssertTrue(profile.validate())
}
```

#### 3. Arrange-Act-Assert Pattern

Always structure tests clearly:

```swift
func testExample() {
    // Arrange - Set up test conditions
    let profile = ServerProfileBuilder().with(host: "test.com").build()

    // Act - Perform the action
    let result = profile.validate()

    // Assert - Verify the outcome
    XCTAssertTrue(result)
}
```

#### 4. Descriptive Test Names

```swift
// ❌ Bad - Unclear
func test1() { }
func testValidation() { }

// ✅ Good - Clear intent
func testValidationRejectsEmptyHost() { }
func testValidationAcceptsLocalhostAddress() { }
func testParseThrowsErrorForInvalidURL() { }
```

#### 5. Test Behavior, Not Implementation

```swift
// ❌ Bad - Tests implementation details
func testUsesAES256Encryption() {
    XCTAssertEqual(profile.encryptionAlgorithm, "aes-256-gcm")
}

// ✅ Good - Tests behavior
func testEncryptedDataCanBeDecrypted() {
    let encrypted = profile.encrypt(data)
    let decrypted = profile.decrypt(encrypted)
    XCTAssertEqual(decrypted, data)
}
```

### Test Maintenance

#### Keep Tests DRY

Use helper methods and builders:

```swift
// ❌ Bad - Duplication
func testCase1() {
    let profile = ServerProfile(host: "example.com", port: 8080, password: "secret", method: .aes256gcm)
    // Test code
}

func testCase2() {
    let profile = ServerProfile(host: "example.com", port: 8080, password: "secret", method: .aes256gcm)
    // Test code
}

// ✅ Good - Shared helper
class ProfileTests: XCTestCase {
    func makeDefaultProfile() -> ServerProfile {
        return ServerProfile(
            host: "example.com",
            port: 8080,
            password: "secret",
            method: .aes256gcm
        )
    }

    func testCase1() {
        let profile = makeDefaultProfile()
        // Test code
    }

    func testCase2() {
        let profile = makeDefaultProfile()
        // Test code
    }
}
```

#### Avoid Test Interdependence

```swift
// ❌ Bad - Tests depend on execution order
var sharedState: ServerProfile?

func testA() {
    sharedState = makeProfile()
}

func testB() {
    XCTAssertNotNil(sharedState)  // Depends on testA
}

// ✅ Good - Independent tests
func testA() {
    let profile = makeProfile()
    // Use profile
}

func testB() {
    let profile = makeProfile()  // Create own data
    // Use profile
}
```

### Debugging Failed Tests

When tests fail:

1. **Read the error message** - XCTest provides good diagnostics
2. **Run test in isolation** - Rule out interdependencies
3. **Add breakpoints** - Debug like regular code
4. **Check test data** - Verify assumptions about input
5. **Simplify test** - Reduce to minimal failing case

### Performance Testing

Test performance-critical code:

```swift
func testPACRuleMatchingPerformance() {
    let pacService = PACService()
    let testURLs = (0..<10000).map { "https://example\($0).com" }

    measure {
        for url in testURLs {
            _ = pacService.shouldUseProxy(for: url)
        }
    }
}
```

---

## Summary

### Success Criteria

Our testing strategy succeeds when:

- ✅ **70%+ code coverage** maintained
- ✅ **All PRs include tests** for new features
- ✅ **CI pipeline passes** on every commit
- ✅ **No production bugs** from untested code paths
- ✅ **Confident refactoring** enabled by test safety net
- ✅ **Fast feedback** (tests run in < 30 seconds)

### Timeline Summary

| Phase | Duration | Coverage Target | Focus |
|-------|----------|-----------------|-------|
| **Phase 1** | Weeks 1-4 | 30% | Foundation, critical paths |
| **Phase 2** | Weeks 5-8 | 70% | Comprehensive coverage |
| **Phase 3** | Weeks 9+ | 80%+ | UI tests, excellence |

### Key Principles

1. **Test behavior, not implementation**
2. **Keep tests fast, independent, and reliable**
3. **Use dependency injection and mocking**
4. **Follow the testing pyramid (70% unit, 20% integration, 10% UI)**
5. **Write tests as documentation**
6. **Maintain high coverage, but focus on valuable tests**

---

## Next Steps

**Immediate Actions:**

1. Create `ShadowsocksX-NGTests` target in Xcode
2. Set up CocoaPods testing dependencies
3. Write first 10 unit tests for `ServerProfile`
4. Configure CI to run tests on commits
5. Add coverage reporting to CI

**Resources:**

- [Apple XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing Swift Code (WWDC)](https://developer.apple.com/videos/testing)
- [Quick/Nimble Frameworks](https://github.com/Quick/Quick)

---

**Version History**

- **1.0** (2025-11-02): Initial testing strategy

**Feedback**

Suggest improvements via pull requests or GitHub issues.
