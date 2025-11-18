//
//  NSColor+Semantic.swift
//  ShadowsocksX-NG
//
//  Created for UI Modernization Phase 2
//  Copyright © 2025 qiuyuzhou. All rights reserved.
//

import Cocoa

/// Extension providing semantic colors for UI modernization.
///
/// This extension provides semantic color helpers that automatically adapt to
/// dark mode and system appearance changes. Use these instead of hardcoded RGB values.
///
/// **Benefits:**
/// - Automatic dark mode support
/// - Better accessibility
/// - Follows macOS Human Interface Guidelines
/// - Consistent with system appearance
///
/// **Availability:** macOS 11.0+
extension NSColor {

    // MARK: - Toast/HUD Colors

    /// Background color for toast/HUD windows.
    ///
    /// Adapts to system appearance:
    /// - Light mode: Dark gray with transparency
    /// - Dark mode: Lighter gray with transparency
    ///
    /// This replaces hardcoded `CGColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 0.75)`
    static var toastBackground: NSColor {
        if #available(macOS 10.14, *) {
            // Modern semantic color with vibrancy support
            return NSColor(name: nil) { appearance in
                if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                    // Dark mode: Lighter background for better contrast
                    return NSColor(white: 0.15, alpha: 0.85)
                } else {
                    // Light mode: Dark background
                    return NSColor(white: 0.05, alpha: 0.75)
                }
            }
        } else {
            // Fallback for older macOS versions
            return NSColor(white: 0.05, alpha: 0.75)
        }
    }

    /// Foreground (text) color for toast/HUD windows.
    ///
    /// Automatically adapts for high contrast against toast background.
    static var toastForeground: NSColor {
        return .labelColor  // System-provided semantic color
    }

    // MARK: - QR Code Colors

    /// Overlay text color for QR code windows.
    ///
    /// A vibrant green color for "SIP002" and "Legacy" labels on QR codes.
    /// Adapts to system appearance for better visibility.
    ///
    /// This replaces hardcoded `NSColor(red: 28/255.0, green: 155/255.0, blue: 71/255.0, alpha: 1)`
    static var qrCodeOverlayText: NSColor {
        if #available(macOS 10.14, *) {
            return NSColor(name: nil) { appearance in
                if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                    // Dark mode: Brighter green for better visibility
                    return NSColor(red: 50/255.0, green: 200/255.0, blue: 100/255.0, alpha: 1.0)
                } else {
                    // Light mode: Original green
                    return NSColor(red: 28/255.0, green: 155/255.0, blue: 71/255.0, alpha: 1.0)
                }
            }
        } else {
            return NSColor(red: 28/255.0, green: 155/255.0, blue: 71/255.0, alpha: 1.0)
        }
    }

    /// Background color for QR code overlay text.
    ///
    /// Provides good contrast behind overlay text on QR codes.
    /// Uses system background color for automatic dark mode support.
    ///
    /// This replaces hardcoded `NSColor.white`
    static var qrCodeOverlayBackground: NSColor {
        if #available(macOS 10.14, *) {
            return .windowBackgroundColor  // Adapts to dark mode
        } else {
            return .white
        }
    }

    // MARK: - Utility Methods

    /// Convert NSColor to CGColor for use with CALayer.
    ///
    /// This is a convenience method for converting semantic NSColors to CGColors
    /// when working with Core Animation layers.
    ///
    /// - Returns: CGColor representation of this color
    func toCGColor() -> CGColor {
        guard let cgColor = self.cgColor else {
            // Fallback: Convert through color space if direct conversion fails
            let components = self.cgColor.components ?? [0, 0, 0, 1]
            return CGColor(
                colorSpace: CGColorSpaceCreateDeviceRGB(),
                components: components
            )!
        }
        return cgColor
    }
}
