# Code Quality Report
## ShadowsocksX-NG Swift Codebase Analysis

**Date:** 2025-11-02
**Version:** 1.0
**Analyzed:** 16 Swift files (~3,445 lines of code)

---

## Executive Summary

This report presents a comprehensive analysis of the ShadowsocksX-NG Swift codebase, identifying opportunities for improvement in code quality, architecture, performance, and maintainability. While the application is functional and serves its purpose well, there are significant areas where modern Swift best practices and architectural patterns could enhance the codebase.

### Overall Assessment

| Category | Status | Priority |
|----------|--------|----------|
| **Code Quality** | ⚠️ Needs Improvement | High |
| **Architecture** | ⚠️ Needs Improvement | High |
| **Performance** | 🟡 Acceptable | Medium |
| **Swift Modernization** | ⚠️ Outdated | Medium |
| **Testing** | ❌ Missing | High |
| **Security** | 🟢 Good (Keychain) | - |

### Key Strengths

- ✅ Keychain password management is well-implemented
- ✅ Application works reliably
- ✅ Good separation between UI and business logic in some areas
- ✅ Uses established third-party libraries (Alamofire, RxSwift)

### Critical Issues

1. **God Class Pattern** - AppDelegate handles too many responsibilities (692 lines)
2. **Widespread Use of Force Unwraps** - 20+ instances of unsafe `!` and `try!`
3. **I/O Blocking Main Thread** - Synchronous file operations on UI thread
4. **No Error Handling** - Empty catch blocks and ignored errors
5. **Tight Coupling** - Direct dependencies, no protocol abstractions
6. **No Unit Tests** - Zero test coverage

---

## 1. Code Quality Issues

### 1.1 God Class - AppDelegate.swift

**File:** `ShadowsocksX-NG/AppDelegate.swift`
**Lines:** 1-692 (entire file)
**Priority:** 🔴 CRITICAL

#### Problem

The AppDelegate class violates the Single Responsibility Principle by handling multiple unrelated concerns:

- Menu bar UI management
- Window controller lifecycle
- Proxy mode configuration
- Server profile management
- System notifications
- URL scheme handling
- Toast notifications
- File system operations
- Launch agent coordination
- Diagnostic report generation

#### Current Structure

```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    // Menu bar
    var statusItem: NSStatusItem!
    var statusItemMenu: NSMenu!

    // Window controllers (8 different windows!)
    var preferencesWindowController: PreferencesWindowController!
    var advPreferencesController: AdvPreferencesController!
    var aboutWindowController: AboutWindowController!
    // ... 5 more

    // Business logic
    func updateServersMenu() { /* 50 lines */ }
    func updateRunningModeMenu() { /* 40 lines */ }
    func applyConfig() { /* 30 lines */ }
    func generateDiagnosisText() { /* 100+ lines */ }

    // ... 40+ methods
}
```

#### Impact

- **Maintainability**: Extremely difficult to modify without side effects
- **Testability**: Impossible to unit test individual responsibilities
- **Readability**: Takes significant time to understand class purpose
- **Collaboration**: Merge conflicts inevitable with multiple developers

#### Recommended Solution

Extract responsibilities into focused classes:

```swift
// 1. Menu Management
class MenuBarManager {
    private let statusItem: NSStatusItem
    private let profileManager: ServerProfileManaging

    func updateServersMenu()
    func updateProxyModeMenu()
}

// 2. Window Coordination
class WindowCoordinator {
    func showPreferences()
    func showAbout()
    func showUserRules()
}

// 3. Proxy Configuration
class ProxyModeCoordinator {
    func switchMode(to mode: ProxyMode)
    func applyConfiguration()
}

// 4. Simplified AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuBarManager: MenuBarManager
    private let windowCoordinator: WindowCoordinator
    private let proxyCoordinator: ProxyModeCoordinator

    // Only lifecycle methods
    func applicationDidFinishLaunching(_ notification: Notification)
    func applicationWillTerminate(_ notification: Notification)
}
```

**Estimated Effort:** 2-3 days
**Dependencies:** None
**Benefits:** Improved testability, maintainability, and team collaboration

---

### 1.2 Force Unwraps and Unsafe Code

**Priority:** 🔴 CRITICAL

#### Problem

Extensive use of force unwraps (`!`) and force try (`try!`) throughout the codebase creates crash risks in production.

#### Instances Found

| File | Lines | Issue | Risk |
|------|-------|-------|------|
| `AppDelegate.swift` | 60 | `attrs[FileAttributeKey.ownerAccountName] as! String` | High |
| `AppDelegate.swift` | 118 | `NSImage(named: "menu_icon")!` | Medium |
| `AppDelegate.swift` | 431 | `try! ws.launchApplication(...)` | High |
| `AppDelegate.swift` | 463 | `try! diagnosisText.write(...)` | Medium |
| `ServerProfile.swift` | 189-206 | Multiple force casts in `fromDictionary()` | High |
| `LaunchAgentUtils.swift` | 41 | `try! fileMgr.createDirectory(...)` | High |
| `PACUtils.swift` | 56 | `try! fileMgr.moveItem(...)` | High |
| `PreferencesWindowController.swift` | 31 | `try! fileMgr.copyItem(...)` | High |
| `Diagnose.swift` | 33 | `try! JSONSerialization.data(...)` | Medium |

**Total:** 20+ instances

#### Example: AppDelegate.swift:60

```swift
// ❌ Current (UNSAFE)
do {
    let attrs = try fm.attributesOfItem(atPath: path)
    let owner = attrs[FileAttributeKey.ownerAccountName] as! String
    if owner != username {
        // ...
    }
} catch {
    // Empty catch!
}
```

**Problems:**
1. Force cast will crash if key doesn't exist or type is wrong
2. Empty catch block hides errors
3. No user feedback on failure

```swift
// ✅ Recommended (SAFE)
do {
    let attrs = try fm.attributesOfItem(atPath: path)
    guard let owner = attrs[FileAttributeKey.ownerAccountName] as? String else {
        logger.warning("Could not determine file owner for \(path)")
        return
    }

    if owner != username {
        logger.info("Fixing file owner from \(owner) to \(username)")
        // ...
    }
} catch {
    logger.error("Failed to check file attributes: \(error.localizedDescription)")
    showAlert("Unable to verify LaunchAgents directory permissions")
}
```

