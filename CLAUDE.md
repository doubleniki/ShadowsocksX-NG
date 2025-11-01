# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

ShadowsocksX-NG is a macOS GUI client for Shadowsocks, a secure proxy protocol. The app runs `ss-local` (from shadowsocks-libev) as a background Launch Agent service, not as an in-app process. This means the proxy service continues running even after the app quits.

**Key Technologies:**
- Swift (GUI layer)
- Objective-C (LaunchAtLogin controller, proxy configuration helper)
- CocoaPods for dependency management
- Xcode workspace build system
- Native C binaries (shadowsocks-libev, privoxy, plugin executables)

## Architecture

### Process Architecture
The application consists of multiple independent processes:

1. **Main App** (`ShadowsocksX-NG.app`): Swift-based GUI that manages configuration and user interactions
2. **ss-local**: Shadowsocks local proxy daemon (runs as Launch Agent via launchd)
3. **privoxy**: HTTP proxy server (runs as Launch Agent via launchd)
4. **proxy_conf_helper**: Command-line tool for modifying system proxy settings (requires admin privileges)
5. **LaunchHelper**: Helper app for launch-at-login functionality
6. **Plugins**: SIP003 plugins (kcptun, simple-obfs, v2ray-plugin) for protocol obfuscation

### Launch Agent Management
- Launch Agent plists are dynamically generated and placed in `~/Library/LaunchAgents/`
- Service identifiers:
  - `com.qiuyuzhou.shadowsocksX-NG.local.plist` (ss-local)
  - `com.qiuyuzhou.shadowsocksX-NG.http.plist` (privoxy)
  - `com.qiuyuzhou.shadowsocksX-NG.kcptun.plist` (kcptun plugin)
- See `LaunchAgentUtils.swift` for plist generation logic
- Binaries and configs stored in `~/Library/Application Support/ShadowsocksX-NG/`

### Key Components

**AppDelegate.swift**: Main application controller that:
- Initializes status bar menu
- Manages proxy mode switching (Auto/Global/Manual/External PAC)
- Coordinates between GUI and background services
- Handles server profile changes and applies them to Launch Agents

**ServerProfile.swift**: Data model for Shadowsocks server configurations
- Supports both legacy and SIP002 URL formats
- Handles base64 encoding/decoding of server URLs
- Supports SIP003 plugins with options
- Validates server configurations (IP/domain, port, password, method)

**LaunchAgentUtils.swift**: Core service management
- Generates Launch Agent plist files for ss-local, privoxy, and kcptun
- Manages starting/stopping services via `launchctl`
- Handles service installation and configuration updates

**ProxyConfHelper**: Privileged helper tool
- Modifies system network proxy settings
- Requires admin authentication via AuthorizationExecuteWithPrivileges
- Separate binary installed via `install_helper.sh`

**PACUtils.swift**: Proxy Auto-Configuration management
- Generates PAC (Proxy Auto-Configuration) files
- Downloads and updates GFW list
- Supports custom user rules
- Embeds `abp.js` (AdBlock Plus rule parser) for rule matching

### Proxy Modes
1. **Auto Mode**: Uses PAC file with GFW list (routes only blocked sites through proxy)
2. **Global Mode**: Routes all traffic through SOCKS5 proxy
3. **Manual Mode**: No system proxy configuration (user configures apps manually)
4. **External PAC Mode**: Uses custom PAC URL

## Build System

### Dependencies Build Process
Native dependencies (shadowsocks-libev, privoxy, plugins) are built in `deps/` directory:
- Builds universal binaries (x86_64 + arm64) using `lipo`
- Each component built separately for each architecture, then combined
- Final binaries copied to `ShadowsocksX-NG/` subdirectories (ss-local/, privoxy/, etc.)
- Dependencies: libsodium, mbedtls, c-ares, libev, pcre

### Build Commands

**Install CocoaPods dependencies:**
```bash
pod install
```

**Build native dependencies (required before first build):**
```bash
# Requires: automake, autoconf, libtool (install via Homebrew)
brew install automake autoconf libtool
make -C deps
```

