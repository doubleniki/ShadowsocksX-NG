# Known Issues and Solutions

## Runtime Warnings

### NSKeyedUnarchiveFromData Deprecation Warning (FIXED ✅)

**Issue:**
```
'NSKeyedUnarchiveFromData' should not be used for un-archiving and will be removed in a future release
```

**Appears:** Xcode console during runtime (keyboard shortcut operations)

**Root Cause:**
The MASShortcut library (v2.4.0) is **archived** (March 5, 2023) and no longer maintained. It uses the deprecated `NSKeyedUnarchiveFromDataTransformerName` API for keyboard shortcut serialization.

**Impact:**
- ⚠️ Warning only - keyboard shortcuts still work
- May break in future macOS versions when API is removed
- No workaround available without patching the library

**Solution: ✅ FIXED**

A post-install hook in `Podfile` automatically patches MASShortcut after each `pod install`:

1. **Automatic Patch (Recommended):**
   - Already configured in `Podfile` (lines 54-88)
   - Runs automatically on `pod install`
   - Replaces `NSKeyedUnarchiveFromDataTransformerName` → `NSSecureUnarchiveFromDataTransformerName`
   - Patches 2 files:
     - `MASShortcutBinder.m` (line 19)
     - `MASShortcutView+Bindings.m` (line 47)

2. **Manual Patch (if needed):**
   ```bash
   pod install  # Applies patch automatically
   ```

**Files Patched:**
- `Pods/MASShortcut/Framework/User Defaults Storage/MASShortcutBinder.m`
- `Pods/MASShortcut/Framework/UI/MASShortcutView+Bindings.m`

**Technical Details:**

Changed from deprecated API:
```objc
NSKeyedUnarchiveFromDataTransformerName  // Deprecated
```

To modern secure API:
```objc
NSSecureUnarchiveFromDataTransformerName  // macOS 10.13+
```

**Why This Works:**
- `NSSecureUnarchiveFromDataTransformerName` is backward compatible with `NSKeyedUnarchiveFromData`
- Adds security benefits (prevents arbitrary object deserialization)
- Available since macOS 10.13 (our minimum is 11.0)
- No functional changes - shortcuts work identically

**Future Considerations:**
- MASShortcut is archived, consider migrating to maintained alternative
- Potential replacements: [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts), custom implementation
- Current solution stable for macOS 11.0 - 15.0+

---

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

## System Warnings

### Task Name Port Warning (Harmless)

**Issue:**
```
Unable to obtain a task name port right for pid XXX: (os/kern) failure (0x5)
```

**Appears:** Xcode console during runtime

**Root Cause:**
Sandboxed macOS apps have restricted access to task ports for security reasons. This is expected behavior when the system attempts to obtain privileged port access.

**Impact:**
- ℹ️ Informational only - no functional impact
- Does not affect app functionality
- Standard behavior for sandboxed apps

**Solution:**
No action required. This is normal and expected.

---

### Layout Recursion Warning (Harmless)

**Issue:**
```
It's not legal to call -layoutSubtreeIfNeeded on a view which is already being laid out.
If you are implementing the view's -layout method, you can call -[super layout] instead.
Break on void _NSDetectedLayoutRecursion(void) to debug. This will be logged only once.
This may break in the future.
```

**Appears:** Xcode console during runtime (table view operations)

**Root Cause:**
RxCocoa 6.2.0 dependency calls `layoutIfNeeded()` on views during delegate proxy operations. This happens in `Pods/RxCocoa/RxCocoa/Common/DelegateProxyType.swift` (lines 330, 365).

**Impact:**
- ⚠️ Warning only - logs once then suppressed
- Does not affect app functionality
- Known issue in RxCocoa framework
- May be addressed in future RxCocoa versions

**Solution:**

**Option 1: Ignore (Recommended)**
The warning is harmless and only appears once. No action needed.

**Option 2: Update RxCocoa**
If a newer version addresses this issue:
```bash
pod update RxCocoa
```

**Option 3: Report to RxSwift Project**
If this persists in newer versions, consider reporting at: https://github.com/ReactiveX/RxSwift/issues

---

**Last Updated:** 2025-11-18
**Status:** 🟡 Known issue with documented workarounds
**Priority:** Low (warning only, no functional impact)
