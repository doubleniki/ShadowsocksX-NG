# UI Modernization Roadmap

## ShadowsocksX-NG → macOS Sequoia Design

**Document Version:** 2.0
**Last Updated:** 2025-11-07
**Current Minimum:** macOS 11.0 Big Sur
**Target macOS:** Sequoia (15.x) and later
**Current Architecture:** AppKit with XIB files + OSVersion utility
**Target Architecture:** Hybrid AppKit + SwiftUI

---

## Executive Summary

This roadmap outlines a **phased approach** to modernizing ShadowsocksX-NG's user interface to align with macOS Sequoia design principles. The strategy prioritizes **incremental improvements** with minimal disruption to existing functionality, ensuring stability throughout the migration.

### Goals

- ✅ Adopt modern macOS design language (SF Symbols, semantic colors, vibrancy)
- ✅ Improve accessibility and user experience
- ✅ Prepare codebase for future SwiftUI migration
- ✅ Maintain backward compatibility where feasible
- ✅ Enhance platform integration (Shortcuts, Widgets)

### Success Metrics

- Visual consistency with native macOS apps
- Zero regression in core functionality
- Improved VoiceOver support (100% labeled controls)
- Reduced PNG asset size (SF Symbols migration)
- User satisfaction feedback (subjective but important)

---

## Current State Analysis

### Technology Stack

| Component    | Current                   | Status                            |
| ------------ | ------------------------- | --------------------------------- |
| UI Framework | AppKit (XIB)              | ⚠️ Legacy but functional          |
| Icons        | PNG files                 | ❌ Non-scalable, manual dark mode |
| Colors       | Mix of system & hardcoded | ⚠️ Partial dark mode support      |
| Typography   | Hardcoded fonts           | ⚠️ No Dynamic Type                |
| Reactive     | RxSwift                   | ⚠️ Non-native framework           |
| Localization | NSLocalizedString         | ✅ Functional                     |

### Key Pain Points

1. **Status bar icons** don't scale properly on different display densities
2. **Hardcoded colors** in toast/QR windows break with custom accent colors
3. **XIB files** are hard to maintain and don't support modern layouts
4. **No accessibility labels** for many controls
5. **RxSwift dependency** adds complexity vs native Combine

---

## Backward Compatibility Overview

**Current minimum:** macOS 11.0 (Big Sur) - enforced in `MACOSX_DEPLOYMENT_TARGET = 11.0`

### Current State (v2.0+)

The project has **already migrated to macOS 11.0+** as the baseline:

- ✅ SF Symbols support (native, no fallbacks needed)
- ✅ Modern AppKit features (fullWidth table style, etc.)
- ✅ SwiftUI 2.0 available
- ✅ Combine framework available
- ✅ OSVersion utility for feature detection

### Future Migration Strategy

This roadmap focuses on **further modernization** while maintaining Big Sur compatibility:

| Phase   | Minimum macOS    | What's Available                  | Status         | Timeline |
| ------- | ---------------- | --------------------------------- | -------------- | -------- |
| **1**   | **11.0** Big Sur | SF Symbols, SwiftUI 2.0, Combine  | ✅ Complete    | Current  |
| **2**   | **11.0** Big Sur | Component modernization           | 🚧 In Progress | Q1 2025  |
| **3**   | **12.0+**        | Widgets, SF Symbols 3+            | 📋 Planned     | Q2 2025  |
| **4**   | **13.0+**        | App Intents, Menu Bar Extras API  | 📋 Planned     | Q3 2025  |
| **5**   | **14.0+**        | Advanced widgets, latest features | 📋 Planned     | Q4 2025  |

### Key Principles

1. **Progressive Enhancement (11.0+ Baseline)**

   - All modern features (SF Symbols, semantic colors, SwiftUI 2.0) available by default
   - Use `@available` checks only for 12.0+ features
   - OSVersion utility provides clean feature detection
   - No need for PNG fallbacks (SF Symbols native on 11.0+)

2. **Communicate Early** (Phase 3+ Version Bumps)

   - Announce minimum version changes 2-3 months before
   - Tag last compatible version for legacy support
   - Provide clear migration guide for users

3. **Feature Detection for Advanced Features**

   ```swift
   // For features beyond 11.0
   if OSVersion.isMontereyOrLater {
       // Use SF Symbols 3+ features
       image = NSImage(systemSymbolName: "paperplane.circle.fill")
   } else {
       // Use SF Symbols 1 (available on Big Sur)
       image = NSImage(systemSymbolName: "paperplane.fill")
   }
   ```

4. **Graceful Enhancement**
   - Big Sur (11.0): Full functionality with modern design
   - Monterey+ (12.0): Enhanced with newer symbol variants, widgets
   - Ventura+ (13.0): App Intents, Shortcuts integration
   - Optional features (Widgets, Shortcuts) degrade gracefully

### Compatibility Matrix Quick Reference

| Feature            | 11.0 Big Sur | 12.0 Monterey | 13.0 Ventura | 14.0+ Sonoma+ |
| ------------------ | ------------ | ------------- | ------------ | ------------- |
| SF Symbols (v1-2)  | ✅           | ✅            | ✅           | ✅            |
| SF Symbols 3+      | ❌           | ✅            | ✅           | ✅            |
| SF Symbols 4+      | ❌           | ❌            | ❌           | ✅            |
| Dark Mode          | ✅           | ✅            | ✅           | ✅            |
| SwiftUI 2.0        | ✅           | ✅            | ✅           | ✅            |
| SwiftUI 3.0+       | ❌           | ✅            | ✅           | ✅            |
| Combine            | ✅           | ✅            | ✅           | ✅            |
| Modern Table Style | ✅           | ✅            | ✅           | ✅            |
| App Intents        | ❌           | ❌            | ✅           | ✅            |
| Widgets            | ❌           | ❌            | ❌           | ✅            |
| Menu Bar Extras    | ❌           | ❌            | ✅           | ✅            |

**See "Important Considerations → Backward Compatibility Strategy" for detailed implementation patterns and testing strategy.**

---

## Phase 1: Foundation & Tooling (Completed ✅)

**Duration:** Completed
**Status:** ✅ Infrastructure in place
**Minimum macOS:** 11.0 (Big Sur)
**Key Achievement:** OSVersion utility implemented

### Objectives

Establish foundation for modern UI development with proper version detection.

### Completed Work

✅ **OSVersion utility created:**

- Centralized version detection system
- Clean API for checking macOS versions (isMontereyOrLater, isVenturaOrLater, etc.)
- Feature availability checks (supportsSFSymbols3, supportsWidgets, etc.)
- Helper methods for SF Symbols and UI components
- Documentation in `docs/ui-modernization/VERSION_DETECTION_GUIDE.md`

✅ **Modern baseline established:**

- Project migrated to macOS 11.0 minimum
- SF Symbols support available natively
- SwiftUI 2.0 and Combine framework available
- Modern AppKit features accessible

### Next Steps (Phase 2 Preparation)

#### 2.1. SF Symbols Migration (To Do)

**Files to modify:**

- `ShadowsocksX-NG/AppDelegate.swift`
- `ShadowsocksX-NG/images/` (deprecate PNG icons after migration)

**Implementation (Big Sur baseline, no fallbacks needed):**

```swift
// Current (using PNG)
let icon = NSImage(named: "menu_icon")

// Target (using SF Symbols - native on 11.0+)
let icon = NSImage(systemSymbolName: "paperplane.fill",
                       accessibilityDescription: "Shadowsocks")!

// For Monterey+ enhanced symbols (optional)
let icon = OSVersion.symbol(
    primary: "paperplane.circle.fill",  // SF Symbols 3 (12.0+)
    fallback: "paperplane.fill"         // SF Symbols 1 (11.0+)
)
```

**Icon Mapping:**

| Current PNG | SF Symbol | Usage |
|-------------|-----------|-------|
| `menu_icon.png` | `paperplane.fill` | Default status bar |
| `menu_icon_disabled.png` | `paperplane` (unfilled) | Disabled state |
| `menu_p_icon.png` | `network` | PAC/Auto mode |
| `menu_g_icon.png` | `globe` | Global mode |
| `menu_m_icon.png` | `gearshape.fill` | Manual mode |
| `menu_e_icon.png` | `link.circle.fill` | External PAC |
| `terminal-logo.png` | `terminal.fill` | HTTP export |
| `virtual-server-icon-3.png` | `server.rack` | Server icon |

**Benefits:**

- 🎯 Automatic rendering for all resolutions
- 🎨 Automatic dark mode adaptation
- 📦 Reduced app bundle size (~200KB savings)
- ⚡ Better performance (vector vs raster)

#### 2.2. Semantic Colors Migration (To Do)

**Files to modify:**

- `ShadowsocksX-NG/ToastWindowController.swift` (line 47)
- `ShadowsocksX-NG/SWBQRCodeWindowController.m` (lines 31-32)
- `ShadowsocksX-NG/UserRulesController.swift` (line 88)

**Create Color Extension:**

