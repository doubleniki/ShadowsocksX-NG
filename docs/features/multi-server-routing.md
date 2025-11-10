# Multi-Server Routing Feature Specification

## Executive Summary

**Status**: Design & Feasibility Complete
**Complexity**: High
**Estimated Time**: 12-17 weeks (full) or 3-4 weeks (simplified MVP)
**Recommendation**: Start with 2-week research phase (Phase 0), then decide between full or simplified implementation
**Last Updated**: 2025-11-10

### Key Findings

✅ **Technically Feasible**: Existing codebase has good foundation (ServerProfile.uuid, modular Launch Agent system)
⚠️ **Critical Blocker**: Multiplexer component is the highest risk - requires 4-6 weeks custom development or integration of existing solution
✅ **Fallback Available**: Simplified approach provides 70% of value with 25% of complexity

## Overview

The current ShadowsocksX-NG build allows only one active proxy profile at a time and stores user routing rules in a single shared `user-rule.txt`. This document specifies the changes required to connect to two or more servers simultaneously and route traffic per domain/zone, along with a detailed feasibility assessment and implementation roadmap.

## Goals

- Run a single local proxy endpoint (multiplexer) that forwards to the selected Shadowsocks upstream based on routing rules.
- Scope user routing rules per server while keeping a global fallback bucket.
- Generate PAC output that selects the appropriate upstream via multiplexer metadata (still one host:port exposed to macOS).
- Preserve compatibility with existing rule files by migrating legacy entries to the default bucket.

## Proposed Architecture

1. **Data Model**
   - Extend `ServerProfile` with a stable identifier and optional `ruleSetId`.
   - Introduce a `ServerRoutingRule` entity persisted as `docs/rules/<profile-id>.json` (or CoreData/SQLite) containing `[pattern, action, priority]` tuples.
   - A migration tool ingests `user-rule.txt`, splitting entries into the default/global set.

2. **Process Management**
   - `ShadowsocksRunner` launches a single multiplexer process (SIP003 plugin or custom daemon) that listens on the usual local port (e.g., 1086) and internally maintains pools of `ss-local` connections per upstream.
   - The multiplexer keeps lightweight connections (or on-demand dials) to each configured server and exposes health stats for UI display.

3. **PAC Generation**
   - `PACUtils.generatePACFile()` still returns a single `PROXY 127.0.0.1:1086` entry (plus `DIRECT` fallback), but injects rule metadata (e.g., custom headers or query params) understood by the multiplexer to pick the correct upstream.
   - Ensure deterministic resolution when multiple rules match by honoring explicit priorities before forwarding metadata to the multiplexer.

4. **UI/UX**
   - Update `UserRulesController` to select a target server (drop-down or segmented control) and show separate lists per profile.
   - Allow bulk import/export per server and highlight conflicts (e.g., two servers claiming the same domain).

## Testing

- Unit: add coverage in `ShadowsocksX-NGTests` for rule serialization, PAC generation, and migration logic.
- Manual: verify simultaneous connections, PAC routing, and menu-bar status indicators on macOS networking.

## Feasibility Assessment

### Overall Status: FEASIBLE BUT COMPLEX

**Estimated Development Time**: 8-11 weeks (full implementation) or 3-4 weeks (simplified approach)
**Complexity Level**: High
**Risk Level**: Medium-High

### Favorable Conditions

1. **Existing Foundation**
   - `ServerProfile.uuid` already exists (ShadowsocksX-NG/ServerProfile.swift:12) - can serve as stable identifier
   - Launch Agent infrastructure (`LaunchAgentUtils.swift`) is modular and extensible
   - PAC generation system already in place
   - Active refactoring efforts with good code quality practices (Phase 1 completed)

2. **Architectural Compatibility**
   - Launch Agent-based architecture already supports multiple concurrent services
   - Proxy switching logic centralized in `AppDelegate`
   - File-based configuration system can accommodate per-server rule files
   - UserDefaults + Keychain persistence already established

