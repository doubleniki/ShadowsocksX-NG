// OSVersion.swift
// Централизованная система проверки версий macOS
// Минимальная поддерживаемая версия: macOS 11.0 Big Sur
//
// QUICK REFERENCE:
//
// Проверка версии:
//   OSVersion.isMontereyOrLater, .isVenturaOrLater, .isSonomaOrLater
//
// Проверка фич:
//   OSVersion.supportsWidgets, .supportsAppIntents, .supportsSFSymbols3
//
// Условное выполнение:
//   OSVersion.onVenturaOrLater { setupFeature() }
//
// SF Symbols:
//   OSVersion.symbol(primary: "star.fill", fallback: "star")
//
// UI Helpers:
//   OSVersion.createModernTableView()
//   OSVersion.applyModernMaterial(to: window)
//
// Подробности: docs/ui-modernization/VERSION_DETECTION_GUIDE.md

import AppKit
import Foundation

// MARK: - OS Version Detection

/// Утилита для определения версии macOS и доступности фич
enum OSVersion {

  // MARK: - Version Checks

  /// macOS 11.0 Big Sur (минимальная версия, всегда true)
  static let isBigSurOrLater = true

  /// macOS 12.0 Monterey или новее
  static var isMontereyOrLater: Bool {
    if #available(macOS 12.0, *) { return true }
    return false
  }

  /// macOS 13.0 Ventura или новее
  static var isVenturaOrLater: Bool {
    if #available(macOS 13.0, *) { return true }
    return false
  }

  /// macOS 14.0 Sonoma или новее
  static var isSonomaOrLater: Bool {
    if #available(macOS 14.0, *) { return true }
    return false
  }

  /// macOS 15.0 Sequoia или новее
  static var isSequoiaOrLater: Bool {
    if #available(macOS 15.0, *) { return true }
    return false
  }

  // MARK: - Feature Availability

  /// SF Symbols 3+ (Monterey)
  static var supportsSFSymbols3: Bool {
    isMontereyOrLater
  }

  /// SF Symbols 4+ (Sonoma)
  static var supportsSFSymbols4: Bool {
    isSonomaOrLater
  }

  /// App Intents (Ventura)
  static var supportsAppIntents: Bool {
    isVenturaOrLater
  }

  /// WidgetKit (Sonoma)
  static var supportsWidgets: Bool {
    isSonomaOrLater
  }

  /// Menu Bar Extras API (Ventura)
  static var supportsMenuBarExtras: Bool {
    isVenturaOrLater
  }

  // MARK: - Detailed Version Info

  /// Текущая версия операционной системы
  static var current: OperatingSystemVersion {
    ProcessInfo.processInfo.operatingSystemVersion
  }

  /// Строковое представление версии (например, "14.0")
  static var versionString: String {
    let version = current
    return "\(version.majorVersion).\(version.minorVersion)"
  }

  /// Полное строковое представление (например, "14.0.1")
  static var fullVersionString: String {
    let version = current
    return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
  }
}

// MARK: - Conditional Execution Helpers

extension OSVersion {

  /// Выполнить код только на Monterey+
  static func onMontereyOrLater(_ closure: () -> Void) {
    guard isMontereyOrLater else { return }
    closure()
  }

  /// Выполнить код только на Ventura+
  static func onVenturaOrLater(_ closure: () -> Void) {
    guard isVenturaOrLater else { return }
    closure()
  }

  /// Выполнить код только на Sonoma+
  static func onSonomaOrLater(_ closure: () -> Void) {
    guard isSonomaOrLater else { return }
    closure()
  }

  /// Выполнить код с fallback для старых версий
  static func runWithFallback<T>(
    onModern: () -> T,
    fallback: () -> T,
    minimumVersion: MinimumVersion
  ) -> T {
    switch minimumVersion {
    case .monterey:
      return isMontereyOrLater ? onModern() : fallback()
    case .ventura:
      return isVenturaOrLater ? onModern() : fallback()
    case .sonoma:
      return isSonomaOrLater ? onModern() : fallback()
    case .sequoia:
      return isSequoiaOrLater ? onModern() : fallback()
    }
  }

