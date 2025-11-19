# PAC Files vs Configuration Files: Technical Comparison

**Last Updated:** 2025-01-19
**Author:** ShadowsocksX-NG Development Team
**Status:** Reference Documentation

## Overview

This document provides a comprehensive technical comparison between PAC (Proxy Auto-Configuration) files and configuration files used in ShadowsocksX-NG for proxy routing and service management.

## Table of Contents

- [1. Introduction](#1-introduction)
- [2. PAC Files](#2-pac-files)
- [3. Configuration Files](#3-configuration-files)
- [4. Key Differences](#4-key-differences)
- [5. Use Cases](#5-use-cases)
- [6. Migration Path](#6-migration-path)

---

## 1. Introduction

ShadowsocksX-NG uses two distinct types of files for different purposes:

1. **PAC Files** - JavaScript-based routing decisions (client-side, browser)
2. **Configuration Files** - Service settings and daemon parameters (server-side, system)

Both are essential but serve completely different roles in the proxy infrastructure.

---

## 2. PAC Files

### 2.1 What is PAC?

**PAC (Proxy Auto-Configuration)** is a JavaScript function that browsers execute to determine whether to use a proxy for each URL request.

**Standard Format:**

```javascript
function FindProxyForURL(url, host) {
    // Return "PROXY host:port" or "DIRECT"
}
```

### 2.2 PAC Files in ShadowsocksX-NG

**File:** `~/.ShadowsocksX-NG/gfwlist.js`

**Generation Process:**

```
GFW List (base64) → Decode → User Rules → abp.js Template → gfwlist.js
```

**Key Components:**

| File | Purpose | Size | Format |
|------|---------|------|--------|
| `gfwlist.txt` | Base64-encoded blocking rules from GFW List | ~500KB | Base64 |
| `user-rule.txt` | User-defined custom rules | ~1KB | Text |
| `abp.js` | AdBlock Plus rule parser template | ~30KB | JavaScript |
| `gfwlist.js` | Final generated PAC file | ~500KB | JavaScript |

**Delivery Method:**

- Embedded HTTP server (GCDWebServer) on port 1089
- Browser requests: `http://localhost:1089/proxy.pac`
- System proxy settings point to this URL

### 2.3 PAC Syntax (AdBlock Plus Format)

```text/plain
# Domain suffix blocking
||example.com^

# Exact domain
|http://exact-domain.com|

# Keyword matching
*keyword*

# Exception (whitelist)
@@||exception-domain.com^

# Regex patterns
/regex-pattern/
```

### 2.4 PAC Limitations

| Feature | Supported |
|---------|-----------|
| Domain-based routing | ✅ Yes |
| IP-based routing | ⚠️ Limited (via `isInNet()`) |
| GEOIP routing | ❌ No |
| Process-based routing | ❌ No |
| Source IP filtering | ❌ No |
| Port-based routing | ❌ No |
| Protocol detection | ❌ No (only HTTP/HTTPS) |

**Execution Context:** Runs in browser sandbox - no access to system resources, process info, or GeoIP databases.

---

## 3. Configuration Files

### 3.1 ss-local Config (Shadowsocks)

**File:** `~/Library/Application Support/ShadowsocksX-NG/ss-local-config.json`

**Format:** JSON

**Example:**

```json
{
  "server": "proxy.example.com",
  "server_port": 8388,
  "local_port": 1086,
  "local_address": "127.0.0.1",
  "password": "secret_password",
  "method": "aes-256-gcm",
  "timeout": 60,
  "plugin": "plugins/v2ray-plugin",
  "plugin_opts": "server;tls;host=example.com"
}
```

**Generation:**

```swift
// ServerProfile.swift:322-347
func toJsonConfig() -> [String: AnyObject] {
    var conf: [String: AnyObject] = [:]
    conf["server"] = serverHost as AnyObject
    conf["server_port"] = serverPort as AnyObject
    conf["local_port"] = AppPreferences.socksPort as AnyObject
    conf["local_address"] = AppPreferences.socksAddress as AnyObject
    conf["password"] = password as AnyObject
    conf["method"] = method as AnyObject
    conf["timeout"] = AppPreferences.timeout as AnyObject

    if let plugin = plugin, !plugin.isEmpty {
        conf["plugin"] = "plugins/\(plugin)" as AnyObject
        if let pluginOpts = pluginOptions, !pluginOpts.isEmpty {
            conf["plugin_opts"] = pluginOpts as AnyObject
        }
    }

    return conf
}
```

### 3.2 privoxy Config

**File:** `~/Library/Application Support/ShadowsocksX-NG/privoxy.config`

**Format:** Privoxy configuration syntax

**Purpose:** HTTP proxy server that forwards to SOCKS5

**Example:**

```text/plain
listen-address  127.0.0.1:1087
forward-socks5 / 127.0.0.1:1086 .
```

### 3.3 Launch Agent Plists

**Files:**

- `~/Library/LaunchAgents/com.qiuyuzhou.shadowsocksX-NG.local.plist` (ss-local)
- `~/Library/LaunchAgents/com.qiuyuzhou.shadowsocksX-NG.http.plist` (privoxy)

**Format:** XML/plist

**Purpose:** macOS service management through launchd

**Example:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.qiuyuzhou.shadowsocksX-NG.local</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/ss-local</string>
        <string>-c</string>
        <string>/path/to/ss-local-config.json</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

### 3.4 Config File Capabilities

| Feature | ss-local | privoxy | xray-core (planned) |
|---------|----------|---------|---------------------|
| Server connection | ✅ | ❌ | ✅ |
| Encryption | ✅ | ❌ | ✅ |
| Plugins (SIP003) | ✅ | ❌ | ❌ |
| HTTP → SOCKS5 | ❌ | ✅ | ✅ |
| Routing rules | ❌ | ❌ | ✅ |
| GEOIP support | ❌ | ❌ | ✅ |
| Multiple outbounds | ❌ | ❌ | ✅ |

---

## 4. Key Differences

### 4.1 Comparison Matrix

| Aspect | PAC Files | Config Files |
|--------|-----------|--------------|
| **Purpose** | Client-side routing decisions | Service configuration |
| **Language** | JavaScript | JSON / Text / XML |
| **Consumers** | Browser (via HTTP) | ss-local, privoxy, launchd |
| **Scope** | Per-request routing | Daemon startup and behavior |
| **Update Trigger** | GFW List update, port change | Server profile change |
| **Execution** | Browser sandbox | System daemons |
| **Access Level** | Limited (no system access) | Full (can bind ports, access files) |
| **Proxy Modes** | Auto/External PAC only | All modes (Auto/Global/Manual) |

### 4.2 Data Flow

```text/plain
┌─────────────────────────────────────────────────────────────┐
│                     User Changes Server                       │
└────────────┬────────────────────────────────────────────────┘
             │
             ├──────────────────┬──────────────────────────────┐
             │                  │                              │
             ▼                  ▼                              ▼
    ┌────────────────┐  ┌──────────────┐           ┌─────────────────┐
    │  ServerProfile │  │ Update Ports │           │ Generate Config │
    │   .toJsonConfig()│  │              │           │                 │
    └────────┬───────┘  └──────┬───────┘           └────────┬────────┘
             │                  │                            │
             ▼                  ▼                            ▼
    ┌────────────────┐  ┌──────────────┐           ┌─────────────────┐
    │ ss-local-      │  │ generatePAC  │           │ Launch Agent    │
    │ config.json    │  │ File()       │           │ plists          │
    └────────┬───────┘  └──────┬───────┘           └────────┬────────┘
             │                  │                            │
             ▼                  ▼                            ▼
    ┌────────────────┐  ┌──────────────┐           ┌─────────────────┐
    │ ss-local       │  │ GCDWebServer │           │ launchd         │
    │ daemon         │  │ (PAC server) │           │                 │
    │ (SOCKS5)       │  │ port 1089    │           │ (start/stop)    │
    └────────┬───────┘  └──────┬───────┘           └─────────────────┘
             │                  │
             │                  ▼
             │         ┌──────────────┐
             │         │ Browser      │
             │         │ requests PAC │
             │         └──────┬───────┘
             │                │
             │                ▼
             │         ┌──────────────┐
             │         │ FindProxyFor │
             │         │ URL()        │
             │         └──────┬───────┘
             │                │
             └────────────────┴──────────────┐
                                             │
                                             ▼
                                  ┌──────────────────┐
                                  │ Traffic routed   │
                                  │ to SOCKS5:1086   │
                                  └──────────────────┘
```

### 4.3 When Each is Used

**PAC Files:**

- ✅ Auto proxy mode
- ✅ External PAC mode
- ❌ Global mode (not used)
- ❌ Manual mode (not used)

**Config Files (ss-local):**

- ✅ Auto mode
- ✅ Global mode
- ✅ Manual mode
- ✅ External PAC mode
- ✅ **ALL modes** (always required)

---

## 5. Use Cases

### 5.1 Current Architecture (PAC + ss-local)

**Advantages:**

- ✅ Minimal components (no extra routing layer)
- ✅ Fast JavaScript execution in browser
- ✅ Industry standard (PAC widely supported)
- ✅ Flexible modes (Auto/Global/Manual)
- ✅ GFW List integration out-of-the-box

**Limitations:**

- ❌ Browser-only (no system-wide routing)
- ❌ HTTP/HTTPS only
- ❌ No GEOIP support
- ❌ No per-application routing
- ❌ No UDP routing
- ❌ Single server only

### 5.2 Future Architecture (Xray-core Routing)

**Proposed Enhancement:** Replace PAC with Xray-core built-in routing

**Capabilities:**

```json
{
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "domain": ["geosite:cn"],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "ip": ["geoip:cn"],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "domain": ["domain:github.com"],
        "outboundTag": "proxy"
      },
      {
        "type": "field",
        "network": "udp",
        "port": "53",
        "outboundTag": "dns-out"
      }
    ]
  }
}
```

**Advantages over PAC:**

- ✅ System-wide routing (all applications)
- ✅ TCP + UDP support
- ✅ GEOIP/GEOSITE databases
- ✅ Process-based routing
- ✅ Port-based routing
- ✅ Multiple outbounds (multi-server)
- ✅ Balancing and fallback

**Trade-offs:**

- ⚠️ Requires Xray-core integration (~12MB binary)
- ⚠️ More complex configuration
- ⚠️ Learning curve for users

---

## 6. Migration Path

### 6.1 Clash-Style Routing Integration

**Phase 1:** PAC-compatible translation (3-4 weeks)

- Parse Clash YAML rules
- Convert to PAC JavaScript
- Support: DOMAIN, DOMAIN-SUFFIX, DOMAIN-KEYWORD, IP-CIDR
- Limitation: ~40% Clash functionality

**Phase 2:** Xray-core routing (6-8 weeks)

- Full Clash syntax support
- GEOIP/GEOSITE integration
- 100% Clash functionality
- Requires Modern Protocols Integration (Xray-core)

### 6.2 Backward Compatibility

**Strategy:** Gradual migration with feature flags

```swift
enum RoutingEngine {
    case pac      // Current (PAC files)
    case xray     // Future (Xray-core routing)
}

class RoutingManager {
    var engine: RoutingEngine = .pac  // Default

    func migrate() {
        // Auto-migrate PAC rules to Xray config
        let pacRules = loadPACRules()
        let xrayRules = convertToXrayRouting(pacRules)
        saveXrayConfig(xrayRules)
    }
}
```

**User Experience:**

1. v0.6.x: PAC mode (current)
2. v0.7-0.9: Both modes available, PAC default
3. v1.0+: Xray mode default, PAC deprecated
4. v2.0+: PAC mode removed

---

## Appendix A: File Locations

| File | Path | Consumer |
|------|------|----------|
| PAC file | `~/.ShadowsocksX-NG/gfwlist.js` | Browser (via HTTP) |
| GFW List | `~/.ShadowsocksX-NG/gfwlist.txt` | PACUtils.swift |
| User rules | `~/.ShadowsocksX-NG/user-rule.txt` | PACUtils.swift |
| ss-local config | `~/Library/Application Support/ShadowsocksX-NG/ss-local-config.json` | ss-local daemon |
| privoxy config | `~/Library/Application Support/ShadowsocksX-NG/privoxy.config` | privoxy daemon |
| Launch Agent (ss-local) | `~/Library/LaunchAgents/com.qiuyuzhou.shadowsocksX-NG.local.plist` | launchd |
| Launch Agent (privoxy) | `~/Library/LaunchAgents/com.qiuyuzhou.shadowsocksX-NG.http.plist` | launchd |

## Appendix B: Code References

- **PAC Generation:** `ShadowsocksX-NG/PACUtils.swift:51-278`
- **ss-local Config:** `ShadowsocksX-NG/ServerProfile.swift:322-347`
- **Launch Agent Management:** `ShadowsocksX-NG/LaunchAgentUtils.swift`
- **Proxy Mode Switching:** `ShadowsocksX-NG/ProxyCoordinator.swift:57-64`

## Appendix C: References

- [PAC File Format Specification](https://developer.mozilla.org/en-US/docs/Web/HTTP/Proxy_servers_and_tunneling/Proxy_Auto-Configuration_PAC_file)
- [AdBlock Plus Filter Syntax](https://adblockplus.org/filter-cheatsheet)
- [Xray-core Routing Documentation](https://xtls.github.io/config/routing.html)
- [SIP003 Plugin Specification](https://shadowsocks.org/en/wiki/Plugin.html)
