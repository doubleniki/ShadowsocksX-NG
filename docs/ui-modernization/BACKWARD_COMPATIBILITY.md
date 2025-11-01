# Backward Compatibility Guide

## ShadowsocksX-NG UI Modernization

**Quick Reference for Developers**

This document provides a quick reference for maintaining backward compatibility during the UI modernization roadmap.

---

## TL;DR - Version Support Timeline

| Release Version      | Minimum macOS  | Key Changes                                 | Timeline |
| -------------------- | -------------- | ------------------------------------------- | -------- |
| **v1.x (current)**   | 10.12 Sierra   | Current codebase                            | Now      |
| **v1.9 (Phase 1-2)** | 10.12 Sierra   | SF Symbols + semantic colors with fallbacks | Q1 2025  |
| **v2.0 (Phase 3)**   | 10.14 Mojave   | SwiftUI for new features                    | Q2 2025  |
| **v2.1 (Phase 4)**   | 10.15 Catalina | Enhanced UX, Combine migration              | Q3 2025  |
| **v2.5 (Phase 5)**   | 11.0 Big Sur   | Full modernization, SF Symbols required     | Q4 2025  |

---

## Golden Rules

### ✅ DO

1. **Always use `@available` checks**

   ```swift
   if #available(macOS 11.0, *) {
       // Modern code
   } else {
       // Fallback
   }
   ```

2. **Provide fallbacks for all features**

   - SF Symbols → PNG icons
   - Semantic colors → Hardcoded colors
   - SwiftUI → XIB/AppKit
   - Vibrancy → Solid backgrounds

3. **Test on multiple versions**

   - Minimum: Current minimum, 10.14, 11.0, latest
   - Use VMs or CI/CD matrix

4. **Feature detection over version detection**

   ```swift
   extension ProcessInfo {
       static var supportsSFSymbols: Bool {
           if #available(macOS 11.0, *) { return true }
           return false
       }
   }
   ```

### ❌ DON'T

1. **Never assume features are available**

   ```swift
   // BAD - will crash on macOS < 11.0
   let image = NSImage(systemSymbolName: "star.fill")!

   // GOOD - safe on all versions
   let image: NSImage = {
       if #available(macOS 11.0, *) {
           return NSImage(systemSymbolName: "star.fill") ?? NSImage()
       } else {
           return NSImage(named: "star-icon")!
       }
   }()
   ```

2. **Never use deprecated APIs without fallback**

   - Check deprecation warnings
   - Provide modern alternative with `@available`

3. **Never break existing functionality**
   - All features must work on minimum supported version
   - Visual differences OK, functional differences NOT OK

---

## Common Patterns

### Pattern 1: Icon Provider

```swift
// IconProvider.swift
class IconProvider {
    static func icon(named: String, fallbackPNG: String) -> NSImage {
        if #available(macOS 11.0, *) {
            if let symbol = NSImage(systemSymbolName: named,
                                   accessibilityDescription: nil) {
                return symbol
            }
        }
        return NSImage(named: fallbackPNG) ?? NSImage()
    }

    // Usage
    static var statusBarIcon: NSImage {
        icon(named: "paperplane.fill", fallbackPNG: "menu_icon")
    }
}
```

### Pattern 2: Semantic Colors

```swift
// NSColor+Semantic.swift
extension NSColor {
    static var appBackground: NSColor {
        if #available(macOS 10.14, *) {
            return .controlBackgroundColor
        } else {
            return NSColor(white: 0.95, alpha: 1.0)
        }
    }

    static var appPrimaryText: NSColor {
        if #available(macOS 10.14, *) {
            return .labelColor
        } else {
            return .black
        }
    }
}
```

### Pattern 3: UI Component Factory

```swift
// UIComponentFactory.swift
class UIComponentFactory {
    static func createTableView() -> NSTableView {
        let tableView = NSTableView()

        if #available(macOS 11.0, *) {
            tableView.style = .fullWidth
        } else {
            tableView.selectionHighlightStyle = .regular
        }

        return tableView
    }
}
```

### Pattern 4: SwiftUI with AppKit Fallback

