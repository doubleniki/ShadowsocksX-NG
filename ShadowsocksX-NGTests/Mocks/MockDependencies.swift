//
//  MockDependencies.swift
//  ShadowsocksX-NGTests
//
//  Created for refactoring Phase 2.3
//

import Foundation
@testable import ShadowsocksX_NG

final class MockPreferences: PreferencesManaging {
    private var storage: [String: Any] = [:]

    func bool(forKey key: String) -> Bool {
        return storage[key] as? Bool ?? false
    }

    func integer(forKey key: String) -> Int {
        return storage[key] as? Int ?? 0
    }

    func string(forKey key: String) -> String? {
        return storage[key] as? String
    }

    func object(forKey key: String) -> Any? {
        return storage[key]
    }

    func array(forKey key: String) -> [Any]? {
        return storage[key] as? [Any]
    }

    func data(forKey key: String) -> Data? {
        return storage[key] as? Data
    }

    func set(_ value: Any?, forKey key: String) {
        storage[key] = value
    }

    func set(_ value: Bool, forKey key: String) {
        storage[key] = value
    }

    func set(_ value: Int, forKey key: String) {
        storage[key] = value
    }

    @discardableResult
    func synchronize() -> Bool {
        return true
    }
}

final class MockProfileManager: ServerProfileManaging {
    var profiles: [ServerProfile] = []
    var activeProfileId: String?

    func save() {}

    func reload() {}

    func getActiveProfile() -> ServerProfile? {
        return profiles.first { $0.uuid == activeProfileId }
    }

    func setActiveProfiledId(_ id: String) {
        activeProfileId = id
    }

    func addServerProfileByURL(urls: [URL]) -> Int {
        return urls.count
    }
}

final class MockLaunchAgent: LaunchAgentManaging {
    func generateSSLocalLaunchAgentPlist() -> Bool { true }
    func generatePrivoxyLaunchAgentPlist() -> Bool { true }
    func generateKcptunLaunchAgentPlist() -> Bool { true }
    func isRunning() -> Bool { true }
    func startSSLocal() {}
    func stopSSLocal() {}
    func startPrivoxy() {}
    func stopPrivoxy() {}
    func stopKcptun() {}
    func startKcptun() {}
}

final class MockKeychain: KeychainManaging {
    private var storage: [String: String] = [:]

    func getPassword(forAccount account: String) -> String? {
        return storage[account]
    }

    @discardableResult
    func savePassword(_ password: String, forAccount account: String) -> Bool {
        storage[account] = password
        return true
    }

    @discardableResult
    func deletePassword(forAccount account: String) -> Bool {
        storage.removeValue(forKey: account)
        return true
    }
}

final class MockFileSystem: FileSystemManaging {
    private var paths: Set<String> = []

    func fileExists(atPath path: String) -> Bool {
        return paths.contains(path)
    }

    func createDirectory(
        atPath path: String,
        withIntermediateDirectories: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws {
        paths.insert(path)
    }

    func copyItem(at srcURL: URL, to dstURL: URL) throws {}

    func moveItem(at srcURL: URL, to dstURL: URL) throws {}

    func removeItem(at URL: URL) throws {
        paths.remove(URL.path)
    }

    func contentsOfDirectory(atPath path: String) throws -> [String] {
        return []
    }

    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        return [:]
    }
}

final class MockDependencyContainer: DependencyContainer {
    let mockPreferences = MockPreferences()
    let mockProfileManager = MockProfileManager()
    let mockLaunchAgent = MockLaunchAgent()
    let mockKeychain = MockKeychain()
    let mockFileSystem = MockFileSystem()

    init() {
        super.init(
            preferences: mockPreferences,
            profileManager: mockProfileManager,
            keychain: mockKeychain,
            launchAgent: mockLaunchAgent,
            fileSystem: mockFileSystem
        )
    }
}
