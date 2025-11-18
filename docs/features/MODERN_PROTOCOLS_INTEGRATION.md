# Modern Protocols Integration Plan

## Overview

This document outlines the integration of modern proxy protocols and DPI circumvention methods into ShadowsocksX-NG using the **Hybrid Multi-Core Architecture** (Approach #4).

### Target Protocols

1. **Shadowsocks 2022** - Modern AEAD-encrypted Shadowsocks with improved security
2. **VLESS** - Lightweight stateless protocol from Xray ecosystem
3. **VMess** - Encrypted protocol with AEAD support from V2Ray/Xray
4. **Trojan-GFW** - TLS masquerading protocol for DPI circumvention
5. **Xray REALITY** - Advanced TLS fingerprint resistance using real websites
6. **Hysteria2** - QUIC-based protocol with brutal congestion control

## Approach #4: Hybrid Multi-Core Architecture

### Architecture Overview

Instead of replacing the entire proxy core or adding all possible binaries, use a balanced approach with three specialized cores:

```
┌─────────────────────────────────────────────────────────┐
│              ShadowsocksX-NG GUI (Swift)                 │
│  - ServerProfile (config model)                          │
│  - LaunchAgentUtils (process management)                 │
│  - PreferencesWindowController (UI)                      │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │   Launch Agents       │
         │   (launchd managed)   │
         └───────────┬───────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
    ┌───▼──┐    ┌───▼──┐    ┌───▼──────┐
    │ ss   │    │ xray │    │ hysteria2│
    │(rust)│    │(core)│    │          │
    └──────┘    └──────┘    └──────────┘
        │           │             │
        └───────────┴─────────────┘
                    │
              ┌─────▼─────┐
              │  privoxy  │
              │(HTTP proxy)│
              └───────────┘
```

### Core Responsibilities

| Core | Protocols | Justification |
|------|-----------|---------------|
| **shadowsocks-rust** | Shadowsocks (legacy + 2022) | Optimized SS implementation, supports 2022 ciphers |
| **xray-core** | VLESS, VMess, Trojan, REALITY | Single binary for 80% of modern protocols |
| **hysteria2** | Hysteria2 | Specialized QUIC protocol, worth separate binary |
| **privoxy** | HTTP proxy | Existing component, unchanged |

### Benefits

- ✅ **Incremental Migration**: Existing Shadowsocks users unaffected
- ✅ **Wide Protocol Coverage**: 6 protocols with 3 core binaries
- ✅ **Native Performance**: Each protocol uses optimized native implementation
- ✅ **Manageable Complexity**: Balanced between simplicity and features
- ✅ **License Compatibility**: All cores permissively licensed or GPL-compatible

---

## Implementation Phases

### Phase 1: Foundation & Data Model (2-3 weeks)

#### 1.1 Protocol Type System

**File**: `ShadowsocksX-NG/Constants.swift`

```swift
enum ProtocolType: String, CaseIterable, Codable {
    case shadowsocks = "shadowsocks"
    case shadowsocks2022 = "shadowsocks2022"
    case vless = "vless"
    case vmess = "vmess"
    case trojan = "trojan"
    case hysteria2 = "hysteria2"

    var displayName: String {
        switch self {
        case .shadowsocks: return "Shadowsocks"
        case .shadowsocks2022: return "Shadowsocks 2022"
        case .vless: return "VLESS"
        case .vmess: return "VMess"
        case .trojan: return "Trojan-GFW"
        case .hysteria2: return "Hysteria2"
        }
    }

    var coreType: ProxyCoreType {
        switch self {
        case .shadowsocks, .shadowsocks2022:
            return .sslocal
        case .vless, .vmess, .trojan:
            return .xray
        case .hysteria2:
            return .hysteria
        }
    }

    var requiresPassword: Bool {
        switch self {
        case .shadowsocks, .shadowsocks2022, .trojan, .hysteria2:
            return true
        case .vless, .vmess:
            return false
        }
    }

    var requiresUserId: Bool {
        switch self {
        case .vless, .vmess:
            return true
        default:
            return false
        }
    }

    var supportedTransports: [TransportType] {
        switch self {
        case .shadowsocks, .shadowsocks2022:
            return [] // Uses plugins instead
        case .vless, .vmess, .trojan:
            return [.tcp, .ws, .h2, .grpc]
        case .hysteria2:
            return [] // QUIC only, no choice
        }
    }
}

enum ProxyCoreType {
    case sslocal
    case xray
    case hysteria
}

enum TransportType: String, CaseIterable, Codable {
    case tcp = "tcp"
    case ws = "ws"
    case h2 = "h2"
    case grpc = "grpc"

    var displayName: String {
        switch self {
        case .tcp: return "TCP"
        case .ws: return "WebSocket"
        case .h2: return "HTTP/2"
        case .grpc: return "gRPC"
        }
    }
}

enum SecurityType: String, CaseIterable, Codable {
    case none = "none"
    case tls = "tls"
    case reality = "reality"

    var displayName: String {
        switch self {
        case .none: return "None"
        case .tls: return "TLS"
        case .reality: return "REALITY"
        }
    }
}

struct TLSSettings: Codable {
    var serverName: String = ""
    var alpn: [String] = ["h2", "http/1.1"]
    var fingerprint: String = "chrome" // chrome, firefox, safari, randomized
    var allowInsecure: Bool = false
}

struct RealitySettings: Codable {
    var publicKey: String = ""
    var shortId: String = ""
    var serverName: String = ""
    var fingerprint: String = "chrome"
    var spiderX: String = "/"
}

struct WebSocketSettings: Codable {
    var path: String = "/"
    var headers: [String: String] = [:]
}
```

#### 1.2 Protocol-Specific Configuration Types

**File**: `ShadowsocksX-NG/ProtocolConfigs.swift` (new file)

Use typed configuration pattern instead of nullable fields:

```swift
// MARK: - Protocol Configuration (Type-Safe Approach)

/// Sealed enum containing protocol-specific configuration
enum ProtocolConfig: Codable {
    case shadowsocks(ShadowsocksConfig)
    case shadowsocks2022(Shadowsocks2022Config)
    case vless(VLESSConfig)
    case vmess(VMessConfig)
    case trojan(TrojanConfig)
    case hysteria2(Hysteria2Config)

    var protocolType: ProtocolType {
        switch self {
        case .shadowsocks: return .shadowsocks
        case .shadowsocks2022: return .shadowsocks2022
        case .vless: return .vless
        case .vmess: return .vmess
        case .trojan: return .trojan
        case .hysteria2: return .hysteria2
        }
    }
}

// MARK: - Shadowsocks Configs

struct ShadowsocksConfig: Codable {
    var method: String
    var password: String
    var plugin: String?
    var pluginOptions: String?

    func isValid() -> Bool {
        return !method.isEmpty && !password.isEmpty
    }
}

struct Shadowsocks2022Config: Codable {
    var method: String              // 2022-blake3-aes-256-gcm
    var key: String                 // Base64 key (not password)
    var plugin: String?
    var pluginOptions: String?

    func isValid() -> Bool {
        return method.hasPrefix("2022-") && !key.isEmpty
    }
}

// MARK: - VLESS Config

struct VLESSConfig: Codable {
    var userId: String
    var flow: String                // "", "xtls-rprx-vision"
    var transport: TransportSettings
    var security: SecuritySettings

    func isValid() -> Bool {
        return !userId.isEmpty && transport.isValid() && security.isValid()
    }
}

// MARK: - VMess Config

struct VMessConfig: Codable {
    var userId: String
    var alterId: Int
    var encryption: String          // "auto", "aes-128-gcm", etc.
    var transport: TransportSettings
    var security: SecuritySettings

    func isValid() -> Bool {
        return !userId.isEmpty && !encryption.isEmpty &&
               transport.isValid() && security.isValid()
    }
}

// MARK: - Trojan Config

struct TrojanConfig: Codable {
    var password: String
    var transport: TransportSettings
    var security: SecuritySettings

    func isValid() -> Bool {
        return !password.isEmpty && transport.isValid() && security.isValid()
    }
}

// MARK: - Hysteria2 Config

struct Hysteria2Config: Codable {
    var password: String
    var obfuscation: String?
    var upBandwidth: Int            // Mbps
    var downBandwidth: Int          // Mbps

    func isValid() -> Bool {
        return !password.isEmpty && upBandwidth > 0 && downBandwidth > 0
    }
}

// MARK: - Transport & Security Settings

struct TransportSettings: Codable {
    var network: TransportType
    var wsSettings: WebSocketSettings?
    var h2Settings: HTTP2Settings?
    var grpcSettings: GRPCSettings?

    func isValid() -> Bool {
        switch network {
        case .tcp: return true
        case .ws: return wsSettings != nil
        case .h2: return h2Settings != nil
        case .grpc: return grpcSettings != nil
        }
    }
}

struct HTTP2Settings: Codable {
    var path: String = "/"
    var host: [String] = []
}

struct GRPCSettings: Codable {
    var serviceName: String
}

struct SecuritySettings: Codable {
    var type: SecurityType
    var tlsSettings: TLSSettings?
    var realitySettings: RealitySettings?

    func isValid() -> Bool {
        switch type {
        case .none: return true
        case .tls: return tlsSettings != nil
        case .reality: return realitySettings != nil
        }
    }
}
```

**File**: `ShadowsocksX-NG/ServerProfile.swift`

Replace nullable fields with single typed config:

```swift
class ServerProfile: NSObject, NSCoding {
    // Common properties
    var uuid: String
    var serverHost: String
    var serverPort: UInt16
    var remark: String

    // Single typed config field (replaces all nullable fields)
    var config: ProtocolConfig

    // Convenience computed property
    var protocolType: ProtocolType {
        return config.protocolType
    }

    // Type-safe initializers
    init(host: String, port: UInt16, config: ProtocolConfig) {
        self.uuid = UUID().uuidString
        self.serverHost = host
        self.serverPort = port
        self.remark = ""
        self.config = config
        super.init()
    }

    // Legacy convenience initializer (backward compatibility)
    convenience init(host: String, port: UInt16, method: String, password: String) {
        let config = ProtocolConfig.shadowsocks(
            ShadowsocksConfig(method: method, password: password)
        )
        self.init(host: host, port: port, config: config)
    }

    // Type-safe validation
    func isValid() -> Bool {
        guard !serverHost.isEmpty && serverPort > 0 else { return false }

        switch config {
        case .shadowsocks(let ss): return ss.isValid()
        case .shadowsocks2022(let ss): return ss.isValid()
        case .vless(let vless): return vless.isValid()
        case .vmess(let vmess): return vmess.isValid()
        case .trojan(let trojan): return trojan.isValid()
        case .hysteria2(let hy2): return hy2.isValid()
        }
    }

    // Config generation
    func generateConfig() -> [String: Any] {
        switch config {
        case .shadowsocks(let ss): return toShadowsocksConfig(ss)
        case .shadowsocks2022(let ss): return toShadowsocks2022Config(ss)
        case .vless(let vless): return toXrayVLESSConfig(vless)
        case .vmess(let vmess): return toXrayVMessConfig(vmess)
        case .trojan(let trojan): return toXrayTrojanConfig(trojan)
        case .hysteria2(let hy2): return toHysteria2Config(hy2)
        }
    }
}
```

**Benefits of Typed Config Pattern:**
- ✅ Type safety: Impossible to mix protocol-specific fields
- ✅ Null safety: No nullable fields, only valid configs exist
- ✅ Scalability: Adding protocols doesn't pollute ServerProfile
- ✅ Clear API: `config.vless.userId` vs ambiguous `userId?`
- ✅ Validation: Protocol-specific validation logic encapsulated
- ✅ Pattern matching: Exhaustive switch statements catch errors

#### 1.3 URL Parsing Extensions

Support for modern protocol URLs:

```swift
// VLESS URL format: vless://uuid@host:port?type=tcp&security=reality&pbk=...&fp=chrome#remark
// VMess URL format: vmess://base64(json)
// Trojan URL format: trojan://password@host:port?sni=example.com#remark
// Hysteria2 URL format: hysteria2://password@host:port?obfs=salamander&obfs-password=xxx#remark

extension ServerProfile {
    convenience init?(url: URL) {
        // Detect protocol from scheme
        guard let scheme = url.scheme?.lowercased() else { return nil }

        switch scheme {
        case "ss":
            // Existing Shadowsocks parsing
            // ...
        case "vless":
            self.init(vlessURL: url)
        case "vmess":
            self.init(vmessURL: url)
        case "trojan":
            self.init(trojanURL: url)
        case "hysteria2", "hy2":
            self.init(hysteria2URL: url)
        default:
            return nil
        }
    }

    // Export URL
    func url() -> URL? {
        switch protocolType {
        case .shadowsocks, .shadowsocks2022:
            return shadowsocksURL()
        case .vless:
            return vlessURL()
        case .vmess:
            return vmessURL()
        case .trojan:
            return trojanURL()
        case .hysteria2:
            return hysteria2URL()
        }
    }
}
```

---

### Phase 2: Shadowsocks 2022 Support (2-4 weeks)

#### 2.1 Replace ss-local with shadowsocks-rust

**File**: `deps/Makefile`

```makefile
# Add shadowsocks-rust target
SHADOWSOCKS_RUST_VERSION = v1.18.2

.PHONY: shadowsocks-rust
shadowsocks-rust:
	@echo "Downloading shadowsocks-rust..."
	mkdir -p dist/shadowsocks-rust

	# Download prebuilt universal binary (if available)
	# Otherwise, build from source
	curl -L -o dist/shadowsocks-rust.tar.xz \
		"https://github.com/shadowsocks/shadowsocks-rust/releases/download/$(SHADOWSOCKS_RUST_VERSION)/shadowsocks-$(SHADOWSOCKS_RUST_VERSION).x86_64-apple-darwin.tar.xz"

	tar -xf dist/shadowsocks-rust.tar.xz -C dist/shadowsocks-rust

	# For arm64, download separately and create universal binary with lipo
	curl -L -o dist/shadowsocks-rust-arm64.tar.xz \
		"https://github.com/shadowsocks/shadowsocks-rust/releases/download/$(SHADOWSOCKS_RUST_VERSION)/shadowsocks-$(SHADOWSOCKS_RUST_VERSION).aarch64-apple-darwin.tar.xz"

	tar -xf dist/shadowsocks-rust-arm64.tar.xz -C dist/shadowsocks-rust

	# Create universal binary
	lipo -create \
		dist/shadowsocks-rust/sslocal-x86_64 \
		dist/shadowsocks-rust/sslocal-arm64 \
		-output dist/shadowsocks-rust/sslocal

	# Copy to app bundle location
	mkdir -p ../ShadowsocksX-NG/ss-local
	cp dist/shadowsocks-rust/sslocal ../ShadowsocksX-NG/ss-local/ss-local
	chmod +x ../ShadowsocksX-NG/ss-local/ss-local
```

#### 2.2 Add 2022 Cipher Support

**File**: `ShadowsocksX-NG/Constants.swift`

```swift
enum EncryptionMethod: String, CaseIterable {
    // Legacy ciphers
    case aes_128_gcm = "aes-128-gcm"
    case aes_256_gcm = "aes-256-gcm"
    case chacha20_ietf_poly1305 = "chacha20-ietf-poly1305"

    // Shadowsocks 2022 ciphers
    case ss2022_blake3_aes_128_gcm = "2022-blake3-aes-128-gcm"
    case ss2022_blake3_aes_256_gcm = "2022-blake3-aes-256-gcm"
    case ss2022_blake3_chacha20_poly1305 = "2022-blake3-chacha20-poly1305"

    var displayName: String {
        switch self {
        case .ss2022_blake3_aes_128_gcm:
            return "2022-blake3-aes-128-gcm (SS2022)"
        case .ss2022_blake3_aes_256_gcm:
            return "2022-blake3-aes-256-gcm (SS2022)"
        case .ss2022_blake3_chacha20_poly1305:
            return "2022-blake3-chacha20-poly1305 (SS2022)"
        default:
            return rawValue
        }
    }

    var keyLength: Int {
        switch self {
        case .ss2022_blake3_aes_128_gcm:
            return 16
        case .ss2022_blake3_aes_256_gcm, .ss2022_blake3_chacha20_poly1305:
            return 32
        default:
            return 0 // Password-based
        }
    }

    var isSS2022: Bool {
        return rawValue.hasPrefix("2022-")
    }
}
```

#### 2.3 Update UI for Protocol Selection

**File**: `ShadowsocksX-NG/PreferencesWindowController.swift`

Add protocol type selector and show/hide fields based on selection:

```swift
@IBOutlet weak var protocolTypePopUp: NSPopUpButton!

func updateUIForProtocol(_ protocolType: ProtocolType) {
    switch protocolType {
    case .shadowsocks, .shadowsocks2022:
        // Show: method, password, plugin, pluginOptions
        encryptionField.isHidden = false
        pluginField.isHidden = false
        // Hide: userId, transport, security
        userIdField.isHidden = true
        transportStackView.isHidden = true

    case .vless, .vmess:
        // Show: userId, transport, security
        userIdField.isHidden = false
        transportStackView.isHidden = false
        // Hide: method, plugin
        encryptionField.isHidden = true
        pluginField.isHidden = true

    case .trojan:
        // Show: password, transport, security
        passwordField.isHidden = false
        transportStackView.isHidden = false
        // Hide: method, plugin, userId
        encryptionField.isHidden = true
        pluginField.isHidden = true
        userIdField.isHidden = true

    case .hysteria2:
        // Show: password, obfuscation, bandwidth
        passwordField.isHidden = false
        hysteriaSettingsStackView.isHidden = false
        // Hide: method, plugin, transport
        encryptionField.isHidden = true
        pluginField.isHidden = true
        transportStackView.isHidden = true
    }
}
```

---

### Phase 3: Xray-core Integration (5-7 weeks)

#### 3.1 Download Xray-core Binary

**File**: `deps/Makefile`

```makefile
XRAY_VERSION = v1.8.8

.PHONY: xray-core
xray-core:
	@echo "Downloading xray-core..."
	mkdir -p dist/xray

	curl -L -o dist/xray.zip \
		"https://github.com/XTLS/Xray-core/releases/download/$(XRAY_VERSION)/Xray-macos-universal.zip"

	unzip -o dist/xray.zip -d dist/xray

	mkdir -p ../ShadowsocksX-NG/xray-core
	cp dist/xray/xray ../ShadowsocksX-NG/xray-core/
	chmod +x ../ShadowsocksX-NG/xray-core/xray
```

#### 3.2 Xray Launch Agent Management

**File**: `ShadowsocksX-NG/LaunchAgentUtils.swift`

```swift
// MARK: - Xray-core Management

func generateXrayLaunchAgentPlist() -> Bool {
    let xrayPath = NSHomeDirectory() + "/Library/Application Support/ShadowsocksX-NG/xray-core/xray"
    let configPath = NSHomeDirectory() + "/Library/Application Support/ShadowsocksX-NG/xray-config.json"
    let logPath = NSHomeDirectory() + "/Library/Logs/xray.log"
    let errPath = NSHomeDirectory() + "/Library/Logs/xray-err.log"

    let launchAgentDirPath = NSHomeDirectory() + "/Library/LaunchAgents"
    let plistFilePath = launchAgentDirPath + "/com.qiuyuzhou.shadowsocksX-NG.xray.plist"

    let arguments = [xrayPath, "run", "-c", configPath]

    let dict: [String: Any] = [
        "Label": "com.qiuyuzhou.shadowsocksX-NG.xray",
        "ProgramArguments": arguments,
        "KeepAlive": true,
        "RunAtLoad": true,
        "StandardOutPath": logPath,
        "StandardErrorPath": errPath
    ]

    do {
        let data = try PropertyListSerialization.data(
            fromPropertyList: dict,
            format: .xml,
            options: 0
        )
        try data.write(to: URL(fileURLWithPath: plistFilePath))
        return true
    } catch {
        ErrorHandler.shared.handle(error, context: "generateXrayLaunchAgentPlist")
        return false
    }
}

func writeXrayConfFile(_ profile: ServerProfile) -> Bool {
    let configPath = NSHomeDirectory() + "/Library/Application Support/ShadowsocksX-NG/xray-config.json"

    var config: [String: Any]

    switch profile.protocolType {
    case .vless:
        config = profile.toXrayVLESSConfig()
    case .vmess:
        config = profile.toXrayVMessConfig()
    case .trojan:
        config = profile.toXrayTrojanConfig()
    default:
        return false
    }

    do {
        let jsonData = try JSONSerialization.data(withJSONObject: config, options: .prettyPrinted)
        try jsonData.write(to: URL(fileURLWithPath: configPath))
        return true
    } catch {
        ErrorHandler.shared.handle(error, context: "writeXrayConfFile")
        return false
    }
}

func syncXray() {
    var plistChanged = false
    var configChanged = false

    plistChanged = generateXrayLaunchAgentPlist()

    if let profile = ServerProfileManager.instance.getActiveProfile() {
        // CRITICAL: Config write must succeed before starting Xray
        do {
            configChanged = try writeXrayConfFileValidated(profile)
        } catch {
            ErrorHandler.shared.error(
                "Failed to write Xray configuration: \(error.localizedDescription)",
                context: "syncXray"
            )
            // ABORT: Do not start Xray with invalid/missing config
            stopXray()
            // Surface error to user
            NotificationCenter.default.post(
                name: NSNotification.Name("ProxyConfigurationFailed"),
                object: nil,
                userInfo: ["error": error.localizedDescription, "protocol": "xray"]
            )
            return
        }
    }

    if UserDefaults.standard.bool(forKey: Constants.UserDefaults.shadowsocksOn) {
        if plistChanged || configChanged {
            stopXray()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.startXray()
            }
        } else {
            startXray()
        }
    } else {
        stopXray()
    }
}

func writeXrayConfFileValidated(_ profile: ServerProfile) throws -> Bool {
    let configPath = NSHomeDirectory() + "/Library/Application Support/ShadowsocksX-NG/xray-config.json"

    var config: [String: Any]

    switch profile.config {
    case .vless(let vless):
        config = profile.toXrayVLESSConfig(vless)
    case .vmess(let vmess):
        config = profile.toXrayVMessConfig(vmess)
    case .trojan(let trojan):
        config = profile.toXrayTrojanConfig(trojan)
    default:
        throw NSError(
            domain: "XrayConfig",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Unsupported protocol for Xray"]
        )
    }

    // Validate JSON can be serialized
    let jsonData: Data
    do {
        jsonData = try JSONSerialization.data(withJSONObject: config, options: .prettyPrinted)
    } catch {
        throw NSError(
            domain: "XrayConfig",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure: \(error.localizedDescription)"]
        )
    }

    // Validate JSON can be deserialized (round-trip test)
    do {
        _ = try JSONSerialization.jsonObject(with: jsonData, options: [])
    } catch {
        throw NSError(
            domain: "XrayConfig",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "JSON validation failed: \(error.localizedDescription)"]
        )
    }

    // Write atomically
    do {
        try jsonData.write(to: URL(fileURLWithPath: configPath), options: .atomic)
    } catch {
        throw NSError(
            domain: "XrayConfig",
            code: 4,
            userInfo: [NSLocalizedDescriptionKey: "Failed to write config file: \(error.localizedDescription)"]
        )
    }

    return true
}

func startXray() {
    let task = Process()
    task.launchPath = "/bin/launchctl"
    task.arguments = ["load", "-w",
                     NSHomeDirectory() + "/Library/LaunchAgents/com.qiuyuzhou.shadowsocksX-NG.xray.plist"]
    task.launch()
}

func stopXray() {
    let task = Process()
    task.launchPath = "/bin/launchctl"
    task.arguments = ["unload",
                     NSHomeDirectory() + "/Library/LaunchAgents/com.qiuyuzhou.shadowsocksX-NG.xray.plist"]
    task.launch()
}
```

#### 3.3 Xray Configuration Generation

**File**: `ShadowsocksX-NG/ServerProfile+Xray.swift` (new file)

```swift
extension ServerProfile {
    func toXrayVLESSConfig() -> [String: Any] {
        var streamSettings: [String: Any] = [
            "network": network.rawValue
        ]

        // Security settings (TLS or REALITY)
        if security == .tls, let tls = tlsSettings {
            streamSettings["security"] = "tls"
            streamSettings["tlsSettings"] = [
                "serverName": tls.serverName,
                "alpn": tls.alpn,
                "fingerprint": tls.fingerprint,
                "allowInsecure": tls.allowInsecure
            ]
        } else if security == .reality, let reality = realitySettings {
            streamSettings["security"] = "reality"
            streamSettings["realitySettings"] = [
                "show": false,
                "fingerprint": reality.fingerprint,
                "serverName": reality.serverName,
                "publicKey": reality.publicKey,
                "shortId": reality.shortId,
                "spiderX": reality.spiderX
            ]
        }

        // Transport settings (WebSocket, HTTP/2, gRPC)
        if network == .ws, let ws = wsSettings {
            streamSettings["wsSettings"] = [
                "path": ws.path,
                "headers": ws.headers
            ]
        }

        return [
            "log": [
                "loglevel": "info"
            ],
            "inbounds": [
                [
                    "port": 1080,
                    "listen": "127.0.0.1",
                    "protocol": "socks",
                    "settings": [
                        "udp": true
                    ]
                ]
            ],
            "outbounds": [
                [
                    "protocol": "vless",
                    "settings": [
                        "vnext": [
                            [
                                "address": serverHost,
                                "port": serverPort,
                                "users": [
                                    [
                                        "id": userId ?? "",
                                        "encryption": "none",
                                        "flow": flow ?? ""
                                    ]
                                ]
                            ]
                        ]
                    ],
                    "streamSettings": streamSettings
                ]
            ]
        ]
    }

    func toXrayVMessConfig(_ vmess: VMessConfig) -> [String: Any] {
        var streamSettings: [String: Any] = [
            "network": vmess.transport.network.rawValue
        ]

        // Security settings
        if vmess.security.type == .tls, let tls = vmess.security.tlsSettings {
            streamSettings["security"] = "tls"
            streamSettings["tlsSettings"] = [
                "serverName": tls.serverName,
                "alpn": tls.alpn,
                "fingerprint": tls.fingerprint,
                "allowInsecure": tls.allowInsecure
            ]
        }

        // Transport settings
        if vmess.transport.network == .ws, let ws = vmess.transport.wsSettings {
            streamSettings["wsSettings"] = [
                "path": ws.path,
                "headers": ws.headers
            ]
        } else if vmess.transport.network == .h2, let h2 = vmess.transport.h2Settings {
            streamSettings["httpSettings"] = [
                "path": h2.path,
                "host": h2.host
            ]
        } else if vmess.transport.network == .grpc, let grpc = vmess.transport.grpcSettings {
            streamSettings["grpcSettings"] = [
                "serviceName": grpc.serviceName
            ]
        }

        return [
            "log": [
                "loglevel": "info"
            ],
            "inbounds": [
                [
                    "port": 1080,
                    "listen": "127.0.0.1",
                    "protocol": "socks",
                    "tag": "socks-in",
                    "settings": [
                        "auth": "noauth",
                        "udp": true
                    ]
                ]
            ],
            "outbounds": [
                [
                    "protocol": "vmess",
                    "tag": "proxy",
                    "settings": [
                        "vnext": [
                            [
                                "address": serverHost,
                                "port": serverPort,
                                "users": [
                                    [
                                        "id": vmess.userId,
                                        "alterId": vmess.alterId,
                                        "security": vmess.encryption,
                                        "level": 0
                                    ]
                                ]
                            ]
                        ]
                    ],
                    "streamSettings": streamSettings
                ],
                [
                    "protocol": "freedom",
                    "tag": "direct"
                ]
            ],
            "routing": [
                "rules": [
                    [
                        "type": "field",
                        "ip": ["geoip:private"],
                        "outboundTag": "direct"
                    ]
                ]
            ]
        ]
    }

    func toXrayTrojanConfig(_ trojan: TrojanConfig) -> [String: Any] {
        var streamSettings: [String: Any] = [
            "network": trojan.transport.network.rawValue
        ]

        // TLS is mandatory for Trojan
        if let tls = trojan.security.tlsSettings {
            streamSettings["security"] = "tls"
            streamSettings["tlsSettings"] = [
                "serverName": tls.serverName,
                "alpn": tls.alpn,
                "fingerprint": tls.fingerprint,
                "allowInsecure": tls.allowInsecure
            ]
        } else {
            // Trojan requires TLS
            streamSettings["security"] = "tls"
            streamSettings["tlsSettings"] = [
                "serverName": serverHost,
                "alpn": ["h2", "http/1.1"]
            ]
        }

        // Transport settings
        if trojan.transport.network == .ws, let ws = trojan.transport.wsSettings {
            streamSettings["wsSettings"] = [
                "path": ws.path,
                "headers": ws.headers
            ]
        } else if trojan.transport.network == .grpc, let grpc = trojan.transport.grpcSettings {
            streamSettings["grpcSettings"] = [
                "serviceName": grpc.serviceName
            ]
        }

        return [
            "log": [
                "loglevel": "info"
            ],
            "inbounds": [
                [
                    "port": 1080,
                    "listen": "127.0.0.1",
                    "protocol": "socks",
                    "tag": "socks-in",
                    "settings": [
                        "auth": "noauth",
                        "udp": true
                    ]
                ]
            ],
            "outbounds": [
                [
                    "protocol": "trojan",
                    "tag": "proxy",
                    "settings": [
                        "servers": [
                            [
                                "address": serverHost,
                                "port": serverPort,
                                "password": trojan.password,
                                "level": 0
                            ]
                        ]
                    ],
                    "streamSettings": streamSettings
                ],
                [
                    "protocol": "freedom",
                    "tag": "direct"
                ]
            ],
            "routing": [
                "rules": [
                    [
                        "type": "field",
                        "ip": ["geoip:private"],
                        "outboundTag": "direct"
                    ]
                ]
            ]
        ]
    }
}
```

---

### Phase 4: Hysteria2 Integration (2-3 weeks)

#### 4.1 Download Hysteria2 Binary

**File**: `deps/Makefile`

```makefile
HYSTERIA_VERSION = v2.2.3

.PHONY: hysteria2
hysteria2:
	@echo "Downloading hysteria2..."
	mkdir -p dist/hysteria2

	curl -L -o dist/hysteria2/hysteria2 \
		"https://github.com/apernet/hysteria/releases/download/app/$(HYSTERIA_VERSION)/hysteria-darwin-universal"

	chmod +x dist/hysteria2/hysteria2

	mkdir -p ../ShadowsocksX-NG/hysteria2
	cp dist/hysteria2/hysteria2 ../ShadowsocksX-NG/hysteria2/
```

#### 4.2 Hysteria2 Configuration

**File**: `ShadowsocksX-NG/ServerProfile+Hysteria.swift` (new file)

```swift
extension ServerProfile {
    func toHysteria2Config(_ hysteria: Hysteria2Config) throws -> String {
        // Build config dictionary for type-safe YAML generation
        var configDict: [String: Any] = [
            "server": "\(serverHost):\(serverPort)",
            "auth": hysteria.password,
            "socks5": [
                "listen": "127.0.0.1:1080"
            ]
        ]

        // Validate and add obfuscation
        if let obfs = hysteria.obfuscation, !obfs.isEmpty {
            // Validate obfuscation type
            let supportedObfuscationTypes = ["salamander"]
            // Future: Make obfuscation type configurable
            configDict["obfs"] = [
                "type": "salamander",
                "salamander": [
                    "password": obfs
                ]
            ]
        }

        // Validate and add bandwidth settings
        guard hysteria.upBandwidth > 0 && hysteria.downBandwidth > 0 else {
            throw NSError(
                domain: "Hysteria2Config",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid bandwidth: up=\(hysteria.upBandwidth), down=\(hysteria.downBandwidth). Both must be > 0."]
            )
        }

        configDict["bandwidth"] = [
            "up": "\(hysteria.upBandwidth) mbps",
            "down": "\(hysteria.downBandwidth) mbps"
        ]

        // Use Yams library for safe YAML encoding
        // Add to Podfile: pod 'Yams', '~> 5.0'
        do {
            let yamlString = try Yams.dump(object: configDict, allowUnicode: true)
            return yamlString
        } catch {
            throw NSError(
                domain: "Hysteria2Config",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "YAML encoding failed: \(error.localizedDescription)"]
            )
        }
    }
}

// MARK: - Unit Tests Required

/*
Test cases for toHysteria2Config:

1. Test password with special characters:
   - Colons: "pass:word:123"
   - Quotes: "pass\"word'123"
   - Newlines: "pass
word"
   - Unicode: "пароль123"
   - YAML special chars: "pass@word#123"

2. Test obfuscation with special characters:
   - Same edge cases as password

3. Test bandwidth validation:
   - Zero bandwidth: upBandwidth=0 (should throw)
   - Negative bandwidth: downBandwidth=-1 (should throw)
   - Large values: upBandwidth=10000 (should work)

4. Test hostname edge cases:
   - IPv6: "[2001:db8::1]:443"
   - IDN: "例え.jp"
   - Localhost: "127.0.0.1:1080"

Example test:
```swift
func testHysteria2ConfigWithSpecialCharacters() throws {
    let profile = ServerProfile(
        host: "example.com",
        port: 443,
        config: .hysteria2(Hysteria2Config(
            password: "pass:word\"123'",
            obfuscation: "obfs@#$%",
            upBandwidth: 100,
            downBandwidth: 500
        ))
    )

    let yaml = try profile.toHysteria2Config(
        profile.config.hysteria2! // Force unwrap for test
    )

    // Verify YAML is valid
    let parsed = try Yams.load(yaml: yaml) as? [String: Any]
    XCTAssertEqual(parsed?["auth"] as? String, "pass:word\"123'")
    XCTAssertNotNil(parsed?["obfs"])
}
```
*/
```

---

### Phase 5: Unified Proxy Management (1 week)

#### 5.1 Update Main Sync Logic

**File**: `ShadowsocksX-NG/LaunchAgentUtils.swift`

```swift
func syncProxy() {
    guard let profile = ServerProfileManager.instance.getActiveProfile() else {
        stopAllCores()
        return
    }

    // Determine which core to use based on protocol
    let coreType = profile.protocolType.coreType

    // Stop all cores
    stopSSLocal()
    stopXray()
    stopHysteria()

    // Start appropriate core
    let isOn = UserDefaults.standard.bool(forKey: Constants.UserDefaults.shadowsocksOn)

    if isOn {
        switch coreType {
        case .sslocal:
            syncSSLocal()
        case .xray:
            syncXray()
        case .hysteria:
            syncHysteria()
        }
    }

    // Always sync privoxy and PAC
    syncPrivoxy()
    syncPac()
}

func stopAllCores() {
    stopSSLocal()
    stopXray()
    stopHysteria()
    stopPrivoxy()
}
```

---

## Port Management and Conflict Resolution

### Reserved Ports

**System-wide reserved ports** (never use for proxy cores):

| Port | Service | Purpose |
|------|---------|---------|
| 1080 | SOCKS5 proxy | Primary SOCKS5 listen port for active core |
| 8118 | HTTP proxy | Privoxy HTTP proxy port |
| 8090 | PAC server | GCDWebServer serving PAC file |

**Important**: Only ONE core can bind to port 1080 at a time. All proxy cores (ss-local, xray, hysteria2) listen on this port.

### Port Allocation Strategy

**Single Active Core Pattern:**

Since only one protocol/profile is active at a time, all cores can share the same ports:

```swift
// Constants.swift
struct ProxyPorts {
    static let socks5 = 1080      // Shared by all cores
    static let http = 8118         // Privoxy
    static let pac = 8090          // PAC server

    // Alternative ports for testing/development only
    static let alternateSocks5 = 1081
}
```

**Binding Order:**

1. Stop all cores before starting new one
2. Wait 1 second for port release (kernel TIME_WAIT)
3. Start new core
4. Verify bind success via log check

**Implementation:**

```swift
func syncProxy() {
    // CRITICAL: Stop all cores first to release ports
    stopSSLocal()
    stopXray()
    stopHysteria()

    // Wait for ports to be released
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        // Start appropriate core based on protocol
        switch profile.protocolType.coreType {
        case .sslocal:
            self.startSSLocal()
        case .xray:
            self.startXray()
        case .hysteria:
            self.startHysteria()
        }

        // Verify core started successfully
        self.verifyProxyCoreBound()
    }
}

func verifyProxyCoreBound() -> Bool {
    // Check if port 1080 is listening
    let task = Process()
    task.launchPath = "/usr/sbin/lsof"
    task.arguments = ["-i", ":1080", "-sTCP:LISTEN"]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    task.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""

    if task.terminationStatus == 0 && !output.isEmpty {
        return true
    } else {
        ErrorHandler.shared.error(
            "Proxy core failed to bind to port 1080",
            context: "verifyProxyCoreBound"
        )
        return false
    }
}
```

### Conflict Resolution

**Scenario 1: Port already in use**

```swift
// In Launch Agent plist, add retry logic
func generateLaunchAgentPlist(for core: ProxyCoreType) -> [String: Any] {
    return [
        "Label": launchAgentLabel(for: core),
        "ProgramArguments": arguments(for: core),
        "KeepAlive": false,  // Don't auto-restart on port conflict
        "RunAtLoad": true,
        "StandardErrorPath": logPath(for: core),
        "StandardOutPath": logPath(for: core),
        // IMPORTANT: Exit on port bind failure
        "AbandonProcessGroup": true
    ]
}
```

**Scenario 2: Multiple cores running (error state)**

Detect and clean up:

```swift
func cleanupStaleProxyCores() {
    let cores = ["ss-local", "xray", "hysteria2"]
    for coreName in cores {
        let task = Process()
        task.launchPath = "/usr/bin/pgrep"
        task.arguments = [coreName]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let pidString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               let pid = Int32(pidString) {
                // Kill stale process
                kill(pid, SIGTERM)
                usleep(100000) // 100ms
                kill(pid, SIGKILL)
            }
        }
    }
}
```

### Multi-Instance Considerations

**NOT SUPPORTED**: Running multiple profiles simultaneously is explicitly not supported in the current architecture.

**Future Enhancement**: To support multi-instance:
1. Allocate dynamic port range (1081-1090)
2. Store active port in profile
3. Configure system proxy to primary instance only
4. Use port multiplexer or load balancer

---

## Technical Requirements

### Binary Dependencies

| Binary | Version | Size (approx) | License |
|--------|---------|---------------|---------|
| shadowsocks-rust | v1.18.2 | ~5 MB | MIT |
| xray-core | v1.8.8 | ~12 MB | MPL-2.0 |
| hysteria2 | v2.2.3 | ~8 MB | MIT |
| privoxy | 3.0.34 | ~2 MB | GPL |

**Total binary size increase**: ~22 MB

### System Requirements

- macOS 11.0+ (unchanged)
- Xcode 14.0+ (unchanged)
- Rust toolchain (for building shadowsocks-rust, optional if using prebuilt)
- Go 1.20+ (for building xray-core/hysteria2, optional if using prebuilt)

### Build Dependencies

**Recommended**: Download prebuilt binaries to simplify build process.

```makefile
.PHONY: all-cores
all-cores: shadowsocks-rust xray-core hysteria2 privoxy

.PHONY: clean-cores
clean-cores:
	rm -rf dist/shadowsocks-rust
	rm -rf dist/xray
	rm -rf dist/hysteria2
	rm -rf ../ShadowsocksX-NG/ss-local/ss-local
	rm -rf ../ShadowsocksX-NG/xray-core/xray
	rm -rf ../ShadowsocksX-NG/hysteria2/hysteria2
```

---

## Testing Strategy

### Unit Tests

**File**: `ShadowsocksX-NGTests/ServerProfileTests.swift`

```swift
func testShadowsocks2022Profile() {
    let profile = ServerProfile()
    profile.protocolType = .shadowsocks2022
    profile.serverHost = "example.com"
    profile.serverPort = 8388
    profile.method = "2022-blake3-aes-256-gcm"
    profile.password = "base64encodedkey=="

    XCTAssertTrue(profile.isValid())

    let config = profile.toJsonConfig()
    XCTAssertEqual(config["method"] as? String, "2022-blake3-aes-256-gcm")
}

func testVLESSProfile() {
    let profile = ServerProfile()
    profile.protocolType = .vless
    profile.serverHost = "example.com"
    profile.serverPort = 443
    profile.userId = "uuid-here"
    profile.flow = "xtls-rprx-vision"
    profile.network = .tcp
    profile.security = .reality

    let reality = RealitySettings()
    reality.publicKey = "pubkey"
    reality.shortId = "short"
    reality.serverName = "www.microsoft.com"
    profile.realitySettings = reality

    XCTAssertTrue(profile.isValid())

    let config = profile.toXrayVLESSConfig()
    XCTAssertNotNil(config["outbounds"])
}
```

### Integration Tests

1. **Launch Agent Tests**:
   - Test plist generation for all cores
   - Test starting/stopping each core via launchctl
   - Verify Launch Agent files created in correct location

2. **Protocol Switching Tests**:
   - Switch from Shadowsocks to VLESS: verify ss-local stops, xray starts
   - Switch from VLESS to Hysteria2: verify xray stops, hysteria starts
   - Verify config files updated correctly

3. **Connection Tests**:
   - Test actual proxy connections for each protocol (requires test servers)
   - Verify SOCKS5 proxy listening on 127.0.0.1:1080
   - Verify privoxy HTTP proxy working

### Manual Testing Checklist

- [ ] Shadowsocks legacy (aes-256-gcm) connection works
- [ ] Shadowsocks 2022 (2022-blake3-aes-256-gcm) connection works
- [ ] VLESS + XTLS-Vision connection works
- [ ] VLESS + REALITY connection works
- [ ] VMess + WebSocket + TLS connection works
- [ ] Trojan + TLS connection works
- [ ] Hysteria2 + Salamander obfuscation works
- [ ] URL import works for all protocol types
- [ ] QR code generation/scanning works
- [ ] Protocol switching doesn't break existing connections
- [ ] PAC mode works with all protocols
- [ ] Global mode works with all protocols
- [ ] App restart preserves protocol selection

---

## Migration Guide

### For Users

**Upgrading from Classic ShadowsocksX-NG**:

1. Existing Shadowsocks profiles automatically work (no migration needed)
2. New "Protocol Type" field in server preferences
3. To use Shadowsocks 2022:
   - Edit server profile
   - Change protocol to "Shadowsocks 2022"
   - Update encryption method to 2022 cipher
   - Update password to base64-encoded key (16 or 32 bytes)

**Adding VLESS/VMess/Trojan Servers**:

1. Click "+" to add new server
2. Select protocol type: VLESS / VMess / Trojan
3. Enter server details (host, port, UUID/password)
4. Configure transport (TCP / WebSocket / HTTP/2 / gRPC)
5. Configure security (None / TLS / REALITY)
6. For REALITY: enter publicKey, shortId, serverName

**Importing from Share URLs**:

- Paste URL or scan QR code
- Supported formats: `ss://`, `vless://`, `vmess://`, `trojan://`, `hysteria2://`
- App auto-detects protocol type

### For Developers

**Adding New Protocol Support**:

1. Add protocol to `ProtocolType` enum
2. Determine which core to use (or add new core)
3. Extend `ServerProfile` with protocol-specific fields
4. Implement config generation method (e.g., `toXrayNewProtocolConfig()`)
5. Add UI fields in `PreferencesWindowController`
6. Implement URL parsing/generation
7. Add unit tests

---

## Roadmap

### Phase 1: Foundation (Weeks 1-3) ✅
- [x] Protocol type system
- [x] ServerProfile extensions
- [x] URL parsing framework

### Phase 2: Shadowsocks 2022 (Weeks 4-7)
- [ ] Replace ss-local with shadowsocks-rust
- [ ] Add 2022 cipher support
- [ ] Update UI for protocol selection
- [ ] Test with 2022 servers

### Phase 3: Xray-core (Weeks 8-14)
- [ ] Download and integrate xray-core binary
- [ ] Implement VLESS config generation
- [ ] Implement VMess config generation
- [ ] Implement Trojan config generation
- [ ] Add transport settings UI (TCP/WS/H2/gRPC)
- [ ] Add TLS settings UI
- [ ] Add REALITY settings UI
- [ ] Test all Xray protocols

### Phase 4: Hysteria2 (Weeks 15-17)
- [ ] Download and integrate hysteria2 binary
- [ ] Implement Hysteria2 config generation
- [ ] Add Hysteria2 settings UI
- [ ] Test Hysteria2 connections

### Phase 5: Testing & Polish (Weeks 18-20)
- [ ] Integration testing
- [ ] Manual testing with real servers
- [ ] UI polish and error handling
- [ ] Documentation
- [ ] Beta release

### Phase 6: Future Enhancements
- [ ] Subscription support (auto-update server lists)
- [ ] Built-in speed testing
- [ ] Connection statistics and graphs
- [ ] Profile groups and tagging
- [ ] Import from other clients (Clash, V2RayN, etc.)

---

## Security Considerations

### 1. Password Storage (Keychain Integration)

**Requirement**: All sensitive credentials MUST be stored in macOS Keychain, never in UserDefaults or plain files.

**Implementation**:

```swift
// File: ShadowsocksX-NG/KeychainHelper.swift

protocol KeychainManaging: AnyObject {
    func getPassword(forAccount account: String) -> String?
    func savePassword(_ password: String, forAccount account: String) -> Bool
    func deletePassword(forAccount account: String) -> Bool

    // NEW: Support for UUIDs and keys
    func getSecret(forKey key: String) -> String?
    func saveSecret(_ secret: String, forKey key: String) -> Bool
    func deleteSecret(forKey key: String) -> Bool
}

class KeychainHelper: KeychainManaging {
    private let serviceName = "com.qiuyuzhou.ShadowsocksX-NG"

    func saveSecret(_ secret: String, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: secret.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete existing entry
        SecItemDelete(query as CFDictionary)

        // Add new entry
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func getSecret(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let secret = String(data: data, encoding: .utf8) else {
            return nil
        }

        return secret
    }
}
```

**Usage**:

```swift
// Store VLESS UUID in Keychain
let keychain = KeychainHelper()
keychain.saveSecret(vlessConfig.userId, forKey: "profile-\(profile.uuid)-userId")

// Store Shadowsocks 2022 key
keychain.saveSecret(ss2022Config.key, forKey: "profile-\(profile.uuid)-ss2022-key")

// Store Trojan password
keychain.saveSecret(trojanConfig.password, forKey: "profile-\(profile.uuid)-password")
```

### 2. Binary Verification (SHA256 + Code Signing)

**Requirement**: All downloaded binaries MUST be verified before use. Build MUST fail if verification fails.

**Implementation** (File: `deps/Makefile`, lines ~316-347, 452-468, 672-689):

```makefile
# SHA256 checksums (update for each release)
XRAY_SHA256 = a1b2c3d4e5f6...
HYSTERIA_SHA256 = f6e5d4c3b2a1...
SHADOWSOCKS_RUST_SHA256 = 123456789abc...

.PHONY: download-xray
download-xray:
	@echo "Downloading xray-core..."
	curl -L -o dist/xray.zip \
		"https://github.com/XTLS/Xray-core/releases/download/v1.8.8/Xray-macos-universal.zip"

	# CRITICAL: Verify SHA256 checksum
	@echo "$(XRAY_SHA256)  dist/xray.zip" | shasum -a 256 -c - || \
		(echo "ERROR: Xray checksum mismatch! Aborting." && rm dist/xray.zip && exit 1)

	# Verify code signature (macOS binaries should be signed)
	unzip -o dist/xray.zip -d dist/xray
	@codesign --verify --deep --strict dist/xray/xray || \
		echo "WARNING: Xray binary is not code-signed"

	# OPTIONAL: Verify Gatekeeper approval
	@spctl --assess --type execute dist/xray/xray || \
		echo "WARNING: Xray binary not approved by Gatekeeper"

	mkdir -p ../ShadowsocksX-NG/xray-core
	cp dist/xray/xray ../ShadowsocksX-NG/xray-core/
	chmod +x ../ShadowsocksX-NG/xray-core/xray

.PHONY: verify-all-binaries
verify-all-binaries:
	@echo "Verifying all binaries..."
	@for binary in ss-local/ss-local xray-core/xray hysteria2/hysteria2; do \
		if [ -f "../ShadowsocksX-NG/$$binary" ]; then \
			echo "Checking $$binary..."; \
			codesign --verify --deep ../ShadowsocksX-NG/$$binary 2>/dev/null || \
				echo "  ⚠️  $$binary is not code-signed"; \
			file ../ShadowsocksX-NG/$$binary | grep "Mach-O" || \
				(echo "  ❌ $$binary is not a valid Mach-O binary" && exit 1); \
		fi; \
	done
	@echo "✅ Binary verification complete"
```

**Checksum Update Procedure**:

1. Download new release manually
2. Run `shasum -a 256 <binary>` to get checksum
3. Update Makefile constants
4. Commit checksum updates with release notes

### 3. Certificate Pinning for TLS/REALITY

**Requirement**: For REALITY connections, implement certificate pinning to prevent MITM attacks.

**Implementation**:

```swift
// File: ShadowsocksX-NG/CertificatePinner.swift

class CertificatePinner {
    private var pinnedCertificates: [String: [Data]] = [:]

    func pinCertificate(_ certData: Data, forHost host: String) {
        if pinnedCertificates[host] == nil {
            pinnedCertificates[host] = []
        }
        pinnedCertificates[host]?.append(certData)
    }

    func validateCertificate(_ cert: SecCertificate, forHost host: String) -> Bool {
        guard let pinnedCerts = pinnedCertificates[host], !pinnedCerts.isEmpty else {
            // No pinning configured for this host
            return true
        }

        let certData = SecCertificateCopyData(cert) as Data

        // Check if certificate matches any pinned certificate
        return pinnedCerts.contains(certData)
    }
}

// Configuration in REALITY settings
struct RealitySettings: Codable {
    var publicKey: String
    var shortId: String
    var serverName: String
    var fingerprint: String
    var spiderX: String = "/"

    // NEW: Certificate pinning
    var pinnedCertificates: [Data]? // Optional pinned certs
    var failOpen: Bool = false      // Fail-open on pin mismatch?
}
```

**Fail-open Policy**:
- `failOpen: false` (default): Connection FAILS if certificate doesn't match pinned cert
- `failOpen: true`: Connection proceeds with warning if pin check fails

**Certificate Rotation Procedure**:
1. Add new certificate to pinned list (keep old cert for grace period)
2. Wait for all users to update (e.g., 30 days)
3. Remove old certificate from pinned list

### 4. "allowInsecure: true" Warning

**Requirement**: When user enables `allowInsecure: true`, MUST show prominent warning in UI.

**Trigger Conditions**:
- User sets `allowInsecure: true` in TLS settings
- User imports profile with `allowInsecure=true`
- User edits existing profile to enable insecure mode

**UI Implementation**:

```swift
// File: ShadowsocksX-NG/PreferencesWindowController.swift

@IBOutlet weak var allowInsecureCheckbox: NSButton!
@IBOutlet weak var securityWarningLabel: NSTextField!

@IBAction func allowInsecureChanged(_ sender: NSButton) {
    if sender.state == .on {
        // Show warning dialog
        let alert = NSAlert()
        alert.messageText = "⚠️ Security Warning"
        alert.informativeText = """
        Enabling "Allow Insecure" disables TLS certificate verification.

        This makes your connection vulnerable to man-in-the-middle attacks.

        Only enable this for testing or if you understand the security risks.

        Do you want to proceed?
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Enable (Unsafe)")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            // User cancelled
            sender.state = .off
            return
        }

        // Show persistent warning label
        securityWarningLabel.isHidden = false
        securityWarningLabel.stringValue = "⚠️ Insecure mode enabled - vulnerable to attacks"
        securityWarningLabel.textColor = .systemRed
    } else {
        securityWarningLabel.isHidden = true
    }
}
```

**Warning Message Specification**:
- **Title**: "⚠️ Security Warning"
- **Content**: Explain MITM vulnerability
- **Buttons**: "Enable (Unsafe)" + "Cancel"
- **Persistent indicator**: Red warning label in UI when enabled

### 5. Build System Security Checklist

**Pre-Build Checklist**:
- [ ] SHA256 checksums updated for all binaries
- [ ] Checksums verified against official releases
- [ ] Code signatures present on downloaded binaries
- [ ] No suspicious network activity during build

**Post-Build Checklist**:
- [ ] All binaries are Mach-O format (verified via `file` command)
- [ ] No world-writable permissions on binaries
- [ ] Launch Agent plists don't contain absolute paths to user directories
- [ ] No hardcoded passwords or keys in config files

**Enforcement**:

Add to CI/CD pipeline (.github/workflows/code-quality.yml):

```yaml
- name: Verify Binary Security
  run: |
    make -C deps verify-all-binaries
    # Check for hardcoded secrets
    ! grep -r "password.*=.*['\"]" ShadowsocksX-NG/*.swift
    ! grep -r "BEGIN.*PRIVATE KEY" ShadowsocksX-NG/
```

---

## Performance Considerations

### Memory Usage

- Only one core active at a time (others stopped)
- Estimated memory per core:
  - shadowsocks-rust: ~10-20 MB
  - xray-core: ~30-50 MB
  - hysteria2: ~20-30 MB
- Total memory overhead: ~30-50 MB (depending on active protocol)

### CPU Usage

- Modern protocols (VLESS, Hysteria2) more CPU-efficient than legacy
- REALITY adds minimal overhead (~5%) vs plain TLS
- QUIC (Hysteria2) may use more CPU during high packet loss

### Startup Time

- Launch Agent start time: <1 second per core
- Config file generation: <100ms
- Total protocol switch time: ~1-2 seconds

---

## Known Limitations

### Shadowsocks 2022

- Requires fixed-length base64 keys (not password-based)
- Not compatible with servers running older Shadowsocks implementations
- Key length must match cipher (16 bytes for AES-128, 32 bytes for AES-256)

### Xray-core

- Does not support Shadowsocks 2022 ciphers
- gRPC transport requires HTTP/2 TLS
- REALITY requires compatible server configuration

### Hysteria2

- UDP-based, may be blocked by some networks
- Requires accurate bandwidth settings for optimal performance
- Not compatible with Hysteria v1 servers

### General

- Only one protocol active at a time (cannot chain protocols)
- No built-in subscription management (manual server entry)
- No automatic server selection based on latency

---

## Troubleshooting

### Common Issues

**Problem**: Shadowsocks 2022 connection fails
- **Solution**: Verify password is base64-encoded key (not plain password)
- Check key length matches cipher (16 or 32 bytes)

**Problem**: VLESS + REALITY connection fails
- **Solution**: Verify publicKey, shortId, serverName are correct
- Check fingerprint matches server configuration
- Ensure server supports REALITY transport

**Problem**: Xray core won't start
- **Solution**: Check ~/Library/Logs/xray-err.log for errors
- Verify xray binary has execute permissions
- Ensure config file is valid JSON

**Problem**: Protocol switching doesn't work
- **Solution**: Check that old core stopped before new core started
- Verify Launch Agent plist files generated correctly
- Restart app if switching gets stuck

### Debug Logs

**Shadowsocks-rust**:
```bash
tail -f ~/Library/Logs/ss-local.log
```

**Xray-core**:
```bash
tail -f ~/Library/Logs/xray.log
tail -f ~/Library/Logs/xray-err.log
```

**Hysteria2**:
```bash
tail -f ~/Library/Logs/hysteria.log
```

**Launch Agent Status**:
```bash
launchctl list | grep shadowsocksX-NG
```

---

## References

### Protocol Specifications

- [Shadowsocks 2022 Edition](https://github.com/Shadowsocks-NET/shadowsocks-specs/blob/main/2022-1-shadowsocks-2022-edition.md)
- [VLESS Protocol](https://xtls.github.io/config/outbounds/vless.html)
- [VMess Protocol](https://www.v2ray.com/en/configuration/protocols/vmess.html)
- [Trojan Protocol](https://trojan-gfw.github.io/trojan/protocol)
- [Hysteria2 Documentation](https://v2.hysteria.network/)
- [Xray REALITY](https://github.com/XTLS/REALITY)

### Implementation Guides

- [Shadowsocks-rust Documentation](https://github.com/shadowsocks/shadowsocks-rust)
- [Xray-core Configuration](https://xtls.github.io/config/)
- [Hysteria2 Client Configuration](https://v2.hysteria.network/docs/getting-started/Client/)

---

## Conclusion

The Hybrid Multi-Core Architecture (Approach #4) provides the best balance between:

- **Feature Coverage**: All 6 requested protocols supported
- **Performance**: Native optimized cores for each protocol family
- **Maintainability**: Clear separation of concerns, easy to update
- **User Experience**: Seamless protocol switching, comprehensive configuration options

**Estimated total implementation time**: 11-17 weeks

**Next Steps**:
1. Review and approve this architecture plan
2. Begin Phase 1 (Foundation) implementation
3. Set up test servers for each protocol
4. Create feature branch: `feature/modern-protocols-integration`
5. Start iterative development and testing
