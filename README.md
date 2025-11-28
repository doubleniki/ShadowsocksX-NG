# ProxyForge

[Download](https://github.com/doubleniki/ShadowsocksX-NG/releases/latest) | [Русская версия](README.ru.md)

[![Actions Status](<https://github.com/doubleniki/ShadowsocksX-NG/workflows/Feature%20Building%20(Optimized)/badge.svg>)](https://github.com/doubleniki/ShadowsocksX-NG/actions)

> **ProxyForge** is a modern macOS proxy client, forked from [ShadowsocksX-NG](https://github.com/shadowsocks/ShadowsocksX-NG) with modernized UI, improved UX, and optimized build pipeline.

## What's New in ProxyForge

This enhanced version builds upon the original ShadowsocksX-NG with significant improvements focused on user experience and development efficiency.

### UI Improvements

- **Persistent User Rules Window**: The User Rules editor now remembers its last configured size and position
- **Quick Add Domain**: Enhanced User Rules editor with convenient domain adding features:
  - Text field for quick domain entry
  - "Add" button to add domains instantly
  - "Add from Clipboard" button to extract domains from clipboard URLs
  - Smart domain extraction from full URLs (automatically strips protocol and www prefix)
  - Duplicate detection to prevent adding the same domain twice
  - Input validation to ensure proper domain format

### Build Pipeline Optimizations

- **Optimized GitHub Actions workflows** with multi-level caching:
  - Homebrew packages caching
  - Native dependencies (shadowsocks-libev, privoxy, plugins) caching
  - CocoaPods dependencies caching
  - Build time reduced by 71-86% (from ~35 minutes to 5-10 minutes)
- **Smart commit filtering**: Builds only trigger for code changes (feat, fix, refactor), not for documentation or style updates
- **Efficient artifact management**: Different retention policies for releases vs. feature builds

### Modern macOS Integration

- **macOS 11.0+ Support**: Leverages native SF Symbols, semantic colors, and modern AppKit features
- **Progressive Enhancement**: Advanced features on newer macOS versions while maintaining compatibility
- **Centralized Version Detection**: OSVersion utility for clean feature detection across the codebase

## Requirements

### Running

- **macOS 11.0 Big Sur or later**
- Recommended: macOS 12.0 Monterey or later for best experience

### Building

- Xcode 13.0+ (for macOS 11.0 deployment target)
- CocoaPods 1.10.1+
- macOS 11.0+ development machine

## Core Features

All features from ShadowsocksX-NG, plus:

- `ss-local` from shadowsocks-libev 3.2.5
- Support for SIP003 plugins: `kcptun`, `simple-obfs`, and `v2ray-plugin`
- PAC updates via GFW List from GitHub
- QR code sharing and scanning for server profiles
- Import server profiles from clipboard URLs
- Custom PAC rules editor
- [AEAD Ciphers](https://shadowsocks.org/en/spec/AEAD-Ciphers.html) support
- HTTP Proxy via [privoxy](http://www.privoxy.org/)
- Manual proxy mode for per-app configuration

## Development Documentation

### Planned Features

We're actively developing next-generation features to make ProxyForge more powerful and flexible:

- **[🚀 Modern Protocols Integration](docs/features/MODERN_PROTOCOLS_INTEGRATION.md)** - Comprehensive roadmap for integrating Shadowsocks 2022, VLESS, VMess, Trojan, and Hysteria2 protocols (Phases 2-4, 12-17 weeks)

- **[🔀 Multi-Server Routing](docs/features/MULTI_SERVER_ROUTING.md)** - Enable simultaneous connections to multiple proxy servers with intelligent per-domain routing, connection pooling, and automatic failover

- **[🎯 Clash-Style Routing](docs/architecture/ROUTING_INTEGRATION_ANALYSIS.md)** - Advanced traffic routing with support for GEOIP, process-based rules, and full Clash syntax compatibility (planned for v1.0.0+)

- **[📊 Features Overview](docs/features/README.md)** - Complete feature documentation and roadmap

**Key Milestones:**

- **v0.7.0-v0.9.0**: Modern Protocols (VLESS, VMess, Trojan, Hysteria2)
- **v1.0.0+**: Advanced Routing (Clash-style rules, GEOIP, multi-server)

### UI Modernization Roadmap

We're also modernizing the UI to align with macOS Sequoia design principles:

- **[📋 UI Modernization Roadmap](docs/ui-modernization/MODERNIZATION_ROADMAP.md)** - Complete phased roadmap for adopting SF Symbols, SwiftUI, semantic colors, and modern macOS features (5 phases, 5-7 months)

- **[🔄 Backward Compatibility Guide](docs/ui-modernization/BACKWARD_COMPATIBILITY.md)** - Quick reference for developers on maintaining compatibility across macOS 11.0+ through gradual migration

**Key Highlights:**

- **Phase 1** (11.0+): Native SF Symbols, semantic colors, enhanced vibrancy
- **Phase 2** (12.0+): SwiftUI components, Widgets, refined UX
- **Phase 3** (13.0+): App Intents, Menu Bar Extras API
- **Phase 4** (14.0+): Advanced features, performance optimizations
- **Phase 5** (15.0+): Full Sequoia integration, latest macOS capabilities

### Project Overview

- **[📖 CLAUDE.md](CLAUDE.md)** - Comprehensive project documentation including architecture, build system, launch agents, and development workflows

## About the Original Project

This is a fork of [ShadowsocksX-NG](https://github.com/shadowsocks/ShadowsocksX-NG), which is itself the next generation of [ShadowsocksX](https://github.com/shadowsocks/shadowsocks-iOS).

### Original Implementation Details

The original ShadowsocksX-NG was created to address maintenance challenges in the previous version:

- **Architecture Change**: Instead of embedding `ss-local` source code, it uses the `ss-local` executable from Homebrew
- **Background Service**: `ss-local` runs as a Launch Agent through launchd, persisting even after app quit
- **Simplified Codebase**: GUI code rewritten in Swift, removing unused legacy code
- **Easier Updates**: Dependencies managed through Homebrew, simplifying `ss-local` version updates

### Key Differences

- The proxy service runs independently of the GUI application
- Manual mode available for per-app SOCKS5 proxy configuration
- Modern Swift-based implementation for better maintainability

## Contributing

Contributions must be available on a separately named branch based on the latest version of the main branch `develop`.

ref: [GitFlow](http://nvie.com/posts/a-successful-git-branching-model/)

## License

The project is released under the terms of the GPLv3.
