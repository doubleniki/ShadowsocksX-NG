//
//  AppPreferences.swift
//  ShadowsocksX-NG
//
//  Created for refactoring - Phase 3.3
//  Type-safe preferences access using property wrappers
//

import Foundation

// MARK: - App Preferences

/// Centralized type-safe access to app preferences
///
/// Usage:
/// ```swift
/// if AppPreferences.shadowsocksOn {
///     // Do something
/// }
///
/// AppPreferences.proxyMode = .global
/// ```
enum AppPreferences {

    // MARK: - Shadowsocks Status

    @UserDefault(wrappedValue: false, Constants.UserDefaults.shadowsocksOn)
    static var shadowsocksOn: Bool

    @UserDefaultOptional(Constants.UserDefaults.activeServerProfileId)
    static var activeServerProfileId: String?

    // MARK: - Proxy Mode

    @UserDefaultCodable(wrappedValue: .auto, Constants.UserDefaults.runningMode)
    static var proxyMode: ProxyMode

    // MARK: - Local Proxy Settings

    @UserDefault(wrappedValue: 1086, Constants.UserDefaults.listenPort)
    static var socksPort: Int

    @UserDefault(wrappedValue: "127.0.0.1", Constants.UserDefaults.listenAddress)
    static var socksAddress: String

    @UserDefault(wrappedValue: 600, Constants.UserDefaults.timeout)
    static var timeout: Int

    // MARK: - HTTP Proxy

    @UserDefault(wrappedValue: false, Constants.UserDefaults.httpEnabled)
    static var httpProxyEnabled: Bool

    @UserDefault(wrappedValue: 1087, Constants.UserDefaults.httpPort)
    static var httpPort: Int

    // MARK: - PAC Server

    @UserDefault(wrappedValue: true, Constants.UserDefaults.pacServerEnabled)
    static var pacServerEnabled: Bool

    @UserDefault(wrappedValue: 1088, Constants.UserDefaults.pacServerPort)
    static var pacServerPort: Int

    // MARK: - Application Settings

    @UserDefault(wrappedValue: false, Constants.UserDefaults.launchAtLogin)
    static var launchAtLogin: Bool

    // Note: localProfileId removed - not used in current implementation

    // MARK: - Advanced Settings

    @UserDefault(wrappedValue: false, Constants.UserDefaults.enableUDPRelay)
    static var enableUDPRelay: Bool

    @UserDefault(wrappedValue: false, Constants.UserDefaults.enableVerboseMode)
    static var enableVerboseMode: Bool

    @UserDefault(wrappedValue: "127.0.0.1", Constants.UserDefaults.httpListenAddress)
    static var httpListenAddress: String

    @UserDefault(wrappedValue: true, Constants.UserDefaults.pacServerBindToLocalhost)
    static var pacServerBindToLocalhost: Bool

    @UserDefault(wrappedValue: "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt", Constants.UserDefaults.gfwListURL)
    static var gfwListURL: String

    @UserDefault(wrappedValue: true, Constants.UserDefaults.autoCheckUpdates)
    static var autoCheckUpdates: Bool

    @UserDefault(wrappedValue: "", Constants.UserDefaults.pacUserRules)
    static var pacUserRules: String

    @UserDefaultOptional(Constants.UserDefaults.externalPACURL)
    static var externalPACURL: String?
}

// Note: ProxyMode is already Codable (defined in Constants.swift)