```swift
// ShadowsocksX-NG/Extensions/NSColor+Semantic.swift (new file)
import Cocoa

extension NSColor {
    // Background colors (all available on 11.0+)
    static var appBackground: NSColor { .controlBackgroundColor }
    static var appSecondaryBackground: NSColor { .textBackgroundColor }
    static var appToastBackground: NSColor {
        .controlBackgroundColor.withAlphaComponent(0.95)
    }

    // Text colors
    static var appPrimaryText: NSColor { .labelColor }
    static var appSecondaryText: NSColor { .secondaryLabelColor }
    static var appTertiaryText: NSColor { .tertiaryLabelColor }

    // Semantic colors
    static var appAccent: NSColor { .controlAccentColor }
    static var appSuccess: NSColor { .systemGreen }
    static var appError: NSColor { .systemRed }
    static var appWarning: NSColor { .systemOrange }
    static var appInfo: NSColor { .systemBlue }
}
```

**Migration Examples:**

```swift
// Toast background (ToastWindowController.swift:47)
// Before:
backgroundColor = CGColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 0.75)

// After:
backgroundColor = NSColor.appToastBackground.cgColor
```

```objc
// QR code text (SWBQRCodeWindowController.m:31)
// Before:
NSColor *textColor = [NSColor colorWithRed:28/255.0 green:155/255.0 blue:71/255.0 alpha:1];

// After:
NSColor *textColor = [NSColor systemGreenColor];
```

#### 1.3. Visual Effect Views (Vibrancy)

**Files to modify:**

- `ShadowsocksX-NG/ToastWindowController.swift`
- `ShadowsocksX-NG/Base.lproj/PreferencesWinController.xib`
- `ShadowsocksX-NG/Base.lproj/ShareServerProfilesWindowController.xib`

**Implementation:**

```swift
// Toast window with HUD material
let visualEffectView = NSVisualEffectView()
visualEffectView.material = .hudWindow
visualEffectView.blendingMode = .behindWindow
visualEffectView.state = .active
window?.contentView = visualEffectView
```

**Materials to use:**

- **Toast notifications:** `.hudWindow`
- **Preferences sidebar:** `.sidebar`
- **Content areas:** `.underWindowBackground`
- **Dialogs:** `.sheet` or `.popover`

#### 1.4. SF Pro Typography

**Files to modify:**

- `ShadowsocksX-NG/SWBQRCodeWindowController.m` (line 32)
- All XIB files (bulk update via Interface Builder)

**Typography Scale:**

```swift
extension NSFont {
    static var appLargeTitle: NSFont { .systemFont(ofSize: 26, weight: .bold) }
    static var appTitle1: NSFont { .systemFont(ofSize: 22, weight: .regular) }
    static var appTitle2: NSFont { .systemFont(ofSize: 17, weight: .regular) }
    static var appTitle3: NSFont { .systemFont(ofSize: 15, weight: .semibold) }
    static var appHeadline: NSFont { .systemFont(ofSize: 13, weight: .semibold) }
    static var appBody: NSFont { .systemFont(ofSize: 13, weight: .regular) }
    static var appCallout: NSFont { .systemFont(ofSize: 12, weight: .regular) }
    static var appSubheadline: NSFont { .systemFont(ofSize: 11, weight: .regular) }
    static var appFootnote: NSFont { .systemFont(ofSize: 10, weight: .regular) }
    static var appCaption1: NSFont { .systemFont(ofSize: 10, weight: .regular) }
    static var appCaption2: NSFont { .systemFont(ofSize: 10, weight: .regular) }
}
```

### Deliverables

- [ ] SF Symbols integrated for all status bar icons
- [ ] Color extension created and applied
- [ ] Vibrancy added to toast and dialog windows
- [ ] Typography scale defined and applied to QR window
- [ ] Documentation updated (screenshot comparisons)

### Testing Checklist

- [ ] Test on macOS 10.15, 11.x, 12.x, 13.x, 14.x, 15.x
- [ ] Verify light/dark mode switching
- [ ] Test all accent color variations (System Preferences → General)
- [ ] Check icon rendering on Retina and non-Retina displays
- [ ] Verify menu bar icon in different menu bar densities

---

## Phase 2: Visual & Component Modernization (In Progress 🚧)

**Duration:** 3-4 weeks
**Status:** 🚧 ~75% Complete
**Risk Level:** 🟢 Low
**Dependencies:** Phase 1 complete ✅
**Minimum macOS:** 11.0 (Big Sur) - No version bump
**Target Completion:** Q1 2025
**Last Updated:** 2025-11-18

### Objectives

Migrate visual assets to SF Symbols and update UI controls to modern macOS standards.

### Current Status (2025-11-18)

**Phase 1 Complete:**
- ✅ OSVersion utility fully implemented and tested (303 lines + 297 test lines)
- ✅ OSVersion integrated in AppDelegate for version validation
- ✅ Comprehensive test suite with 100% coverage of OSVersion features

**Phase 2 Progress (Session 2025-11-18):**

**✅ Completed:**
1. **SF Symbols Migration:**
   - ✅ Status bar icons (paperplane, network, globe, gearshape, link.circle)
   - ✅ Password visibility toggle icons (eye.fill, eye.slash.fill)
   - ✅ Created StatusBarIcon.swift enum for centralized icon management
   - ✅ Migrated MenuBarManager.swift from PNG to SF Symbols
   - ✅ Updated PreferencesWindowController for password visibility icons

2. **Semantic Colors Migration:**
   - ✅ Created NSColor+Semantic.swift extension
   - ✅ Migrated ToastWindowController background color
   - ✅ Migrated SWBQRCodeWindowController overlay colors
   - ✅ Automatic dark mode adaptation for all colors
   - ✅ Added @objc attributes for Objective-C interoperability

3. **Vibrancy Effects:**
   - ✅ Added NSVisualEffectView to toast notifications
   - ✅ HUD material for authentic macOS appearance
   - ✅ Automatic light/dark mode blur adaptation

4. **Bug Fixes & Improvements:**
   - ✅ Fixed 3 compilation errors (@objc, toCGColor, XIB outlet)
   - ✅ Updated all GitHub URLs to doubleniki fork
   - ✅ Fixed server preferences auto-selection issue
   - ✅ Patched MASShortcut deprecated API warnings
   - ✅ Documented all console warnings in KNOWN_ISSUES.md

**Metrics:**
- Files created: 2 (StatusBarIcon.swift, NSColor+Semantic.swift)
- Files modified: 11
- Lines added: ~300
- Lines removed: ~40
- Code quality: Significantly improved
- Bundle size reduction: ~200KB (PNG assets no longer needed)

**📋 Remaining Work:**
- Table view modernization (requires Xcode on macOS)
- Button & control styles standardization
- Form inputs with placeholders and validation
- Toolbar modernization (requires Xcode/Interface Builder)
- XIB file updates (6 files with Xcode 10.x-11.x toolsVersion)

**Note:** Remaining tasks require macOS with Xcode for XIB/Interface Builder modifications. SF Symbols and semantic colors migrations are complete and can be used immediately.

### Tasks

#### 2.1. Table View Modernization

**Files to modify:**

- `ShadowsocksX-NG/PreferencesWindowController.swift`
- `ShadowsocksX-NG/ShareServerProfilesWindowController.swift`
- `ShadowsocksX-NG/ProxyInterfacesViewCtrl.swift`

**Updates (native on 11.0+):**

```swift
// Server list table (PreferencesWindowController.swift)
// Modern fullWidth style is available on Big Sur
tableView.style = .fullWidth
tableView.floatsGroupRows = false
tableView.rowSizeStyle = .default
tableView.intercellSpacing = NSSize(width: 0, height: 2)
tableView.selectionHighlightStyle = .regular
tableView.usesAutomaticRowHeights = true

// Use OSVersion for Monterey+ enhancements (optional)
OSVersion.onMontereyOrLater {
    // Additional Monterey-specific refinements if needed
}
```

**Cell Improvements:**

- Increase row height for better touch target (min 32pt)
- Add subtle separator lines
- Use SF Symbols for status indicators
- Add hover effects for interactive elements

#### 2.2. Button & Control Styles

**Files to modify:**

- All XIB files (via Interface Builder)
- Programmatically created buttons in Swift files

**Button Style Guide:**

```swift
// Primary actions
button.bezelStyle = .rounded
button.controlSize = .large
button.contentTintColor = .controlAccentColor

// Secondary actions
button.bezelStyle = .roundRect
button.controlSize = .regular

// Toolbar buttons
button.bezelStyle = .texturedRounded
button.isBordered = false

// Destructive actions
button.contentTintColor = .systemRed
```

**Controls to update:**

- Add/Remove server buttons (preferences)
- Import/Export buttons
- OK/Cancel buttons in dialogs
- Quick add button (user rules)

#### 2.3. Form Inputs

**Files to modify:**

- `ShadowsocksX-NG/Base.lproj/PreferencesWindowController.xib`
- `ShadowsocksX-NG/Base.lproj/ImportWindowController.xib`

**Improvements:**

```swift
// Text fields with placeholders
serverAddressField.placeholderString = "example.com or 192.168.1.1"
portField.placeholderString = "8388"
passwordField.placeholderString = "Enter password"

// Combo box styling
methodComboBox.completes = true
methodComboBox.usesDataSource = true

// Validation feedback (inline)
func showFieldError(_ field: NSTextField, message: String) {
    field.layer?.borderWidth = 1.0
    field.layer?.borderColor = NSColor.systemRed.cgColor
    field.layer?.cornerRadius = 4.0

    // Tooltip for error message
    field.toolTip = message
}
```

