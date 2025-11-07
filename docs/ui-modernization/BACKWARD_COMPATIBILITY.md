# Backward Compatibility Guide

## ShadowsocksX-NG UI Modernization

**Quick Reference for Developers**

This document provides a quick reference for maintaining backward compatibility during the UI modernization roadmap.

---

## TL;DR - Version Support Timeline

| Release Version      | Minimum macOS | Key Changes                             | Timeline |
| -------------------- | ------------- | --------------------------------------- | -------- |
| **v2.0+ (current)**  | 11.0 Big Sur  | Modern baseline, SF Symbols native      | Now      |
| **v2.1 (Phase 1)**   | 11.0 Big Sur  | SwiftUI components, enhanced UX         | Q1 2025  |
| **v2.5 (Phase 2)**   | 12.0 Monterey | Widgets, App Intents, advanced features | Q3 2025  |
| **v3.0 (Phase 3)**   | 13.0 Ventura  | Full SwiftUI, modern architecture       | Q4 2025  |

---

## Golden Rules

### ✅ DO

1. **Use `@available` checks for features above 11.0**

   ```swift
   if #available(macOS 12.0, *) {
       // Monterey+ features (Widgets, etc)
   } else {
       // Big Sur compatible code
   }
   ```

2. **Leverage built-in Big Sur features**

   - ✅ SF Symbols - native support
   - ✅ Semantic colors - always available
   - ✅ Dark Mode - required
   - ✅ SwiftUI 2.0 - stable baseline
   - ⚠️ Provide fallbacks only for 12.0+ features

3. **Test on multiple versions**

   - Minimum: 11.0 Big Sur
   - Test: 12.0 Monterey, 13.0 Ventura, 14.0 Sonoma, latest
   - Use VMs or CI/CD matrix

4. **Use OSVersion utility for feature detection**

   ```swift
   // Используйте централизованную утилиту OSVersion
   if OSVersion.supportsWidgets {
       setupWidgets()
   }

   if OSVersion.supportsAppIntents {
       registerAppIntents()
   }

   // См. VERSION_DETECTION_GUIDE.md для деталей
   ```

### ❌ DON'T

1. **Never assume advanced features (12.0+) are available**

   ```swift
   // BAD - will crash on macOS 11.0
   @available(macOS 12.0, *)
   func useMontereyFeature() {
       // Called without availability check!
   }

   // GOOD - safe check before use
   func useFeatureIfAvailable() {
       if #available(macOS 12.0, *) {
           useMontereyFeature()
       } else {
           useBigSurAlternative()
       }
   }
   ```

2. **Never use deprecated APIs**

   - SF Symbols are standard - no PNG fallbacks needed
   - Semantic colors are standard - no hardcoded colors
   - Check deprecation warnings for Big Sur APIs

3. **Never break existing functionality**
   - All features must work on macOS 11.0+
   - Visual differences OK for 12.0+ features
   - Functional differences NOT OK

---

## Common Patterns

> **Note:** Используйте утилиту `OSVersion` для упрощения работы с версиями.
> См. [VERSION_DETECTION_GUIDE.md](./VERSION_DETECTION_GUIDE.md) для подробностей.

### Pattern 1: SF Symbols (Always Available)

```swift
// Используйте OSVersion для получения символов
class IconProvider {
    static var statusBarIcon: NSImage {
        OSVersion.symbol(primary: "paperplane.fill")
    }

    static var serverIcon: NSImage {
        // С fallback для старых версий SF Symbols
        OSVersion.symbol(
            primary: "server.rack",
            fallback: "square.grid.2x2"
        )
    }
}
```

### Pattern 2: Semantic Colors (Always Available)

```swift
// NSColor+App.swift - Direct usage, no checks needed
extension NSColor {
    static var appBackground: NSColor {
        .controlBackgroundColor
    }

    static var appPrimaryText: NSColor {
        .labelColor
    }

    static var appSecondaryText: NSColor {
        .secondaryLabelColor
    }

    static var appAccent: NSColor {
        .controlAccentColor
    }
}
```

### Pattern 3: Modern UI Components

```swift
// Используйте OSVersion helpers
class UIComponentFactory {
    static func createModernTableView() -> NSTableView {
        // Создает table view с оптимальными настройками для версии
        return OSVersion.createModernTableView()
    }

    static func setupWindow(_ window: NSWindow) {
        // Применяет современные материалы
        OSVersion.applyModernMaterial(to: window)
    }
}
```

### Pattern 4: SwiftUI Integration

```swift
// SwiftUI is stable on Big Sur - use directly
func showImportWindow() {
    let contentView = ImportWindowView()
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
        styleMask: [.titled, .closable, .resizable],
        backing: .buffered,
        defer: false
    )
    window.contentView = NSHostingView(rootView: contentView)
    window.makeKeyAndOrderFront(nil)
}
```

### Pattern 5: Advanced Features with Fallback