#### Example: ServerProfile.swift:189-206

```swift
// ❌ Current (UNSAFE)
class func fromDictionary(_ data:[String:AnyObject?]) -> ServerProfile {
    let p = ServerProfile()
    p.serverHost = data["ServerHost"] as! String
    p.serverPort = (data["ServerPort"] as! NSNumber).uint16Value
    p.method = data["Method"] as! String
    // ... more force casts
    return p
}
```

**Problems:**
1. Will crash on any missing or mistyped field
2. No validation
3. No error reporting

```swift
// ✅ Recommended (SAFE)
class func fromDictionary(_ data: [String: AnyObject?]) -> ServerProfile? {
    guard let serverHost = data["ServerHost"] as? String,
          let serverPortNum = data["ServerPort"] as? NSNumber,
          let method = data["Method"] as? String else {
        logger.error("Invalid server profile data: missing required fields")
        return nil
    }

    let profile = ServerProfile()
    profile.serverHost = serverHost
    profile.serverPort = serverPortNum.uint16Value
    profile.method = method

    // Optional fields with defaults
    profile.remark = data["Remark"] as? String ?? ""
    profile.plugin = data["Plugin"] as? String ?? ""

    return profile
}
```

**Estimated Effort:** 1-2 days to fix all instances
**Priority:** Must fix before any major feature work
**Benefits:** Eliminates crash risks, improves user experience

---

### 1.3 Poor Error Handling

**Priority:** 🔴 CRITICAL

#### Problem

Empty catch blocks and ignored errors throughout the codebase silently fail, leaving users confused about what went wrong.

#### Instances Found

| File | Lines | Context |
|------|-------|---------|
| `LaunchAgentUtils.swift` | 156-158 | GeneratePACFile failure ignored |
| `PACUtils.swift` | 103-105 | File move failure ignored |
| `PACUtils.swift` | 151-153 | Template copy failure ignored |
| `PACUtils.swift` | 156-158 | JSON write failure ignored |
| `UserRulesController.swift` | 272 | Rule write failure ignored |
| `ShareServerProfilesWindowController.swift` | 92 | File operations with `try!` |

#### Example: LaunchAgentUtils.swift:156-158

```swift
// ❌ Current
do {
    try gfwlist.write(toFile: GFWListFilePath, atomically: true, encoding: .utf8)
} catch {
    // Silent failure!
}
```

**Impact:**
- User doesn't know PAC file failed to generate
- Proxy won't work, but no indication why
- Debugging becomes extremely difficult

```swift
// ✅ Recommended
enum PACError: LocalizedError {
    case writeFailed(path: String, reason: Error)
    case downloadFailed(url: String)
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .writeFailed(let path, let reason):
            return "Failed to write PAC file to \(path): \(reason.localizedDescription)"
        case .downloadFailed(let url):
            return "Failed to download GFW list from \(url)"
        case .invalidFormat:
            return "Downloaded GFW list has invalid format"
        }
    }
}

do {
    try gfwlist.write(toFile: GFWListFilePath, atomically: true, encoding: .utf8)
    logger.info("Successfully wrote PAC file to \(GFWListFilePath)")
} catch {
    let pacError = PACError.writeFailed(path: GFWListFilePath, reason: error)
    logger.error("PAC generation failed: \(pacError.localizedDescription)")

    NotificationCenter.default.post(
        name: NOTIFY_PAC_GENERATION_FAILED,
        object: pacError
    )

    // Show user-facing alert if critical
    if criticalOperation {
        showAlert(pacError.localizedDescription)
    }
}
```

**Recommended Error Handling Strategy:**

```swift
// Create centralized error handler
class ErrorHandler {
    static func handle(_ error: Error, context: String, critical: Bool = false) {
        logger.error("[\(context)] \(error.localizedDescription)")

        // Report to analytics (if implemented)
        Analytics.reportError(error, context: context)

        // Show to user if critical
        if critical {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Error in \(context)"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .critical
                alert.runModal()
            }
        }
    }
}

// Usage
do {
    try performCriticalOperation()
} catch {
    ErrorHandler.handle(error, context: "PAC Generation", critical: true)
}
```

**Estimated Effort:** 2-3 days
**Benefits:** Better user experience, easier debugging, crash analytics

---

### 1.4 Code Duplication

**Priority:** 🟡 HIGH

#### Problem

Similar logic is copy-pasted across multiple locations instead of being abstracted.

#### Example 1: Service Synchronization

**LaunchAgentUtils.swift:171-202 (SyncSSLocal)**
```swift
func SyncSSLocal() {
    var on = UserDefaults.standard.bool(forKey: "ShadowsocksOn")
    let enabled = UserDefaults.standard.bool(forKey: "LocalHTTP.ListenEnabled")
    let localPort = UserDefaults.standard.integer(forKey: "LocalHTTP.ListenPort")

    if on {
        if httpProxyUrl == "" {
            httpProxyUrl = "http://127.0.0.1:\(localPort)"
        }

        // 30+ lines of logic
    }
}
```

**LaunchAgentUtils.swift:425-452 (SyncPrivoxy)**
```swift
func SyncPrivoxy() {
    let on = UserDefaults.standard.bool(forKey: "LocalHTTP.ListenEnabled")
    let httpPort = UserDefaults.standard.integer(forKey: "LocalSocks5.ListenPort")
    let localPort = UserDefaults.standard.integer(forKey: "LocalHTTP.ListenPort")

    // Almost identical logic!
}
```

**Duplication:** 90% identical code structure

**Solution:**

