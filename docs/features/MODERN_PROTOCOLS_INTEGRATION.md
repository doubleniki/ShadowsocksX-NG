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

#### 1.2 ServerProfile Extensions

**File**: `ShadowsocksX-NG/ServerProfile.swift`

Add new properties:

```swift
class ServerProfile: NSObject, NSCoding {
    // Existing properties
    var uuid: String
    var serverHost: String
    var serverPort: UInt16
    var remark: String

    // NEW: Protocol type selection
    var protocolType: ProtocolType = .shadowsocks

    // Shadowsocks-specific (nullable for other protocols)
    var method: String? // Encryption method
    var password: String? // Also used by Trojan
    var plugin: String?
    var pluginOptions: String?

    // VLESS/VMess-specific
    var userId: String? // UUID for VLESS/VMess
    var alterId: Int? // VMess only (legacy)
    var encryption: String? // VMess: "auto", "aes-128-gcm", "chacha20-poly1305", "none"
    var flow: String? // VLESS: "", "xtls-rprx-vision"

    // Transport settings (VLESS/VMess/Trojan)
    var network: TransportType = .tcp
    var security: SecurityType = .none
    var tlsSettings: TLSSettings?
    var realitySettings: RealitySettings?
    var wsSettings: WebSocketSettings?

    // Hysteria2-specific
    var obfuscation: String? // Salamander password
    var upBandwidth: Int? // Mbps
    var downBandwidth: Int? // Mbps

    // ... existing methods ...

    // NEW: Protocol-specific validation
    func isValid() -> Bool {
        guard !serverHost.isEmpty && serverPort > 0 else { return false }

        switch protocolType {
        case .shadowsocks, .shadowsocks2022:
            return method != nil && password != nil
        case .vless:
            return userId != nil
        case .vmess:
            return userId != nil
        case .trojan:
            return password != nil
        case .hysteria2:
            return password != nil
        }
    }
}
```

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
    var changed = false
    changed = changed || generateXrayLaunchAgentPlist()

    if let profile = ServerProfileManager.instance.getActiveProfile() {
        changed = changed || writeXrayConfFile(profile)
    }

    if UserDefaults.standard.bool(forKey: Constants.UserDefaults.shadowsocksOn) {
        if changed {
            stopXray()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                startXray()
            }
        } else {
            startXray()
        }
    } else {
        stopXray()
    }
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

    func toXrayVMessConfig() -> [String: Any] {
        // Similar structure to VLESS
        // ...
    }

    func toXrayTrojanConfig() -> [String: Any] {
        // Trojan protocol config
        // ...
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
    func toHysteria2Config() -> String {
        // Hysteria2 uses YAML format
        var config = """
        server: \(serverHost):\(serverPort)
        auth: \(password ?? "")

        socks5:
          listen: 127.0.0.1:1080

        """

        if let obfs = obfuscation, !obfs.isEmpty {
            config += """
            obfs:
              type: salamander
              salamander:
                password: \(obfs)

            """
        }

        if let up = upBandwidth, let down = downBandwidth {
            config += """
            bandwidth:
              up: \(up) mbps
              down: \(down) mbps

            """
        }

        return config
    }
}
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

### Password Storage

- All passwords stored in macOS Keychain (existing implementation)
- UUID/keys also stored in Keychain for consistency
- Never log passwords or keys to files

### Binary Verification

- Download binaries from official GitHub releases only
- Verify checksums (SHA256) before use
- Consider code signing binaries for added security

### Privilege Management

- Proxy cores run as user processes (no root required)
- System proxy modification still requires admin (existing ProxyConfHelper)
- Launch Agents run in user context (~/Library/LaunchAgents)

### TLS/REALITY Settings

- Default to secure fingerprints (chrome, firefox)
- Warn users about `allowInsecure: true` in TLS settings
- Validate REALITY publicKey format (base64)

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
