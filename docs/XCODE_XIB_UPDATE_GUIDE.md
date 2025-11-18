# Xcode XIB Update Guide

## Quick Reference: Updating XIB Files to Modern Format

This guide helps you update old XIB files to fix deprecation warnings and modernize your UI.

---

## Problem: NSToolbarItem Size Warnings

**Symptom:**
```
NSToolbarItem.minSize and NSToolbarItem.maxSize methods are deprecated.
```

**Affected File:** `ShadowsocksX-NG/Base.lproj/PreferencesWinController.xib`

---

## Step-by-Step Update Process

### 1. Open Project in Xcode

```bash
cd /path/to/ShadowsocksX-NG
open ShadowsocksX-NG.xcworkspace
```

**Important:** Open `.xcworkspace`, not `.xcodeproj` (CocoaPods requirement)

### 2. Locate XIB File

In Xcode's Project Navigator (⌘1):
```
ShadowsocksX-NG
└── Base.lproj
    └── PreferencesWinController.xib
```

Click to open in Interface Builder.

### 3. Update Document Version

**In File Inspector (⌥⌘1):**

1. Select the XIB file in Project Navigator
2. Open File Inspector panel on the right
3. Find **"Interface Builder Document"** section
4. Look for:
   - **Opens in:** Should say "Xcode 14.0" or later
   - If it says "Xcode 11.x" or older, update it

**How to update:**
- Click on the document version dropdown
- Select latest available Xcode version (14.0, 15.0, etc.)
- Xcode may prompt: "Update to Recommended Settings" → Click **Update**

### 4. Inspect Toolbar Items

**In Document Outline (left sidebar):**

1. Expand the hierarchy:
   ```
   Preferences Window
   └── Window
       └── Toolbar
           ├── General (toolbarItem)
           ├── Advanced (toolbarItem)
           ├── HTTP (toolbarItem)
           └── Interfaces (toolbarItem)
   ```

2. Select each toolbar item one by one

### 5. Remove Size Constraints

**For EACH toolbar item:**

1. Select the item in Document Outline
2. Open **Size Inspector** (⌥⌘5) on the right panel
3. Look for these fields:
   - **Min Size** (width/height)
   - **Max Size** (width/height)

4. If you see values in these fields:
   - Clear them (delete values)
   - Or set to default: Min Size (0, 0), Max Size (10000, 10000)

5. Check **"Use Auto Layout"** if available

### 6. Let System Calculate Sizes

**In Attributes Inspector (⌥⌘4):**

For each toolbar item:
- **Label:** Keep as is ("General", "Advanced", etc.)
- **Palette Label:** Keep as is
- **Min Size / Max Size:** Should be empty or (0,0) / (10000, 10000)
- Let Xcode calculate optimal sizes based on content

### 7. Update Toolbar Settings

Select the **Toolbar** (not individual items):

**In Attributes Inspector:**
- ✅ **Display Mode:** Icon and Label (or as needed)
- ✅ **Size Mode:** Regular
- ✅ **Allows User Customization:** Unchecked (per project settings)
- ✅ **Autosaves Configuration:** Unchecked

### 8. Verify Changes

**Check XML (optional):**

Right-click XIB → Open As → Source Code

Look for the header:
```xml
<document type="com.apple.InterfaceBuilder3.Cocoa.XIB"
          version="3.0"
          toolsVersion="23XXX"    <!-- Should be 23000+ for Xcode 14+ -->
          targetRuntime="MacOSX.Cocoa"
          ...>
```

Old value: `toolsVersion="15400"` (Xcode 11)
New value: `toolsVersion="23000+"` (Xcode 14+)

### 9. Build and Test

1. **Clean Build Folder:** ⇧⌘K (Shift + Cmd + K)
2. **Build Project:** ⌘B (Cmd + B)
3. **Run:** ⌘R (Cmd + R)
4. **Open Preferences Window** in the app
5. **Check Console:** The warning should be gone

### 10. Verify Visual Appearance

Test the Preferences window:
- ✅ All toolbar items visible
- ✅ Icons display correctly
- ✅ Text labels not clipped
- ✅ No layout issues
- ✅ Toolbar items respond to clicks
- ✅ Window resizes correctly

