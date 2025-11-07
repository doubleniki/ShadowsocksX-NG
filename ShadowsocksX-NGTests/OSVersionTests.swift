// OSVersionTests.swift
// Юнит-тесты для OSVersion утилиты

import XCTest

@testable import ShadowsocksX_NG

class OSVersionTests: XCTestCase {

  // MARK: - Version Detection Tests

  func testMinimumVersionIsAlwaysSupported() {
    // Big Sur - минимальная версия, всегда true
    XCTAssertTrue(OSVersion.isBigSurOrLater, "Big Sur должен всегда поддерживаться")
  }

  func testVersionStringIsNotEmpty() {
    let version = OSVersion.versionString
    XCTAssertFalse(version.isEmpty, "Version string не должен быть пустым")
    XCTAssertTrue(version.contains("."), "Version string должен содержать точку")
  }

  func testFullVersionStringFormat() {
    let fullVersion = OSVersion.fullVersionString
    let components = fullVersion.split(separator: ".")
    XCTAssertGreaterThanOrEqual(
      components.count, 2, "Full version должен иметь минимум 2 компонента")
  }

  func testCurrentVersionIsValid() {
    let version = OSVersion.current
    XCTAssertGreaterThanOrEqual(version.majorVersion, 11, "Major version должна быть >= 11")
  }

  // MARK: - Version Comparison Tests

  func testVersionComparisons() {
    let current = OSVersion.current

    // Проверяем логику версий
    if current.majorVersion >= 12 {
      XCTAssertTrue(OSVersion.isMontereyOrLater, "На macOS 12+ isMontereyOrLater должен быть true")
    }

    if current.majorVersion >= 13 {
      XCTAssertTrue(OSVersion.isVenturaOrLater, "На macOS 13+ isVenturaOrLater должен быть true")
    }

    if current.majorVersion >= 14 {
      XCTAssertTrue(OSVersion.isSonomaOrLater, "На macOS 14+ isSonomaOrLater должен быть true")
    }
  }

  // MARK: - Feature Availability Tests

  func testSFSymbols3Availability() {
    let expected = OSVersion.isMontereyOrLater
    XCTAssertEqual(
      OSVersion.supportsSFSymbols3, expected,
      "SF Symbols 3 должен быть доступен на Monterey+")
  }

  func testSFSymbols4Availability() {
    let expected = OSVersion.isSonomaOrLater
    XCTAssertEqual(
      OSVersion.supportsSFSymbols4, expected,
      "SF Symbols 4 должен быть доступен на Sonoma+")
  }

  func testAppIntentsAvailability() {
    let expected = OSVersion.isVenturaOrLater
    XCTAssertEqual(
      OSVersion.supportsAppIntents, expected,
      "App Intents должен быть доступен на Ventura+")
  }

  func testWidgetsAvailability() {
    let expected = OSVersion.isSonomaOrLater
    XCTAssertEqual(
      OSVersion.supportsWidgets, expected,
      "Widgets должен быть доступен на Sonoma+")
  }

  func testMenuBarExtrasAvailability() {
    let expected = OSVersion.isVenturaOrLater
    XCTAssertEqual(
      OSVersion.supportsMenuBarExtras, expected,
      "Menu Bar Extras должен быть доступен на Ventura+")
  }

  // MARK: - SF Symbols Tests

  func testBasicSFSymbolsAreAvailable() {
    // Базовые символы должны быть доступны на Big Sur+
    XCTAssertTrue(OSVersion.symbolAvailable("star.fill"), "star.fill должен быть доступен")
    XCTAssertTrue(OSVersion.symbolAvailable("circle.fill"), "circle.fill должен быть доступен")
    XCTAssertTrue(OSVersion.symbolAvailable("square.fill"), "square.fill должен быть доступен")
  }

  func testSymbolReturnsValidImage() {
    let image = OSVersion.symbol(primary: "star.fill")
    XCTAssertNotNil(image, "Symbol должен вернуть NSImage")
  }

  func testSymbolWithFallback() {
    let image = OSVersion.symbol(primary: "nonexistent.symbol", fallback: "star.fill")
    XCTAssertNotNil(image, "Symbol с fallback должен вернуть NSImage")
  }

  func testInvalidSymbolReturnsEmptyImage() {
    let available = OSVersion.symbolAvailable("definitely.not.a.real.symbol.name.12345")
    XCTAssertFalse(available, "Несуществующий символ не должен быть доступен")
  }

  // MARK: - Conditional Execution Tests

  func testConditionalExecutionCallsOnCorrectVersion() {
    var montereyCodeExecuted = false
    var venturaCodeExecuted = false
    var sonomaCodeExecuted = false

    OSVersion.onMontereyOrLater {
      montereyCodeExecuted = true
    }

    OSVersion.onVenturaOrLater {
      venturaCodeExecuted = true
    }

    OSVersion.onSonomaOrLater {
      sonomaCodeExecuted = true
    }

    // Проверяем соответствие текущей версии
    if OSVersion.isMontereyOrLater {
      XCTAssertTrue(montereyCodeExecuted, "Monterey код должен выполниться на Monterey+")
    } else {
      XCTAssertFalse(montereyCodeExecuted, "Monterey код не должен выполниться на Big Sur")
    }

    if OSVersion.isVenturaOrLater {
      XCTAssertTrue(venturaCodeExecuted, "Ventura код должен выполниться на Ventura+")
    }

    if OSVersion.isSonomaOrLater {
      XCTAssertTrue(sonomaCodeExecuted, "Sonoma код должен выполниться на Sonoma+")
    }
  }