```swift
// Generic service synchronization
protocol LaunchService {
    var serviceName: String { get }
    var plistName: String { get }
    var enabledKey: String { get }
    func generateConfig() throws -> String
}

class ServiceSynchronizer {
    func sync<T: LaunchService>(_ service: T) throws {
        let enabled = UserDefaults.standard.bool(forKey: service.enabledKey)
        let plistPath = service.plistPath

        if enabled {
            // Generate config
            let config = try service.generateConfig()
            try config.write(toFile: service.configPath, atomically: true, encoding: .utf8)

            // Generate plist
            let plist = try service.generatePlist()
            try plist.write(toFile: plistPath, atomically: true, encoding: .utf8)

            // Load service
            try runLaunchCtl("load", plistPath)
        } else {
            try runLaunchCtl("unload", plistPath)
            try? FileManager.default.removeItem(atPath: plistPath)
        }
    }
}

// Concrete implementations
struct SSLocalService: LaunchService {
    var serviceName = "ss-local"
    var plistName = "com.qiuyuzhou.shadowsocksX-NG.local"
    var enabledKey = "ShadowsocksOn"

    func generateConfig() throws -> String {
        // ss-local specific config
    }
}

struct PrivoxyService: LaunchService {
    var serviceName = "privoxy"
    var plistName = "com.qiuyuzhou.shadowsocksX-NG.http"
    var enabledKey = "LocalHTTP.ListenEnabled"

    func generateConfig() throws -> String {
        // privoxy specific config
    }
}

// Usage
let synchronizer = ServiceSynchronizer()
try synchronizer.sync(SSLocalService())
try synchronizer.sync(PrivoxyService())
```

**Benefits:**
- Single source of truth for sync logic
- Easy to add new services
- Better error handling
- More testable

**Estimated Effort:** 1 day
**Lines Saved:** ~100 lines

---

### 1.5 Magic Strings and Numbers

**Priority:** 🟡 MEDIUM

#### Problem

String literals and magic numbers scattered throughout code make it error-prone and hard to maintain.

#### Examples

**AppDelegate.swift:**
```swift
// Lines 96-114: UserDefaults keys as literals
let on = defaults.bool(forKey: "ShadowsocksOn")
let mode = defaults.string(forKey: "ShadowsocksRunningMode")
let port = defaults.integer(forKey: "LocalSocks5.ListenPort")

// Line 49: Magic number
let item = statusItemMenu.item(withTag: 100 + Int(i))

// Lines 259-260: Mode strings
defaults.set("auto", forKey: "ShadowsocksRunningMode")
defaults.set("global", forKey: "ShadowsocksRunningMode")
```

**ServerProfile.swift:**
```swift
// Lines 29-47: Method strings
if self.method == "aes-256-cfb" { ... }
else if self.method == "aes-128-cfb" { ... }
// 15+ similar comparisons
```

**Solution:**

```swift
// 1. Centralized constants
enum Constants {
    enum UserDefaults {
        static let shadowsocksOn = "ShadowsocksOn"
        static let runningMode = "ShadowsocksRunningMode"
        static let listenPort = "LocalSocks5.ListenPort"
        static let httpEnabled = "LocalHTTP.ListenEnabled"
        static let httpPort = "LocalHTTP.ListenPort"
    }

    enum UI {
        static let menuItemIndexBase = 100
        static let maxServersInMenu = 10
    }
}

// 2. Type-safe enums
enum ProxyMode: String, Codable, CaseIterable {
    case auto
    case global
    case manual
    case externalPAC

    var displayName: String {
        switch self {
        case .auto: return NSLocalizedString("Auto Mode By PAC", comment: "")
        case .global: return NSLocalizedString("Global Mode", comment: "")
        case .manual: return NSLocalizedString("Manual Mode", comment: "")
        case .externalPAC: return NSLocalizedString("Auto Mode By External PAC", comment: "")
        }
    }

    var menuShortcut: String {
        switch self {
        case .auto: return "a"
        case .global: return "g"
        case .manual: return "m"
        case .externalPAC: return "e"
        }
    }
}

enum EncryptionMethod: String, CaseIterable {
    case aes128gcm = "aes-128-gcm"
    case aes192gcm = "aes-192-gcm"
    case aes256gcm = "aes-256-gcm"
    case aes128cfb = "aes-128-cfb"
    case aes192cfb = "aes-192-cfb"
    case aes256cfb = "aes-256-cfb"
    case chacha20 = "chacha20"
    case chacha20ietf = "chacha20-ietf"
    case chacha20ietfpoly1305 = "chacha20-ietf-poly1305"
    case xchacha20ietfpoly1305 = "xchacha20-ietf-poly1305"

    var displayName: String {
        return rawValue
    }

    var isAEAD: Bool {
        return rawValue.contains("gcm") || rawValue.contains("poly1305")
    }
}

// 3. Property wrapper for type-safe UserDefaults
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    let defaults: UserDefaults

    init(_ key: String, defaultValue: T, defaults: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.defaults = defaults
    }

    var wrappedValue: T {
        get {
            return defaults.object(forKey: key) as? T ?? defaultValue
        }
        set {
            defaults.set(newValue, forKey: key)
        }
    }
}

// 4. Type-safe preferences
class Preferences {
    @UserDefault(Constants.UserDefaults.shadowsocksOn, defaultValue: false)
    static var isShadowsocksOn: Bool

    @UserDefault(Constants.UserDefaults.listenPort, defaultValue: 1086)
    static var socksPort: Int

    static var proxyMode: ProxyMode {
        get {
            guard let raw = UserDefaults.standard.string(forKey: Constants.UserDefaults.runningMode),
                  let mode = ProxyMode(rawValue: raw) else {
                return .auto
            }
            return mode
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Constants.UserDefaults.runningMode)
        }
    }
}

// Usage
if Preferences.isShadowsocksOn {
    switch Preferences.proxyMode {
    case .auto:
        configurePAC()
    case .global:
        configureGlobal()
    case .manual:
        // ...
    case .externalPAC:
        // ...
    }
}
```

**Benefits:**
- Compile-time safety (typos caught at compile time)
- Autocomplete in IDE
- Easier refactoring (change in one place)
- Better discoverability of available options

**Estimated Effort:** 2 days
**Priority:** Medium (high value, but not blocking)

---

## 2. Architecture Issues

### 2.1 Tight Coupling - No Protocol Abstractions

**Priority:** 🔴 HIGH

#### Problem

Classes directly depend on concrete implementations, making code hard to test and modify.

#### Examples

```swift
// AppDelegate.swift - Direct singleton access
let profiles = ServerProfileManager.instance.profiles
let activeProfile = ServerProfileManager.instance.getActiveProfile()

// Throughout codebase - Direct UserDefaults access
let value = UserDefaults.standard.bool(forKey: "SomeKey")

// LaunchAgentUtils.swift - Global functions, no abstraction
StartSSLocal()
StopSSLocal()
```

#### Solution: Dependency Injection with Protocols

