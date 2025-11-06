//  Constants.swift
//  ShadowsocksX-NG
//
//  Created for refactoring - Phase 1
//  Type-safe constants and enumerations
//

import AppKit
import Foundation

/// Centralized constants for the application
enum Constants {

    // MARK: - User Defaults Keys

    enum UserDefaults {
        static let shadowsocksOn = "ShadowsocksOn"
        static let runningMode = "ShadowsocksRunningMode"
        static let listenPort = "LocalSocks5.ListenPort"
        static let listenAddress = "LocalSocks5.ListenAddress"
        static let timeout = "LocalSocks5.Timeout"
        static let enableUDPRelay = "LocalSocks5.EnableUDPRelay"
        static let enableVerboseMode = "LocalSocks5.EnableVerboseMode"

        static let httpEnabled = "LocalHTTP.ListenEnabled"
        static let httpPort = "LocalHTTP.ListenPort"
        static let httpListenAddress = "LocalHTTP.ListenAddress"

        static let pacServerEnabled = "LocalHTTPForPAC.ListenEnabled"
        static let pacServerPort = "LocalHTTPForPAC.ListenPort"
        static let pacServerBindToLocalhost = "PacServer.BindToLocalhost"

        static let launchAtLogin = "LaunchAtLogin"
        static let activeServerProfileId = "ActiveServerProfileId"
        static let serverProfiles = "ServerProfiles"

        static let gfwListURL = "GFWListURL"
        static let autoCheckUpdates = "AutoCheckUpdates"
    }

    // MARK: - Notification Names

    enum Notification {
        static let configChanged = Foundation.Notification.Name("NOTIFY_CONF_CHANGED")
        static let serverProfilesChanged = Foundation.Notification.Name(
            "NOTIFY_SERVER_PROFILES_CHANGED")
        static let foundSSURL = Foundation.Notification.Name("NOTIFY_FOUND_SS_URL")
        static let pacGenerationFailed = Foundation.Notification.Name(
            "NOTIFY_PAC_GENERATION_FAILED")
    }

    // MARK: - File Paths

    enum Path {
        static let appSupportDirectory = "/Library/Application Support/ShadowsocksX-NG/"
        static let userConfigDirectory = "/.ShadowsocksX-NG/"
        static let launchAgentsDirectory = "/Library/LaunchAgents/"

        static let ssLocalBinary = "ss-local/ss-local"
        static let privoxyBinary = "privoxy/privoxy"

        static let launchAgentSSLocal = "com.qiuyuzhou.shadowsocksX-NG.local.plist"
        static let launchAgentPrivoxy = "com.qiuyuzhou.shadowsocksX-NG.http.plist"
        static let launchAgentKcptun = "com.qiuyuzhou.shadowsocksX-NG.kcptun.plist"

        static let gfwListFile = "gfwlist.txt"
        static let userRulesFile = "user-rule.txt"
        static let pacFile = "gfwlist.js"
        static let ssLocalConfigFile = "ss-local-config.json"
        static let privoxyConfigFile = "privoxy.config"
        static let userPrivoxyConfigFile = "user-privoxy.config"

        /// Returns full path to app support directory
        static var appSupport: String {
            return FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(appSupportDirectory)
                .path
        }

        /// Returns full path to user config directory
        static var userConfig: String {
            return FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(userConfigDirectory)
                .path
        }

        /// Returns full path to Launch Agents directory
        static var launchAgents: String {
            return FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(launchAgentsDirectory)
                .path
        }
    }

    // MARK: - UI Constants

    enum UI {
        static let menuItemIndexBase = 100
        static let maxServersInMenu = 10
        static let toastFadeDuration: TimeInterval = 0.35
        static let toastDisplayDuration: TimeInterval = 1.2
        static let statusItemWidth: CGFloat = NSStatusItem.variableLength
    }

    // MARK: - Network Constants

    enum Network {
        static let defaultSocksPort: UInt16 = 1086
        static let defaultHTTPPort: UInt16 = 1087
        static let defaultPACPort: UInt16 = 1089
        static let defaultTimeout: TimeInterval = 60.0
        static let defaultListenAddress = "127.0.0.1"

        static let gfwListDefaultURL =
            "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
    }

    // MARK: - Log Files

    enum Log {
        static let ssLocalLog = "ss-local.log"
        static let privoxyLog = "privoxy.log"
        static let kcptunLog = "kcptun.log"

        /// Returns full path to log directory
        static var directory: String {
            return FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Logs")
                .path
        }
    }
}

// MARK: - Proxy Mode Enum