---

## Troubleshooting

### Issue: "Update to Recommended Settings" Not Available

**Solution:**
1. File → Validate Settings
2. If no prompts appear, the file may already be modern
3. Check `toolsVersion` in source code manually

### Issue: Toolbar Items Still Clipped

**Solution:**
1. Select toolbar item
2. Editor → Size to Fit Content
3. Verify Min/Max sizes are cleared
4. Rebuild project

### Issue: Changes Don't Take Effect

**Solution:**
1. Clean Build Folder (⇧⌘K)
2. Delete Derived Data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/ShadowsocksX-NG-*
   ```
3. Rebuild and run

### Issue: XIB Merge Conflicts in Git

**Solution:**
XIB files are XML and can conflict. To resolve:

```bash
# Use local version
git checkout --ours ShadowsocksX-NG/Base.lproj/PreferencesWinController.xib

# Or use incoming version
git checkout --theirs ShadowsocksX-NG/Base.lproj/PreferencesWinController.xib

# Or open in Xcode and manually resolve
open ShadowsocksX-NG/Base.lproj/PreferencesWinController.xib
# Fix in Interface Builder, then commit
```

---

## Additional XIB Files to Check

After fixing `PreferencesWinController.xib`, check these files for similar issues:

```bash
ShadowsocksX-NG/
├── ToastWindowController.xib
├── SWBQRCodeWindowController.xib
└── Base.lproj/
    ├── PreferencesWinController.xib  ← Just fixed
    ├── UserRulesController.xib
    └── ServerProfileManager.xib (if exists)
```

Run this command to find old XIB files:

```bash
grep -r "toolsVersion=\"15" ShadowsocksX-NG/*.xib ShadowsocksX-NG/Base.lproj/*.xib
```

Update any that return results using the same process.

---

## Automated Check Script

Save this as `check_xib_versions.sh`:

```bash
#!/bin/bash

echo "Checking XIB file versions..."
echo ""

find . -name "*.xib" -type f | while read xib; do
    version=$(grep "toolsVersion=" "$xib" | head -1 | sed -E 's/.*toolsVersion="([0-9]+)".*/\1/')

    if [ "$version" -lt "23000" ]; then
        echo "⚠️  OLD: $xib (toolsVersion=$version)"
    else
        echo "✅  OK:  $xib (toolsVersion=$version)"
    fi
done

echo ""
echo "Note: toolsVersion < 23000 indicates Xcode 13 or older"
echo "      toolsVersion >= 23000 indicates Xcode 14+"
```

Run:
```bash
chmod +x check_xib_versions.sh
./check_xib_versions.sh
```

---

## Best Practices

1. **Always Use Workspace:** Open `.xcworkspace` for CocoaPods projects
2. **Update Regularly:** Keep XIB files updated with each Xcode version
3. **Test After Update:** Always test UI after updating XIB files
4. **Version Control:** Commit XIB updates separately for easier review
5. **Document Changes:** Note in commit message: "Update XIB to Xcode 14 format"

---

## Example Commit Message

```
chore(xib): update PreferencesWinController.xib to Xcode 14 format

- Update toolsVersion from 15400 (Xcode 11) to 23XXX (Xcode 14)
- Remove deprecated minSize/maxSize from toolbar items
- Fix NSToolbarItem deprecation warnings in console
- Verify toolbar items display correctly
- No functional changes

Fixes console warning:
"NSToolbarItem.minSize and NSToolbarItem.maxSize methods are deprecated"

Related: docs/KNOWN_ISSUES.md
```

---

## References

- **Apple Docs:** [Updating Interface Builder Files](https://developer.apple.com/documentation/xcode/updating-to-the-latest-sdk)
- **NSToolbar:** [Apple Documentation](https://developer.apple.com/documentation/appkit/nstoolbar)
- **Project Docs:** [docs/ui-modernization/README.md](ui-modernization/README.md)

---

**Last Updated:** 2025-11-18
**Xcode Version:** 14.0+ recommended, 15.0+ preferred
**macOS:** 11.0+ (Big Sur or later)
