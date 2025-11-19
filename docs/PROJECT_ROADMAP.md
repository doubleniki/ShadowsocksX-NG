# ShadowsocksX-NG Roadmap

This document outlines planned features and enhancements for future releases of ShadowsocksX-NG.

## Roadmap Highlights

- **v0.3.0** (Current): Phase 1 & 2 refactoring complete, rule similarity detection, enhanced notifications
- **v0.4.0** (Next): UI/UX improvements, traffic statistics, server latency indicators
- **v0.5.0**: Advanced PAC features with rule categories and domain testing
- **v0.6.0**: **Multi-Server Routing** (major feature) - simultaneous connections to multiple servers with intelligent routing
- **v0.7.0+**: Advanced server management, security features, statistics, and developer tools

## Recently Completed (Version 0.3.0)

### Code Quality & Architecture

- [x] **Phase 1 Refactoring** - Foundation & safety improvements
  - Eliminated all force unwrapping in test files
  - Centralized error handling through ErrorHandler singleton
  - Enhanced Keychain security for server passwords
  - Updated deployment target to macOS 11.0
  - SwiftLint integration with documented exceptions

- [x] **Phase 2 Refactoring** - AppDelegate architecture improvements
  - Extracted coordinators from AppDelegate (MenuBarManager, ProxyCoordinator, WindowCoordinator)
  - Implemented delegate pattern for menu actions
  - Fixed RxSwift subscription lifecycle issues
  - MenuBarManager improvements and bug fixes

### User Rules Enhancement

- [x] **Rule Similarity Detection** - Prevent duplicate rules
  - Compare new rules against existing PAC rules before adding
  - Show warnings when adding similar/duplicate rules
  - Improved user feedback during rule addition

### Notifications

- [x] **Enhanced Notification System** - Improved user feedback
  - Refactored in-app notification system
  - Updated user notification service
  - Better error and status messages

## Version 0.4.0 (Next Minor Release)

### UI/UX Improvements

- [ ] **Copy PAC User Rules List** - Add ability to copy all user rules to clipboard for backup or sharing
  - Add "Copy All Rules" button to User Rules window
  - Support copying in ABP format (compatible with other tools)
  - Status indicator showing number of rules copied
  - Paste rules from clipboard (bulk import)

- [ ] **Traffic Statistics Display** - Real-time bandwidth monitoring
  - Show current upload/download speed in menu bar (optional)
  - Display total data usage for current session
  - Historical traffic graphs in preferences window
  - Per-server traffic statistics

- [ ] **Server Latency Indicator** - Connection quality display
  - Ping test functionality for each server profile
  - Visual latency indicator (color-coded: green/yellow/red)
  - Show ping time in server list
  - Auto-sort servers by latency option

- [ ] **Enhanced QR Code Scanning** - Improved import workflow
  - Support scanning from iPhone/iPad via Continuity Camera
  - Batch QR code scanning (multiple servers at once)
  - QR code history (recently scanned codes)

## Version 0.5.0

### Advanced PAC Features

- [ ] **Rule Categories** - Organize rules into logical groups
  - Predefined categories (Streaming, Social Media, Development, etc.)
  - Custom category creation
  - Enable/disable entire categories
  - Import/export category rule sets

- [ ] **Rule Presets Library** - Common rule collections
  - Built-in presets for common use cases
  - Community-contributed rule sets
  - One-click preset installation
  - Preset update notifications

- [ ] **Domain Testing Tool** - Check if domain matches rules
  - Input domain to test against current rules
  - Show which rule matched (if any)
  - Explain proxy routing decision
  - Bulk domain testing from file

### Smart Features

- [ ] **Intelligent Mode Switching** - Context-aware proxy configuration
  - Auto-detect network type (Home/Work/Public)
  - Network-specific proxy mode profiles
  - Geolocation-based mode selection
  - VPN detection and auto-disable

- [ ] **Schedule-Based Automation** - Time-based proxy control
  - Schedule proxy on/off times
  - Different modes for different times of day
  - Weekend/weekday schedules
  - Holiday schedule support

## Version 0.6.0 (Major Feature Release)

### Multi-Server Routing

**Status**: Design & feasibility complete ([see detailed specification](docs/features/MULTI_SERVER_ROUTING.md))
**Estimated Effort**: 12-17 weeks (full implementation) or 3-4 weeks (simplified MVP)
**Approach**: Research-first with GO/NO-GO decision point after Phase 0

> **Note**: This is a complex feature requiring significant architectural changes. Implementation will begin with a 2-week research phase to validate the technical approach before committing to full development.

- [ ] **Phase 0: Research & Validation** (2 weeks)
  - Technology spike for multiplexer solutions (v2ray-core, xray-core, custom)
  - PAC metadata encoding prototype
  - 2-server proof-of-concept with performance benchmarks
  - GO/NO-GO decision point

- [ ] **Option A: Full Multi-Server Routing** (12-17 weeks after Phase 0)
  - Data model extensions (ServerRoutingRule, RuleSetManager)
  - Multiplexer service implementation or integration
  - Per-server rule management with conflict detection
  - Enhanced PAC generation with routing metadata
  - UI redesign for multi-server rule management
  - Migration utility for existing user-rule.txt
  - Comprehensive testing and documentation

