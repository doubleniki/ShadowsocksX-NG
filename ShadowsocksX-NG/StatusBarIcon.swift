//
//  StatusBarIcon.swift
//  ShadowsocksX-NG
//
//  Created for Phase 2 UI Modernization
//  Provides SF Symbols mapping for status bar icons
//

import Cocoa

/// Status bar icon provider using SF Symbols
/// Replaces PNG assets with vector-based SF Symbols for better scaling and dark mode support
enum StatusBarIcon {

    // MARK: - Icon Types

    /// Status bar icon for different states
    enum IconType {
        case enabled        // Normal active state
        case disabled       // Shadowsocks is off
        case auto           // Auto/PAC mode
        case global         // Global mode
        case manual         // Manual mode
        case externalPAC    // External PAC mode
    }

    // MARK: - SF Symbols Mapping

    /// Get SF Symbol for icon type
    /// - Parameter type: The icon type
    /// - Returns: NSImage with SF Symbol
    static func icon(for type: IconType) -> NSImage {
        let symbolName: String

        switch type {
        case .enabled:
            // Default enabled state - paperplane filled
            symbolName = "paperplane.fill"

        case .disabled:
            // Disabled state - paperplane unfilled
            symbolName = "paperplane"

        case .auto:
            // Auto/PAC mode - network symbol
            symbolName = "network"

        case .global:
            // Global mode - globe symbol
            symbolName = "globe"

        case .manual:
            // Manual mode - gearshape filled
            symbolName = "gearshape.fill"

        case .externalPAC:
            // External PAC - link circle filled
            symbolName = "link.circle.fill"
        }

        // Use OSVersion helper for safe symbol loading
        let image = OSVersion.symbol(primary: symbolName)
        image.isTemplate = true // Enable template rendering for menu bar
        return image
    }

    // MARK: - Legacy PNG Mapping (for reference)

    /// Legacy PNG icon names (deprecated, use SF Symbols instead)
    private enum LegacyPNGName {
        static let enabled = "menu_icon"
        static let disabled = "menu_icon_disabled"
        static let auto = "menu_p_icon"
        static let global = "menu_g_icon"
        static let manual = "menu_m_icon"
        static let externalPAC = "menu_e_icon"
    }
}

// MARK: - Convenience Extensions

extension StatusBarIcon {

    /// Get icon for proxy mode string
    /// - Parameters:
    ///   - mode: Proxy mode string ("auto", "global", "manual", "externalPAC")
    ///   - isEnabled: Whether Shadowsocks is currently enabled
    /// - Returns: NSImage for the current state
    static func icon(forMode mode: String?, isEnabled: Bool) -> NSImage {
        guard isEnabled else {
            return icon(for: .disabled)
        }

        guard let mode = mode else {
            return icon(for: .enabled)
        }

        switch mode {
        case "auto":
            return icon(for: .auto)
        case "global":
            return icon(for: .global)
        case "manual":
            return icon(for: .manual)
        case "externalPAC":
            return icon(for: .externalPAC)
        default:
            return icon(for: .enabled)
        }
    }

    /// Get icon for password visibility toggle button
    /// - Parameter visible: Whether password is currently visible (true = showing, false = hidden)
    /// - Returns: NSImage for password visibility toggle
    ///
    /// **Legacy PNG Mapping:**
    /// - `visible: true` → "icons8-Eye Filled-50" → eye.fill (password is showing, click to hide)
    /// - `visible: false` → "icons8-Blind Filled-50" → eye.slash.fill (password is hidden, click to show)
    ///
    /// **Note:** The icon shows the *current* state, not the action.
    /// When password is visible (true), show eye.fill. When hidden (false), show eye.slash.fill.
    static func passwordVisibility(visible: Bool) -> NSImage {
        let symbolName = visible ? "eye.fill" : "eye.slash.fill"
        return OSVersion.symbol(primary: symbolName)
    }

    /// Get icon for HTTP proxy export command menu item
    /// - Returns: NSImage with terminal symbol
    ///
    /// **Legacy PNG Mapping:**
    /// - "terminal-logo.png" → terminal.fill (HTTP export command)
    ///
    /// Used in the "HTTP Proxy Export Line To Pasteboard" menu item.
    static func terminalIcon() -> NSImage {
        return OSVersion.symbol(primary: "terminal.fill")
    }
}

// MARK: - SF Symbols Reference

/*
 SF Symbols Mapping Documentation:

 ## Status Bar Icons
 | Icon Type      | SF Symbol            | Big Sur+ | Monterey+ | Description                    |
 |----------------|----------------------|----------|-----------|--------------------------------|
 | enabled        | paperplane.fill      | ✅       | ✅        | Default active state           |
 | disabled       | paperplane           | ✅       | ✅        | Unfilled paperplane (inactive) |
 | auto           | network              | ✅       | ✅        | PAC/Auto proxy mode            |
 | global         | globe                | ✅       | ✅        | Global proxy mode              |
 | manual         | gearshape.fill       | ✅       | ✅        | Manual configuration           |
 | externalPAC    | link.circle.fill     | ✅       | ✅        | External PAC URL               |

 ## Password Visibility Icons
 | State          | SF Symbol            | Legacy PNG                  | Description                    |
 |----------------|----------------------|-----------------------------|--------------------------------|
 | visible        | eye.fill             | icons8-Eye Filled-50        | Password is showing            |
 | hidden         | eye.slash.fill       | icons8-Blind Filled-50      | Password is hidden             |

 ## Menu Item Icons
 | Purpose        | SF Symbol            | Legacy PNG                  | Description                    |
 |----------------|----------------------|-----------------------------|--------------------------------|
 | HTTP export    | terminal.fill        | terminal-logo.png           | Export command to clipboard    |

 All symbols are available on macOS 11.0 (Big Sur)+
 No fallback needed as minimum deployment target is 11.0

 Benefits over PNG:
 - ✅ Automatic rendering for all display densities (1x, 2x, 3x)
 - ✅ Native dark mode support (no separate @dark assets)
 - ✅ Smaller app bundle size (~200KB savings)
 - ✅ Better accessibility (vector-based, crisp at any size)
 - ✅ Easier to maintain (no separate @2x files)
 - ✅ Consistent with macOS Human Interface Guidelines
 */