```swift
// 1. Define protocols for all services
protocol ServerProfileManaging {
    var profiles: [ServerProfile] { get }
    var activeProfile: ServerProfile? { get }

    func add(_ profile: ServerProfile)
    func remove(_ profile: ServerProfile)
    func save()
    func reload()
}

protocol PreferencesManaging {
    func bool(forKey: String) -> Bool
    func integer(forKey: String) -> Int
    func string(forKey: String) -> String?
    func set(_ value: Any?, forKey: String)
}

protocol LaunchAgentManaging {
    func start(service: String) async throws
    func stop(service: String) async throws
    func restart(service: String) async throws
    func isRunning(service: String) -> Bool
}

// 2. Concrete implementations
class ServerProfileManager: ServerProfileManaging {
    static let shared = ServerProfileManager()
    // ... existing implementation
}

class UserDefaultsPreferences: PreferencesManaging {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func bool(forKey key: String) -> Bool {
        return defaults.bool(forKey: key)
    }
    // ... other methods
}

// 3. Inject dependencies
class AppDelegate: NSObject, NSApplicationDelegate {
    // Injected dependencies
    private let profileManager: ServerProfileManaging
    private let preferences: PreferencesManaging
    private let launchAgentManager: LaunchAgentManaging

    // Default initialization (production)
    convenience override init() {
        self.init(
            profileManager: ServerProfileManager.shared,
            preferences: UserDefaultsPreferences(),
            launchAgentManager: LaunchAgentManager.shared
        )
    }

    // Testable initialization
    init(
        profileManager: ServerProfileManaging,
        preferences: PreferencesManaging,
        launchAgentManager: LaunchAgentManaging
    ) {
        self.profileManager = profileManager
        self.preferences = preferences
        self.launchAgentManager = launchAgentManager
        super.init()
    }

    // Now testable!
    func updateProxyMode() {
        guard preferences.bool(forKey: "ShadowsocksOn") else { return }

        let mode = preferences.string(forKey: "ShadowsocksRunningMode") ?? "auto"
        // ... rest of logic
    }
}

// 4. Testing becomes easy
class MockProfileManager: ServerProfileManaging {
    var profiles: [ServerProfile] = []
    var activeProfile: ServerProfile?
    var saveCalled = false

    func save() {
        saveCalled = true
    }
    // ... other methods
}

class AppDelegateTests: XCTestCase {
    func testUpdateProxyMode() {
        let mockProfiles = MockProfileManager()
        let mockPrefs = MockPreferences()
        let sut = AppDelegate(
            profileManager: mockProfiles,
            preferences: mockPrefs,
            launchAgentManager: MockLaunchAgent()
        )

        mockPrefs.setBool(true, forKey: "ShadowsocksOn")
        sut.updateProxyMode()

        XCTAssertTrue(mockProfiles.saveCalled)
    }
}
```

**Benefits:**
- Testable without running actual app
- Can swap implementations (e.g., different storage backends)
- Clearer dependencies
- Easier to mock for tests

**Estimated Effort:** 3-4 days
**Impact:** High - enables all future testing

---

### 2.2 Violation of Single Responsibility Principle (SRP)

**Priority:** 🔴 HIGH

#### Problem: ServerProfile Class

**File:** `ServerProfile.swift`
**Lines:** 1-389

The ServerProfile class has too many responsibilities:

1. **Data Model** (properties)
2. **Validation** (validatePassword, validateHost, etc.)
3. **URL Parsing** (fromURL)
4. **Serialization** (toJSON, toDictionary, fromDictionary)
5. **Password Management** (Keychain integration)
6. **QR Code Generation** (URL encoding)

#### Solution: Split into Focused Classes

```swift
// 1. Pure data model
struct ServerProfile: Codable, Identifiable {
    let id: UUID
    var serverHost: String
    var serverPort: UInt16
    var method: EncryptionMethod
    var remark: String
    var plugin: String
    var pluginOptions: String

    init(
        id: UUID = UUID(),
        serverHost: String = "",
        serverPort: UInt16 = 8388,
        method: EncryptionMethod = .aes256gcm,
        remark: String = "",
        plugin: String = "",
        pluginOptions: String = ""
    ) {
        self.id = id
        self.serverHost = serverHost
        self.serverPort = serverPort
        self.method = method
        self.remark = remark
        self.plugin = plugin
        self.pluginOptions = pluginOptions
    }
}

// 2. Validation
struct ServerProfileValidator {
    enum ValidationError: LocalizedError {
        case invalidHost(String)
        case invalidPort(UInt16)
        case invalidMethod(String)
        case passwordTooShort

        var errorDescription: String? {
            switch self {
            case .invalidHost(let host):
                return "Invalid server host: \(host)"
            case .invalidPort(let port):
                return "Invalid port: \(port)"
            case .invalidMethod(let method):
                return "Invalid encryption method: \(method)"
            case .passwordTooShort:
                return "Password must be at least 6 characters"
            }
        }
    }

    func validate(_ profile: ServerProfile, password: String) throws {
        // Host validation
        guard !profile.serverHost.isEmpty else {
            throw ValidationError.invalidHost("Host cannot be empty")
        }

        // Port validation
        guard profile.serverPort > 0 && profile.serverPort < 65536 else {
            throw ValidationError.invalidPort(profile.serverPort)
        }

        // Password validation
        guard password.count >= 6 else {
            throw ValidationError.passwordTooShort
        }
    }
}

// 3. URL parsing
struct ServerProfileURLParser {
    enum URLFormat {
        case legacy // ss://base64(method:password@host:port)
        case sip002  // ss://base64(method:password)@host:port/?plugin=...
    }

    func parse(_ url: URL) throws -> (profile: ServerProfile, password: String) {
        guard url.scheme == "ss" else {
            throw ParsingError.invalidScheme
        }

        // Detect format and parse accordingly
        if url.host != nil {
            return try parseSIP002(url)
        } else {
            return try parseLegacy(url)
        }
    }

    private func parseLegacy(_ url: URL) throws -> (ServerProfile, String) {
        // Implementation
    }

    private func parseSIP002(_ url: URL) throws -> (ServerProfile, String) {
        // Implementation
    }
}

// 4. Password management
class ServerProfilePasswordManager {
    private let keychain: KeychainManaging

    init(keychain: KeychainManaging = KeychainManager.shared) {
        self.keychain = keychain
    }

    func getPassword(for profile: ServerProfile) -> String? {
        return keychain.getPassword(forAccount: profile.id.uuidString)
    }

    func setPassword(_ password: String, for profile: ServerProfile) throws {
        try keychain.savePassword(password, forAccount: profile.id.uuidString)
    }

    func deletePassword(for profile: ServerProfile) throws {
        try keychain.deletePassword(forAccount: profile.id.uuidString)
    }
}

// 5. URL generation (for QR codes)
struct ServerProfileURLGenerator {
    func generateURL(for profile: ServerProfile, password: String, format: URLFormat = .sip002) -> URL? {
        switch format {
        case .legacy:
            return generateLegacyURL(profile, password: password)
        case .sip002:
            return generateSIP002URL(profile, password: password)
        }
    }
}

// Usage
let parser = ServerProfileURLParser()
let (profile, password) = try parser.parse(url)

let validator = ServerProfileValidator()
try validator.validate(profile, password: password)

let passwordManager = ServerProfilePasswordManager()
try passwordManager.setPassword(password, for: profile)

let generator = ServerProfileURLGenerator()
let qrURL = generator.generateURL(for: profile, password: password)
```

