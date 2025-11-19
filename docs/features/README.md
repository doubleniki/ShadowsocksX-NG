# Features Documentation

This directory contains detailed specifications and analysis for new features being developed for ShadowsocksX-NG.

## Active Features

### 🚀 Modern Protocols Integration

**Document:** [`MODERN_PROTOCOLS_INTEGRATION.md`](MODERN_PROTOCOLS_INTEGRATION.md)
**Status:** Phases 2-4 in progress
**Target:** v0.7.0-v0.9.0

Comprehensive integration of modern proxy protocols:

- Shadowsocks 2022 (BLAKE3-based AEAD)
- VLESS (lightweight stateless)
- VMess (V2Ray encryption)
- Trojan (TLS masquerading)
- Hysteria2 (QUIC-based)

**Timeline:** 12-17 weeks (Hybrid Multi-Core architecture)

### 🔀 Multi-Server Routing

**Document:** [`MULTI_SERVER_ROUTING.md`](MULTI_SERVER_ROUTING.md)
**Status:** Feasibility analysis complete, GO decision
**Target:** v0.6.0+

Enable simultaneous connections to multiple proxy servers with intelligent routing:

- Per-domain/per-IP routing rules
- Connection pooling
- Automatic failover
- Load balancing

**Dependencies:** Modern Protocols Integration

### 📊 PAC vs Config Analysis

**Document:** [`PAC_CONFIG_COMPARISON.md`](PAC_CONFIG_COMPARISON.md)
**Status:** Reference documentation
**Target:** Educational

Technical comparison between PAC files and configuration files:

- Current PAC-based routing
- Configuration file formats
- Migration path to advanced routing

## Planned Features

### 🎯 Clash-Style Routing

**Document:** [`../architecture/ROUTING_INTEGRATION_ANALYSIS.md`](../architecture/ROUTING_INTEGRATION_ANALYSIS.md)
**Status:** Planning phase
**Target:** v1.0.0+

Advanced routing with Clash syntax support:

- GEOIP/GEOSITE databases
- Process-based routing
- Multi-protocol routing
- Full Clash compatibility

**Dependencies:** Modern Protocols Integration (Xray-core)

### 🔍 User Rule Similarity Detection

**Document:** `USER_RULE_SIMILARITY_PLAN.md`
**Status:** Design specification
**Target:** v0.3.0+

Prevent duplicate domain entries in user rules with smart similarity detection.

## Feature Roadmap

```
v0.6.2 (Current)
  └─ Bug fixes, UI improvements

v0.7.0-v0.9.0 (Modern Protocols)
  ├─ Phase 2: Shadowsocks 2022
  ├─ Phase 3: VLESS/VMess/Trojan/REALITY
  └─ Phase 4: Hysteria2

v1.0.0+ (Advanced Routing)
  ├─ Clash-style routing
  ├─ Multi-server orchestration
  └─ GEOIP integration

v2.0.0+ (Future)
  └─ TBD
```

## Priority Matrix

| Feature | Priority | Complexity | Dependencies |
|---------|----------|------------|--------------|
| Modern Protocols | **High** | Medium-High | - |
| Multi-Server Routing | **High** | High | Modern Protocols |
| Clash Routing | Medium | Medium | Modern Protocols |
| User Rule Similarity | Low | Low | - |

## Documentation Standards

All feature documents should include:

- Executive summary
- Current state vs. desired state
- Implementation phases
- Technical challenges
- Risk assessment
- Timeline and dependencies
- Decision criteria (GO/NO-GO)

## Contributing

When proposing a new feature:

1. Create a detailed specification document
2. Include feasibility analysis
3. Define success criteria
4. Update this README with the new feature
5. Link from main project roadmap

## Related Documentation

- [Project Roadmap](../PROJECT_ROADMAP.md) - High-level release planning
- [Refactoring Plan](../code-quality/REFACTORING_PLAN.md) - Code quality improvements
- [UI Modernization](../ui-modernization/README.md) - Interface updates
