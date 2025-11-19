# Clash-Style Routing Integration Analysis

**Last Updated:** 2025-01-19
**Status:** Planning Phase
**Target Release:** v1.0.0+

## Executive Summary

This document analyzes the feasibility and approach for integrating Clash-style routing rules into ShadowsocksX-NG, enabling advanced traffic routing with support for GEOIP, process-based rules, and multi-protocol configurations.

## Current State vs. Desired State

### Current (PAC-based)

```javascript
// gfwlist.js - Browser-only, domain matching
if (host.indexOf("github.com") >= 0) return "SOCKS5 127.0.0.1:1086";
return "DIRECT";
```

**Limitations:**

- Browser-only (HTTP/HTTPS)
- No GEOIP support
- No process/port-based routing
- Single proxy server

### Desired (Clash-style)

```yaml
rules:
  - DOMAIN-SUFFIX,github.com,proxy-vless
  - GEOIP,CN,DIRECT
  - PROCESS-NAME,discord,proxy-hysteria2
  - MATCH,proxy-shadowsocks
```

**Capabilities:**

- System-wide (all applications)
- GEOIP/GEOSITE databases
- Process and port-based routing
- Multiple proxy servers

## Integration Options

### Option 1: PAC Translation (Low Complexity)

**Timeline:** 3-4 weeks
**Functionality:** ~40% of Clash features

**Pros:**

- Works with current architecture
- No new binaries needed
- Backward compatible

**Cons:**

- Limited to browser
- No GEOIP
- No process-based routing

### Option 2: Xray-core Routing (Recommended)

**Timeline:** 6-8 weeks
**Functionality:** 100% of Clash features

**Architecture:**

```
ShadowsocksX-NG GUI
        ↓
   Clash YAML Parser
        ↓
   Xray JSON Config Generator
        ↓
   Xray-core (routing engine)
        ↓
   ss-local / VLESS / VMess / Trojan / Hysteria2
```

**Pros:**

- Full Clash syntax support
- System-wide routing
- GEOIP/GEOSITE built-in
- Multiple protocols

**Cons:**

- Requires Xray-core integration
- ~12MB additional binary
- Learning curve for users

## Implementation Phases

### Phase 1: Foundation (2 weeks)

- Clash YAML parser in Swift
- Basic rule types (DOMAIN, DOMAIN-SUFFIX, IP-CIDR)
- Validation and error handling

### Phase 2: Xray Integration (2 weeks)

- Xray config generator (Clash → Xray JSON)
- Launch Agent management for Xray
- Testing with real traffic

### Phase 3: Advanced Features (1 week)

- GEOIP database download and management
- GEOSITE integration
- Process-based routing (if supported by Xray on macOS)

### Phase 4: UI and Migration (1 week)

- Rule editor with syntax highlighting
- PAC → Clash migration tool
- Documentation and user guides

## Technical Challenges

### Challenge 1: GEOIP Database Management

**Problem:** GeoIP databases are large (~10MB) and need updates

**Solution:**

```swift
class GeoDataManager {
    func downloadGeoData() async throws {
        // Download from v2fly/geoip releases
        try await downloadFile(
            from: "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat",
            to: appSupport + "/geoip.dat"
        )
    }

    func updateIfNeeded() async {
        // Check weekly for updates
        if needsUpdate() {
            try? await downloadGeoData()
        }
    }
}
```

### Challenge 2: Process-Based Routing on macOS

**Problem:** macOS sandboxing may restrict process inspection

**Investigation Needed:**

- Test Xray-core process routing on macOS
- Fallback to domain/IP routing if not supported
- Document limitations clearly

### Challenge 3: Backward Compatibility

**Solution:** Dual-mode support

```swift
enum RoutingMode {
    case pac        // Current users
    case clash      // New users / power users
}

// One-time migration wizard on upgrade
func migrateToClash() {
    let pacRules = loadPACRules()
    let clashRules = convertToClash(pacRules)
    saveClashConfig(clashRules)
}
```

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Xray incompatibility | Low | High | Phase 1 prototype testing |
| GeoIP too large | Medium | Low | Lazy loading, CDN |
| User confusion | Medium | Medium | Clear UI, migration wizard |
| Breaking existing setups | Medium | High | Feature flag, gradual rollout |

## Dependencies

### Required for Implementation

1. **Modern Protocols Integration** - Xray-core binary (Phases 2-3)
2. **Multi-Server Routing** - Multiple outbound support

### Synergies

- Xray-core provides both protocol support AND routing engine
- Single binary for VLESS/VMess/Trojan + Clash routing
- Unified configuration model

## Timeline Integration

```
Week 1-2:   Clash Parser + Validation
Week 3-4:   Xray Config Generator
Week 5:     GEOIP Integration
Week 6:     UI + Migration Tools
Week 7-8:   Testing + Documentation

Prerequisites:
  - Xray-core integration (from Modern Protocols plan)
  - Available after v0.9.0
```

## Decision: GO/NO-GO Criteria

**GO if:**

- ✅ Xray-core routing works well on macOS
- ✅ GEOIP database size acceptable (<20MB)
- ✅ No major performance degradation
- ✅ User demand for advanced routing

**NO-GO if:**

- ❌ Xray routing broken on macOS
- ❌ GeoIP unusably large (>50MB)
- ❌ Significant performance issues
- ❌ Low user interest

## Recommendation

**Proceed with Option 2 (Xray-core routing)** after Modern Protocols Integration (Phase 3) completes.

**Rationale:**

1. Full Clash functionality (100% vs 40%)
2. Synergy with protocol integration
3. Future-proof architecture
4. Competitive with Clash/ClashX

**Target Release:** v1.0.0 (after v0.9.0 Modern Protocols)

## References

- [Clash Wiki](https://github.com/Dreamacro/clash/wiki)
- [Xray Routing Documentation](https://xtls.github.io/config/routing.html)
- [V2Fly GeoIP](https://github.com/v2fly/geoip)
- Related: `docs/features/MODERN_PROTOCOLS_INTEGRATION.md`
- Related: `docs/features/MULTI_SERVER_ROUTING.md`