```swift
// Используйте OSVersion feature flags
func setupAdvancedFeatures() {
    // Widgets (Sonoma+)
    if OSVersion.supportsWidgets {
        if #available(macOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // App Intents (Ventura+)
    if OSVersion.supportsAppIntents {
        if #available(macOS 13.0, *) {
            AppShortcutsProvider.updateAppShortcutParameters()
        }
    }

    // Или используйте conditional execution
    OSVersion.onVenturaOrLater {
        if #available(macOS 13.0, *) {
            registerAppIntents()
        }
    }

    // Big Sur baseline features always work
    setupStatusBarMenu()
    setupSystemTray()
}
```

---

## Testing Checklist

### Before Each Release

- [ ] Test on macOS 11.0 Big Sur (minimum version)
- [ ] Test on macOS 12.0 Monterey
- [ ] Test on macOS 13.0 Ventura
- [ ] Test on macOS 14.0 Sonoma
- [ ] Test on latest macOS (15.x Sequoia)
- [ ] Run automated tests on CI matrix
- [ ] Check for deprecation warnings
- [ ] Test light AND dark mode
- [ ] Check all accent color variations
- [ ] Verify SF Symbols render correctly
- [ ] Test advanced features (Widgets, App Intents) on supported versions

### Manual Testing

```markdown
## Version X.Y Testing

### macOS 11.0 Big Sur (minimum)

- [ ] App launches successfully
- [ ] SF Symbols render properly
- [ ] Dark mode works
- [ ] Semantic colors display correctly
- [ ] Core features functional
- [ ] SwiftUI views work
- [ ] No crashes or errors

### macOS 12.0 Monterey

- [ ] All Big Sur features work
- [ ] Enhanced UI features work
- [ ] Performance is good

### macOS 13.0 Ventura

- [ ] App Intents work (if implemented)
- [ ] Advanced features functional
- [ ] No regressions

### macOS 14.0+ Sonoma/Sequoia

- [ ] Widgets work (if implemented)
- [ ] Latest features functional
- [ ] Performance optimal
- [ ] No deprecated warnings
```

---

## Feature Compatibility Matrix

| Feature              | 11.0 Big Sur | 12.0 Monterey | 13.0 Ventura | 14.0+ Sonoma | Notes                          |
| -------------------- | ------------ | ------------- | ------------ | ------------ | ------------------------------ |
| SF Symbols           | ✅           | ✅            | ✅           | ✅           | Native support (v1/v2)         |
| Semantic Colors      | ✅           | ✅            | ✅           | ✅           | Always available               |
| Dark Mode            | ✅           | ✅            | ✅           | ✅           | Required                       |
| SwiftUI 2.0          | ✅           | ✅            | ✅           | ✅           | Stable baseline                |
| Combine              | ✅           | ✅            | ✅           | ✅           | Can replace RxSwift            |
| Vibrancy Effects     | ✅           | ✅            | ✅           | ✅           | Modern materials               |
| SF Symbols 3         | ❌           | ✅            | ✅           | ✅           | Enhanced symbol set            |
| App Intents          | ❌           | ❌            | ✅           | ✅           | Requires `@available` check    |
| Widgets (WidgetKit)  | ❌           | ❌            | ❌           | ✅           | Requires `@available` check    |
| SF Symbols 4         | ❌           | ❌            | ❌           | ✅           | Latest symbols                 |
| Menu Bar Extras API  | ❌           | ❌            | ✅           | ✅           | Modern menu bar integration    |

---

## Migration Timeline

### Current Status: Big Sur Baseline (v2.0+)

**Current:** November 2025
**Minimum:** 11.0 Big Sur
**Achieved:**

- ✅ SF Symbols native (no fallbacks)
- ✅ Semantic colors standard
- ✅ Dark mode required
- ✅ SwiftUI 2.0 stable
- ✅ Modern design baseline

### Phase 1: SwiftUI Enhancement (v2.1)

**Target:** Q1 2025
**Minimum:** 11.0 Big Sur
**Changes:**

- ✅ Migrate more UI to SwiftUI
- ✅ Enhanced UX patterns
- ✅ Improved performance
- ✅ Better accessibility
- 📊 No breaking changes - same minimum

### Phase 2: Advanced Features (v2.5)

**Target:** Q3 2025
**Minimum:** 12.0 Monterey (consideration)
**Changes:**

- ⚠️ May drop 11.0 support (evaluate user base)
- ✅ SF Symbols 3 features
- ✅ Enhanced UI capabilities
- ✅ Widget support (14.0+, optional)
- ✅ App Intents (13.0+, optional)

**Decision factors:**

- User base on 11.0 (<5% → upgrade minimum)
- User base on 11.0 (>10% → keep 11.0 support)
- SwiftUI 3.0 features needed?

### Phase 3: Full Modern Architecture (v3.0)

**Target:** Q4 2025
**Minimum:** 13.0 Ventura (consideration)
**Changes:**

