# Known Issues and Solutions

## Runtime Warnings

### NSToolbarItem.minSize/maxSize Deprecation Warning

**Issue:**
```
NSToolbarItem.minSize and NSToolbarItem.maxSize methods are deprecated.
Usage may result in clipping of items.
It is recommended to let the system measure the item automatically using constraints.
```

**Appears:** Xcode console during runtime (app launch)

**Root Cause:**
The `PreferencesWinController.xib` file was created with Xcode 11.x (toolsVersion="15400") and uses an outdated XIB format. When loaded on modern macOS/Xcode versions, the XIB deserialization process internally calls the deprecated `minSize`/`maxSize` methods on toolbar items.

**Impact:**
- ⚠️ Warning only - does not affect functionality
- May cause visual clipping in toolbar items on some macOS versions
- No crashes or data loss

**Solution:**

#### Option 1: Update XIB File (Recommended)

Open the project in Xcode and update the XIB file to modern format:

1. Open `ShadowsocksX-NG.xcworkspace` in Xcode 14+ or 15+
2. Navigate to `ShadowsocksX-NG/Base.lproj/PreferencesWinController.xib`
3. Open the file in Interface Builder
4. **File → Update to Recommended Settings** (if prompted)
5. Select the toolbar items and remove any explicit size constraints:
   - Select each toolbar item in Interface Builder
   - In Size Inspector (⌥⌘5), check for minSize/maxSize
   - Remove any explicit size constraints
   - Let the system calculate sizes automatically
6. Update the document version:
   - File Inspector (⌥⌘1)
   - Interface Builder Document → Xcode version: "Xcode 14.0" or later
7. Save the file
8. Verify the warning is gone: Clean Build (⇧⌘K) → Build (⌘B) → Run (⌘R)

**Expected Result:**
- `toolsVersion` updated from "15400" to "23XXX+" (Xcode 14+)
- Toolbar items use auto-layout constraints instead of fixed sizes
- Warning disappears from console

#### Option 2: Suppress Warning (Temporary)

If you cannot update the XIB immediately, you can suppress the warning:

**In `PreferencesWinController.swift`:**

```swift
override func windowDidLoad() {
    super.windowDidLoad()

    // Suppress NSToolbarItem size deprecation warnings
    UserDefaults.standard.set(false, forKey: "NSToolbar LogInvalidSize")

    // ... rest of code
}
```

**Note:** This only hides the warning; the underlying issue remains.

#### Option 3: Programmatic Toolbar (Advanced)

Replace the XIB toolbar with programmatic code:

**In `PreferencesWinController.swift`:**

```swift
override func windowDidLoad() {
    super.windowDidLoad()

    // Remove XIB toolbar and create programmatically
    if let window = window {
        let newToolbar = NSToolbar(identifier: "PreferencesToolbar")
        newToolbar.delegate = self
        newToolbar.allowsUserCustomization = false
        newToolbar.autosavesConfiguration = false
        newToolbar.displayMode = .iconAndLabel
        newToolbar.sizeMode = .regular
        window.toolbar = newToolbar
        newToolbar.selectedItemIdentifier = NSToolbarItem.Identifier("general")
    }

    // ... rest of code
}

// Implement NSToolbarDelegate methods...
```

This approach gives you full control and avoids XIB-related issues entirely.

---

## Recommendation

**For this project:** Use **Option 1** - Update the XIB file in Xcode.

**Why:**
- ✅ Fixes root cause permanently
- ✅ No code changes needed
- ✅ Maintains visual design workflow in Interface Builder
- ✅ Future-proof for macOS updates
- ✅ 5 minutes of work in Xcode

**When to use other options:**
- Option 2: Quick CI/CD fix, planning to update XIB later
- Option 3: Need programmatic control, migrating away from XIBs

---

## Related Files

- `ShadowsocksX-NG/Base.lproj/PreferencesWinController.xib` - Contains outdated toolbar
- `ShadowsocksX-NG/PreferencesWinController.swift` - Window controller implementation

## References

- Apple Documentation: [NSToolbarItem](https://developer.apple.com/documentation/appkit/nstoolbaritem)
- Migration Guide: [Modernizing Your UI](https://developer.apple.com/documentation/xcode/modernizing-your-ui)
- [docs/ui-modernization/README.md](ui-modernization/README.md) - UI Modernization roadmap

---

**Last Updated:** 2025-11-18
**Status:** 🟡 Known issue with documented workarounds
**Priority:** Low (warning only, no functional impact)