3. **Code Quality**
   - Project uses Swift 5+ with modern practices
   - SwiftLint configured with style guidelines
   - Comprehensive error handling via `ErrorHandler` singleton
   - Good test coverage foundation in `ShadowsocksX-NGTests`

### Major Challenges

1. **Multiplexer Component (CRITICAL PATH)**
   - **Biggest Risk**: Need to build or integrate a SOCKS5 multiplexer that:
     - Accepts connections on single port (127.0.0.1:1086)
     - Routes based on domain/pattern metadata
     - Manages connection pools to multiple `ss-local` upstreams
     - Provides health monitoring and failover
   - **Options**:
     - Build custom multiplexer daemon (4-6 weeks, high complexity)
     - Integrate existing solution (v2ray-core, trojan-go, xray-core)
     - Use SIP003-compatible plugin (availability unknown)

2. **PAC Generation Complexity**
   - Current `generatePACFile()` is already complex:
     - 161 lines (exceeds recommended 50)
     - Cyclomatic complexity: 24 (exceeds recommended 10)
     - Listed in SwiftLint exceptions requiring future refactoring
   - Encoding routing metadata in PAC while maintaining single endpoint is non-trivial
   - PAC specification has limitations on metadata passing

3. **UI/UX Complete Redesign**
   - `UserRulesController` needs ground-up rewrite for per-server management
   - Menu bar status must display multi-server health
   - New features: server selection, conflict detection, bulk import/export
   - Localization updates (English, Chinese)

4. **Migration Path Complexity**
   - Must migrate existing `user-rule.txt` without data loss
   - User routing rules are valuable and critical to preserve
   - Need graceful upgrade path for existing installations
   - Backward compatibility constraints

### Technical Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Multiplexer performance overhead** | High | Benchmark early, optimize connection pooling, implement smart caching |
| **PAC metadata encoding limitations** | Medium | Research PAC spec thoroughly in Phase 1, test with multiple browsers |
| **Resource consumption (memory/CPU)** | Medium | Implement lazy connection initialization, configurable pool limits |
| **Breaking changes to existing setups** | High | Feature flag for opt-in, comprehensive migration testing |
| **SIP003 plugin compatibility** | Medium | Test with all plugins (kcptun, simple-obfs, v2ray-plugin) during spike |
| **macOS network stack integration** | Low | Existing proxy_conf_helper already handles this |

### Technical Constraints & Dependencies

#### Codebase Dependencies

- **ServerProfile.swift** (ShadowsocksX-NG/ServerProfile.swift)
  - Already has `uuid: String` property (line 12) - ready to use as stable identifier
  - Keychain integration for password storage (secure)
  - Methods: `toDictionary()`, `fromDictionary()` - need extension for rule association

- **LaunchAgentUtils.swift** (ShadowsocksX-NG/LaunchAgentUtils.swift)
  - Well-structured with separate functions for each service
  - `generateSSLocalLauchAgentPlist()` (line 54-163)
  - `startSSLocal()`, `stopSSLocal()`, `syncSSLocal()`
  - **Extension needed**: Support multiple ss-local instances on different ports

- **PACUtils.swift** (ShadowsocksX-NG/PACUtils.swift)
  - `generatePACFile()` function is complex (161 lines, complexity 24)
  - Listed in `.swiftlint.yml` exceptions for future refactoring
  - **Major refactoring needed**: Decompose and add multi-server support

- **UserRulesController.swift** (ShadowsocksX-NG/UserRulesController.swift)
  - Contains `RuleSimilarityChecker` struct for detecting duplicate rules
  - **Complete redesign needed**: Per-server rule management

- **AppDelegate.swift** (ShadowsocksX-NG/AppDelegate.swift)
  - Main application controller, recently refactored (Phase 1 complete)
  - Proxy mode switching logic centralized
  - **Moderate changes needed**: Multi-server coordination

#### System Requirements

- macOS 11.0+ (current deployment target)
- Xcode 14.0+ (compatible with Xcode 15+)
- CocoaPods 1.10+
- Swift 5.0+