**Add form sections:**

- Group related fields with `NSBox` or visual separators
- Add helpful descriptions below fields (secondary text)
- Implement live validation with inline error messages

#### 2.4. Toolbar Modernization

**Files to modify:**

- `ShadowsocksX-NG/PreferencesWinController.swift`
- `ShadowsocksX-NG/Base.lproj/PreferencesWinController.xib`

**Modern Toolbar:**

```swift
if #available(macOS 11.0, *) {
    toolbar.displayMode = .iconOnly

    // Centered items for tab-like appearance
    let centeredIdentifiers = toolbarItems.map { $0.itemIdentifier }
    if let toolbar = window?.toolbar as? NSToolbar {
        toolbar.centeredItemIdentifiers = centeredIdentifiers
    }
}

// Update toolbar items with SF Symbols
let item = NSToolbarItem(itemIdentifier: itemIdentifier)
if #available(macOS 11.0, *) {
    item.image = NSImage(systemSymbolName: "server.rack", accessibilityDescription: "Servers")
} else {
    item.image = NSImage(named: "virtual-server-icon-3")
}
item.label = "Servers"
```

**Toolbar items to update:**

- Servers → `server.rack`
- HTTP → `network`
- Advanced → `gearshape.2`
- About → `info.circle`

### Deliverables

- [ ] All table views updated to modern style
- [ ] Button and control styles standardized
- [ ] Form inputs with placeholders and validation
- [ ] Toolbar redesigned with centered items and SF Symbols
- [ ] Style guide document created

### Testing Checklist

- [ ] Table view sorting and filtering work correctly
- [ ] Drag-and-drop reordering still functions
- [ ] Button click states (normal/hover/pressed) look correct
- [ ] Form validation triggers appropriately
- [ ] Toolbar items respond to clicks
- [ ] Keyboard shortcuts still work (⌘S for servers, etc.)

---

## Phase 3: Advanced Features & Monterey Integration

**Duration:** 4-6 weeks
**Status:** 📋 Planned
**Risk Level:** 🟡 Medium
**Dependencies:** Phase 2 complete
**Minimum macOS:** 12.0 (Monterey) - ⚠️ Optional version bump
**Target Completion:** Q2 2025

### Objectives

Leverage Monterey+ features (SF Symbols 3, improved SwiftUI) while maintaining Big Sur fallbacks.

### Compatibility Note

Phase 3 **optionally raises minimum to macOS 12.0 (Monterey)**:

- **Why:** SF Symbols 3 with richer icon set, mature SwiftUI 3.0
- **Impact:** Drops Big Sur support (~5-10% of users if implemented)
- **Alternative:** Keep 11.0 minimum, use OSVersion checks for Monterey features
- **Decision:** To be made based on Phase 2 feedback and usage metrics

**Recommended approach:**

- Keep 11.0 as minimum
- Use OSVersion checks for Monterey+ enhancements
- Delay minimum version bump to Phase 4 if needed

### Strategy: Hybrid Approach

**Keep in AppKit:**

- ✅ Status bar menu (no SwiftUI equivalent for `NSStatusItem`)
- ✅ Server table with drag-and-drop (better in `NSTableView`)
- ✅ QR code scanning (system permissions easier in AppKit)
- ✅ Proxy configuration helper (system integration)

**Migrate to SwiftUI:**

- ✅ Import window (simple form)
- ✅ Toast notifications (SwiftUI overlays)
- ✅ About window (static content)
- ✅ User rules editor (text + simple list)

### Tasks

#### 3.1. SwiftUI Infrastructure

**New files to create:**

```
ShadowsocksX-NG/SwiftUI/
├── Views/
│   ├── ImportView.swift
│   ├── ToastView.swift
│   ├── AboutView.swift
│   └── UserRulesView.swift
├── ViewModels/
│   ├── ImportViewModel.swift
│   └── UserRulesViewModel.swift
├── Models/
│   └── AppState.swift (Combine-based)
└── Utilities/
    └── NSHostingControllerExtensions.swift
```

**Create hosting bridge:**

```swift
// NSHostingControllerExtensions.swift
import SwiftUI

extension NSHostingController {
    convenience init(rootView: Content, title: String) {
        self.init(rootView: rootView)
        self.title = title
    }

    func asWindow(size: NSSize = NSSize(width: 400, height: 300)) -> NSWindow {
        let window = NSWindow(contentViewController: self)
        window.title = self.title ?? ""
        window.setContentSize(size)
        window.styleMask = [.titled, .closable]
        window.center()
        return window
    }
}
```

#### 3.2. Import Window (SwiftUI)

**Replace:** `ShadowsocksX-NG/ImportWindowController.swift`

**New implementation:**

```swift
// SwiftUI/Views/ImportView.swift
import SwiftUI

struct ImportView: View {
    @StateObject private var viewModel = ImportViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Import Server URL")
                .font(.title2)

            TextField("ss://...", text: $viewModel.urlString)
                .textFieldStyle(.roundedBorder)
                .onAppear { viewModel.loadFromClipboard() }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("Import") { viewModel.importServer() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!viewModel.isValid)
            }
        }
        .padding()
        .frame(width: 400)
    }
}
```

#### 3.3. Toast Notifications (SwiftUI)

**Replace:** `ShadowsocksX-NG/ToastWindowController.swift`

**New implementation:**

```swift
// SwiftUI/Views/ToastView.swift
import SwiftUI

struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool

    var body: some View {
        Text(message)
            .padding()
            .background(.thinMaterial)
            .cornerRadius(18)
            .shadow(radius: 10)
            .transition(.opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation { isShowing = false }
                }
            }
    }
}

// Usage from AppKit
func showToast(_ message: String) {
    let hostingView = NSHostingView(rootView: ToastView(message: message, isShowing: .constant(true)))
    // Position and display logic
}
```

#### 3.4. Combine Migration (from RxSwift)

**Strategy:** Gradual replacement, starting with new code.

**Create observable state:**

```swift
// SwiftUI/Models/AppState.swift
import Combine
import Foundation

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isRunning: Bool = false
    @Published var currentMode: ProxyMode = .off
    @Published var servers: [ServerProfile] = []
    @Published var currentServerId: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Load from UserDefaults
        loadState()

        // Observe changes
        $isRunning.sink { isRunning in
            UserDefaults.standard.set(isRunning, forKey: "ShadowsocksOn")
        }.store(in: &cancellables)
    }

    func toggleRunning() {
        isRunning.toggle()
        // LaunchAgent logic here
    }
}
```

**Bridge with AppKit:**

```swift
// AppDelegate.swift
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Subscribe to state changes
        AppState.shared.$isRunning.sink { [weak self] isRunning in
            self?.updateMenuIcon(running: isRunning)
        }.store(in: &cancellables)
    }
}
```

### Deliverables

- [ ] SwiftUI infrastructure set up
- [ ] Import window migrated to SwiftUI
- [ ] Toast notifications using SwiftUI
- [ ] AppState with Combine created
- [ ] Bridge between AppKit and SwiftUI functional
- [ ] Documentation for hybrid architecture

### Testing Checklist

- [ ] SwiftUI windows open and close properly
- [ ] State synchronization between AppKit and SwiftUI works
- [ ] No memory leaks in hosting controllers
- [ ] Dark mode switching works in SwiftUI views
- [ ] Localization works in SwiftUI strings
- [ ] Keyboard shortcuts work in SwiftUI views

---

## Phase 4: Platform Integration & Ventura Features

**Duration:** 6-8 weeks
**Status:** 📋 Planned
**Risk Level:** 🟡 Medium
**Dependencies:** Phase 3 complete
**Minimum macOS:** 13.0 (Ventura) - ⚠️ Optional version bump
**Target Completion:** Q3 2025

### Objectives

Add App Intents, Shortcuts, and Menu Bar Extras (Ventura+ features).

### Compatibility Note

Phase 4 **optionally raises minimum to macOS 13.0 (Ventura)**:

- **Why:** App Intents, Shortcuts integration, Menu Bar Extras API
- **Impact:** Drops 11.0-12.x support (~10-15% of users if implemented)
- **Alternative:** Keep 11.0/12.0 minimum, make these features optional
- **Decision:** Based on Phase 3 metrics and feature demand

**Recommended approach:**

- Keep 11.0 as minimum
- App Intents/Shortcuts available only on 13.0+ (graceful degradation)
- Core functionality works identically on all versions

### Tasks

#### 4.1. Animations & Transitions

**Files to modify:**

- `ShadowsocksX-NG/AppDelegate.swift` (menu transitions)
- `ShadowsocksX-NG/PreferencesWindowController.swift` (table animations)
- All SwiftUI views (native animations)

**Animation Guidelines:**

```swift
// Spring animations for natural feel
NSAnimationContext.runAnimationGroup { context in
    context.duration = 0.3
    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    context.allowsImplicitAnimation = true

    // Animate changes
    view.animator().alphaValue = 1.0
    view.animator().frame = newFrame
}

// Table row animations
tableView.beginUpdates()
tableView.insertRows(at: indexSet, withAnimation: .slideDown)
tableView.endUpdates()
```

**Animations to add:**

