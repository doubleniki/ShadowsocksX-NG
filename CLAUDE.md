# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## File Operations

**CRITICAL**: ALWAYS use Serena MCP server tools for ALL file operations instead of standard Read/Edit/Write tools:

- `mcp__serena__read_file` - Instead of Read tool
- `mcp__serena__replace_regex` - Instead of Edit tool (for pattern-based edits)
- `mcp__serena__replace_symbol_body` - For replacing entire code symbols (functions, methods, classes)
- `mcp__serena__create_text_file` - Instead of Write tool
- `mcp__serena__find_symbol` - For searching code symbols
- `mcp__serena__search_for_pattern` - For searching code patterns
- `mcp__serena__get_symbols_overview` - For understanding file structure
- `mcp__serena__list_dir` - For listing directory contents
- `mcp__serena__find_file` - For finding files by pattern

**Why Serena MCP?** It provides semantic code understanding, type-aware operations, and better context management.

## Working with Subagents

**CRITICAL**: Claude Code MUST use specialized subagents for their respective domains:

- **macos-swift-expert**: Use for macOS-specific development tasks, Swift code, AppKit frameworks, Cocoa APIs, Launch Agents, Keychain integration, and macOS system integration
- **typescript-senior-dev**: Use for TypeScript code tasks (not applicable to this Swift project)
- **web-architecture-planner**: Use for web architecture planning (not applicable to this native macOS app)
- **Explore**: Use for codebase exploration, finding files by patterns, searching for keywords, and answering questions about code structure
- **Plan**: Use for planning complex multi-step implementations

**Delegation Guidelines (MANDATORY):**

1. **ALWAYS use the Explore agent** (Task tool with subagent_type=Explore) when:
   - Understanding codebase structure
   - Finding files by patterns
   - Searching for specific code patterns
   - Answering questions about code architecture
   - **DO NOT use Glob/Grep directly for exploration - use Explore agent**

2. **ALWAYS delegate to macos-swift-expert** (Task tool with subagent_type=macos-swift-expert) for:
   - Swift code reviews and improvements
   - macOS-specific feature implementations
   - Launch Agent and system integration tasks
   - Keychain and security-related work
   - AppKit/Cocoa framework usage
   - **DO NOT attempt complex Swift/macOS work directly - use macos-swift-expert**

3. **ALWAYS use the Plan agent** (Task tool with subagent_type=Plan) before implementing complex features that require multiple steps

4. **NEVER attempt** complex Swift refactoring or macOS system integration directly - ALWAYS delegate to the appropriate expert agent

## Documentation

This repository contains extensive documentation in the `docs/` folder:

**Code Quality:**

- [`docs/code-quality/DEVELOPMENT_SETUP.md`](docs/code-quality/DEVELOPMENT_SETUP.md) - Development environment setup
- [`docs/code-quality/CODE_QUALITY_REPORT.md`](docs/code-quality/CODE_QUALITY_REPORT.md) - Code quality analysis and metrics
- [`docs/code-quality/REFACTORING_PLAN.md`](docs/code-quality/REFACTORING_PLAN.md) - Roadmap for refactoring efforts
- [`docs/code-quality/SWIFT_STYLE_GUIDE.md`](docs/code-quality/SWIFT_STYLE_GUIDE.md) - Swift coding conventions
- [`docs/code-quality/TESTING_STRATEGY.md`](docs/code-quality/TESTING_STRATEGY.md) - Testing approach and guidelines

**UI Modernization:**

- [`docs/ui-modernization/README.md`](docs/ui-modernization/README.md) - Overview of UI modernization efforts
- [`docs/ui-modernization/MODERNIZATION_ROADMAP.md`](docs/ui-modernization/MODERNIZATION_ROADMAP.md) - Roadmap for UI updates
- [`docs/ui-modernization/BACKWARD_COMPATIBILITY.md`](docs/ui-modernization/BACKWARD_COMPATIBILITY.md) - Maintaining compatibility with older macOS versions
- [`docs/ui-modernization/MIGRATION_TO_OSVERSION.md`](docs/ui-modernization/MIGRATION_TO_OSVERSION.md) - Migrating to ProcessInfo.operatingSystemVersion
- [`docs/ui-modernization/VERSION_DETECTION_GUIDE.md`](docs/ui-modernization/VERSION_DETECTION_GUIDE.md) - Guide for OS version detection