**Benefits:**
- Each class has one clear purpose
- Easy to test in isolation
- Easy to modify one aspect without affecting others
- Better code reuse

**Estimated Effort:** 2-3 days
**Lines Reduced:** ServerProfile.swift from 389 to ~100 lines

---

### 2.3 Missing Abstractions

**Priority:** 🟡 MEDIUM

#### Problem: Direct System API Usage

Throughout the codebase, system APIs are used directly without abstraction:

```swift
// File system operations
let fm = FileManager.default
try fm.createDirectory(atPath: path, withIntermediateDirectories: true)
try fm.copyItem(at: src, to: dst)

// Process execution
let task = Process()
task.launchPath = "/bin/launchctl"
task.arguments = ["load", plistPath]
task.launch()
task.waitUntilExit()

// UserDefaults
UserDefaults.standard.set(value, forKey: key)
```

**Problems:**
- Hard to test (requires actual file system)
- No error logging/metrics
- Scattered error handling
- Can't swap implementations

#### Solution: Protocol-Based Abstractions

```swift
// 1. File System Abstraction
protocol FileSystemManaging {
    func fileExists(atPath path: String) -> Bool
    func createDirectory(atPath path: String, withIntermediateDirectories: Bool) throws
    func copyItem(at srcURL: URL, to dstURL: URL) throws
    func moveItem(at srcURL: URL, to dstURL: URL) throws
    func removeItem(at URL: URL) throws
    func contentsOfDirectory(at URL: URL) throws -> [URL]
}

class FileSystemManager: FileSystemManaging {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func createDirectory(atPath path: String, withIntermediateDirectories: Bool) throws {
        do {
            try fileManager.createDirectory(
                atPath: path,
                withIntermediateDirectories: withIntermediateDirectories
            )
            logger.debug("Created directory: \(path)")
        } catch {
            logger.error("Failed to create directory \(path): \(error)")
            throw error
        }
    }

    // ... other methods with logging
}

// Mock for testing
class MockFileSystem: FileSystemManaging {
    var files: [String: Data] = [:]
    var directories: Set<String> = []

    func fileExists(atPath path: String) -> Bool {
        return files[path] != nil || directories.contains(path)
    }

    func createDirectory(atPath path: String, withIntermediateDirectories: Bool) throws {
        directories.insert(path)
    }

    // ... other methods
}

// 2. Process Execution Abstraction
protocol ProcessExecuting {
    func execute(
        launchPath: String,
        arguments: [String],
        timeout: TimeInterval?
    ) async throws -> ProcessResult
}

struct ProcessResult {
    let exitCode: Int32
    let output: String
    let error: String
}

class ProcessExecutor: ProcessExecuting {
    func execute(
        launchPath: String,
        arguments: [String],
        timeout: TimeInterval? = nil
    ) async throws -> ProcessResult {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: launchPath)
        task.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        logger.debug("Executing: \(launchPath) \(arguments.joined(separator: " "))")

        try task.run()

        // Handle timeout if specified
        if let timeout = timeout {
            try await withTimeout(timeout) {
                task.waitUntilExit()
            }
        } else {
            task.waitUntilExit()
        }

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        logger.debug("Exit code: \(task.terminationStatus)")

        return ProcessResult(
            exitCode: task.terminationStatus,
            output: output,
            error: error
        )
    }
}

// 3. Launch Control Abstraction
protocol LaunchControlManaging {
    func load(plistPath: String) async throws
    func unload(plistPath: String) async throws
    func list() async throws -> [String]
    func isRunning(service: String) async throws -> Bool
}

class LaunchControlManager: LaunchControlManaging {
    private let processExecutor: ProcessExecuting

    init(processExecutor: ProcessExecuting = ProcessExecutor()) {
        self.processExecutor = processExecutor
    }

    func load(plistPath: String) async throws {
        let result = try await processExecutor.execute(
            launchPath: "/bin/launchctl",
            arguments: ["load", plistPath],
            timeout: 5.0
        )

        guard result.exitCode == 0 else {
            throw LaunchControlError.loadFailed(
                service: plistPath,
                error: result.error
            )
        }
    }

    func isRunning(service: String) async throws -> Bool {
        let result = try await processExecutor.execute(
            launchPath: "/bin/launchctl",
            arguments: ["list", service],
            timeout: 3.0
        )

        return result.exitCode == 0
    }
}
```

**Benefits:**
- Testable without real file system or processes
- Centralized logging
- Consistent error handling
- Can add retry logic, metrics, etc. in one place

**Estimated Effort:** 3-4 days
**Priority:** Medium-High (enables testing)

---

## 3. Performance Issues

### 3.1 I/O Blocking Main Thread

**Priority:** 🔴 CRITICAL

#### Problem

Synchronous file and process operations block the UI thread, causing freezes.

#### Instances

| File | Method | Issue |
|------|--------|-------|
| `LaunchAgentUtils.swift:88-94` | `StartSSLocal()` | Process execution blocks main thread |
| `PACUtils.swift:79-159` | `GeneratePACFile()` | File I/O on main thread |
| `ServerProfile.swift:30` | `password` getter | Keychain access (can be slow) |
| `Diagnose.swift:11-26` | `shell()` | Shell commands synchronous |

#### Example: LaunchAgentUtils.swift