- ✅ Server list reordering (smooth position changes)
- ✅ Menu item state changes (fade transition)
- ✅ Toast appear/disappear (scale + fade)
- ✅ Form validation errors (shake + color change)
- ✅ Status icon switching (cross-fade)

#### 4.2. Settings Window Redesign

**Goal:** Modern sidebar-based settings (like System Settings)

**New structure:**

```
┌─────────────────────────────────┐
│ ┌─────────┬─────────────────────┤
│ │ Servers │ Server Details      │
│ │ HTTP    │                     │
│ │ Advanced│ [Content Area]      │
│ │ About   │                     │
│ └─────────┴─────────────────────┤
└─────────────────────────────────┘
```

**Implementation:**

- Replace `NSToolbar` with `NSSplitView`
- Sidebar width: 180pt fixed
- Content area: flexible width
- Use `NSOutlineView` for sidebar (future-proof for sub-sections)

**Files to create/modify:**

- `ShadowsocksX-NG/ModernPreferencesWindowController.swift` (new)
- Phase out `PreferencesWinController.swift` gradually

#### 4.3. Context Menus

**Files to modify:**

- `ShadowsocksX-NG/PreferencesWindowController.swift` (table context menu)
- `ShadowsocksX-NG/AppDelegate.swift` (status bar menu items)

**Modernization:**

```swift
let menu = NSMenu()

// Add items with SF Symbols
let editItem = NSMenuItem(title: "Edit Server", action: #selector(editServer), keyEquivalent: "")
if #available(macOS 11.0, *) {
    editItem.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: nil)
}
menu.addItem(editItem)

// Destructive actions with red color
let deleteItem = NSMenuItem(title: "Delete Server", action: #selector(deleteServer), keyEquivalent: "")
if #available(macOS 11.0, *) {
    deleteItem.image = NSImage(systemSymbolName: "trash", accessibilityDescription: nil)
}
deleteItem.attributedTitle = NSAttributedString(
    string: "Delete Server",
    attributes: [.foregroundColor: NSColor.systemRed]
)
menu.addItem(deleteItem)
```

#### 4.4. Empty States & Onboarding

**Files to modify:**

- `ShadowsocksX-NG/PreferencesWindowController.swift`

**Empty state when no servers:**

```swift
struct EmptyServerListView: View {
    var onAddServer: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "server.rack")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Servers")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add your first Shadowsocks server to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onAddServer) {
                Label("Add Server", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
```

**First launch experience:**

- Welcome window with quick setup
- Import options (URL, QR code, config file)
- Permission requests explained (network, screen recording)

### Deliverables

- [ ] Animation system implemented
- [ ] Settings window redesigned with sidebar
- [ ] Context menus modernized
- [ ] Empty states for all list views
- [ ] First launch onboarding flow
- [ ] Micro-interactions polished (hover states, etc.)

### Testing Checklist

- [ ] Animations are smooth at 60fps
- [ ] Settings sidebar resizes properly
- [ ] Context menus show correct items
- [ ] Empty states display when appropriate
- [ ] First launch flow completes successfully
- [ ] No animation glitches during mode switching

---

## Phase 5: Advanced Integration & Sonoma+ Features

**Duration:** 6-8 weeks
**Status:** 📋 Planned
**Risk Level:** 🟢 Low (optional features only)
**Dependencies:** Phase 4 complete
**Minimum macOS:** 11.0 (Big Sur) - No version bump required
**Target Completion:** Q4 2025

### Objectives

Add Widgets (14.0+) and other advanced integration features as optional enhancements.

### Compatibility Note

Phase 5 **maintains 11.0 minimum** with optional Sonoma+ features:

- **Core app:** Works fully on Big Sur 11.0+
- **Enhanced features:** Widgets available on Sonoma 14.0+
- **Graceful degradation:** Features unavailable on older versions simply don't appear
- **No functionality loss:** All essential features work on 11.0+

**Features by version:**

- **11.0+ (baseline):** Full functionality, modern UI
- **12.0+ (enhanced):** SF Symbols 3, better SwiftUI
- **13.0+ (optional):** App Intents, Shortcuts
- **14.0+ (optional):** Widgets, advanced notifications

**Implementation approach:**

```swift
// Widgets available only on 14.0+ (optional feature)
#if canImport(WidgetKit)
    if OSVersion.isSonomaOrLater {
        // Build and register widgets
    }
#endif

// Shortcuts available on 13.0+ (optional feature)
OSVersion.onVenturaOrLater {
    AppShortcuts.updateShortcuts()
}
```

**Long-term strategy:**

- Keep 11.0 minimum through v2.x (2+ years minimum)
- Monitor usage metrics for future version bumps
- Consider 13.0 minimum for v3.0 (2026+) when 11-12 usage < 5%

### Tasks

#### 5.1. App Intents & Shortcuts

**Target:** macOS 13+ (Shortcuts app)

**Create App Intents:**

```swift
// ShadowsocksX-NG/AppIntents/ToggleShadowsocksIntent.swift
import AppIntents

@available(macOS 13.0, *)
struct ToggleShadowsocksIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Shadowsocks"
    static var description = IntentDescription("Turn Shadowsocks on or off")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Enabled")
    var enabled: Bool?

    func perform() async throws -> some IntentResult {
        if let enabled = enabled {
            await AppState.shared.setRunning(enabled)
        } else {
            await AppState.shared.toggleRunning()
        }

        return .result()
    }
}
```

**Shortcuts to implement:**

1. Toggle Shadowsocks (on/off/toggle)
2. Switch to specific server
3. Change proxy mode (Auto/Global/Manual)
4. Enable/disable HTTP proxy

**Configuration:**

- Add `NSSupportsAppIntents` to Info.plist
- Implement `AppShortcutsProvider` for suggested shortcuts
- Add app icon for Shortcuts app gallery

#### 5.2. Menu Bar Extras (macOS 13+)

**Modern status bar implementation:**

```swift
// ShadowsocksX-NG/MenuBarExtra.swift (SwiftUI alternative)
import SwiftUI

@available(macOS 13.0, *)
@main
struct ShadowsocksApp: App {
    var body: some Scene {
        MenuBarExtra("Shadowsocks", systemImage: "paperplane.fill") {
            MenuBarContentView()
        }
        .menuBarExtraStyle(.menu)
    }
}

struct MenuBarContentView: View {
    @ObservedObject var appState = AppState.shared

    var body: some View {
        Button(action: { appState.toggleRunning() }) {
            Label(
                appState.isRunning ? "Turn Off" : "Turn On",
                systemImage: appState.isRunning ? "stop.fill" : "play.fill"
            )
        }
        .keyboardShortcut("s", modifiers: [.command])

        Divider()

        // ... rest of menu
    }
}
```

**Note:** This requires significant refactoring. Consider as Phase 5B or later.

#### 5.3. Widgets (macOS 14+)

**Widget ideas:**

1. **Status Widget** - Shows current connection status
2. **Quick Toggle Widget** - Large button to enable/disable
3. **Server List Widget** - Quick switch between recent servers

**Implementation:**

```swift
// ShadowsocksWidgetExtension/ShadowsocksWidget.swift
import WidgetKit
import SwiftUI

struct ShadowsocksStatusWidget: Widget {
    let kind: String = "ShadowsocksStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Shadowsocks Status")
        .description("View your current connection status")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StatusWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Image(systemName: entry.isRunning ? "paperplane.fill" : "paperplane")
                .font(.system(size: 40))
                .foregroundColor(entry.isRunning ? .green : .secondary)

            Text(entry.isRunning ? "Connected" : "Disconnected")
                .font(.headline)

            if entry.isRunning {
                Text(entry.serverName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
```

**Setup:**

- Create Widget Extension target in Xcode
- Configure App Groups for shared data
- Implement timeline provider with refresh logic

#### 5.4. Quick Actions & Services

**Finder integration:**

1. **Import Server URL** - Right-click on text file → Services → Import Shadowsocks URL
2. **Export Server Config** - Right-click in Finder → Export Selected Server

**Implementation:**

```xml
<!-- Info.plist: NSServices -->
<key>NSServices</key>
<array>
    <dict>
        <key>NSMenuItem</key>
        <dict>
            <key>default</key>
            <string>Import Shadowsocks URL</string>
        </dict>
        <key>NSMessage</key>
        <string>importURL</string>
        <key>NSPortName</key>
        <string>ShadowsocksX-NG</string>
        <key>NSSendTypes</key>
        <array>
            <string>NSStringPboardType</string>
        </array>
    </dict>
</array>
```

```swift
// AppDelegate.swift
@objc func importURL(_ pasteboard: NSPasteboard, userData: String, error: NSErrorPointer) {
    guard let urlString = pasteboard.string(forType: .string) else { return }
    // Import logic
}
```

#### 5.5. Focus Modes Integration

**Respect system Focus status:**

```swift
// Check if Focus mode is active
if #available(macOS 12.0, *) {
    import UserNotifications

    UNUserNotificationCenter.current().getNotificationSettings { settings in
        if settings.notificationCenterSetting == .enabled {
            // Show notification
        } else {
            // Suppress notification (Focus mode active)
        }
    }
}
```

**Implementation:**

- Critical notifications (connection errors) → always show
- Informational toasts → respect Focus mode

#### 5.6. Accessibility Enhancements

**VoiceOver support:**

