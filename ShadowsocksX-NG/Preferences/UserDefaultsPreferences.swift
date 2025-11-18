//
//  UserDefaultsPreferences.swift
//  ShadowsocksX-NG
//
//  Created for refactoring - Phase 2.1
//  Wrapper for UserDefaults to enable dependency injection and testing
//

import Foundation

/// Wrapper class for UserDefaults conforming to PreferencesManaging protocol
class UserDefaultsPreferences: PreferencesManaging {
    private let defaults: UserDefaults

    // MARK: - Initialization

    /// Initialize with a UserDefaults instance
    /// - Parameter defaults: The UserDefaults instance (default: .standard)
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Read Methods

    func bool(forKey key: String) -> Bool {
        return defaults.bool(forKey: key)
    }

    func integer(forKey key: String) -> Int {
        return defaults.integer(forKey: key)
    }

    func string(forKey key: String) -> String? {
        return defaults.string(forKey: key)
    }

    func object(forKey key: String) -> Any? {
        return defaults.object(forKey: key)
    }

    func array(forKey key: String) -> [Any]? {
        return defaults.array(forKey: key)
    }

    func data(forKey key: String) -> Data? {
        return defaults.data(forKey: key)
    }

    // MARK: - Write Methods

    func set(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func set(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func set(_ value: Int, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    // MARK: - Synchronization

    @discardableResult
    func synchronize() -> Bool {
        return defaults.synchronize()
    }
}