```swift
// ❌ Current (BLOCKS UI)
func StartSSLocal() {
    let task = Process()
    task.launchPath = ssLocalPath
    task.arguments = args
    task.launch()
    task.waitUntilExit() // BLOCKS!

    if task.terminationStatus == 0 {
        // Update UI
    }
}
```

**User Impact:**
- UI freezes when starting/stopping services
- Poor user experience
- Can't cancel long-running operations

#### Solution: Async/Await

```swift
// ✅ Modern async/await (Swift 5.5+)
func startSSLocal() async throws -> Bool {
    logger.info("Starting ss-local service")

    let task = Process()
    task.executableURL = URL(fileURLWithPath: ssLocalPath)
    task.arguments = generateArguments()

    let outputPipe = Pipe()
    task.standardOutput = outputPipe
    task.standardError = outputPipe

    return try await withCheckedThrowingContinuation { continuation in
        task.terminationHandler = { process in
            let success = process.terminationStatus == 0

            if success {
                logger.info("ss-local started successfully")
            } else {
                let output = String(
                    data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
                    encoding: .utf8
                ) ?? ""
                logger.error("ss-local failed to start: \(output)")
            }

            continuation.resume(returning: success)
        }

        do {
            try task.run()
        } catch {
            logger.error("Failed to launch ss-local: \(error)")
            continuation.resume(throwing: error)
        }
    }
}

// Usage from AppDelegate
func toggleShadowsocks() {
    Task {
        do {
            let success = await launchAgentManager.startSSLocal()

            await MainActor.run {
                if success {
                    updateMenuIcon(running: true)
                    showToast("Shadowsocks started")
                } else {
                    showAlert("Failed to start Shadowsocks")
                }
            }
        } catch {
            await MainActor.run {
                showAlert("Error starting Shadowsocks: \(error.localizedDescription)")
            }
        }
    }
}
```

#### Alternative: Dispatch Queues (for older Swift)

```swift
// ✅ DispatchQueue approach (Swift 4.x)
func startSSLocal(completion: @escaping (Bool) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
        let task = Process()
        task.launchPath = ssLocalPath
        task.arguments = args
        task.launch()
        task.waitUntilExit()

        let success = task.terminationStatus == 0

        DispatchQueue.main.async {
            completion(success)
        }
    }
}

// Usage
startSSLocal { success in
    if success {
        self.updateMenuIcon(running: true)
    } else {
        self.showAlert("Failed to start")
    }
}
```

**Benefits:**
- UI remains responsive
- Can show progress indicators
- Can cancel operations
- Better user experience

**Estimated Effort:** 2-3 days to convert all I/O operations
**Priority:** Critical for user experience

---

### 3.2 Excessive UserDefaults Access

**Priority:** 🟡 MEDIUM

#### Problem

UserDefaults is read repeatedly in hot code paths without caching.

#### Examples

```swift
// AppDelegate.swift - Called frequently
func updateRunningModeMenu() {
    let mode = defaults.string(forKey: "ShadowsocksRunningMode") // Read 1
    let autoItem = menu.item(withTag: 1)
    autoItem?.state = mode == "auto" ? .on : .off // Read 2

    let globalItem = menu.item(withTag: 2)
    globalItem?.state = mode == "global" ? .on : .off // Read 3

    let manualItem = menu.item(withTag: 3)
    manualItem?.state = mode == "manual" ? .on : .off // Read 4
    // Same value read 4 times!
}

// LaunchAgentUtils.swift - In loop
for profile in profiles {
    let port = defaults.integer(forKey: "LocalSocks5.ListenPort") // Read every iteration!
    // Use port
}
```

#### Solution: Preferences Cache

```swift
// 1. Cached preferences
class PreferencesCache {
    static let shared = PreferencesCache()

    private var cache: [String: Any] = [:]
    private let defaults: UserDefaults
    private let queue = DispatchQueue(label: "com.shadowsocks.preferences", attributes: .concurrent)

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Observe changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(defaultsChanged),
            name: UserDefaults.didChangeNotification,
            object: defaults
        )
    }

    func value<T>(forKey key: String, defaultValue: T) -> T {
        return queue.sync {
            if let cached = cache[key] as? T {
                return cached
            }

            let value = defaults.object(forKey: key) as? T ?? defaultValue
            cache[key] = value
            return value
        }
    }

    func setValue<T>(_ value: T, forKey key: String) {
        queue.async(flags: .barrier) {
            self.cache[key] = value
            self.defaults.set(value, forKey: key)
        }
    }

    @objc private func defaultsChanged(_ notification: Notification) {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
}

// 2. Usage
func updateRunningModeMenu() {
    let mode = PreferencesCache.shared.value(
        forKey: "ShadowsocksRunningMode",
        defaultValue: "auto"
    ) // Only one read from UserDefaults, rest from cache

    autoItem?.state = mode == "auto" ? .on : .off
    globalItem?.state = mode == "global" ? .on : .off
    manualItem?.state = mode == "manual" ? .on : .off
}
```

**Benefits:**
- Faster access (in-memory cache)
- Reduced disk I/O
- Thread-safe with dispatch queue
- Automatic cache invalidation

**Estimated Effort:** 1 day
**Performance Gain:** 10-20% in hot paths

---

### 3.3 Memory Leaks - Retain Cycles

**Priority:** 🟡 MEDIUM

#### Problem

RxSwift subscriptions and closures may create retain cycles.

#### Examples

```swift
// AppDelegate.swift:125-130
notifyCenter.rx.notification(NOTIFY_CONF_CHANGED)
    .subscribe(onNext: { _ in
        self.applyConfig() // Strong reference to self!
    })
// No .disposed(by: disposeBag)

// ToastWindowController.swift:97-102
timer = Timer.scheduledTimer(
    timeInterval: 1.2,
    target: self, // Strong reference
    selector: #selector(fadeOut),
    userInfo: nil,
    repeats: false
)
// Timer not invalidated in deinit
```

#### Solution

