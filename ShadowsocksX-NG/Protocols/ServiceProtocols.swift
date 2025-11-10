//
//  ServiceProtocols.swift
//  ShadowsocksX-NG
//
//  Created for refactoring - Phase 2.1
//  Protocol definitions for dependency injection and testing
//

import Foundation

// MARK: - Server Profile Management

/// Protocol for managing server profiles
protocol ServerProfileManaging {
    var profiles: [ServerProfile] { get set }
    var activeProfileId: String? { get set }

    func save()
    func reload()
    func getActiveProfile() -> ServerProfile?
    func setActiveProfiledId(_ id: String)
    func addServerProfileByURL(urls: [URL]) -> Int
}

// MARK: - Preferences Management

/// Protocol for managing user preferences
protocol PreferencesManaging {
    func bool(forKey key: String) -> Bool
    func integer(forKey key: String) -> Int
    func string(forKey key: String) -> String?
    func object(forKey key: String) -> Any?
    func array(forKey key: String) -> [Any]?
    func data(forKey key: String) -> Data?

    func set(_ value: Any?, forKey key: String)
    func set(_ value: Bool, forKey key: String)
    func set(_ value: Int, forKey key: String)

    @discardableResult
    func synchronize() -> Bool
}

// MARK: - Keychain Management

/// Protocol for managing Keychain operations
protocol KeychainManaging {
    func getPassword(forAccount account: String) -> String?
    func savePassword(_ password: String, forAccount account: String) -> Bool
    func deletePassword(forAccount account: String) -> Bool
}

// MARK: - Launch Agent Management

/// Protocol for managing Launch Agent services
protocol LaunchAgentManaging {
    func generateSSLocalLaunchAgentPlist() -> Bool
    func generatePrivoxyLaunchAgentPlist() -> Bool
    func generateKcptunLaunchAgentPlist() -> Bool
    func isRunning() -> Bool
    func startSSLocal()
    func stopSSLocal()
    func startPrivoxy()
    func stopPrivoxy()
    func stopKcptun()
    func startKcptun()
}

// MARK: - File System Management

/// Protocol for file system operations
protocol FileSystemManaging {
    func fileExists(atPath path: String) -> Bool
    func createDirectory(
        atPath path: String,
        withIntermediateDirectories: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws
    func copyItem(at srcURL: URL, to dstURL: URL) throws
    func moveItem(at srcURL: URL, to dstURL: URL) throws
    func removeItem(at URL: URL) throws
    func contentsOfDirectory(atPath path: String) throws -> [String]
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
}