```swift
// All controls must have accessibility labels
button.setAccessibilityLabel("Add Server")
button.setAccessibilityHint("Opens a form to add a new Shadowsocks server")

// Custom controls need explicit role
customView.setAccessibilityRole(.button)

// Group related elements
serverFormBox.setAccessibilityRole(.group)
serverFormBox.setAccessibilityLabel("Server Configuration")
```

**Checklist:**

- [ ] All buttons/icons have accessibility labels
- [ ] Form fields have helpful hints
- [ ] Error messages are announced
- [ ] Status changes are announced (connection state)
- [ ] Keyboard navigation works for all actions
- [ ] Focus indicators are visible

**Voice Control:**

```swift
// Add spoken commands
if #available(macOS 10.15, *) {
    let command = NSAccessibilityCustomAction(
        name: "Toggle Shadowsocks",
        actionHandler: { _ in
            self.toggleShadowsocks()
            return true
        }
    )
    statusItem.button?.accessibilityCustomActions = [command]
}
```

**Testing:**

- Run Accessibility Inspector (Xcode → Open Developer Tool)
- Test with VoiceOver enabled (⌘F5)
- Test with Voice Control enabled
- Verify contrast ratios meet WCAG AA standards

### Deliverables

- [ ] App Intents implemented for Shortcuts app
- [ ] Widget extension created and functional
- [ ] Finder Services configured
- [ ] Focus mode support added
- [ ] Full accessibility audit complete
- [ ] Keyboard navigation optimized
- [ ] Documentation for all integrations

### Testing Checklist

- [ ] Shortcuts work from Shortcuts app and Siri
- [ ] Widgets update correctly (test timeline refresh)
- [ ] Services appear in Finder context menu
- [ ] Focus mode is respected for notifications
- [ ] VoiceOver announces all UI elements correctly
- [ ] Voice Control can execute all actions
- [ ] Keyboard-only navigation works throughout app

---

## Important Considerations

### 1. Backward Compatibility Strategy

#### Current State

**Minimum supported version:** macOS 11.0 (Big Sur, 2020)

- Enforced in `project.pbxproj`: `MACOSX_DEPLOYMENT_TARGET = 11.0`
- Enforced in `Podfile`: `platform :macos, '11.0'`
- OSVersion utility provides centralized feature detection

#### Current Migration Status

**Phase 1 Complete** - Project successfully migrated to macOS 11.0 baseline:

✅ **Completed:**

- MACOSX_DEPLOYMENT_TARGET updated to 11.0 across all targets
- OSVersion utility implemented for clean feature detection
- Documentation updated (README, BACKWARD_COMPATIBILITY.md, etc.)
- Modern baseline established (SF Symbols, SwiftUI 2.0, Combine available)

#### Future Migration Strategy

The strategy focuses on **progressive enhancement** while maintaining Big Sur compatibility:

| Phase         | Minimum Version  | Key Capabilities Available       | User Base Coverage\* | Status    |
| ------------- | ---------------- | -------------------------------- | -------------------- | --------- |
| **Phase 1**   | 11.0 (Big Sur)   | SF Symbols, SwiftUI 2.0, Combine | ~95%+                | ✅ Complete |
| **Phase 2**   | 11.0 (Big Sur)   | Visual & component modernization | ~95%+                | 🚧 Current |
| **Phase 3**   | 11.0 or 12.0     | Monterey enhancements (optional) | ~90%+                | 📋 Planned |
| **Phase 4**   | 11.0 or 13.0     | App Intents (optional)           | ~85%+                | 📋 Planned |
| **Phase 5**   | 11.0             | Widgets on 14.0+ (optional)      | ~95%+                | 📋 Planned |

\*Based on typical Apple ecosystem metrics (2025)

#### Supported Version Analysis

**macOS 11.0 Big Sur (2020) - Current Minimum ✅**

- ✅ **Available:** SF Symbols 1-2, SwiftUI 2.0, Combine, modern AppKit
- ✅ **Benefits:** Modern design baseline, all essential features
- 🎯 **Status:** Fully supported, baseline for all development
- 📦 **Coverage:** ~95%+ of active users

**macOS 12.0 Monterey (2021) - Enhanced Features**

- ✅ **Added:** SF Symbols 3+, SwiftUI 3.0, improved performance
- 🎯 **Strategy:** Optional enhancements via OSVersion checks
- 📦 **Coverage:** ~90%+ of active users

**macOS 13.0 Ventura (2022) - Platform Integration**

- ✅ **Added:** App Intents, Shortcuts, Menu Bar Extras API
- 🎯 **Strategy:** Optional features with graceful degradation
- 📦 **Coverage:** ~85%+ of active users

**macOS 14.0 Sonoma (2023) - Advanced Features**

- ✅ **Added:** Widgets, SF Symbols 4+, interactive widgets
- 🎯 **Strategy:** Completely optional, no functionality loss on older versions
- 📦 **Coverage:** ~75%+ of active users

**macOS 15.0 Sequoia (2024+) - Latest**

- ✅ **Added:** Latest APIs and refinements
- 🎯 **Strategy:** Use latest features where beneficial, always with fallbacks
- 📦 **Coverage:** ~50%+ and growing

#### Current Development Timeline

```
v1.x (Legacy)  →  v2.0 (11.0+)  →  v2.x (Future)
                      ↓
                  Phase 1 ✅
                      ↓
                  Phase 2 🚧
                      ↓
                  Phase 3-5 📋
                      ↓
              Full modernization

11.0 Big Sur:    Baseline (current minimum)
                 All core features available

12.0+ Monterey:  Enhanced symbols, better SwiftUI
                 Optional via OSVersion checks

13.0+ Ventura:   App Intents, Shortcuts
                 Optional features

14.0+ Sonoma:    Widgets, advanced features
                 Optional enhancements
```

#### Implementation Patterns for Current Baseline (11.0+)

**1. Using OSVersion Utility (Recommended)**

```swift
// Check for Monterey+ features
if OSVersion.isMontereyOrLater {
    // Use SF Symbols 3+ features
    image = NSImage(systemSymbolName: "paperplane.circle.fill")
} else {
    // Use SF Symbols 1-2 (available on Big Sur)
    image = NSImage(systemSymbolName: "paperplane.fill")
}

// Check for Ventura+ features
OSVersion.onVenturaOrLater {
    // Setup App Intents
    AppShortcuts.updateShortcuts()
}

// Feature availability checks
if OSVersion.supportsWidgets {  // Sonoma 14.0+
    // Setup widgets
}
```

**2. SF Symbols Pattern (Native on 11.0+)**

```swift
// Direct SF Symbols usage (no PNG fallback needed)
let statusBarIcon = NSImage(
    systemSymbolName: "paperplane.fill",
    accessibilityDescription: "Shadowsocks Status"
)!

// Using OSVersion helper for version-specific symbols
let enhancedIcon = OSVersion.symbol(
    primary: "paperplane.circle.fill",  // SF Symbols 3 (12.0+)
    fallback: "paperplane.fill"         // SF Symbols 1-2 (11.0+)
)

// Check symbol availability
if OSVersion.symbolAvailable("wifi.router.fill") {
    // Use specific symbol
} else {
    // Use alternative symbol
}

// Usage
statusItem.button?.image = statusBarIcon
```

**3. Color System (Native on 11.0+)**

```swift
extension NSColor {
    // All semantic colors are available on Big Sur+
    static var appBackground: NSColor {
        .controlBackgroundColor
    }

    static var appPrimaryText: NSColor {
        .labelColor
        }

    static var appSecondaryText: NSColor {
        .secondaryLabelColor
    }

    static var appToastBackground: NSColor {
        .controlBackgroundColor.withAlphaComponent(0.95)
    }

    // Semantic colors for status
    static var appSuccess: NSColor { .systemGreen }
    static var appError: NSColor { .systemRed }
    static var appWarning: NSColor { .systemOrange }
    static var appInfo: NSColor { .systemBlue }

    // Accent color
    static var appAccent: NSColor { .controlAccentColor }

    // Dark mode is always available on 11.0+
    static var isDarkMode: Bool {
        NSApp.effectiveAppearance.bestMatch(
                from: [.darkAqua, .aqua]
            ) == .darkAqua
    }
}
```

**4. UI Component Factory Pattern (Leveraging OSVersion)**

```swift
// Factory for creating modern UI components
class UIComponentFactory {
    static func createTableView() -> NSTableView {
        // Use OSVersion helper (creates modern table on 11.0+)
        return OSVersion.createModernTableView()
    }

    static func createButton(
        title: String,
                            action: Selector,
        target: Any?,
        prominence: ButtonProminence = .standard
    ) -> NSButton {
        let button = NSButton()
        button.title = title
        button.action = action
        button.target = target as? AnyObject

        // Modern styles available on 11.0+
        switch prominence {
        case .primary:
            button.bezelStyle = .rounded
            button.controlSize = .large
            button.contentTintColor = .controlAccentColor
        case .secondary:
            button.bezelStyle = .roundRect
            button.controlSize = .regular
        case .destructive:
            button.bezelStyle = .rounded
            button.contentTintColor = .systemRed
        default:
            button.bezelStyle = .rounded
        }

        return button
    }

    enum ButtonProminence {
        case primary, secondary, destructive, standard
    }
}
```