```swift
// 1. Add DisposeBag for RxSwift
class AppDelegate: NSObject, NSApplicationDelegate {
    private let disposeBag = DisposeBag()

    func setupNotifications() {
        notifyCenter.rx.notification(NOTIFY_CONF_CHANGED)
            .subscribe(onNext: { [weak self] _ in
                self?.applyConfig()
            })
            .disposed(by: disposeBag)
    }
}

// 2. Proper timer cleanup
class ToastWindowController: NSWindowController {
    private var fadeTimer: Timer?

    func show() {
        fadeTimer = Timer.scheduledTimer(
            withTimeInterval: 1.2,
            repeats: false
        ) { [weak self] _ in
            self?.fadeOut()
        }
    }

    deinit {
        fadeTimer?.invalidate()
        fadeTimer = nil
    }
}

// 3. Use Combine (iOS 13+/macOS 10.15+) - automatic cancellation
class AppDelegate: NSObject, NSApplicationDelegate {
    private var cancellables = Set<AnyCancellable>()

    func setupNotifications() {
        NotificationCenter.default
            .publisher(for: NOTIFY_CONF_CHANGED)
            .sink { [weak self] _ in
                self?.applyConfig()
            }
            .store(in: &cancellables)
    }
}
```

**Tool:** Use Xcode Instruments → Leaks to verify

**Estimated Effort:** 1 day
**Priority:** Medium (prevents gradual memory growth)

---

## 4. Swift Modernization

### 4.1 Not Using Modern Swift Features

**Priority:** 🟡 MEDIUM

#### Problem

Codebase uses old Swift patterns from Swift 2/3 era.

#### Missing Features

1. **Async/Await** (Swift 5.5+)
2. **Actors** for thread-safety (Swift 5.5+)
3. **Result Type** (Swift 5.0+)
4. **Property Wrappers** (Swift 5.1+)
5. **Codable** (Swift 4.0+)

#### Current vs Modern

```swift
// ❌ Old callback style
func downloadGFWList(completion: @escaping (Bool, Error?) -> Void) {
    AF.request(url).responseString { response in
        switch response.result {
        case .success(let value):
            do {
                try value.write(toFile: path, atomically: true, encoding: .utf8)
                completion(true, nil)
            } catch {
                completion(false, error)
            }
        case .failure(let error):
            completion(false, error)
        }
    }
}

// ✅ Modern async/await
func downloadGFWList() async throws {
    let response = try await AF.request(url).serializingString().value
    try response.write(toFile: path, atomically: true, encoding: .utf8)
}

// Usage
Task {
    do {
        try await downloadGFWList()
        showToast("GFW list updated")
    } catch {
        showAlert("Failed to update GFW list: \(error.localizedDescription)")
    }
}
```

```swift
// ❌ Old NSObject singleton (not thread-safe)
class ServerProfileManager: NSObject {
    static let instance = ServerProfileManager()

    var profiles: [ServerProfile] = []

    func addProfile(_ profile: ServerProfile) {
        profiles.append(profile) // Race condition possible!
    }
}

// ✅ Modern actor (thread-safe by default)
actor ServerProfileManager {
    static let shared = ServerProfileManager()

    private(set) var profiles: [ServerProfile] = []

    func addProfile(_ profile: ServerProfile) {
        profiles.append(profile) // Thread-safe automatically!
    }

    func getProfiles() -> [ServerProfile] {
        return profiles
    }
}

// Usage
Task {
    let profiles = await ServerProfileManager.shared.getProfiles()
    // Use profiles
}
```

```swift
// ❌ Old optionals in closures
func performOperation(completion: @escaping (String?, Error?) -> Void) {
    // Can call completion(nil, nil) - invalid state!
}

// ✅ Modern Result type
func performOperation(completion: @escaping (Result<String, Error>) -> Void) {
    // Only valid states: success or failure
}

// Even better: async/await
func performOperation() async throws -> String {
    // Automatic error propagation
}
```

**Estimated Effort:** 3-5 days for major refactoring
**Benefits:** Safer, more maintainable, better performance

---

### 4.2 Weak Type Safety

**Priority:** 🟡 MEDIUM

#### Problem

Use of `Any`, `AnyObject`, and Objective-C types weakens type safety.

#### Examples

```swift
// ServerProfile.swift
var serverPort: uint16 // Objective-C type

// PreferencesWindowController.swift
func getDataAtRow(_ index: Int) -> [String: AnyObject] // Loses type information

// Diagnose.swift
func shell(_ args: String...) -> [String: Any] // Any is too general
```

#### Solution

```swift
// ✅ Use Swift native types
var serverPort: UInt16

// ✅ Use specific types
func getDataAtRow(_ index: Int) -> [String: String] {
    // Or better: return ServerProfile directly
}

func getProfile(at index: Int) -> ServerProfile? {
    guard index >= 0 && index < profiles.count else { return nil }
    return profiles[index]
}

// ✅ Use Result with specific error type
enum ShellError: Error {
    case executionFailed(exitCode: Int32)
    case timeout
}

func shell(_ args: String...) -> Result<String, ShellError> {
    // Type-safe result
}
```

**Benefits:**
- Compile-time error checking
- Better autocomplete
- Self-documenting code
- Fewer runtime errors

**Estimated Effort:** 2 days
**Priority:** Medium (improves safety gradually)

---

## 5. Testing & Maintainability

### 5.1 Lack of Unit Tests

**Priority:** 🔴 CRITICAL (for long-term maintenance)

#### Problem

No test coverage means:
- Regressions go undetected
- Refactoring is risky
- New features may break existing functionality
- No confidence in changes

#### Current State

```
Test Coverage: 0%
Unit Tests: 0
Integration Tests: 0
UI Tests: 0
```

#### Recommended Testing Strategy

See [TESTING_STRATEGY.md](./TESTING_STRATEGY.md) for complete details.

**Quick Start:**

```swift
// 1. Create test target in Xcode
// File → New → Target → macOS Unit Testing Bundle

// 2. Example test
import XCTest
@testable import ShadowsocksX_NG

class ServerProfileTests: XCTestCase {
    func testProfileCreation() {
        let profile = ServerProfile(
            serverHost: "example.com",
            serverPort: 8388,
            method: .aes256gcm
        )

        XCTAssertEqual(profile.serverHost, "example.com")
        XCTAssertEqual(profile.serverPort, 8388)
    }

    func testProfileValidation() {
        let validator = ServerProfileValidator()
        let profile = ServerProfile(
            serverHost: "",  // Invalid!
            serverPort: 8388,
            method: .aes256gcm
        )

        XCTAssertThrowsError(
            try validator.validate(profile, password: "password")
        ) { error in
            XCTAssertTrue(error is ServerProfileValidator.ValidationError)
        }
    }
}
```