**Other:**

- [`docs/Other/ADD_NEW_FILES_TO_COMPILATION.md`](docs/Other/ADD_NEW_FILES_TO_COMPILATION.md) - Adding new files to Xcode project

**When to consult documentation:**

- Before implementing features related to UI modernization, check the UI modernization docs
- For code quality questions, refer to the style guide and refactoring plan
- When setting up development environment, follow DEVELOPMENT_SETUP.md
- For questions about adding new files, see ADD_NEW_FILES_TO_COMPILATION.md

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

**CRITICAL RULES for Claude Code:**

- **ALWAYS** create a new feature branch before implementing any changes
- **NEVER** commit directly to `develop` or `main`
- **NEVER** mention AI, Claude, automation, or code generation in commit messages
- **NEVER** add phrases like "Generated with Claude Code", "AI-assisted", or similar
- Write commit messages as if written by a human developer
- Branch naming convention: `feature/<description>`, `fix/<description>`, or `docs/<description>`
- Workflow:
  1. Ensure you're on `develop`: `git checkout develop`
  2. Pull latest changes: `git pull origin develop`
  3. Create new branch: `git checkout -b feature/your-feature-name`
  4. Make changes and commit (follow commit message rules above)
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

## Refactoring Progress

### Phase 1: Foundation & Safety (Completed)

**Code Quality Improvements:**

- ✅ Eliminated all force unwrapping (`!`) in test files
- ✅ Fixed variable shadowing in `PreferencesWindowController` (editingProfile)
- ✅ Centralized error handling through `ErrorHandler` singleton
- ✅ Fixed directory path construction in `Constants.swift` (removed leading slashes)
- ✅ Replaced all non-public error logging calls with public API
- ✅ Renamed functions to comply with Swift naming conventions (e.g., `SyncPac` → `syncPac`)
- ✅ Fixed shorthand operators (e.g., `addCount = addCount + 1` → `addCount += 1`)
- ✅ Refactored `applicationDidFinishLaunching` from 128 lines to 36 lines
  - Extracted methods: `registerDefaultSettings()`, `setupStatusBarItem()`, `setupNotificationObservers()`
- ✅ Enhanced error handling in `LaunchAgentUtils` (plist write operations)
- ✅ Improved localization coverage (PreferencesWindowController, error messages)

**Error Handling Architecture:**

- ✅ Consolidated error definitions into `Errors/AppError.swift`
- ✅ Removed duplicate `AppErrors.swift` file
- ✅ Added new error types: `FileSystemError.copyFailed`, `FileSystemError.moveFailed`
- ✅ Comprehensive error handling in file I/O operations
- ✅ Type-safe error propagation with context information

**Security Improvements:**

- ✅ Fixed Keychain password synchronization in `ServerProfile` duplication
- ✅ Password stored securely in Keychain, not in UserDefaults
- ✅ Proper cleanup of Keychain entries when profiles are deleted
- ✅ Added `KEYCHAIN_FIX.md` documentation

**Project Configuration:**

- ✅ Updated deployment target from 10.12 to 11.0 across all components:
  - Main app: macOS 11.0
  - Podfile: macOS 11.0
  - LaunchHelper: macOS 11.0
  - All pod targets: macOS 11.0 (via post_install hook)
- ✅ Added TOOLCHAIN_DIR fallback for Xcode < 15 compatibility
- ✅ Fixed RxSwift compilation errors related to Date availability
- ✅ Disabled user script sandboxing for CocoaPods (`ENABLE_USER_SCRIPT_SANDBOXING = 'NO'`)

**SwiftLint Configuration:**

- ✅ Added exceptions for components pending future refactoring:
  - `generatePACFile` (function_body_length: 161 lines, cyclomatic_complexity: 24)
- ✅ All code now passes SwiftLint checks with documented exceptions
- ✅ Removed `AppDelegate` type_body_length exception (refactored to pass)

**Documentation:**

- ✅ Restored `DEVELOPMENT_SETUP.md` with proper UTF-8 encoding
- ✅ All corrupted placeholder characters ("???????") replaced with readable English text
- ✅ Added `KEYCHAIN_FIX.md` for Keychain security improvements