**Build app (debug):**
```bash
make debug
# Or with version:
make VERSION=1.0.0 debug
```

**Build app (release):**
```bash
make VERSION=1.0.0 release
```

**Create DMG installer:**
```bash
make debug-dmg    # for debug build
make release-dmg  # for release build
```

**Clean build artifacts:**
```bash
make clean
```

### Build Outputs
- App binary: `build/Debug/ShadowsocksX-NG.app` or `build/Release/ShadowsocksX-NG.app`
- DMG installer: `build/Debug/ShadowsocksX-NG.dmg` or `build/Release/ShadowsocksX-NG.dmg`

### Direct Xcode Build
```bash
# Open workspace (not .xcodeproj)
open ShadowsocksX-NG.xcworkspace

# Command line build
xcodebuild -workspace ShadowsocksX-NG.xcworkspace \
  -scheme ShadowsocksX-NG \
  -configuration Debug \
  SYMROOT=${PWD}/build
```

Note: Must use `.xcworkspace` (not `.xcodeproj`) because project uses CocoaPods.

## Testing

**Run tests:**
```bash
xcodebuild test \
  -workspace ShadowsocksX-NG.xcworkspace \
  -scheme ShadowsocksX-NGTests \
  -configuration Debug
```

Test target: `ShadowsocksX-NGTests`

## Development Workflow

### Branching Strategy
- Main development branch: `develop` (NOT `main` or `master`)
- Feature branches must be based on latest `develop`
- Follow GitFlow branching model
- Create pull requests against `develop` branch

**IMPORTANT for Claude Code:**
- ALWAYS create a new feature branch before implementing any changes
- NEVER commit directly to `develop` or `main`
- Branch naming convention: `feature/<description>`, `fix/<description>`, or `docs/<description>`
- Workflow:
  1. Ensure you're on `develop`: `git checkout develop`
  2. Pull latest changes: `git pull origin develop`
  3. Create new branch: `git checkout -b feature/your-feature-name`
  4. Make changes and commit
  5. Push branch: `git push origin feature/your-feature-name`
  6. Create pull request to merge into `develop`

### CocoaPods Dependencies
- Alamofire (networking)
- GCDWebServer (embedded PAC file server)
- MASShortcut (keyboard shortcuts)
- RxSwift/RxCocoa (reactive programming)
- BRLOptionParser (for proxy_conf_helper CLI parsing)

When updating Podfile, run:
```bash
pod install
pod update  # to update to latest compatible versions
```

### Version Management
Version is set via `agvtool`:
```bash
make VERSION=1.2.3 set-version
# Or directly:
agvtool new-marketing-version 1.2.3
```

## File Locations at Runtime

**Application bundle:**
- Embedded binaries: `ShadowsocksX-NG.app/Contents/Resources/`

**User directories:**
- Application support: `~/Library/Application Support/ShadowsocksX-NG/`
  - ss-local binary and config
  - privoxy binary and config
  - Plugin binaries
- Launch Agents: `~/Library/LaunchAgents/`
  - Service plist files
- User config: `~/.ShadowsocksX-NG/`
  - Custom user rules
- Logs: `~/Library/Logs/`
  - `ss-local.log`, `privoxy.log`, `kcptun.log`

## Debugging Services

**Check if Launch Agents are loaded:**
```bash
launchctl list | grep shadowsocks
```

**View ss-local logs:**
```bash
tail -f ~/Library/Logs/ss-local.log
```

**View privoxy logs:**
```bash
tail -f ~/Library/Logs/privoxy.log
```

**Manually start/stop services:**
```bash
launchctl load ~/Library/LaunchAgents/com.qiuyuzhou.shadowsocksX-NG.local.plist
launchctl unload ~/Library/LaunchAgents/com.qiuyuzhou.shadowsocksX-NG.local.plist
```

**Check current system proxy settings:**
```bash
networksetup -getwebproxy Wi-Fi
networksetup -getsocksfirewallproxy Wi-Fi
```