/// Enumeration of proxy operating modes
enum ProxyMode: String, Codable, CaseIterable {
    case auto
    case global
    case manual
    case externalPAC = "externalPAC"

    var displayName: String {
        switch self {
        case .auto:
            return NSLocalizedString("Auto Mode By PAC", comment: "Proxy mode")
        case .global:
            return NSLocalizedString("Global Mode", comment: "Proxy mode")
        case .manual:
            return NSLocalizedString("Manual Mode", comment: "Proxy mode")
        case .externalPAC:
            return NSLocalizedString("Auto Mode By External PAC", comment: "Proxy mode")
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

    /// Returns the proxy mode from UserDefaults
    static var current: ProxyMode {
        get {
            guard
                let rawValue = Foundation.UserDefaults.standard.string(
                    forKey: Constants.UserDefaults.runningMode)
            else {
                return .auto
            }

            // Migrate legacy "external_pac" to "externalPAC"
            if rawValue == "external_pac" {
                let migratedMode = ProxyMode.externalPAC
                Foundation.UserDefaults.standard.set(
                    migratedMode.rawValue, forKey: Constants.UserDefaults.runningMode)
                return migratedMode
            }

            guard let mode = ProxyMode(rawValue: rawValue) else {
                return .auto
            }
            return mode
        }
        set {
            Foundation.UserDefaults.standard.set(
                newValue.rawValue, forKey: Constants.UserDefaults.runningMode)
        }
    }
}

// MARK: - Encryption Method Enum

/// Supported encryption methods for Shadowsocks
enum EncryptionMethod: String, Codable, CaseIterable {
    // AEAD Ciphers (Recommended)
    case aes128gcm = "aes-128-gcm"
    case aes192gcm = "aes-192-gcm"
    case aes256gcm = "aes-256-gcm"
    case chacha20ietfpoly1305 = "chacha20-ietf-poly1305"
    case xchacha20ietfpoly1305 = "xchacha20-ietf-poly1305"

    // Stream Ciphers (Legacy)
    case aes128cfb = "aes-128-cfb"
    case aes192cfb = "aes-192-cfb"
    case aes256cfb = "aes-256-cfb"
    case aes128ctr = "aes-128-ctr"
    case aes192ctr = "aes-192-ctr"
    case aes256ctr = "aes-256-ctr"
    case camellia128cfb = "camellia-128-cfb"
    case camellia192cfb = "camellia-192-cfb"
    case camellia256cfb = "camellia-256-cfb"
    case chacha20 = "chacha20"
    case chacha20ietf = "chacha20-ietf"
    case rc4md5 = "rc4-md5"

    var displayName: String {
        return rawValue
    }

    /// Returns true if this is an AEAD cipher (recommended)
    var isAEAD: Bool {
        switch self {
        case .aes128gcm, .aes192gcm, .aes256gcm,
            .chacha20ietfpoly1305, .xchacha20ietfpoly1305:
            return true
        default:
            return false
        }
    }

    /// Returns true if this is a legacy/deprecated cipher
    var isLegacy: Bool {
        return !isAEAD
    }

    /// Recommended encryption methods (AEAD only)
    static var recommended: [EncryptionMethod] {
        return [
            .aes256gcm,
            .chacha20ietfpoly1305,
            .xchacha20ietfpoly1305,
            .aes192gcm,
            .aes128gcm,
        ]
    }

    /// All available methods grouped by category
    static var categorized: [(category: String, methods: [EncryptionMethod])] {
        return [
            ("AEAD Ciphers (Recommended)", recommended),
            ("Stream Ciphers (Legacy)", allCases.filter { $0.isLegacy }),
        ]
    }
}

// MARK: - Plugin Types

/// Supported SIP003 plugins
enum PluginType: String, CaseIterable {
    case simpleObfs = "simple-obfs"
    case kcptun = "kcptun"
    case v2rayPlugin = "v2ray-plugin"

    var displayName: String {
        switch self {
        case .simpleObfs:
            return "simple-obfs"
        case .kcptun:
            return "kcptun"
        case .v2rayPlugin:
            return "v2ray-plugin"
        }
    }

    var binaryName: String {
        switch self {
        case .simpleObfs:
            return "obfs-local"
        case .kcptun:
            return "client"
        case .v2rayPlugin:
            return "v2ray-plugin"
        }
    }

    var supportedOptions: [String] {
        switch self {
        case .simpleObfs:
            return ["obfs=http", "obfs=tls", "obfs-host="]
        case .kcptun:
            return ["mode=fast", "mode=fast2", "mode=fast3", "crypt=", "key="]
        case .v2rayPlugin:
            return ["mode=websocket", "tls", "host=", "path="]
        }
    }
}