  enum MinimumVersion {
    case monterey
    case ventura
    case sonoma
    case sequoia
  }
}

// MARK: - SF Symbols Helpers

extension OSVersion {

  /// Получить SF Symbol с fallback для старых версий символов
  /// - Parameters:
  ///   - primary: Основной символ (может требовать новую версию)
  ///   - fallback: Fallback символ для Big Sur
  /// - Returns: NSImage с символом
  static func symbol(primary: String, fallback: String? = nil) -> NSImage {
    // Попробовать основной символ
    if let image = NSImage(systemSymbolName: primary, accessibilityDescription: nil) {
      return image
    }

    // Попробовать fallback
    if let fallbackName = fallback,
      let image = NSImage(systemSymbolName: fallbackName, accessibilityDescription: nil)
    {
      return image
    }

    // Вернуть пустое изображение
    return NSImage()
  }

  /// Проверить доступность конкретного SF Symbol
  static func symbolAvailable(_ name: String) -> Bool {
    NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
  }
}

// MARK: - UI Helpers

extension OSVersion {

  /// Создать NSTableView с современными настройками
  static func createModernTableView() -> NSTableView {
    let tableView = NSTableView()
    tableView.style = .fullWidth
    tableView.usesAlternatingRowBackgroundColors = true

    onMontereyOrLater {
      if #available(macOS 12.0, *) {
        tableView.rowSizeStyle = .default
      }
    }

    return tableView
  }

  /// Применить современные материалы к окну
  static func applyModernMaterial(to window: NSWindow) {
    guard let contentView = window.contentView else { return }

    let effectView = NSVisualEffectView()
    effectView.frame = contentView.bounds
    effectView.autoresizingMask = [.width, .height]
    effectView.material = .hudWindow
    effectView.blendingMode = .behindWindow
    effectView.state = .active

    // Улучшенные материалы на новых версиях
    onMontereyOrLater {
      if #available(macOS 12.0, *) {
        effectView.material = .sidebar
      }
    }

    contentView.addSubview(effectView, positioned: .below, relativeTo: nil)
  }
}

// MARK: - Property Wrapper для версионных фич

/// Property wrapper для ленивой инициализации версионно-зависимых фич
@propertyWrapper
struct VersionDependent<T> {
  private let builder: () -> T?
  private let fallback: T
  private var cached: T?

  var wrappedValue: T {
    mutating get {
      if cached == nil {
        cached = builder() ?? fallback
      }
      return cached!
    }
  }

  init(minimumVersion: OSVersion.MinimumVersion, builder: @escaping () -> T, fallback: T) {
    self.fallback = fallback
    self.builder = {
      let isSupported: Bool
      switch minimumVersion {
      case .monterey: isSupported = OSVersion.isMontereyOrLater
      case .ventura: isSupported = OSVersion.isVenturaOrLater
      case .sonoma: isSupported = OSVersion.isSonomaOrLater
      case .sequoia: isSupported = OSVersion.isSequoiaOrLater
      }
      return isSupported ? builder() : nil
    }
  }
}

// MARK: - Debug Helpers

extension OSVersion {

  /// Вывести информацию о текущей системе в консоль
  static func printSystemInfo() {
    print("=== System Information ===")
    print("macOS Version: \(fullVersionString)")
    print("Minimum Supported: 11.0 (Big Sur)")
    print("")
    print("Feature Support:")
    print("  SF Symbols 3: \(supportsSFSymbols3)")
    print("  SF Symbols 4: \(supportsSFSymbols4)")
    print("  App Intents: \(supportsAppIntents)")
    print("  Widgets: \(supportsWidgets)")
    print("  Menu Bar Extras: \(supportsMenuBarExtras)")
    print("=========================")
  }

  /// Проверить соответствие минимальным требованиям
  static func validateMinimumVersion() -> Bool {
    let version = current
    guard version.majorVersion >= 11 else {
      NSLog("⚠️ Unsupported macOS version: \(fullVersionString). Minimum required: 11.0")
      return false
    }
    return true
  }
}
