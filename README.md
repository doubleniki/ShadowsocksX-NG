# ShadowsocksX-NG

> **Note**: This is a fork of the [original ShadowsocksX-NG](https://github.com/shadowsocks/ShadowsocksX-NG) with additional UI improvements and optimized build pipeline.

[Download](https://github.com/doubleniki/ShadowsocksX-NG/releases/latest)

[![Actions Status](<https://github.com/doubleniki/ShadowsocksX-NG/workflows/Feature%20Building%20(Optimized)/badge.svg>)](https://github.com/doubleniki/ShadowsocksX-NG/actions)

Next Generation of [ShadowsocksX](https://github.com/shadowsocks/shadowsocks-iOS)

## Why a new implementation?

It's hard to maintain the original implementation as there is too much unused code in it.
It also embeds the `ss-local` source code. It's crazy to maintain dependencies of `ss-local`.
So it's hard to update the `ss-local` version.

Now I just copied the `ss-local` from Homebrew. Run `ss-local` executable as a Launch Agent in the background.
So there is only some source code related to GUI left.
Then I have rewrited the GUI code in Swift.

## Requirements

### Running

macOS 10.12+

### Building

- Xcode 12.5.1+
- CocoaPods 1.10.1+

## Download

From [here](https://github.com/doubleniki/ShadowsocksX-NG/releases/)

## Features

- `ss-local` from shadowsocks-libev 3.2.5.
- Support SIP003 plugins. Embed `kcptun`, `simple-obfs` and `v2ray-plugin`.
- Could update PAC by download GFW List from GitHub.
- Share your server profiles by qrcode or url.
- Import server profile urls from pasteboard.
- Import server profile by scan QRCode on screen.
- Custom rules for PAC.
- Support for [AEAD Ciphers](https://shadowsocks.org/en/spec/AEAD-Ciphers.html)
- HTTP Proxy by [privoxy](http://www.privoxy.org/)

## Enhancements in This Fork

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

## Difference from original ShadowsocksX

`ss-local` is run as a background service through launchd, not as an in-app process.
So after you quit the app, the `ss-local` might be still running.

Added a manual mode which won't configure the system proxy settings,
so that you could configure your apps to use the SOCKS5 proxy manually.

## Development Documentation

### UI Modernization Roadmap

We're actively modernizing the UI to align with macOS Sequoia design principles while maintaining backward compatibility:

- **[📋 UI Modernization Roadmap](docs/ui-modernization/MODERNIZATION_ROADMAP.md)** - Complete phased roadmap for adopting SF Symbols, SwiftUI, semantic colors, and modern macOS features (5 phases, 5-7 months)

- **[🔄 Backward Compatibility Guide](docs/ui-modernization/BACKWARD_COMPATIBILITY.md)** - Quick reference for developers on maintaining compatibility across macOS 10.12+ through gradual migration

**Key Highlights:**

- **Phase 1-2** (10.12+): SF Symbols with PNG fallbacks, semantic colors, vibrancy
- **Phase 3** (10.14+): SwiftUI integration, dark mode required
- **Phase 4** (10.15+): Enhanced UX, Combine migration
- **Phase 5** (11.0+): Full modernization, App Intents, Widgets

### Project Overview

- **[📖 CLAUDE.md](CLAUDE.md)** - Comprehensive project documentation including architecture, build system, launch agents, and development workflows

## Contributing

Contributions must be available on a separately named branch based on the latest version of the main branch `develop`.

ref: [GitFlow](http://nvie.com/posts/a-successful-git-branching-model/)

## License

The project is released under the terms of the GPLv3.