```swift
// Window creation
func showImportWindow() {
    if #available(macOS 10.15, *), useModernUI {
        let window = SwiftUIWindowFactory.createImportWindow()
        window.makeKeyAndOrderFront(nil)
    } else {
        // Fallback to XIB-based controller
        let controller = LegacyImportWindowController()
        controller.showWindow(nil)
    }
}
```

### Pattern 5: Vibrancy with Degradation

```swift
func setupWindowAppearance(_ window: NSWindow) {
    if #available(macOS 10.14, *) {
        let effectView = NSVisualEffectView()
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        window.contentView = effectView
    } else {
        // Solid background for older systems
        let bgView = NSView()
        bgView.wantsLayer = true
        bgView.layer?.backgroundColor = NSColor(white: 0.95, alpha: 1.0).cgColor
        window.contentView = bgView
    }
}
```

---

## Testing Checklist

### Before Each Release

- [ ] Test on minimum supported macOS version
- [ ] Test on macOS 10.14 (Dark Mode baseline)
- [ ] Test on macOS 11.0 (SF Symbols baseline)
- [ ] Test on latest macOS (15.x)
- [ ] Run automated tests on CI matrix
- [ ] Check for deprecation warnings
- [ ] Verify all fallbacks work
- [ ] Test light AND dark mode (where applicable)
- [ ] Check all accent color variations

### Manual Testing

```markdown
## Version X.Y Testing

### macOS 10.12 (if supported)

- [ ] App launches
- [ ] PNG icons visible
- [ ] Light mode works
- [ ] Core features functional

### macOS 10.14

- [ ] Dark mode works
- [ ] Semantic colors adapt
- [ ] Vibrancy renders

### macOS 11.0+

- [ ] SF Symbols render
- [ ] Modern table styles
- [ ] No deprecated warnings

### Latest (15.x)

- [ ] All features work
- [ ] Performance OK
- [ ] No regressions
```

---

## Feature Compatibility Matrix

| Feature         | 10.12 | 10.14 | 10.15 | 11.0+ | Implementation               |
| --------------- | ----- | ----- | ----- | ----- | ---------------------------- |
| SF Symbols      | ❌    | ❌    | ❌    | ✅    | `IconProvider` pattern       |
| Semantic Colors | ❌    | ✅    | ✅    | ✅    | `NSColor+Semantic` extension |
| Dark Mode API   | ❌    | ✅    | ✅    | ✅    | `@available` check           |
| SwiftUI         | ❌    | ❌    | ✅    | ✅    | Dual implementation          |
| Combine         | ❌    | ❌    | ✅    | ✅    | Keep RxSwift longer          |
| Vibrancy        | ⚠️    | ✅    | ✅    | ✅    | Solid background fallback    |
| App Intents     | ❌    | ❌    | ❌    | 13.0+ | Optional feature             |
| Widgets         | ❌    | ❌    | ❌    | 14.0+ | Optional feature             |

---

## Migration Timeline

### Phase 1-2: No Breaking Changes (v1.9)

**Target:** Q1 2025
**Minimum:** 10.12 Sierra
**Changes:**

- ✅ SF Symbols with PNG fallback
- ✅ Semantic colors with hardcoded fallback
- ✅ Vibrancy where available
- ✅ 100% functional parity on all versions

### Phase 3: First Breaking Change (v2.0)

**Target:** Q2 2025
**Minimum:** 10.14 Mojave
**Changes:**

- ⚠️ Drops 10.12-10.13 support (~2% users)
- ✅ SwiftUI for new features
- ✅ Dark mode required
- 📢 Announce 2-3 months early
- 📦 Tag v1.x for legacy support

**Communication:**

```markdown
## Deprecation Notice

ShadowsocksX-NG v2.0 will require macOS 10.14 (Mojave) or later.

**Timeline:**

- Now: Announcement
- +2 months: v1.9 final release (10.12+ support)
- +3 months: v2.0 release (10.14+ required)

**Options for users on 10.12-10.13:**

1. Update macOS to 10.14+ (free, supports Macs 2012+)
2. Stay on v1.9 (security updates until Q3 2025)
```

### Phase 4: Second Breaking Change (v2.1)

**Target:** Q3 2025
**Minimum:** 10.15 Catalina (optional)
**Changes:**