#### Build System Dependencies

- Native dependencies built in `deps/` directory
- Multiplexer binary would need:
  - Universal binary support (x86_64 + arm64)
  - Build via `deps/Makefile`
  - Codesigning/notarization integration

#### Third-Party Dependencies (via CocoaPods)

- Alamofire (networking) - already used
- GCDWebServer (PAC file serving) - already used
- RxSwift/RxCocoa (reactive programming) - already used
- No new dependencies required for data model
- Potential new dependency: If using existing multiplexer solution

#### PAC Specification Constraints

- PAC files use JavaScript (ECMAScript 3)
- Standard PAC functions: `isInNet()`, `dnsDomainIs()`, `shExpMatch()`
- **Limitation**: Cannot directly pass custom metadata to proxy
- **Workaround options**:
  - Encode routing hint in PAC return value (complex)
  - Use SOCKS5 username field for routing metadata
  - Generate different PAC files per context (not scalable)

#### macOS System Limitations

- Single system-wide PAC file or proxy setting
- Cannot have different proxies per application (without per-app VPN)
- PAC file must return single `PROXY host:port` or `DIRECT`
- **Impact**: Must use multiplexer on single port (e.g., 127.0.0.1:1086)

#### Launch Agent Constraints

- Services run in user LaunchAgent context
- Plist files stored in `~/Library/LaunchAgents/`
- Each service needs unique label (e.g., `com.qiuyuzhou.shadowsocksX-NG.local.N`)
- **Limitation**: All services must use different ports
- Current port usage:
  - ss-local: 1086 (SOCKS5)
  - privoxy: 1087 (HTTP)
  - kcptun: varies
  - **New**: multiplexer would occupy 1086, ss-local instances use 1088+

#### Security & Sandboxing

- App sandbox requirements for macOS App Store (if applicable)
- Keychain access for server passwords (already implemented)
- Code signing for all binaries (including multiplexer)
- Notarization required for distribution outside App Store

## Open Questions

- How many concurrent servers should be supported without overwhelming the UI? **Recommendation: Start with 2-5, expand to 10 max based on feedback**
- Should we allow chained fallbacks (server A → server B) when the primary target is down? **Phase 2 feature - focus on single-server selection first**
- Do we need per-rule QoS/latency metadata to aid automatic server selection? **Phase 2 feature - manual selection sufficient for MVP**
- Which multiplexer approach is most viable? **Requires Phase 1 research spike**
- Can PAC files encode sufficient metadata for routing decisions? **Requires Phase 1 prototyping**

## Implementation Plan (Full Version)

### Phase 0: Research & Validation (2 weeks)

**Goal**: De-risk the critical path and validate technical approach

#### Week 1: Technology Spike

- [ ] **Research existing multiplexer solutions** (3 days)
  - Evaluate v2ray-core routing capabilities
  - Evaluate xray-core with routing rules
  - Evaluate trojan-go multiplexing features
  - Research SIP003-compatible mux plugins
  - Document pros/cons of each approach
  - **Deliverable**: Technology comparison matrix

- [ ] **PAC metadata encoding prototype** (2 days)
  - Test PAC spec limitations for metadata passing
  - Prototype using SOCKS username for routing hints
  - Test with Safari, Chrome, and system proxy settings
  - **Deliverable**: Working PAC prototype or "blocker" decision

#### Week 2: Proof of Concept

- [ ] **Build minimal 2-server routing prototype** (5 days)
  - Simple CLI multiplexer (Go/Rust) that routes based on SOCKS username
  - Basic PAC file that encodes server ID in connection metadata
  - Test with 2 real Shadowsocks servers
  - Measure latency overhead
  - **Deliverable**: PoC demo + performance metrics
  - **Decision Point**: GO/NO-GO for full implementation

---

### Phase 1: Data Model & Migration (2 weeks)

**Prerequisites**: Phase 0 approved
**Goal**: Implement data layer without breaking existing functionality

