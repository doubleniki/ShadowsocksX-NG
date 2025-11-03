# ShadowsocksX-NG Roadmap

This document outlines planned features and enhancements for future releases of ShadowsocksX-NG.

## Version 0.2.0 (Next Minor Release)

### User Rules Enhancement
- [ ] **Copy PAC User Rules List** - Add ability to copy all user rules to clipboard for backup or sharing
  - Add "Copy All Rules" button to User Rules window
  - Support copying in ABP format (compatible with other tools)
  - Status indicator showing number of rules copied

### UI/UX Improvements
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

## Version 0.3.0

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

## Version 0.4.0

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

## Version 0.5.0

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

## Future Considerations (Version 1.0+)

### Cloud & Sync
- [ ] **Profile Cloud Sync** - Cross-device synchronization
  - iCloud sync for server profiles
  - Sync user rules across devices
  - Sync preferences and settings
  - Conflict resolution

### Advanced Routing
- [ ] **Custom Routing Rules** - Fine-grained control
  - IP-based routing rules
  - Process-based routing (route specific apps)
  - Advanced rule syntax (regex, wildcards)
  - Rule priority system

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

**Last Updated:** 2025-11-03
**Current Version:** 0.1.0