**Test Suite:**

- ✅ All test classes renamed to comply with Swift naming conventions
- ✅ Comprehensive guard statements with `XCTFail` for better test diagnostics
- ✅ Updated tests for ServerProfile Keychain integration

**CI/CD Improvements:**

- ✅ Added native dependencies caching in GitHub Actions
- ✅ Automatic placeholder binary creation for CI builds
- ✅ Fixed project file references (removed deleted files)

### Phase 2: UI Modernization (Completed 2025-11-18)

**SF Symbols Migration:**

- ✅ Created `StatusBarIcon.swift` enum for centralized icon management
- ✅ Migrated status bar icons from PNG to SF Symbols:
  - `menu_icon` → `paperplane.fill` (enabled)
  - `menu_icon_disabled` → `paperplane` (disabled)
  - `menu_p_icon` → `network` (Auto/PAC mode)
  - `menu_g_icon` → `globe` (Global mode)
  - `menu_m_icon` → `gearshape.fill` (Manual mode)
  - `menu_e_icon` → `link.circle.fill` (External PAC)
- ✅ Updated `MenuBarManager.swift` to use SF Symbols (reduced ~30 lines of code)
- ✅ Benefits: vector-based, auto dark mode, smaller bundle size (~200KB saved)

**Semantic Colors Migration:**

- ✅ Created `NSColor+Semantic.swift` extension for adaptive colors
- ✅ Implemented automatic dark mode color adaptation:
  - `toastBackground` - HUD window background (adapts gray level)
  - `toastForeground` - HUD text color
  - `qrCodeOverlayText` - QR code labels (brighter green in dark mode)
  - `qrCodeOverlayBackground` - QR code label background
- ✅ Migrated `ToastWindowController.swift` to semantic colors
- ✅ Migrated `SWBQRCodeWindowController.m` to semantic colors
- ✅ Added `@objc` attributes for Objective-C/Swift interoperability
- ✅ Removed 3 hardcoded RGB color values

**Bug Fixes:**

- ✅ Fixed XIB outlet connection error in `UserRulesController.xib`
- ✅ Fixed `toCGColor()` implementation with proper RGB color space conversion
- ✅ Added Swift bridging header to Objective-C files
- ✅ Fixed server preferences auto-selection issue
- ✅ Patched MASShortcut deprecated API (`NSKeyedUnarchiveFromData` → `NSSecureUnarchiveFromData`)

**Repository Updates:**

- ✅ Updated all GitHub URLs from `shadowsocks/ShadowsocksX-NG` to `doubleniki/ShadowsocksX-NG`
- ✅ Help menu wiki link
- ✅ Plugin help wiki link
- ✅ Check for updates releases link

**Documentation:**

- ✅ Documented console warnings in `KNOWN_ISSUES.md` (task port, layout recursion)
- ✅ Created comprehensive progress report in `UI_MODERNIZATION_PROGRESS.md`
- ✅ Updated `MODERNIZATION_ROADMAP.md` with Phase 2 status

**Metrics:**

- Files created: 2 (StatusBarIcon.swift, NSColor+Semantic.swift)
- Files modified: 9
- Lines added: ~262
- Lines removed: ~31
- Net change: +241 lines
- Code quality: Improved (type safety, dark mode support, maintainability)

### Known Limitations

**Binary Dependencies:**

- Native dependencies (ss-local, privoxy, v2ray-plugin, etc.) must be built via `make -C deps`
- CI uses cached binaries or creates placeholders for compilation testing
- Placeholder binaries are sufficient for CI but not for runtime functionality

**Future Refactoring Planned:**

- generatePACFile function needs to be decomposed into helper functions
- Constants.swift visibility issues in some contexts (currently using hardcoded paths)
- Other UI icons migration (terminal-logo, virtual-server-icon, http icons)
- Component modernization (table views, buttons, form inputs)
- Vibrancy effects (windows and dialogs)
- These are tracked in SwiftLint exclusions with TODO comments

### System Requirements

- macOS 11.0 or later (updated from 10.12)
- Xcode 14.0 or later (compatible with Xcode 15+)
- CocoaPods 1.10 or later

For detailed development setup instructions, see `docs/code-quality/DEVELOPMENT_SETUP.md`.