**5. SwiftUI Integration (Available on 11.0+)**

```swift
// SwiftUI 2.0 is available on Big Sur
class SwiftUIWindowFactory {
    static func createImportWindow() -> NSWindow {
        let hostingController = NSHostingController(
            rootView: ImportView()
        )
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Import Server"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 400, height: 300))
        return window
    }

    // Use newer SwiftUI features on Monterey+
    static func createModernWindow<Content: View>(
        title: String,
        content: Content
    ) -> NSWindow {
        let hostingController = NSHostingController(rootView: content)
        let window = NSWindow(contentViewController: hostingController)
        window.title = title

        // Enhanced features on Monterey+
        OSVersion.onMontereyOrLater {
            // SwiftUI 3.0 enhancements
            window.toolbarStyle = .unified
        }

        return window
    }
}

// Usage (SwiftUI always available on 11.0+)
func showImportWindow() {
        let window = SwiftUIWindowFactory.createImportWindow()
        window.makeKeyAndOrderFront(nil)
}
```

**6. Vibrancy and Materials (Native on 11.0+)**

```swift
func setupWindowAppearance(_ window: NSWindow) {
    // Vibrancy fully supported on Big Sur+
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active

        window.contentView = visualEffectView
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)

    // Use OSVersion helper for enhanced materials
    OSVersion.applyModernMaterial(to: window)

    // Or use Monterey+ materials if available
    OSVersion.onMontereyOrLater {
        visualEffectView.material = .sidebar  // Better on Monterey+
    }
}
```

#### Feature Compatibility Matrix (Current Baseline: 11.0+)

| Feature                 | 11.0 Big Sur | 12.0 Monterey | 13.0 Ventura | 14.0+ Sonoma+ | Enhancement Strategy    |
| ----------------------- | ------------ | ------------- | ------------ | ------------- | ----------------------- |
| **SF Symbols (1-2)**    | ✅           | ✅            | ✅           | ✅            | Native support          |
| **SF Symbols 3**        | ❌           | ✅            | ✅           | ✅            | OSVersion checks        |
| **SF Symbols 4**        | ❌           | ❌            | ❌           | ✅            | OSVersion checks        |
| **Semantic Colors**     | ✅           | ✅            | ✅           | ✅            | Native support          |
| **Dark Mode**           | ✅           | ✅            | ✅           | ✅            | Native support          |
| **SwiftUI 2.0**         | ✅           | ✅            | ✅           | ✅            | Native support          |
| **SwiftUI 3.0+**        | ❌           | ✅            | ✅           | ✅            | OSVersion checks        |
| **Combine**             | ✅           | ✅            | ✅           | ✅            | Can replace RxSwift     |
| **Modern Table Styles** | ✅           | ✅            | ✅           | ✅            | Native support          |
| **App Intents**         | ❌           | ❌            | ✅           | ✅            | Optional feature        |
| **Widgets**             | ❌           | ❌            | ❌           | ✅            | Optional feature        |
| **Menu Bar Extras**     | ❌           | ❌            | ✅           | ✅            | Optional feature        |
| **Vibrancy Effects**    | ✅           | ✅            | ✅           | ✅            | Native support          |

**Legend:**

- ✅ Fully available - use directly
- ❌ Not available - implement enhancement for newer versions only

**Key Insight:** All essential modern features are available on Big Sur 11.0+. Newer versions only add optional enhancements.

#### Testing Strategy for Supported Versions

**1. Virtual Machine Setup**

```bash
# Recommended test configurations
VMs_TO_TEST=(
    "macOS 11.0 Big Sur"     # Minimum supported (baseline)
    "macOS 12.0 Monterey"    # SF Symbols 3, SwiftUI 3
    "macOS 13.0 Ventura"     # App Intents, Menu Bar Extras
    "macOS 14.0 Sonoma"      # Widgets, SF Symbols 4
    "macOS 15.0 Sequoia"     # Target version (latest)
)
```

**2. Automated Compatibility Checks**

```swift
// Add to test suite
class CompatibilityTests: XCTestCase {
    func testOSVersionDetection() {
        // OSVersion utility should work correctly
        XCTAssertTrue(OSVersion.isBigSurOrLater, "Minimum is 11.0")

        // Check feature availability matches actual OS
        let actualVersion = ProcessInfo.processInfo.operatingSystemVersion
        if actualVersion.majorVersion >= 12 {
            XCTAssertTrue(OSVersion.isMontereyOrLater)
            XCTAssertTrue(OSVersion.supportsSFSymbols3)
        }
        if actualVersion.majorVersion >= 13 {
            XCTAssertTrue(OSVersion.isVenturaOrLater)
            XCTAssertTrue(OSVersion.supportsAppIntents)
        }
        if actualVersion.majorVersion >= 14 {
            XCTAssertTrue(OSVersion.isSonomaOrLater)
            XCTAssertTrue(OSVersion.supportsWidgets)
        }
    }

    func testSFSymbolAvailability() {
        // SF Symbols should always be available on 11.0+
        let icon = NSImage(systemSymbolName: "paperplane.fill",
                           accessibilityDescription: nil)
        XCTAssertNotNil(icon, "SF Symbols must be available on 11.0+")
    }

    func testColorSystem() {
        // All semantic colors should be available
        XCTAssertNotNil(NSColor.appBackground)
        XCTAssertNotNil(NSColor.appPrimaryText)
        XCTAssertNotNil(NSColor.appAccent)
        XCTAssertGreaterThan(NSColor.appBackground.alphaComponent, 0)
    }

    func testModernTableView() {
        // Modern table view should be creatable
        let tableView = OSVersion.createModernTableView()
        XCTAssertEqual(tableView.style, .fullWidth)
    }
}
```

**3. Manual Testing Checklist**

Create regression test plan for each supported version (11.0+):

**All Versions (11.0-15.0):**

- [ ] App launches successfully
- [ ] Status bar icon appears correctly (SF Symbols)
- [ ] Menu opens and functions
- [ ] Preferences window works
- [ ] Server connection succeeds
- [ ] Dark mode and light mode both work
- [ ] No crashes or warnings in Console.app

**Version-Specific Features:**

- [ ] Monterey 12.0+: SF Symbols 3 render correctly
- [ ] Ventura 13.0+: App Intents/Shortcuts available and functional
- [ ] Sonoma 14.0+: Widgets appear and update correctly

**4. Continuous Integration**

```yaml
# .github/workflows/compatibility-test.yml
name: macOS Compatibility Tests
on: [push, pull_request]

jobs:
  test:
    strategy:
      matrix:
        os:
          - macos-12 # Monterey (12.x)
          - macos-13 # Ventura (13.x)
          - macos-14 # Sonoma (14.x)
          - macos-15 # Sequoia (15.x) - if available
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: Build and Test
        run: |
          xcodebuild test \
            -workspace ShadowsocksX-NG.xcworkspace \
            -scheme ShadowsocksX-NG \
            -configuration Debug \
            MACOSX_DEPLOYMENT_TARGET=11.0
```

#### Deprecation Communication Plan

**When raising minimum version:**

1. **Announce Early** (2-3 months before change)

   - GitHub Discussions post
   - Update README with deprecation notice
   - In-app notification for users on old versions

2. **Provide Last Compatible Version**

   - Tag last version supporting older macOS
   - Create "legacy" branch for critical security fixes
   - Document in release notes

3. **Gradual Rollout**
   - Phase 1-2: Ship with 10.12+ support
   - Phase 3: Announce 10.14+ will be required in next major version
   - Phase 4: Make the switch with 2.0.0 release

**Example Deprecation Notice:**

```markdown
## Deprecation Notice: macOS 10.12 and 10.13 Support

Starting with ShadowsocksX-NG v2.0 (planned for Q3 2025),
the minimum supported version will be macOS 10.14 (Mojave).

**Why:**

- Enables modern dark mode support
- Better performance and stability
- 97%+ of users already on 10.14+

**What this means:**

- v1.x will continue to receive security updates until Q4 2025
- If you're on 10.12 or 10.13, please update your macOS or stay on v1.x
- Full functionality will remain available on v1.x

**How to prepare:**

- Check your macOS version: Apple menu → About This Mac
- Update to macOS 10.14+ (free update)
- Or download v1.x for continued support
```

#### User Migration Path

**For users on older macOS:**

1. **Check Compatibility**

   - Add menu item: "About This Mac" → shows current version
   - In-app compatibility checker

2. **Offer Alternatives**

   - Link to v1.x downloads (legacy branch)
   - Suggest macOS update path
   - Document command-line alternatives (ss-local directly)

3. **Preserve Settings**
   - Ensure config files remain compatible
   - Provide migration tool if format changes

#### Phase-Specific Compatibility Guidelines

**Phase 1 (Visual Modernization)**

- ✅ **Keep 10.12+**: All changes use fallbacks
- Icons: SF Symbols with PNG fallback
- Colors: Semantic with hardcoded fallback
- Typography: System fonts (always available)
- Vibrancy: Optional, solid backgrounds on old systems

**Phase 2 (Component Modernization)**

- ✅ **Keep 10.12+**: Modern styles where available
- Table views: Modern style on 11.0+, classic on older
- Buttons: Rounded style (available on 10.12)
- Forms: Enhanced on 10.14+, functional on older