- 🔴 Major architectural update
- ✅ Full SwiftUI app
- ✅ App Intents required
- ✅ Modern Swift concurrency
- ✅ Enhanced system integration

**Communication plan:**

```markdown
## Version Update Notice

ShadowsocksX-NG v3.0 will require macOS 13.0 (Ventura) or later.

**Timeline:**

- Now: Announcement
- +2 months: v2.5 final release (11.0/12.0 support)
- +3 months: v3.0 release (13.0+ required)

**Options for users on older macOS:**

1. Update macOS to 13.0+ (free, supports Macs 2017+)
2. Stay on v2.5 (security updates until 2026)
```

---

## Version Update Checklist

### When Raising Minimum Version (Future Updates)

**3 months before:**

- [ ] Analyze user base on affected macOS versions
- [ ] Announce in GitHub Discussions and README
- [ ] Add in-app notification for affected users
- [ ] Create tracking issue for migration
- [ ] Document new features requiring higher version

**1 month before:**

- [ ] Tag last version supporting current minimum (e.g., v2.5.0 for 11.0)
- [ ] Create legacy branch if needed (e.g., `legacy/v2.x`)
- [ ] Update all documentation
- [ ] Prepare migration guide with upgrade instructions
- [ ] Test thoroughly on new minimum version

**At release:**

- [ ] Update `MACOSX_DEPLOYMENT_TARGET` in Xcode project
- [ ] Update Info.plist `LSMinimumSystemVersion` key
- [ ] Remove old version fallback code
- [ ] Update CI/CD test matrix (remove old version)
- [ ] Update README with new requirements
- [ ] Release notes prominently highlight version requirement

**After release:**

- [ ] Monitor GitHub issues for compatibility problems
- [ ] Provide support for users upgrading macOS
- [ ] Security updates for legacy branch (6-12 months)
- [ ] Close issues related to old version limitations

---

## Handling Edge Cases

### Problem: User reports crash on Big Sur

**Investigation:**

1. Verify actual macOS version (user may be confused)
2. Check crash logs for API availability issues
3. Test on actual Big Sur system (not just VM)

**Solutions:**

- Add runtime version check at app launch
- Show friendly error if macOS < 11.0
- Direct user to system requirements documentation
- Log detailed version info for debugging

### Problem: Feature works on Monterey+ but not Big Sur

**Investigation:**

1. Check Apple's API availability documentation
2. Test on actual Big Sur system
3. Check for SwiftUI 3.0+ features
4. Verify SF Symbols version compatibility

**Solutions:**

- Add `if #available(macOS 12.0, *)` check
- Provide Big Sur-compatible alternative
- Document feature as Monterey+ only if critical
- Use SF Symbols 1/2 that work on Big Sur

### Problem: SF Symbol doesn't render on Big Sur

**Investigation:**

1. Check if symbol is from SF Symbols 3+ (Monterey+)
2. Verify symbol name spelling
3. Test with SF Symbols app on Big Sur

**Solutions:**

- Use SF Symbols 1 or 2 symbols for broad support
- Check symbol availability in SF Symbols app
- Provide fallback symbol if needed:

  ```swift
  let image = NSImage(systemSymbolName: "symbol.name")
              ?? NSImage(systemSymbolName: "fallback.symbol")
              ?? NSImage()
  ```

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

- [VERSION_DETECTION_GUIDE.md](./VERSION_DETECTION_GUIDE.md) - Утилита OSVersion и примеры
- [MODERNIZATION_ROADMAP.md](./MODERNIZATION_ROADMAP.md) - Full roadmap
- [CLAUDE.md](../../CLAUDE.md) - Project overview

---

## Quick Reference: Version Capabilities

```swift
// macOS Version Detection
let version = ProcessInfo.processInfo.operatingSystemVersion

// Big Sur (11.0) - Minimum, always available:
// ✅ SF Symbols 1/2
// ✅ Semantic Colors
// ✅ Dark Mode
// ✅ SwiftUI 2.0
// ✅ Combine

// Check for advanced features:
let hasSFSymbols3 = version.majorVersion >= 12
let hasAppIntents = version.majorVersion >= 13
let hasWidgets = version.majorVersion >= 14

// Recommended: Use @available for features above 11.0
if #available(macOS 12.0, *) {
    // Monterey+ features: SF Symbols 3, etc
}

if #available(macOS 13.0, *) {
    // Ventura+ features: App Intents, etc
}

if #available(macOS 14.0, *) {
    // Sonoma+ features: Widgets, SF Symbols 4, etc
}

// Example: Feature detection helper
extension ProcessInfo {
    static var supportsAdvancedFeatures: Bool {
        if #available(macOS 14.0, *) { return true }
        return false
    }
}
```

---

**Last Updated:** 2025-11-07
**Applies to:** UI Modernization Roadmap v2.0 (Big Sur baseline)

For questions, see [GitHub Discussions](../../discussions) or file an issue.