  func testRunWithFallbackReturnsCorrectValue() {
    let modernValue = "modern"
    let fallbackValue = "fallback"

    // Тест для Monterey
    let montereyResult = OSVersion.runWithFallback(
      onModern: { modernValue },
      fallback: { fallbackValue },
      minimumVersion: .monterey
    )

    if OSVersion.isMontereyOrLater {
      XCTAssertEqual(montereyResult, modernValue, "Должен вернуть modern value на Monterey+")
    } else {
      XCTAssertEqual(montereyResult, fallbackValue, "Должен вернуть fallback на Big Sur")
    }

    // Тест для Ventura
    let venturaResult = OSVersion.runWithFallback(
      onModern: { modernValue },
      fallback: { fallbackValue },
      minimumVersion: .ventura
    )

    if OSVersion.isVenturaOrLater {
      XCTAssertEqual(venturaResult, modernValue, "Должен вернуть modern value на Ventura+")
    } else {
      XCTAssertEqual(venturaResult, fallbackValue, "Должен вернуть fallback на Big Sur/Monterey")
    }
  }

  // MARK: - UI Helpers Tests

  func testCreateModernTableView() {
    let tableView = OSVersion.createModernTableView()

    XCTAssertNotNil(tableView, "Table view должен быть создан")
    XCTAssertEqual(tableView.style, .fullWidth, "Table view должен иметь fullWidth стиль")
    XCTAssertTrue(
      tableView.usesAlternatingRowBackgroundColors,
      "Table view должен использовать alternating colors")
  }

  func testApplyModernMaterialToWindow() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
      styleMask: [.titled],
      backing: .buffered,
      defer: false
    )

    let initialContentView = window.contentView
    XCTAssertNotNil(initialContentView, "Content view должен существовать")

    OSVersion.applyModernMaterial(to: window)

    // Проверяем, что visual effect view был добавлен
    let hasVisualEffectView =
      initialContentView?.subviews.contains { $0 is NSVisualEffectView } ?? false
    XCTAssertTrue(hasVisualEffectView, "Visual effect view должен быть добавлен")
  }

  // MARK: - Validation Tests

  func testValidateMinimumVersion() {
    let isValid = OSVersion.validateMinimumVersion()

    // На любой тестовой машине с macOS 11.0+ должно быть valid
    let current = OSVersion.current
    if current.majorVersion >= 11 {
      XCTAssertTrue(isValid, "Версия должна быть валидной на macOS 11.0+")
    }
  }

  // MARK: - Performance Tests

  func testVersionCheckPerformance() {
    measure {
      // Проверяем производительность множественных проверок
      for _ in 0..<1000 {
        _ = OSVersion.isMontereyOrLater
        _ = OSVersion.isVenturaOrLater
        _ = OSVersion.isSonomaOrLater
      }
    }
  }

  func testSymbolLoadingPerformance() {
    measure {
      // Проверяем производительность загрузки символов
      for _ in 0..<100 {
        _ = OSVersion.symbol(primary: "star.fill")
      }
    }
  }

  // MARK: - Edge Cases Tests

  func testEmptySymbolName() {
    let available = OSVersion.symbolAvailable("")
    XCTAssertFalse(available, "Пустое имя символа не должно быть доступно")
  }

  func testSymbolWithSpecialCharacters() {
    // Символы с цифрами существуют (например, "square.grid.2x2")
    let exists = OSVersion.symbolAvailable("square.grid.2x2")
    // Этот символ доступен на Big Sur+
    XCTAssertTrue(exists, "Символ с цифрами должен быть доступен")
  }

  // MARK: - Integration Tests

  func testRealWorldScenario() {
    // Имитация реального использования

    // 1. Проверка минимальной версии
    guard OSVersion.validateMinimumVersion() else {
      XCTFail("Минимальная версия не поддерживается")
      return
    }

    // 2. Получение иконок
    let statusIcon = OSVersion.symbol(primary: "paperplane.fill")
    XCTAssertNotNil(statusIcon, "Status icon должен быть доступен")

    // 3. Создание UI компонентов
    let tableView = OSVersion.createModernTableView()
    XCTAssertNotNil(tableView, "Table view должен быть создан")

    // 4. Условная настройка фич
    var featuresConfigured = false
    OSVersion.onMontereyOrLater {
      featuresConfigured = true
    }

    if OSVersion.isMontereyOrLater {
      XCTAssertTrue(featuresConfigured, "Features должны быть настроены")
    }
  }

  // MARK: - Debug Helper Tests

  func testPrintSystemInfoDoesNotCrash() {
    // Просто проверяем, что метод не крашится
    XCTAssertNoThrow(OSVersion.printSystemInfo())
  }
}