**Phase 3 (Architecture Modernization)**

- ⚠️ **Consider 10.14+ minimum**: Dark mode API needed
- SwiftUI: Only for new features, AppKit for core
- Combine: Considered optional, RxSwift remains
- Dual implementation: XIB + SwiftUI coexist

**Phase 4 (UX Enhancement)**

- ⚠️ **Suggest 10.15+ minimum**: SwiftUI more stable
- Animations: Use AppKit NSAnimationContext (10.12+)
- Settings: SwiftUI on 10.15+, AppKit fallback
- Empty states: Can be implemented in AppKit too

**Phase 5 (Platform Integration)**

- 🔴 **Require 11.0+ minimum**: SF Symbols essential
- App Intents: 13.0+ only (graceful unavailability)
- Widgets: 14.0+ only (optional feature)
- Shortcuts: Degrade gracefully on older versions

#### Decision Framework: When to Drop Old Versions

**Consider dropping version X when:**

1. **Usage < 3%**: Check analytics/GitHub downloads
2. **Security risk**: Old macOS has unpatched vulnerabilities
3. **Development burden**: Maintaining fallbacks delays features
4. **Platform requirement**: Third-party dependency requires newer OS

**Postpone dropping if:**

1. **Usage > 5%**: Still significant user base
2. **Low maintenance**: Fallbacks are simple and stable
3. **No blockers**: Modern features can be optional
4. **Corporate users**: May be stuck on older versions

### 2. Testing Matrix

#### Comprehensive Version Coverage

| macOS Version           | Priority    | Test Focus                              | Phase Coverage |
| ----------------------- | ----------- | --------------------------------------- | -------------- |
| **15.x (Sequoia)**      | 🔴 Critical | Primary development target, latest APIs | All phases     |
| **14.x (Sonoma)**       | 🔴 High     | Widget support, stability               | Phase 4-5      |
| **13.x (Ventura)**      | 🟡 Medium   | App Intents, modern SwiftUI             | Phase 5        |
| **12.x (Monterey)**     | 🟡 Medium   | SF Symbols 3, SwiftUI maturity          | Phase 3-5      |
| **11.x (Big Sur)**      | 🟡 Medium   | SF Symbols baseline, modern design      | Phase 3-5      |
| **10.15 (Catalina)**    | 🟢 Low      | SwiftUI 1.0, Combine baseline           | Phase 3-4      |
| **10.14 (Mojave)**      | 🟢 Low      | Dark mode API, semantic colors          | Phase 1-3      |
| **10.13 (High Sierra)** | ⚪ Minimal  | Baseline compatibility, no new features | Phase 1-2 only |
| **10.12 (Sierra)**      | ⚪ Minimal  | Current minimum, basic functionality    | Phase 1-2 only |

**Testing Priority by Phase:**

**Phase 1-2 Testing:**

- 🔴 Must test: 10.12, 10.14, 11.0, 15.x
- 🟡 Should test: 10.13, 10.15, 12.x
- Reason: Wide compatibility, PNG fallbacks must work

**Phase 3-4 Testing:**

- 🔴 Must test: 10.14, 10.15, 11.0, 15.x
- 🟡 Should test: 12.x, 13.x, 14.x
- Reason: SwiftUI baseline, dark mode required

**Phase 5 Testing:**

- 🔴 Must test: 11.0, 12.x, 13.x, 14.x, 15.x
- 🟢 Nice to have: 10.15
- Reason: SF Symbols required, modern features

**Test Scenarios (All Versions):**

1. **App Lifecycle**

   - Cold launch from Applications folder
   - Launch at login functionality
   - Quit and relaunch (settings persistence)

2. **Visual Appearance**

   - Light/Dark mode switching (10.14+)
   - Light mode only (10.12-10.13)
   - All 8 accent color variations (10.14+)
   - Status bar icon rendering
   - Menu bar legibility

3. **Display Configuration**

   - Retina display (2x, 3x scaling)
   - Non-Retina display (1x)
   - Multiple displays (different DPI)
   - Menu bar position (top vs notch area on newer Macs)

4. **Core Functionality**

   - Server connection/disconnection
   - Proxy mode switching (Auto/Global/Manual)
   - Server list management (add/edit/delete/reorder)
   - QR code scanning (requires screen recording permission)
   - PAC file generation and updates

5. **Permissions**

   - Screen recording permission (10.15+, required for QR scan)
   - Network extension permission
   - Accessibility permission (for global shortcuts)

6. **Localization**

   - English (Base) interface
   - Simplified Chinese (zh-Hans) interface
   - Number/date formatting
   - Right-to-left text handling (future-proofing)

7. **Performance**

   - Memory usage < 100MB idle
   - CPU usage < 1% idle
   - App launch time < 1 second
   - Menu open latency < 100ms

8. **Regression Testing**
   - Launch Agent persistence
   - Config file compatibility
   - Upgrade from previous version (settings migration)

#### Platform-Specific Test Cases

**macOS 10.12-10.13 (No Dark Mode):**

- [ ] Light mode UI is legible and functional
- [ ] PNG icons render correctly
- [ ] Hardcoded colors are appropriate
- [ ] No dark mode-related crashes
- [ ] Vibrancy fallback to solid backgrounds works

**macOS 10.14 (Dark Mode Introduction):**

- [ ] Dark mode toggle works system-wide
- [ ] Semantic colors adapt correctly
- [ ] Manual dark mode detection works
- [ ] Vibrancy effects render properly
- [ ] No deprecated API warnings

**macOS 10.15 (SwiftUI/Combine Available):**

- [ ] SwiftUI windows open and close
- [ ] No SwiftUI layout bugs
- [ ] Combine publishers don't leak memory
- [ ] Notarization succeeds
- [ ] Gatekeeper allows app to launch

**macOS 11.0 (SF Symbols Available):**

- [ ] SF Symbols render at correct sizes
- [ ] Status bar icon switches correctly
- [ ] Menu items show symbols properly
- [ ] Symbol color tinting works
- [ ] No blurry or pixelated symbols

**macOS 13.0+ (App Intents):**

- [ ] Shortcuts app shows app actions
- [ ] Siri can execute shortcuts
- [ ] Shortcuts execute correctly
- [ ] App doesn't need to be running for shortcuts

**macOS 14.0+ (Widgets):**

- [ ] Widget appears in Notification Center
- [ ] Widget updates correctly
- [ ] Widget interactions work
- [ ] Widget doesn't drain battery

#### Automated Testing Strategy

**Unit Tests:**

```swift
// Version-specific capability tests
func testFeatureAvailability() {
    XCTAssertEqual(ProcessInfo.supportsSFSymbols, ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 11)
    XCTAssertEqual(ProcessInfo.supportsModernDarkMode, ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 10 && ProcessInfo.processInfo.operatingSystemVersion.minorVersion >= 14)
}

// Fallback mechanism tests
func testIconFallbacks() {
    let icon = IconProvider.statusBarIcon
    XCTAssertNotNil(icon)
    XCTAssertGreaterThan(icon.size.width, 0)
}

// Color system tests
func testColorSystemCompleteness() {
    XCTAssertNotNil(NSColor.appBackground)
    XCTAssertNotNil(NSColor.appPrimaryText)
    XCTAssertNotNil(NSColor.appAccent)
}
```

**Integration Tests:**

```swift
// Launch Agent tests
func testLaunchAgentInstallation() {
    let launchAgentPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents/com.qiuyuzhou.shadowsocksX-NG.local.plist")

    // Test installation
    LaunchAgentUtils.installLaunchAgents()
    XCTAssertTrue(FileManager.default.fileExists(atPath: launchAgentPath.path))

    // Test uninstallation
    LaunchAgentUtils.removeLaunchAgents()
    XCTAssertFalse(FileManager.default.fileExists(atPath: launchAgentPath.path))
}

// UI tests
func testPreferencesWindowOpens() {
    let app = XCUIApplication()
    app.launch()

    // Click status bar item (tricky, may need accessibility)
    // Open preferences
    // Verify window appears
}
```

**Manual Testing Checklist Template:**

Create a checklist for each release:

```markdown
## Release X.Y.Z Testing Checklist

### macOS 10.12 Sierra

- [ ] App launches without crash
- [ ] Status bar icon visible
- [ ] Can add/edit/delete servers
- [ ] Can connect to server
- [ ] Light mode UI works
- [ ] PNG icons render

### macOS 10.14 Mojave

- [ ] All 10.12 tests pass
- [ ] Dark mode toggle works
- [ ] Semantic colors adapt
- [ ] Vibrancy effects render

### macOS 11.0 Big Sur

- [ ] All 10.14 tests pass
- [ ] SF Symbols render correctly
- [ ] Modern table view style works
- [ ] No deprecated API warnings

### macOS 15.0 Sequoia

- [ ] All 11.0 tests pass
- [ ] Latest APIs work correctly
- [ ] No performance regressions
- [ ] All new features functional
```

### 3. Performance Considerations

**Potential bottlenecks:**

1. **Visual effects** - Can impact older hardware

   - Solution: Disable vibrancy on Macs older than 2016
   - Check: `ProcessInfo.processInfo.operatingSystemVersion`

2. **SwiftUI rendering** - More memory-intensive than AppKit

   - Solution: Use `NSHostingController` judiciously
   - Monitor: Memory usage during window opening

