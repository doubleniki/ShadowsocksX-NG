# Swift Style Guide

**ShadowsocksX-NG Project**

Version 1.0 | Last Updated: 2025-11-02

---

## Table of Contents

1. [Introduction](#introduction)
2. [General Principles](#general-principles)
3. [Code Formatting](#code-formatting)
4. [Naming Conventions](#naming-conventions)
5. [Type Annotations](#type-annotations)
6. [Optionals and Safety](#optionals-and-safety)
7. [Error Handling](#error-handling)
8. [Functions and Methods](#functions-and-methods)
9. [Classes and Structs](#classes-and-structs)
10. [Protocols](#protocols)
11. [Extensions](#extensions)
12. [Closures](#closures)
13. [Properties](#properties)
14. [Control Flow](#control-flow)
15. [Concurrency](#concurrency)
16. [Memory Management](#memory-management)
17. [Access Control](#access-control)
18. [Comments and Documentation](#comments-and-documentation)
19. [File Organization](#file-organization)
20. [Swift Language Features](#swift-language-features)
21. [Project-Specific Conventions](#project-specific-conventions)

---

## Introduction

This style guide defines coding standards for the ShadowsocksX-NG project. It aims to:

- Ensure code consistency across the codebase
- Improve code readability and maintainability
- Prevent common bugs and crashes
- Leverage modern Swift features effectively
- Facilitate code reviews and collaboration

**Key Philosophy**: Write code that is clear, safe, and maintainable. When in doubt, prioritize readability over cleverness.

---

## General Principles

### 1. Safety First

Always write safe code that handles edge cases:

```swift
// ❌ Bad - Force unwrap can crash
let name = profile.serverName!

// ✅ Good - Safe unwrapping
guard let name = profile.serverName else {
    logger.error("Profile missing server name")
    return
}
```

### 2. Clarity Over Brevity

Write code that is easy to understand:

```swift
// ❌ Bad - Too clever
let x = d.reduce(into: [:]) { $0[$1.k] = $1.v }

// ✅ Good - Clear intent
var configDictionary: [String: String] = [:]
for item in data {
    configDictionary[item.key] = item.value
}
```

### 3. Explicit Over Implicit

Make types and behaviors explicit when it improves clarity:

```swift
// ❌ Bad - Unclear type
let result = getData()

// ✅ Good - Explicit return type
let result: Result<ServerProfile, NetworkError> = getData()
```

### 4. Fail Fast

Detect errors as early as possible:

```swift
// ❌ Bad - Silent failure
func startProxy() {
    guard isConfigured else { return }
    // ...
}

// ✅ Good - Fail with error
func startProxy() throws {
    guard isConfigured else {
        throw ProxyError.notConfigured
    }
    // ...
}
```

---

## Code Formatting

### Indentation

- Use **4 spaces** for indentation (not tabs)
- Maximum line length: **120 characters**
- Break long lines at logical points

```swift
// ✅ Good
func configure(server: String,
               port: Int,
               password: String,
               method: EncryptionMethod) {
    // ...
}
```

### Spacing

```swift
// ✅ Good spacing
if condition {
    doSomething()
}

let value = calculate(a + b)
let array = [1, 2, 3]
let dict = ["key": "value"]

// ❌ Bad spacing
if condition{
    doSomething()
}

let value=calculate(a+b)
let array=[1,2,3]
```

### Braces

Always use braces for control flow statements:

```swift
// ❌ Bad - No braces
if isValid
    start()

// ✅ Good - Braces on all control flow
if isValid {
    start()
}
```

Opening braces on same line:

```swift
// ✅ Good
class MyClass {
    func myMethod() {
        if condition {
            // ...
        }
    }
}
```

### Vertical Whitespace

Use blank lines to separate logical sections:

```swift
// ✅ Good
class ServerProfile {
    // MARK: - Properties

    let serverHost: String
    let serverPort: Int

    // MARK: - Initialization

    init(host: String, port: Int) {
        self.serverHost = host
        self.serverPort = port
    }

    // MARK: - Public Methods

    func validate() -> Bool {
        // ...
    }
}
```

### Commas

Space after commas, not before:

```swift
// ✅ Good
let array = [1, 2, 3]
func foo(a: Int, b: Int) { }

// ❌ Bad
let array = [1,2,3]
let array = [1 , 2 , 3]
```

---

## Naming Conventions

### General Rules

- Use **descriptive names** that clearly indicate purpose
- Avoid abbreviations unless widely understood
- Use **camelCase** for variables, functions, parameters
- Use **PascalCase** for types (classes, structs, enums, protocols)

### Variables and Constants

```swift
// ✅ Good
let maximumRetryCount = 3
var currentServerProfile: ServerProfile?
let isProxyEnabled: Bool

// ❌ Bad
let max = 3  // Too abbreviated
let flag = true  // Unclear purpose
let sp: ServerProfile?  // Cryptic abbreviation
```

### Functions and Methods

Use verb phrases that describe the action:

```swift
// ✅ Good
func startProxy()
func validateServerConfiguration() -> Bool
func convert(profile: ServerProfile) -> Dictionary

// ❌ Bad
func proxy()  // Not descriptive
func check() -> Bool  // What does it check?
func convert() -> Dictionary  // Missing parameter label
```

### Types

```swift
// ✅ Good
class ProxyManager { }
struct ServerConfiguration { }
enum ProxyMode { }
protocol ProfileValidating { }

// ❌ Bad
class proxymanager { }  // Wrong case
struct Config { }  // Too abbreviated
enum mode { }  // Wrong case
```

### Enums

Use **lowerCamelCase** for enum cases:

```swift
// ✅ Good
enum ProxyMode {
    case auto
    case global
    case manual
    case externalPAC
}

// ❌ Bad
enum ProxyMode {
    case Auto
    case Global
    case MANUAL
}
```

### Boolean Properties

Start with `is`, `has`, `should`, or `can`:

```swift
// ✅ Good
var isEnabled: Bool
var hasValidConfiguration: Bool
var shouldAutoStart: Bool
var canConnect: Bool

// ❌ Bad
var enabled: Bool
var valid: Bool
var autoStart: Bool
```

### Constants

Use descriptive names; avoid generic names like `k` prefix:

```swift
// ✅ Good
private let defaultTimeout: TimeInterval = 30.0
private let maximumRetryAttempts = 3

// ❌ Bad
private let kTimeout: TimeInterval = 30.0
private let MAX_RETRY = 3
```

### Generics

Use descriptive names for generic type parameters:

```swift
// ✅ Good
func convert<Source, Destination>(_ value: Source) -> Destination

class Cache<Key: Hashable, Value> { }

// ✅ Acceptable for simple cases
func first<T>(_ array: [T]) -> T?
```

---

## Type Annotations

### When to Use Explicit Types

Use explicit type annotations when:
1. The type is not obvious from the right-hand side
2. It improves clarity
3. You want to enforce a specific type

```swift
// ✅ Good - Type not obvious
let timeout: TimeInterval = 30

// ✅ Good - Enforcing protocol type
let validator: ProfileValidating = ServerProfileValidator()

// ❌ Unnecessary - Type is obvious
let name: String = "ShadowsocksX-NG"
let count: Int = 42
```

### Collections

Be explicit about empty collection types:

```swift
// ✅ Good
var profiles: [ServerProfile] = []
var configOptions: [String: Any] = [:]

// ❌ Bad - Type unclear
var profiles = []
var configOptions = [:]
```

---

## Optionals and Safety

### Never Force Unwrap

**Rule**: Avoid force unwrapping (`!`) except in very specific cases (see exceptions below).

```swift
// ❌ Bad - Can crash
let host = serverProfile.host!
let port = Int(portString)!

// ✅ Good - Safe unwrapping
guard let host = serverProfile.host else {
    logger.error("Server profile missing host")
    return
}

guard let port = Int(portString) else {
    logger.error("Invalid port: \(portString)")
    return
}
```

### Exceptions to Force Unwrap Rule

Force unwrapping is acceptable only when:

1. **IBOutlets** (will crash anyway if not connected):
```swift
@IBOutlet weak var tableView: NSTableView!
```

2. **Resources that must exist** (programmer error if missing):
```swift
// Image in asset catalog that must exist
let appIcon = NSImage(named: "AppIcon")!
```

3. **Immediately after nil check**:
```swift
if profile.host != nil {
    configureWith(host: profile.host!)  // Safe - just checked
}
```

**Better alternative**: Use `guard let` or `if let` instead:
```swift
// ✅ Better
guard let host = profile.host else { return }
configureWith(host: host)
```

### Optional Chaining

Use optional chaining instead of nested `if let`:

```swift
// ❌ Bad - Nested unwrapping
if let profile = currentProfile {
    if let host = profile.host {
        if let port = profile.port {
            connect(host: host, port: port)
        }
    }
}

// ✅ Good - Optional chaining
if let host = currentProfile?.host,
   let port = currentProfile?.port {
    connect(host: host, port: port)
}
```

### Nil Coalescing

Use `??` for default values:

```swift
// ✅ Good
let timeout = configuration.timeout ?? 30.0
let name = serverProfile.name ?? "Unnamed Server"
```

### Implicitly Unwrapped Optionals

Avoid `!` type declarations. Use only for:
- IBOutlets
- Two-phase initialization when required

```swift
// ❌ Bad
var manager: ProxyManager!

// ✅ Good
var manager: ProxyManager?

// ✅ Acceptable - IBOutlet
@IBOutlet weak var statusLabel: NSTextField!
```

---

## Error Handling

### Use Swift Errors

Define custom error types:

```swift
// ✅ Good
enum ProxyError: Error {
    case notConfigured
    case invalidHost(String)
    case connectionFailed(underlying: Error)
    case timeout
}

extension ProxyError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Proxy is not configured"
        case .invalidHost(let host):
            return "Invalid host: \(host)"
        case .connectionFailed(let error):
            return "Connection failed: \(error.localizedDescription)"
        case .timeout:
            return "Connection timed out"
        }
    }
}
```

### Never Use Empty Catch

```swift
// ❌ Bad - Silent failure
do {
    try startProxy()
} catch {
    // Silent failure
}

// ✅ Good - Proper error handling
do {
    try startProxy()
} catch {
    logger.error("Failed to start proxy: \(error)")
    showErrorAlert(error)
}
```

### Use throws for Recoverable Errors

```swift
// ✅ Good
func loadConfiguration() throws -> Configuration {
    guard let data = try? Data(contentsOf: configURL) else {
        throw ConfigurationError.fileNotFound
    }

    guard let config = try? JSONDecoder().decode(Configuration.self, from: data) else {
        throw ConfigurationError.invalidFormat
    }

    return config
}
```

### Result Type for Async Operations

```swift
// ✅ Good
func fetchServerList(completion: @escaping (Result<[ServerProfile], NetworkError>) -> Void) {
    // ...
    if let error = error {
        completion(.failure(.networkFailure(error)))
    } else if let profiles = profiles {
        completion(.success(profiles))
    }
}

// Usage
fetchServerList { result in
    switch result {
    case .success(let profiles):
        self.updateUI(with: profiles)
    case .failure(let error):
        self.handleError(error)
    }
}
```

### Assertions and Preconditions

Use for programmer errors that should never happen:

```swift
// ✅ Good - Validate invariants
func setCurrentProfile(at index: Int) {
    precondition(index >= 0 && index < profiles.count,
                 "Profile index out of bounds")
    currentProfileIndex = index
}

// Use assert for debug-only checks
func configure(with profile: ServerProfile) {
    assert(!profile.host.isEmpty, "Server host cannot be empty")
    // ...
}
```

---

## Functions and Methods

### Function Length

Keep functions focused and short (ideally < 30 lines):

```swift
// ❌ Bad - Too long (100+ lines)
func handleServerChange() {
    // 100+ lines of mixed responsibilities
}

// ✅ Good - Split into focused functions
func handleServerChange() {
    validateConfiguration()
    stopCurrentProxy()
    updateProxyConfiguration()
    startNewProxy()
    updateUI()
}
```

### Parameters

Limit parameters (max 4-5):

```swift
// ❌ Bad - Too many parameters
func connect(host: String, port: Int, password: String, method: String,
             timeout: TimeInterval, plugin: String?, pluginOpts: String?) {
    // ...
}

// ✅ Good - Use configuration object
func connect(with configuration: ProxyConfiguration) {
    // ...
}
```

### Parameter Labels

Use parameter labels that read naturally:

```swift
// ✅ Good - Reads like English
func move(from source: URL, to destination: URL)
func connect(to host: String, port: Int)

// Usage
move(from: sourceURL, to: destinationURL)
connect(to: "server.com", port: 8080)

// ❌ Bad - Unclear
func move(source: URL, destination: URL)
func connect(host: String, port: Int)
```

### Default Parameters

Use default parameters instead of overloads:

```swift
// ✅ Good
func loadConfiguration(from url: URL? = nil) throws -> Configuration {
    let configURL = url ?? defaultConfigurationURL
    // ...
}

// ❌ Bad - Multiple overloads
func loadConfiguration() throws -> Configuration { }
func loadConfiguration(from url: URL) throws -> Configuration { }
```

### Return Early

Use guard statements for early returns:

```swift
// ✅ Good - Early returns
func validateProfile(_ profile: ServerProfile) -> Bool {
    guard !profile.host.isEmpty else {
        logger.error("Host is empty")
        return false
    }

    guard profile.port > 0 && profile.port < 65536 else {
        logger.error("Invalid port: \(profile.port)")
        return false
    }

    return true
}

// ❌ Bad - Nested conditions
func validateProfile(_ profile: ServerProfile) -> Bool {
    if !profile.host.isEmpty {
        if profile.port > 0 && profile.port < 65536 {
            return true
        } else {
            logger.error("Invalid port: \(profile.port)")
            return false
        }
    } else {
        logger.error("Host is empty")
        return false
    }
}
```

---

## Classes and Structs

### Choose Structs by Default

Use structs for value types, classes for reference types:

```swift
// ✅ Good - Value type
struct ServerProfile {
    let host: String
    let port: Int
    let password: String
}

// ✅ Good - Reference type (needs identity/inheritance)
class ProxyManager {
    // Shared state, lifecycle management
}
```

### Single Responsibility Principle

Each type should have one clear responsibility:

```swift
// ❌ Bad - Multiple responsibilities
class ServerManager {
    func loadProfiles() { }
    func startProxy() { }
    func updateUI() { }
    func downloadGFWList() { }
}

// ✅ Good - Focused classes
class ProfileRepository {
    func loadProfiles() -> [ServerProfile] { }
    func saveProfiles(_ profiles: [ServerProfile]) { }
}

class ProxyService {
    func start(with profile: ServerProfile) throws { }
    func stop() { }
}

class GFWListService {
    func download(completion: @escaping (Result<Data, Error>) -> Void) { }
}
```

### Property Organization

Group properties logically:

```swift
class ServerProfile {
    // MARK: - Constants

    static let defaultPort = 8080

    // MARK: - Properties

    let id: UUID
    let host: String
    let port: Int

    // MARK: - Computed Properties

    var isValid: Bool {
        !host.isEmpty && port > 0
    }

    // MARK: - Initialization

    init(host: String, port: Int) {
        self.id = UUID()
        self.host = host
        self.port = port
    }
}
```

### Minimize Class Size

Keep classes focused (aim for < 300 lines):

```swift
// If a class grows too large, split it:

// Before: AppDelegate (692 lines)
class AppDelegate: NSObject, NSApplicationDelegate {
    // Everything mixed together
}

// After: Split responsibilities
class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuBarManager: MenuBarManager
    private let windowCoordinator: WindowCoordinator
    private let proxyCoordinator: ProxyCoordinator
}

class MenuBarManager {
    // Menu bar logic only
}

class WindowCoordinator {
    // Window management only
}

class ProxyCoordinator {
    // Proxy lifecycle only
}
```

---

## Protocols

### Protocol Naming

Use `-ing` or `-able` suffix for capability protocols:

```swift
// ✅ Good
protocol ProfileValidating {
    func validate(_ profile: ServerProfile) -> Bool
}

protocol Configurable {
    func configure(with options: [String: Any])
}

protocol Downloadable {
    func download(from url: URL, completion: @escaping (Result<Data, Error>) -> Void)
}
```

### Protocol Composition

Use protocol composition for flexible types:

```swift
// ✅ Good
protocol Identifiable {
    var id: UUID { get }
}

protocol Timestamped {
    var createdAt: Date { get }
    var updatedAt: Date { get }
}

// Compose protocols
func process<T: Identifiable & Timestamped>(_ item: T) {
    logger.info("Processing \(item.id) created at \(item.createdAt)")
}
```

### Prefer Protocols for Testing

Define protocols for dependencies to enable mocking:

```swift
// ✅ Good - Protocol for dependency
protocol ProfileRepository {
    func loadProfiles() -> [ServerProfile]
    func save(_ profiles: [ServerProfile])
}

class ProxyManager {
    private let repository: ProfileRepository

    init(repository: ProfileRepository) {
        self.repository = repository
    }
}

// Easy to mock in tests
class MockProfileRepository: ProfileRepository {
    var savedProfiles: [ServerProfile] = []

    func loadProfiles() -> [ServerProfile] {
        return savedProfiles
    }

    func save(_ profiles: [ServerProfile]) {
        savedProfiles = profiles
    }
}
```

---

## Extensions

### Organization

Use extensions to organize code by functionality:

```swift
// MARK: - ProfileValidating
extension ServerProfile: ProfileValidating {
    func validate() -> Bool {
        return !host.isEmpty && port > 0
    }
}

// MARK: - Codable
extension ServerProfile: Codable {
    // Codable implementation
}

// MARK: - CustomStringConvertible
extension ServerProfile: CustomStringConvertible {
    var description: String {
        return "\(host):\(port)"
    }
}
```

### Extension File Naming

For large extensions, use separate files:

```
ServerProfile.swift
ServerProfile+Validation.swift
ServerProfile+Codable.swift
ServerProfile+URL.swift
```

### Don't Over-extend

Don't add unrelated functionality to system types:

```swift
// ❌ Bad - Too specific
extension String {
    func isShadowsocksURL() -> Bool {
        return hasPrefix("ss://")
    }
}

// ✅ Good - Keep in domain-specific type
struct URLValidator {
    static func isShadowsocksURL(_ string: String) -> Bool {
        return string.hasPrefix("ss://")
    }
}
```

---

## Closures

### Trailing Closure Syntax

Use trailing closure for single closure parameters:

```swift
// ✅ Good
profiles.map { $0.host }

array.filter { $0 > 0 }

fetchData { result in
    print(result)
}

// ❌ Bad - Don't use trailing closure for multiple closures
UIView.animate(withDuration: 0.3) {
    view.alpha = 0
} completion: { _ in
    view.removeFromSuperview()
}
```

### Capture Lists

Always use capture lists for `self` in closures:

```swift
// ✅ Good - Weak self to avoid retain cycles
service.fetchData { [weak self] result in
    guard let self = self else { return }
    self.handleResult(result)
}

// ✅ Good - Unowned if self always exists
service.fetchData { [unowned self] result in
    self.handleResult(result)
}

// ❌ Bad - Strong reference cycle
service.fetchData { result in
    self.handleResult(result)  // Captures self strongly
}
```

### Shorthand Argument Names

Use `$0`, `$1` for very simple closures only:

```swift
// ✅ Good - Simple operation
let hosts = profiles.map { $0.host }

// ❌ Bad - Too complex
let results = profiles.map {
    $0.host + ":" + String($0.port) + " (" + $0.method + ")"
}

// ✅ Good - Named parameters for complex logic
let results = profiles.map { profile in
    return "\(profile.host):\(profile.port) (\(profile.method))"
}
```

---

## Properties

### Lazy Properties

Use `lazy` for expensive initialization:

```swift
class ProxyManager {
    // ✅ Good - Only initialized when accessed
    lazy var gfwListParser: GFWListParser = {
        return GFWListParser(rules: loadDefaultRules())
    }()
}
```

### Computed Properties

Use computed properties for derived values:

```swift
// ✅ Good
struct ServerProfile {
    let host: String
    let port: Int

    var endpoint: String {
        return "\(host):\(port)"
    }

    var isLocalhost: Bool {
        return host == "localhost" || host == "127.0.0.1"
    }
}

// ❌ Bad - Should be computed property
var endpoint: String = ""

func updateEndpoint() {
    endpoint = "\(host):\(port)"
}
```

### Property Observers

Use `didSet`/`willSet` for side effects:

```swift
// ✅ Good
class ProxyManager {
    var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                startProxy()
            } else {
                stopProxy()
            }
        }
    }
}
```

### Static vs Class Properties

Use `static` by default, `class` only if overriding is needed:

```swift
// ✅ Good - Most cases
class Configuration {
    static let defaultTimeout: TimeInterval = 30.0
}

// ✅ Good - When overriding is needed
class BaseService {
    class var serviceName: String {
        return "BaseService"
    }
}

class ProxyService: BaseService {
    override class var serviceName: String {
        return "ProxyService"
    }
}
```

---

## Control Flow

### If vs Guard

Use `guard` for early exits:

```swift
// ✅ Good - Guard for early exit
func process(_ profile: ServerProfile?) {
    guard let profile = profile else {
        logger.error("No profile provided")
        return
    }

    guard profile.isValid else {
        logger.error("Invalid profile")
        return
    }

    // Main logic here
}

// ❌ Bad - Nested ifs
func process(_ profile: ServerProfile?) {
    if let profile = profile {
        if profile.isValid {
            // Main logic here
        } else {
            logger.error("Invalid profile")
        }
    } else {
        logger.error("No profile provided")
    }
}
```

### Switch Statements

Always handle all cases:

```swift
enum ProxyMode {
    case auto
    case global
    case manual
}

// ✅ Good - All cases handled
func configureProxy(mode: ProxyMode) {
    switch mode {
    case .auto:
        enablePAC()
    case .global:
        enableGlobalProxy()
    case .manual:
        disableProxy()
    }
}

// ❌ Bad - Missing default or case
func configureProxy(mode: ProxyMode) {
    switch mode {
    case .auto:
        enablePAC()
    case .global:
        enableGlobalProxy()
    // Missing .manual case!
    }
}
```

### For-In Loops

Use `for-in` over index-based loops:

```swift
// ✅ Good
for profile in profiles {
    process(profile)
}

// ✅ Good - When index is needed
for (index, profile) in profiles.enumerated() {
    print("Profile \(index): \(profile)")
}

// ❌ Bad - C-style loop
for i in 0..<profiles.count {
    process(profiles[i])
}
```

### Ternary Operator

Use for simple cases only:

```swift
// ✅ Good - Simple assignment
let title = isEnabled ? "Disable" : "Enable"

// ❌ Bad - Too complex
let status = isConnected ? (hasError ? "Connected with errors" : "Connected") : "Disconnected"

// ✅ Good - Use if-else for complex logic
let status: String
if isConnected {
    status = hasError ? "Connected with errors" : "Connected"
} else {
    status = "Disconnected"
}
```

---

## Concurrency

### Grand Central Dispatch

Use modern GCD API:

```swift
// ✅ Good - Modern GCD
DispatchQueue.global(qos: .userInitiated).async {
    let data = self.processData()

    DispatchQueue.main.async {
        self.updateUI(with: data)
    }
}

// ❌ Bad - Old API
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
    // Old-style
}
```

### Main Thread

Always update UI on main thread:

```swift
// ✅ Good
func updateServerList(_ servers: [ServerProfile]) {
    DispatchQueue.main.async {
        self.tableView.reloadData()
    }
}

// Helper extension
extension DispatchQueue {
    static func mainAsync(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}
```

### Async/Await (Modern Swift)

Migrate to async/await for new code:

```swift
// ✅ Good - Modern async/await
func fetchServerList() async throws -> [ServerProfile] {
    let data = try await networkService.fetchData(from: serverListURL)
    let profiles = try JSONDecoder().decode([ServerProfile].self, from: data)
    return profiles
}

// Usage
Task {
    do {
        let profiles = try await fetchServerList()
        await updateUI(with: profiles)
    } catch {
        logger.error("Failed to fetch servers: \(error)")
    }
}
```

### Actors for Thread Safety

Use actors to protect mutable state:

```swift
// ✅ Good - Thread-safe with actor
actor ProfileCache {
    private var profiles: [UUID: ServerProfile] = [:]

    func get(_ id: UUID) -> ServerProfile? {
        return profiles[id]
    }

    func set(_ profile: ServerProfile) {
        profiles[profile.id] = profile
    }
}
```

---

## Memory Management

### Avoid Retain Cycles

Use weak/unowned for delegate patterns:

```swift
// ✅ Good - Weak delegate
protocol ProxyManagerDelegate: AnyObject {
    func proxyDidStart()
}

class ProxyManager {
    weak var delegate: ProxyManagerDelegate?
}
```

### Closures and Retain Cycles

Always use capture lists:

```swift
// ✅ Good
class ViewController {
    func loadData() {
        service.fetch { [weak self] result in
            guard let self = self else { return }
            self.handleResult(result)
        }
    }
}
```

### Lazy Initialization

Be careful with lazy properties capturing self:

```swift
// ❌ Bad - Retain cycle
class MyClass {
    var name = "Test"

    lazy var printer: () -> Void = {
        print(self.name)  // Captures self strongly
    }
}

// ✅ Good - No strong capture
class MyClass {
    var name = "Test"

    lazy var printer: () -> Void = { [weak self] in
        guard let self = self else { return }
        print(self.name)
    }
}
```

---

## Access Control

### Default to Private

Use the most restrictive access level possible:

```swift
// ✅ Good
class ProxyManager {
    // Public API
    func start() { }
    func stop() { }

    // Private implementation
    private func configureSocket() { }
    private func cleanup() { }

    // Private properties
    private var socket: Socket?
    private let configuration: Configuration
}
```

### Access Level Guidelines

- `private`: Only within the type
- `fileprivate`: Within the same file
- `internal`: Within the module (default)
- `public`: Accessible from other modules
- `open`: Subclassable from other modules

```swift
// ✅ Good - Appropriate access levels
public class ProxyManager {  // Public API
    private let configuration: Configuration
    fileprivate var state: State  // Shared within file
    internal func configure() { }  // Module-level
}

// Extension in same file can access fileprivate
extension ProxyManager {
    func resetState() {
        state = .idle  // Can access fileprivate
    }
}
```

---

## Comments and Documentation

### When to Comment

Comment **why**, not **what**:

```swift
// ❌ Bad - Obvious comment
// Set the name
name = "Server"

// ✅ Good - Explains reasoning
// Use base64 encoding to support special characters in URL
let encoded = serverURL.base64Encoded()

// ✅ Good - Explains non-obvious behavior
// Must delay by one run loop to allow UI to update
DispatchQueue.main.async {
    self.tableView.reloadData()
}
```

### Documentation Comments

Use `///` for public API:

```swift
/// Starts the proxy service with the specified configuration.
///
/// - Parameter profile: The server profile to connect to
/// - Throws: `ProxyError` if the configuration is invalid or connection fails
/// - Returns: `true` if the proxy started successfully
func startProxy(with profile: ServerProfile) throws -> Bool {
    // Implementation
}
```

### MARK Comments

Use `MARK:` to organize code:

```swift
class ServerProfile {
    // MARK: - Properties

    let host: String
    let port: Int

    // MARK: - Initialization

    init(host: String, port: Int) {
        self.host = host
        self.port = port
    }

    // MARK: - Public Methods

    func validate() -> Bool {
        // ...
    }

    // MARK: - Private Methods

    private func parseConfiguration() {
        // ...
    }
}
```

Standard MARK sections:
- `// MARK: - Properties`
- `// MARK: - Initialization`
- `// MARK: - Lifecycle` (for view controllers)
- `// MARK: - Public Methods`
- `// MARK: - Private Methods`
- `// MARK: - Protocol Conformance`

### TODO/FIXME Comments

```swift
// TODO: Implement retry logic for failed connections
// FIXME: Memory leak when closing window
// NOTE: This behavior is required by macOS 10.12 compatibility
```

---

## File Organization

### File Structure

Organize files in this order:

```swift
// 1. Imports
import Foundation
import Cocoa

// 2. Type Definition
class ProxyManager {

    // 3. Type Properties
    static let shared = ProxyManager()

    // 4. Instance Properties
    private let configuration: Configuration
    private var isRunning = false

    // 5. Computed Properties
    var status: String {
        return isRunning ? "Running" : "Stopped"
    }

    // 6. Initialization
    init(configuration: Configuration) {
        self.configuration = configuration
    }

    // 7. Lifecycle (if applicable)

    // 8. Public Methods
    func start() { }
    func stop() { }

    // 9. Private Methods
    private func configure() { }
}

// 10. Extensions
extension ProxyManager: ProxyServiceDelegate {
    // Protocol implementation
}
```

### File Naming

Match file name to primary type:

```
ServerProfile.swift         // Contains ServerProfile struct
ProxyManager.swift          // Contains ProxyManager class
ProfileValidator.swift      // Contains ProfileValidator
```

### One Type Per File

Prefer one primary type per file:

```swift
// ✅ Good
// ServerProfile.swift
struct ServerProfile {
    // ...
}

// ❌ Bad - Multiple unrelated types
// Models.swift
struct ServerProfile { }
struct UserPreferences { }
enum ProxyMode { }
```

Exception: Related helper types can be in the same file:

```swift
// ✅ Acceptable
// ServerProfile.swift
struct ServerProfile {
    // ...
}

enum ServerProfileError: Error {
    case invalidHost
    case invalidPort
}
```

---

## Swift Language Features

### Use Modern Swift Features

#### Codable

```swift
// ✅ Good - Use Codable
struct ServerProfile: Codable {
    let host: String
    let port: Int
    let password: String
}

// Automatic encoding/decoding
let encoder = JSONEncoder()
let data = try encoder.encode(profile)

// ❌ Bad - Manual dictionary conversion
func toDictionary() -> [String: Any] {
    return [
        "host": host,
        "port": port,
        "password": password
    ]
}
```

#### Result Type

```swift
// ✅ Good - Result type
func loadConfiguration() -> Result<Configuration, ConfigError> {
    do {
        let config = try parseConfiguration()
        return .success(config)
    } catch {
        return .failure(.parseError(error))
    }
}

// ❌ Bad - Tuple with optional error
func loadConfiguration() -> (Configuration?, Error?) {
    // ...
}
```

#### Property Wrappers

```swift
// ✅ Good - Use property wrappers
@UserDefault(key: "autoStartEnabled", defaultValue: false)
var isAutoStartEnabled: Bool

@Clamped(range: 1...65535)
var serverPort: Int = 8080

// Property wrapper definition
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T

    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}
```

#### String Interpolation

```swift
// ✅ Good
logger.info("Connecting to \(host):\(port) using \(method)")

// ❌ Bad
logger.info("Connecting to " + host + ":" + String(port) + " using " + method)
```

#### Keypaths

```swift
// ✅ Good - Type-safe keypaths
let hosts = profiles.map(\.host)
let sortedByPort = profiles.sorted(by: \.port)

// Custom sorting
profiles.sort(by: \.host)
```

---

## Project-Specific Conventions

### User Defaults Keys

Define keys as static constants:

```swift
// ✅ Good
extension UserDefaults {
    enum Keys {
        static let proxyMode = "ProxyMode"
        static let autoStartEnabled = "AutoStartEnabled"
        static let selectedServerIndex = "SelectedServerIndex"
    }
}

// Usage
UserDefaults.standard.set(true, forKey: UserDefaults.Keys.autoStartEnabled)

// ❌ Bad - Magic strings
UserDefaults.standard.set(true, forKey: "AutoStartEnabled")
```

### Notification Names

Define as static constants:

```swift
// ✅ Good
extension Notification.Name {
    static let serverProfileDidChange = Notification.Name("ServerProfileDidChange")
    static let proxyDidStart = Notification.Name("ProxyDidStart")
    static let proxyDidStop = Notification.Name("ProxyDidStop")
}

// Usage
NotificationCenter.default.post(name: .serverProfileDidChange, object: self)
```

### Launch Agent Management

Use helper utilities:

```swift
// ✅ Good
class LaunchAgentManager {
    func installAgent(_ agentType: AgentType) throws {
        let plistPath = try generatePlist(for: agentType)
        try executeLaunchctl(["load", plistPath])
    }
}

// ❌ Bad - Shell commands in business logic
func installAgent() {
    _ = runCommand("launchctl load ~/Library/LaunchAgents/...")
}
```

### File Paths

Use FileManager and URL:

```swift
// ✅ Good
let appSupportURL = FileManager.default
    .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("ShadowsocksX-NG")

let configURL = appSupportURL.appendingPathComponent("config.json")

// ❌ Bad - String manipulation
let path = NSHomeDirectory() + "/Library/Application Support/ShadowsocksX-NG/config.json"
```

### Logging

Use structured logging:

```swift
// ✅ Good - Structured logger
import os.log

extension OSLog {
    private static let subsystem = Bundle.main.bundleIdentifier!

    static let proxy = OSLog(subsystem: subsystem, category: "Proxy")
    static let network = OSLog(subsystem: subsystem, category: "Network")
    static let ui = OSLog(subsystem: subsystem, category: "UI")
}

// Usage
os_log("Starting proxy with profile: %{public}@",
       log: .proxy,
       type: .info,
       profile.host)

// ❌ Bad - Print statements
print("Starting proxy")
```

### Error Presentation

Use consistent alert patterns:

```swift
// ✅ Good
class AlertPresenter {
    static func showError(_ error: Error,
                         in window: NSWindow? = nil) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")

        if let window = window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}

// ❌ Bad - Inconsistent alert creation
let alert = NSAlert()
alert.messageText = "Error occurred"
// ...
```

---

## Code Review Checklist

When reviewing code, check for:

### Safety
- [ ] No force unwraps (except IBOutlets and justified cases)
- [ ] No empty catch blocks
- [ ] All errors handled appropriately
- [ ] No implicit assumptions that can fail

### Clarity
- [ ] Descriptive names for all identifiers
- [ ] Functions are focused and short
- [ ] Code is self-documenting
- [ ] Comments explain "why", not "what"

### Architecture
- [ ] Single responsibility per type
- [ ] Dependencies injected, not hardcoded
- [ ] Protocols used for abstraction
- [ ] Proper separation of concerns

### Swift Style
- [ ] Modern Swift features used (Codable, Result, etc.)
- [ ] Proper access control
- [ ] No retain cycles in closures
- [ ] UI updates on main thread

### Testing
- [ ] Code is testable (protocols, dependency injection)
- [ ] Edge cases considered
- [ ] Error paths tested

---

## Enforcement

### SwiftLint

Use SwiftLint to enforce style rules automatically:

```yaml
# .swiftlint.yml
disabled_rules:
  - trailing_whitespace

opt_in_rules:
  - empty_count
  - closure_spacing
  - explicit_init
  - force_unwrapping

line_length: 120

identifier_name:
  min_length: 2
  max_length: 50

file_length:
  warning: 500
  error: 1000

function_body_length:
  warning: 30
  error: 50
```

### Xcode Settings

Configure Xcode for consistency:
- **Indentation**: 4 spaces
- **Tab Width**: 4 spaces
- **Line Endings**: Unix (LF)
- **Text Encoding**: UTF-8
- **Trim Trailing Whitespace**: Yes
- **Show Warnings**: All

---

## Migration Path

For existing code that doesn't follow these guidelines:

### Priority 1 (Immediate)
1. Fix all force unwraps that can crash
2. Add error handling to empty catch blocks
3. Fix obvious memory leaks

### Priority 2 (Next Sprint)
4. Refactor God classes (AppDelegate)
5. Add protocols for dependency injection
6. Implement proper logging

### Priority 3 (Ongoing)
7. Migrate to Codable
8. Add async/await where applicable
9. Improve test coverage
10. Add documentation

---

## Resources

### Official Guidelines
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Swift Programming Language Guide](https://docs.swift.org/swift-book/)

### Third-Party Guides
- [Ray Wenderlich Swift Style Guide](https://github.com/raywenderlich/swift-style-guide)
- [Google Swift Style Guide](https://google.github.io/swift/)
- [Airbnb Swift Style Guide](https://github.com/airbnb/swift)

### Tools
- [SwiftLint](https://github.com/realm/SwiftLint) - Linting tool
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) - Auto-formatting

---

**Version History**

- **1.0** (2025-11-02): Initial version based on codebase analysis

**Feedback**

This guide is a living document. Suggest improvements via pull requests or GitHub issues.
