//
//  UserDefault.swift
//  ShadowsocksX-NG
//
//  Created for refactoring - Phase 3.3
//  Property wrappers for type-safe UserDefaults access
//

import Foundation

// MARK: - UserDefault Property Wrapper

/// Property wrapper for type-safe UserDefaults access
///
/// Supports UserDefaults-compatible types: String, Int, Double, Bool, Data, Date, URL, Array, Dictionary
///
/// Usage:
/// ```swift
/// @UserDefault(wrappedValue: false, "LaunchAtLogin")
/// static var launchAtLogin: Bool
/// ```
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    let defaults: UserDefaults

    init(wrappedValue defaultValue: T, _ key: String, defaults: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.defaults = defaults
    }

    var wrappedValue: T {
        get {
            return defaults.object(forKey: key) as? T ?? defaultValue
        }
        nonmutating set {
            defaults.set(newValue, forKey: key)
        }
    }
}

// MARK: - UserDefaultCodable Property Wrapper

/// Property wrapper for Codable types in UserDefaults
///
/// Usage:
/// ```swift
/// @UserDefaultCodable(wrappedValue: .auto, "RunningMode")
/// static var proxyMode: ProxyMode
/// ```
@propertyWrapper
struct UserDefaultCodable<T: Codable> {
    let key: String
    let defaultValue: T
    let defaults: UserDefaults

    init(wrappedValue defaultValue: T, _ key: String, defaults: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.defaults = defaults
    }

    var wrappedValue: T {
        get {
            guard let data = defaults.data(forKey: key) else {
                return defaultValue
            }
            let decoder = JSONDecoder()
            return (try? decoder.decode(T.self, from: data)) ?? defaultValue
        }
        nonmutating set {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(newValue)
                defaults.set(data, forKey: key)
            } catch {
                // Log encoding failure but don't crash
                ErrorHandler.shared.warning(
                    "Failed to encode \(T.self) for key '\(key)': \(error.localizedDescription)",
                    context: "UserDefaultCodable"
                )
                // Optionally could remove the key instead of leaving stale data
                // defaults.removeObject(forKey: key)
            }
        }
    }
}

// MARK: - UserDefaultOptional Property Wrapper

/// Property wrapper for optional values in UserDefaults
///
/// Usage:
/// ```swift
/// @UserDefaultOptional("ActiveServerProfileId")
/// static var activeProfileId: String?
/// ```
@propertyWrapper
struct UserDefaultOptional<T> {
    let key: String
    let defaults: UserDefaults

    init(_ key: String, defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    var wrappedValue: T? {
        get {
            return defaults.object(forKey: key) as? T
        }
        nonmutating set {
            if let value = newValue {
                defaults.set(value, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
    }
}