3. **SF Symbols rendering** - Minimal but non-zero cost
   - Solution: Cache rendered images for menu items
   - Implement: Image cache in `AppDelegate`

**Performance targets:**

- App launch: < 1 second (cold start)
- Menu open: < 100ms
- Preference window: < 200ms
- Memory footprint: < 100MB (idle)
- CPU usage: < 1% (idle)

### 4. Design System Documentation

**Create a design system guide:**

```
ShadowsocksX-NG/Documentation/DesignSystem.md
├── Colors (semantic color palette)
├── Typography (font scale)
├── Icons (SF Symbol mapping)
├── Spacing (padding/margin scale)
├── Animations (duration/easing)
└── Components (reusable UI patterns)
```

**Benefits:**

- Consistency across all new UI
- Faster development (copy-paste patterns)
- Easier onboarding for contributors
- Living documentation

### 5. Risk Mitigation

#### Risk: Breaking existing functionality

**Mitigation:**

- Feature flags for new UI (`UserDefaults` toggle)
- Parallel implementation (keep old code during Phase 3)
- Comprehensive test suite before each merge
- Beta testing period (1-2 weeks per phase)

#### Risk: Poor performance on older Macs

**Mitigation:**

- Performance testing on 2015+ hardware
- Graceful degradation (disable effects if needed)
- User setting: "Reduce transparency" (honor system setting)

#### Risk: User confusion with new UI

**Mitigation:**

- Changelog with screenshots for each release
- "What's New" window on first launch after update
- Preserve familiar workflows (don't change core interactions)
- Optional "classic mode" toggle for Phase 1-2

#### Risk: Incomplete SwiftUI migration

**Mitigation:**

- Hybrid architecture is acceptable long-term
- No need to force migration of stable AppKit code
- Focus on new features in SwiftUI only
- Document architectural decisions (ADRs)

### 6. Code Quality & Standards

**Swift style guide:**

- Follow [Swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint for consistent formatting
- 100% SwiftUI previews for new views
- Document all public APIs with DocC comments

**Review process:**

- Pull request template with screenshot requirement
- Design review for all UI changes
- Accessibility review before merge
- Performance profile for significant changes

### 7. Dependency Management

**Current:** CocoaPods
**Future consideration:** Swift Package Manager

**Dependencies to keep:**

- ✅ Alamofire (mature, well-maintained)
- ✅ GCDWebServer (PAC server functionality)
- ⚠️ RxSwift → Migrate to Combine (Phase 3)
- ✅ MASShortcut → Keep for global hotkeys

**New dependencies (if needed):**

- SwiftLintPlugin (SPM)
- SnapshotTesting (for UI tests)

### 8. Localization Strategy

**Current languages:**

- English (Base)
- Simplified Chinese (zh-Hans)

**Modernization:**

- Use `.strings` files (not `.stringsdict` unless plurals needed)
- Validate all strings in Interface Builder XIBs
- Add localization for new SwiftUI views:

  ```swift
  Text("Add Server", comment: "Button title for adding new server")
  ```

- Consider crowdsourcing translations (Crowdin, etc.)

### 9. Distribution & Updates

**Code signing:**

- Ensure all new binaries are signed
- Notarize app for Gatekeeper
- Test installation on fresh Mac

**Update mechanism:**

- Sparkle framework (if not already using)
- Delta updates to minimize download size
- Automatic update checking (user preference)

**Release channels:**

- **Stable:** Fully tested releases (current `develop` branch)
- **Beta:** Phase testing (feature branches)
- **Nightly:** Automated builds from `develop` (optional)

### 10. Documentation Updates

**User-facing docs:**

- Update screenshots in README
- Create visual changelog (before/after images)
- FAQ for common migration questions

**Developer docs:**

- Architecture Decision Records (ADRs) for major changes
- SwiftUI component catalog
- Contribution guide for UI development

---

## Success Metrics & KPIs

### Quantitative Metrics

| Metric                 | Baseline | Target (Post-Phase 5)               |
| ---------------------- | -------- | ----------------------------------- |
| App bundle size        | ~50MB    | <45MB (SF Symbols savings)          |
| Launch time (cold)     | ~1.2s    | <1.0s                               |
| Memory usage (idle)    | ~80MB    | <100MB (SwiftUI overhead)           |
| Accessibility coverage | ~30%     | 100% (all controls labeled)         |
| Dark mode compliance   | ~70%     | 100% (semantic colors)              |
| GitHub stars           | Current  | +20% (better visuals attract users) |

### Qualitative Metrics

**User feedback surveys:**

- Post-update survey: "How do you like the new design?"
- Net Promoter Score (NPS) tracking
- GitHub issue sentiment analysis

**Design audit checklist:**

- [ ] Matches macOS HIG (Human Interface Guidelines)
- [ ] Consistent with native apps (System Settings, etc.)
- [ ] Accessibility Pass/Fail (Accessibility Inspector)
- [ ] Works in all appearance modes (light/dark/auto)

---

## Timeline Overview

```
┌─────────────────────────────────────────────────────────┐
│ Phase 1: Visual (2-3 weeks)                             │
├─────────────────────────────────────────────────────────┤
│ Phase 2: Components (3-4 weeks)                         │
├─────────────────────────────────────────────────────────┤
│ Phase 3: Architecture (4-6 weeks) ← HIGH RISK           │
├─────────────────────────────────────────────────────────┤
│ Phase 4: UX (6-8 weeks)                                 │
├─────────────────────────────────────────────────────────┤
│ Phase 5: Platform (6-8 weeks)                           │
└─────────────────────────────────────────────────────────┘
Total: 21-29 weeks (~5-7 months)
```

**Milestones:**

- ✅ Phase 1 complete → Beta 1 release
- ✅ Phase 2 complete → Beta 2 release
- ✅ Phase 3 complete → Beta 3 release (feature-complete)
- ✅ Phase 4 complete → Release Candidate 1
- ✅ Phase 5 complete → Version 2.0 Release

---

## Next Steps

### Immediate Actions (Week 1)

1. **Setup:**

   - [ ] Create feature branch: `git checkout -b feature/ui-modernization`
   - [ ] Install SwiftLint: `brew install swiftlint`
   - [ ] Update CocoaPods: `pod update`
   - [ ] Configure Xcode warnings (treat as errors)

2. **Planning:**

   - [ ] Review this roadmap with team/stakeholders
   - [ ] Prioritize phases based on user feedback
   - [ ] Set up project board (GitHub Projects or Jira)
   - [ ] Create issue templates for UI changes

3. **Prototyping:**

   - [ ] Create SF Symbols proof-of-concept
   - [ ] Test vibrancy on multiple macOS versions
   - [ ] Benchmark current performance (baseline)

4. **Communication:**
   - [ ] Announce modernization plan to users (GitHub Discussions)
   - [ ] Recruit beta testers (call for volunteers)
   - [ ] Set up feedback channel (Discord/Telegram/GitHub)

### Phase 1 Kickoff (Week 2)

- [ ] Begin SF Symbols migration
- [ ] Create semantic color extension
- [ ] Add vibrancy to toast window
- [ ] Daily standup progress updates

---

## Appendix

### A. Reference Designs

**Apps to study for inspiration:**

- **System Settings** (macOS 13+) - Modern sidebar design
- **Finder** - Menu bar, context menus
- **Xcode** (macOS 14+) - Toolbar design
- **Safari** - Tab bar, preferences
- **Messages** - Empty states, conversation list

### B. Tools & Resources

**Design:**

- SF Symbols app (download from Apple Developer)
- Sketch/Figma macOS UI kits
- HIG (Human Interface Guidelines): <https://developer.apple.com/design/human-interface-guidelines/macos>

**Development:**

- SwiftUI tutorials: <https://developer.apple.com/tutorials/swiftui>
- AppKit → SwiftUI migration guide
- Accessibility Inspector (Xcode → Developer Tools)

**Testing:**

- Accessibility Inspector
- Instruments (Time Profiler, Allocations)
- Network Link Conditioner (test proxy performance)

### C. Glossary

- **AppKit:** Legacy macOS UI framework (Objective-C/Swift)
- **SwiftUI:** Modern declarative UI framework (Swift only)
- **SF Symbols:** Apple's icon library (macOS 11+)
- **Semantic colors:** System colors that adapt to appearance
- **Vibrancy:** Translucent material effect (blurs background)
- **NSHostingController:** Bridge to host SwiftUI in AppKit
- **HIG:** Human Interface Guidelines (design rules)

### D. Contact & Feedback

For questions or suggestions about this roadmap:

- GitHub Issues: [Report issues or propose changes]
- Discussions: [General feedback and questions]
- Email: [Maintainer email if public]

---

**Document History:**

- v1.0 (2025-11-02): Initial roadmap created
- v2.0 (2025-11-07): **Major update** - Reflected current state (macOS 11.0+ baseline, Phase 1 complete, OSVersion utility implemented)
- v2.1 (2025-11-18): **Progress update** - Phase 2 status updated, identified MenuBarManager.swift as primary SF Symbols migration target, documented current implementation state
- v2.2 (TBD): Updates after Phase 2 completion
- v3.0 (TBD): Major revision after Phase 3 lessons learned

---

_This roadmap is a living document and will be updated as the project progresses._