#### Week 1: Models & Persistence

- [ ] **Define ServerRoutingRule model** (1 day)
  - Create `ServerRoutingRule.swift` in Models/
  - Properties: `id`, `serverUUID`, `pattern`, `action`, `priority`, `enabled`
  - Implement `Codable` for JSON serialization
  - Add validation methods

- [ ] **Extend ServerProfile** (1 day)
  - Add optional `ruleSetId` property (use existing `uuid`)
  - Add `hasCustomRules` computed property
  - Update `toDictionary()` and `fromDictionary()` methods
  - Maintain backward compatibility

- [ ] **Create RuleSetManager** (2 days)
  - Singleton class for managing rule sets
  - Methods: `loadRules(for:)`, `saveRules(for:)`, `deleteRules(for:)`
  - JSON persistence at `~/Library/Application Support/ShadowsocksX-NG/rules/<uuid>.json`
  - Global rule set at `rules/global.json`
  - Error handling via `ErrorHandler`

- [ ] **Unit tests for models** (1 day)
  - Test ServerRoutingRule validation
  - Test RuleSetManager CRUD operations
  - Test JSON serialization/deserialization
  - Test file I/O error handling
  - **Target**: 80%+ coverage

#### Week 2: Migration Utility

- [ ] **Implement UserRuleMigration** (3 days)
  - Parse existing `user-rule.txt` (AdBlock Plus format)
  - Detect rule patterns (domain, keyword, regex)
  - Create `global.json` rule set from legacy file
  - Backup original file to `user-rule.txt.backup`
  - Add migration status tracking in UserDefaults
  - Handle edge cases (empty file, corrupted data, missing file)