- [ ] **Option B: Simplified MVP - Intelligent Quick Switching** (3-4 weeks after Phase 0)
  - Per-server rule management without multiplexer
  - Rule-based automatic server selection
  - Quick switching (< 2 seconds) between servers
  - Auto-switch on domain change (optional)
  - Can upgrade to full version in future release

**Key Benefits**:

- Route different domains through different servers simultaneously (Option A)
- Per-server routing rules with global fallback bucket
- Preserve all existing functionality and compatibility
- Built on existing ServerProfile.uuid infrastructure

**Technical Highlights**:

- Multiplexer on single port (127.0.0.1:1086) routing to multiple ss-local upstreams
- Health monitoring and failover support
- Migration path from legacy user-rule.txt format
- Full backward compatibility

## Version 0.7.0

### Advanced Server Management

- [ ] **Server Groups** - Organize servers into categories
  - Create custom server groups (e.g., US Servers, Fast Servers)
  - Nested groups support
  - Quick switching between groups
  - Import/export entire groups

- [ ] **Server Health Monitoring** - Continuous connection monitoring
  - Auto-detect failed servers
  - Automatic failover to backup server
  - Server uptime statistics
  - Alert notifications for server issues

- [ ] **Subscription Management** - Server list auto-updates
  - Subscribe to server URLs (ss:// subscription format)
  - Auto-update subscriptions on schedule
  - Multiple subscription sources
  - Subscription conflict resolution

### Security & Privacy

- [ ] **Connection Logging Controls** - Enhanced privacy options
  - Configurable log levels
  - Auto-purge old logs
  - Privacy mode (no domain logging)
  - Encrypted log storage option

- [ ] **Leak Protection** - Prevent IP/DNS leaks
  - DNS leak detection and prevention
  - Kill switch (block internet if proxy fails)
  - IPv6 leak protection
  - WebRTC leak protection warnings

## Version 0.8.0

### Advanced Statistics & Analytics

- [ ] **Connection History** - Detailed activity logs
  - Domain access history
  - Connection timeline view
  - Search and filter history
  - Export history reports

- [ ] **Advanced Traffic Analysis** - Detailed bandwidth insights
  - Per-application traffic breakdown (if possible)
  - Per-domain bandwidth statistics
  - Traffic patterns visualization
  - Data usage alerts and limits

### Developer Features

- [ ] **Debug Dashboard** - Advanced troubleshooting tools
  - Real-time ss-local log viewer
  - Network request inspector
  - PAC file tester
  - System proxy configuration viewer

- [ ] **API/CLI Interface** - Programmatic control
  - Command-line interface for automation
  - AppleScript/JXA support
  - REST API for local control
  - Shortcuts.app integration

## Future Considerations (Version 0.9.0+)

### Cloud & Sync

- [ ] **Profile Cloud Sync** - Cross-device synchronization
  - iCloud sync for server profiles
  - Sync user rules across devices
  - Sync preferences and settings
  - Conflict resolution

### Advanced Routing (Post Multi-Server Routing)

**Note**: These features build upon the Multi-Server Routing foundation (v0.6.0)

- [ ] **Enhanced Custom Routing Rules** - Fine-grained control
  - IP-based routing rules
  - Process-based routing (route specific apps)
  - Advanced rule syntax (regex, wildcards)
  - Chained server fallbacks (server A → server B)
  - QoS/latency-based automatic server selection

### Integration

- [ ] **Browser Extensions** - Direct browser control
  - Safari extension for quick mode switching
  - Chrome/Firefox extension support
  - Per-site proxy settings
  - Whitelist/blacklist per-site

- [ ] **System Integration** - Deep macOS integration
  - Share Sheet extension (import from anywhere)
  - Quick Look plugin for ss:// URLs
  - Spotlight integration for servers
  - Touch Bar support

## Community Features

### Documentation & Support

- [ ] **In-App Help System** - Contextual documentation
  - Interactive tutorials for first-time users
  - Tooltips and help hints
  - FAQ section
  - Video tutorials

- [ ] **User Feedback System** - Built-in feedback collection
  - Bug reporting from within app
  - Feature request submission
  - Anonymous usage statistics (opt-in)
  - Beta testing program

### Localization

- [ ] **Multi-language Support** - Internationalization
  - Chinese (Simplified & Traditional)
  - Russian
  - Japanese
  - Korean
  - Spanish
  - More languages based on community contributions

## Performance & Stability

### Optimization

- [ ] **Memory Optimization** - Reduce resource usage
  - Optimize menu bar memory footprint
  - Reduce Launch Agent overhead
  - Better cache management
  - Background process optimization

- [ ] **Startup Performance** - Faster launch times
  - Lazy loading of resources
  - Parallel service initialization
  - Profile cache optimization
  - Reduced I/O operations

### Reliability

- [ ] **Error Recovery** - Improved stability
  - Auto-restart failed services
  - Better error messages
  - Crash reporting (opt-in)
  - Self-healing configuration

## Contributing

We welcome community contributions! If you'd like to work on any of these features:

1. Check existing issues and pull requests
2. Discuss your approach in an issue first
3. Follow the development workflow in CLAUDE.md
4. Submit a pull request to the `develop` branch

## Feedback

Have ideas for new features? Please:

- Open an issue with the `enhancement` label
- Describe your use case and proposed solution
- Vote on existing feature requests

---

**Note:** This roadmap is subject to change based on community feedback, technical constraints, and development priorities. Features may be moved between versions or postponed as needed.

**Last Updated:** 2025-11-10
**Current Version:** 0.3.0