- ⚠️ Optionally drops 10.14 (~2% users)
- ✅ Mature SwiftUI
- ✅ Combine framework
- 🤔 Evaluate based on Phase 3 experience

**Decision factors:**

- If SwiftUI works well on 10.14 → stay on 10.14
- If SwiftUI 1.0 too buggy → bump to 10.15

### Phase 5: Final Breaking Change (v2.5)

**Target:** Q4 2025
**Minimum:** 11.0 Big Sur
**Changes:**

- 🔴 Drops 10.14-10.15 support (~5% users)
- ✅ SF Symbols required (no more PNG fallbacks)
- ✅ Modern design required
- ✅ App Intents/Widgets optional (13.0+/14.0+)
- 📌 Final minimum version for v2.x line

---

## Version Update Checklist

### When Raising Minimum Version

**3 months before:**

- [ ] Announce in GitHub Discussions
- [ ] Update README with deprecation notice
- [ ] Add in-app notification for affected users
- [ ] Create tracking issue for migration

**1 month before:**

- [ ] Tag last version supporting old macOS (e.g., v1.9.0)
- [ ] Create legacy branch (e.g., `legacy/v1.x`)
- [ ] Update documentation
- [ ] Prepare migration guide

**At release:**

- [ ] Update `MACOSX_DEPLOYMENT_TARGET` in Xcode
- [ ] Update Info.plist `LSMinimumSystemVersion`
- [ ] Remove deprecated fallback code (optional)
- [ ] Update CI/CD test matrix
- [ ] Release notes highlight version requirement

**After release:**

- [ ] Monitor GitHub issues for compatibility problems
- [ ] Provide support for users migrating
- [ ] Security updates for legacy branch (6 months)

---

## Handling Edge Cases

### Problem: User reports crash on unsupported macOS

**Investigation:**

1. Check if version is below minimum
2. Check if using unsupported API
3. Check if `@available` check missing

**Solutions:**

- Add runtime version check at app launch
- Show friendly error if macOS too old
- Direct user to legacy version download

### Problem: Feature works on 11.0 but not 10.15

**Investigation:**

1. Check API availability docs
2. Test on actual 10.15 system (not just VM)
3. Check for SwiftUI version differences

**Solutions:**

- Add more granular `@available` checks
- Provide 10.15-specific workaround
- Consider keeping feature 11.0+ only

### Problem: Dark mode doesn't work on 10.14

**Investigation:**

1. Check for `NSAppearance` usage
2. Verify semantic colors used
3. Test appearance change notification

**Solutions:**

- Use `effectiveAppearance` API
- Observe `NSAppearanceDidChangeNotification`
- Ensure colors are dynamic, not cached

---

## Resources

### Documentation

- [Apple HIG - macOS](https://developer.apple.com/design/human-interface-guidelines/macos)
- [SF Symbols App](https://developer.apple.com/sf-symbols/)
- [@available Documentation](https://docs.swift.org/swift-book/ReferenceManual/Attributes.html#ID583)

### Tools

- **Accessibility Inspector** - Test VoiceOver labels
- **Instruments** - Profile performance on older macOS
- **Xcode Organizer** - Check crash logs by macOS version

### Internal Docs

- [MODERNIZATION_ROADMAP.md](./MODERNIZATION_ROADMAP.md) - Full roadmap
- [CLAUDE.md](../../CLAUDE.md) - Project overview

---

## Quick Reference: Version Capabilities

```swift
// macOS Version Detection
let version = ProcessInfo.processInfo.operatingSystemVersion

// Check capabilities
let hasDarkMode = version.majorVersion >= 10 && version.minorVersion >= 14
let hasSwiftUI = version.majorVersion >= 10 && version.minorVersion >= 15
let hasSFSymbols = version.majorVersion >= 11
let hasAppIntents = version.majorVersion >= 13
let hasWidgets = version.majorVersion >= 14

// Recommended: Use @available instead
if #available(macOS 10.14, *) {
    // Dark mode available
}
```

---

**Last Updated:** 2025-11-02
**Applies to:** UI Modernization Roadmap v1.0

For questions, see [GitHub Discussions](../../discussions) or file an issue.