- [ ] **Migration unit tests** (1 day)
  - Test with real user-rule.txt examples
  - Test backup creation
  - Test idempotency (don't migrate twice)
  - Test rollback scenarios

- [ ] **Integration with app startup** (1 day)
  - Run migration on first launch after update
  - Show migration progress/success dialog
  - Add rollback option in Preferences

---

### Phase 2: Multiplexer Service (4-6 weeks)

**Prerequisites**: Phase 0 decision, Phase 1 complete
**Goal**: Implement or integrate routing multiplexer

#### Option A: Custom Multiplexer (6 weeks)

- [ ] **Design multiplexer architecture** (3 days)
  - Choose language (Go recommended for networking)
  - Design IPC protocol (Unix socket or HTTP)
  - Design routing metadata format (SOCKS username, custom header)
  - Design health check interface
  - **Deliverable**: Architecture document

- [ ] **Implement core routing** (2 weeks)
  - SOCKS5 server implementation
  - Parse routing metadata from connections
  - Route to appropriate upstream ss-local instance
  - Connection pooling and lifecycle management
  - Graceful shutdown and error recovery

- [ ] **Implement health monitoring** (1 week)
  - Periodic health checks to each ss-local
  - Expose status via Unix socket/HTTP endpoint
  - Latency tracking and reporting
  - Automatic failover on upstream failure

- [ ] **Build system integration** (1 week)
  - Add to `deps/` Makefile
  - Universal binary build (x86_64 + arm64)
  - Bundle in app Resources/
  - Codesigning configuration

- [ ] **Integration with LaunchAgentUtils** (1 week)
  - Generate multiplexer Launch Agent plist
  - Start/stop lifecycle management
  - Log file configuration
  - Crash recovery

- [ ] **Testing** (1 week)
  - Unit tests for routing logic
  - Integration tests with real ss-local
  - Load testing and performance optimization
  - Memory leak detection

#### Option B: Integrate Existing Solution (3-4 weeks)

- [ ] **Evaluate and select solution** (1 week - done in Phase 0)

- [ ] **Integration layer** (1 week)
  - Wrap chosen multiplexer (v2ray-core/xray-core)
  - Create Swift interface for configuration
  - Generate multiplexer config files
  - Launch Agent integration

- [ ] **Configuration bridge** (1 week)
  - Convert ServerProfile to multiplexer config format
  - Convert routing rules to multiplexer format
  - Handle plugin configuration passthrough

- [ ] **Testing** (1 week)
  - Integration testing with all plugins
  - Performance benchmarking
  - Failover testing

---

### Phase 3: Routing Logic & PAC Generation (2 weeks)

**Prerequisites**: Phase 1 complete, Phase 2 in progress
**Goal**: Update PAC generation and routing logic

#### Week 1: Rule Matching Engine

- [ ] **Refactor RuleSimilarityChecker** (2 days)
  - Extend to support per-server rule matching
  - Implement priority-based rule resolution
  - Handle conflicts (same domain, multiple servers)
  - Add server UUID to rule matching results

- [ ] **Update Quick Add flow** (1 day)
  - Add server selection dropdown
  - Associate new rules with selected server
  - Show existing rules for domain before adding
  - Warn on conflicts

- [ ] **Rule conflict detector** (2 days)
  - Implement conflict detection algorithm
  - UI feedback for conflicting rules
  - Resolution suggestions (priority adjustment)
  - Unit tests for edge cases

#### Week 2: PAC Generation Rewrite

- [ ] **Decompose generatePACFile()** (3 days)
  - Extract helper functions to reduce complexity
  - Create `PACRuleEncoder` class
  - Encode server UUID in SOCKS username or custom field
  - Update PAC template to pass metadata to multiplexer
  - Maintain single `PROXY 127.0.0.1:1086` endpoint

- [ ] **Update syncPac()** (1 day)
  - Regenerate PAC on rule changes
  - Regenerate PAC on active server list changes
  - Optimize to avoid unnecessary regeneration

- [ ] **Unit tests** (1 day)
  - Test PAC generation with multiple servers
  - Test rule priority resolution
  - Test metadata encoding/decoding
  - Test edge cases (no servers, all servers disabled)

---

### Phase 4: User Interface (2 weeks)

**Prerequisites**: Phase 1 complete
**Goal**: Redesign UI for multi-server rule management

#### Week 1: UserRulesController Redesign

- [ ] **Design UI layout** (1 day)
  - Sketch per-server tabs or dropdown design
  - Design global rules bucket UI
  - Design conflict indicator UI
  - Design import/export per-server UI
  - **Deliverable**: UI mockups

- [ ] **Implement UI structure** (2 days)
  - Update UserRulesController.xib
  - Add NSTabView or NSSegmentedControl for server selection
  - Add global rules section
  - Add server selection state management

- [ ] **Implement rule editing** (2 days)
  - Add/edit/delete rules per server
  - Drag-and-drop priority reordering
  - Enable/disable individual rules
  - Rule validation and error display

#### Week 2: Menu Bar & Status

- [ ] **Multi-server status display** (2 days)
  - Show connected server count in menu bar
  - Add submenu with per-server status
  - Display latency/health indicators
  - Color-coded status (green/yellow/red)

- [ ] **Import/Export per server** (1 day)
  - Import rules for selected server
  - Export rules for selected server
  - Bulk operations (import to multiple servers)

- [ ] **Localization updates** (2 days)
  - Update en.lproj strings
  - Update zh-Hans.lproj strings
  - Add new UI strings for multi-server features

---

### Phase 5: System Integration (1 week)

**Prerequisites**: Phase 2-4 complete
**Goal**: End-to-end integration and polish

- [ ] **AppDelegate integration** (2 days)
  - Update proxy mode switching logic
  - Handle multiple active servers
  - Update server profile change handling
  - Ensure multiplexer restarts on config changes

- [ ] **Launch Agent coordination** (1 day)
  - Ensure multiple ss-local instances can run (different ports)
  - Update stopSSLocal to handle multiple instances
  - Update syncSSLocal for multi-server scenarios

- [ ] **Codesigning & notarization** (1 day)
  - Add multiplexer binary to signing
  - Update entitlements if needed
  - Test notarization with new binary

- [ ] **CLI support** (1 day)
  - Add defaults write support for rule configuration
  - Document CLI usage for automation
  - Test scripted deployments

---

### Phase 6: Testing & Release (2 weeks)

**Prerequisites**: Phase 5 complete
**Goal**: Comprehensive testing and production readiness

#### Week 1: Testing

- [ ] **XCTest expansion** (3 days)
  - Test all new models (RuleSet, ServerRoutingRule)
  - Test migration utility thoroughly
  - Test PAC generation with multiple servers
  - Test multiplexer command interface (if custom)
  - Test UI controllers (snapshot testing)
  - **Target**: 80%+ coverage on new code

- [ ] **Manual testing checklist** (2 days)
  - Two servers with different domain rules
  - Three servers with overlapping rules
  - Server failure scenarios (one goes down)
  - Network switching (WiFi → Ethernet)
  - Migration from legacy single-server setup
  - Plugin compatibility (kcptun, simple-obfs, v2ray-plugin)
  - Performance: latency, memory usage, CPU usage
  - macOS proxy verification (System Preferences, Safari, Chrome)

#### Week 2: Documentation & Release

- [ ] **User documentation** (2 days)
  - Update README with multi-server routing section
  - Create tutorial with screenshots
  - Document migration process
  - Create troubleshooting guide

- [ ] **Developer documentation** (1 day)
  - Document multiplexer architecture
  - Document rule storage format
  - Document IPC protocol (if custom multiplexer)
  - Update CLAUDE.md with new architecture

- [ ] **Release preparation** (2 days)
  - Update CHANGELOG
  - Create release notes
  - Prepare demo GIFs/videos
  - Beta release to small user group
  - Collect feedback and fix critical issues

---

### Total Time Estimate

- Phase 0 (Research): 2 weeks
- Phase 1 (Data Model): 2 weeks
- Phase 2 (Multiplexer): 4-6 weeks
- Phase 3 (Routing): 2 weeks
- Phase 4 (UI): 2 weeks
- Phase 5 (Integration): 1 week
- Phase 6 (Testing): 2 weeks

**Total: 15-17 weeks for custom multiplexer, 12-14 weeks for existing solution**

---

## Alternative: Simplified Implementation (3-4 weeks)

If Phase 0 research reveals the full multiplexer approach is too complex, consider this simpler alternative:

### Profile Groups with Intelligent Quick Switching

**Concept**: Instead of simultaneous multi-server connections, implement intelligent single-server switching based on rules.

#### Week 1-2: Rule-Based Server Selection

- [ ] Per-server rule management (reuse Phase 1 data model)
- [ ] Rule matching engine that selects server for current domain
- [ ] Automatic PAC regeneration when accessing new domain
- [ ] Quick switching (< 2 seconds) between servers

#### Week 3: UI & Automation

- [ ] UserRulesController redesign (simplified, no tabs)
- [ ] Menu bar shows "active server for current domain"
- [ ] Quick switch menu item
- [ ] Auto-switch on domain change (optional preference)

#### Week 4: Testing & Release

- [ ] Testing and documentation
- [ ] Much lower risk, no multiplexer complexity
- [ ] Can evolve to full multi-server later

### Benefits of Simplified Approach

- ✅ No multiplexer complexity
- ✅ No connection pooling overhead
- ✅ Works with all existing plugins
- ✅ Easier to test and maintain
- ✅ Still provides per-server rule management
- ✅ Can upgrade to full version later

### Limitations

- ❌ Not truly simultaneous multi-server
- ❌ Switching delay when domain changes
- ❌ Cannot route different domains simultaneously

---

## Recommendation

**Start with Phase 0 (2 weeks)** to validate the technical approach. Based on Phase 0 results:

1. **If multiplexer approach is viable**: Proceed with full implementation (12-17 weeks)
2. **If multiplexer has significant blockers**: Implement simplified approach (3-4 weeks), gather user feedback, then revisit full version in future release

The simplified approach provides 70% of the value with 25% of the complexity, making it an excellent MVP strategy.