**Priority Tests:**
1. Server profile validation
2. URL parsing (legacy & SIP002)
3. Proxy mode switching logic
4. PAC file generation
5. Keychain operations

**Estimated Effort:** 1-2 weeks initial setup, ongoing
**Goal:** 70%+ code coverage

---

### 5.2 Missing Documentation

**Priority:** 🟡 MEDIUM

#### Problem

Complex logic lacks explanation, making maintenance difficult.

#### Examples Needing Documentation

```swift
// ServerProfile.swift:61-171 - Complex URL parsing
// No explanation of legacy vs SIP002 format

// LaunchAgentUtils.swift:51-160 - PAC file generation
// No explanation of logic

// Utils.swift - QR code scanning
// No explanation of CIDetector usage
```

#### Solution: Add Documentation Comments

```swift
/// Parses a Shadowsocks URL and creates a server profile.
///
/// Supports two URL formats:
/// - **Legacy**: `ss://base64(method:password@host:port)#remark`
/// - **SIP002**: `ss://base64(method:password)@host:port/?plugin=...#remark`
///
/// - Parameter url: The `ss://` URL to parse
/// - Returns: A tuple containing the profile and password, or `nil` if parsing fails
///
/// - Note: Legacy format does not percent-encode the password per RFC3986
///
/// ## Example
/// ```swift
/// let url = URL(string: "ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ=@example.com:8388#MyServer")!
/// if let (profile, password) = ServerProfile.parse(url) {
///     print("Server: \(profile.serverHost)")
/// }
/// ```
///
/// - SeeAlso: [Shadowsocks URI Scheme](https://shadowsocks.org/en/wiki/SIP002-URI-Scheme.html)
convenience init?(url: URL) {
    // Implementation
}
```

**Tools:**
- Use DocC (Xcode 13+) for documentation generation
- Add code examples in comments
- Link to relevant RFCs/specs

**Estimated Effort:** 1-2 weeks for comprehensive docs
**Benefits:** Easier onboarding, fewer bugs, better maintenance

---

## 6. Security Considerations

### 6.1 Keychain Implementation (GOOD!)

**Status:** ✅ WELL IMPLEMENTED

The `KeychainManager.swift` is an example of good Swift code:
- Proper error handling
- Singleton pattern
- Migration from UserDefaults
- Logging
- Diagnostics

**Minor Improvements:**

```swift
// 1. Use OSLog instead of NSLog
import os.log

class KeychainManager {
    private let logger = Logger(
        subsystem: "com.qiuyuzhou.shadowsocksX-NG",
        category: "Keychain"
    )

    func savePassword(_ password: String, forAccount account: String) -> Bool {
        // ... implementation
        logger.info("Successfully saved password for account: \(account, privacy: .private)")
        return true
    }
}

// 2. Make thread-safe with actor (Swift 5.5+)
actor KeychainManager {
    static let shared = KeychainManager()

    // Thread-safe by default!
    func savePassword(_ password: String, forAccount account: String) async -> Bool {
        // Implementation
    }
}
```

---

### 6.2 Shell Command Injection Risk

**File:** `Diagnose.swift:11-26`
**Priority:** 🟡 MEDIUM

#### Problem

```swift
func shell(_ args: String...) -> [String: Any] {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c"] + args  // Potential injection if args contain user input
    // ...
}
```

If user input is passed to shell commands, this could be exploited.

#### Solution

```swift
// 1. Avoid shell altogether - use Process with explicit arguments
func executeCommand(_ command: String, arguments: [String]) async throws -> ProcessResult {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: command)
    task.arguments = arguments  // Safe - no shell interpretation
    // ...
}

// 2. If shell needed, sanitize input
func sanitizeShellArgument(_ arg: String) -> String {
    // Remove dangerous characters
    let dangerous = CharacterSet(charactersIn: ";|&$`\\\"'<>()[]{}!")
    return arg.components(separatedBy: dangerous).joined()
}

// 3. Use whitelisting
enum AllowedCommand: String {
    case launchctl = "/bin/launchctl"
    case networksetup = "/usr/sbin/networksetup"

    var path: String { rawValue }
}

func execute(_ command: AllowedCommand, arguments: [String]) async throws -> ProcessResult {
    // Only allowed commands can be executed
}
```

---

## Summary & Prioritization

### Critical Priority (Fix Immediately)

1. **Replace all force unwraps** - Eliminates crash risks
2. **Add error handling** - Improves reliability
3. **Move I/O off main thread** - Fixes UI freezes
4. **Refactor AppDelegate** - Enables testing

**Estimated Effort:** 1-2 weeks
**Impact:** Stability and user experience

### High Priority (Next Sprint)

1. **Add protocol abstractions** - Enables dependency injection
2. **Split ServerProfile responsibilities** - Improves maintainability
3. **Eliminate code duplication** - Reduces bugs
4. **Add basic unit tests** - Prevents regressions

**Estimated Effort:** 2-3 weeks
**Impact:** Code quality and testability

### Medium Priority (Future Sprints)

1. **Convert to async/await** - Modern Swift
2. **Replace magic strings with enums** - Type safety
3. **Add Codable support** - Simplify serialization
4. **Implement caching for UserDefaults** - Performance
5. **Add comprehensive documentation** - Maintainability

**Estimated Effort:** 3-4 weeks
**Impact:** Long-term maintainability

### Low Priority (Nice to Have)

1. **Consistent code style** (SwiftLint)
2. **Remove TODO comments**
3. **Optimize algorithms**
4. **Add UI tests**

---

## Next Steps

1. **Review this report** with the team
2. **Create GitHub issues** for each category
3. **Prioritize** based on project needs
4. **Start with Critical items** (force unwraps, error handling)
5. **Set up testing infrastructure** early
6. **Refactor incrementally** (don't rewrite everything)

See also:
- [REFACTORING_PLAN.md](./REFACTORING_PLAN.md) - Step-by-step implementation plan
- [SWIFT_STYLE_GUIDE.md](./SWIFT_STYLE_GUIDE.md) - Coding standards
- [TESTING_STRATEGY.md](./TESTING_STRATEGY.md) - Testing approach

---

**Report Version:** 1.0
**Last Updated:** 2025-11-02
**Next Review:** After Phase 1 completion
