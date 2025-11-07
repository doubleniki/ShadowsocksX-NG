# Руководство по определению версий macOS

## Обзор

Начиная с v2.0, минимальная поддерживаемая версия — macOS 11.0 Big Sur. Для упрощения работы с версиями и избежания boilerplate кода используйте утилиту `OSVersion`.

---

## Быстрый старт

### До (много boilerplate)

```swift
// Проверка версии - повторяется везде
if #available(macOS 12.0, *) {
    // Код для Monterey
} else {
    // Fallback для Big Sur
}

// Проверка SF Symbol
if #available(macOS 11.0, *) {
    if let image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil) {
        return image
    }
}

// Проверка фичи
if #available(macOS 13.0, *) {
    setupAppIntents()
}
```

### После (чистый код)

```swift
// Простая проверка версии
if OSVersion.isMontereyOrLater {
    // Код для Monterey
}

// Проверка фичи
if OSVersion.supportsAppIntents {
    setupAppIntents()
}

// SF Symbol с fallback
let icon = OSVersion.symbol(primary: "star.fill")

// Условное выполнение
OSVersion.onVenturaOrLater {
    setupAdvancedFeatures()
}
```

---

## Основные возможности

### 1. Проверка версий

```swift
// Простые булевы свойства
if OSVersion.isBigSurOrLater { } // Всегда true
if OSVersion.isMontereyOrLater { }
if OSVersion.isVenturaOrLater { }
if OSVersion.isSonomaOrLater { }
if OSVersion.isSequoiaOrLater { }

// Получить версию как строку
let version = OSVersion.versionString // "14.0"
let full = OSVersion.fullVersionString // "14.0.1"
```

### 2. Проверка доступности фич

```swift
// Вместо запоминания, какая версия что поддерживает
if OSVersion.supportsSFSymbols3 {
    // Monterey+ символы
}

if OSVersion.supportsAppIntents {
    // Ventura+ App Intents
}

if OSVersion.supportsWidgets {
    // Sonoma+ WidgetKit
}

if OSVersion.supportsMenuBarExtras {
    // Ventura+ Menu Bar Extras API
}
```

### 3. Условное выполнение

```swift
// Выполнить только на определенной версии
OSVersion.onMontereyOrLater {
    setupMontereyFeature()
}

OSVersion.onVenturaOrLater {
    registerAppIntents()
}

// С возвращаемым значением и fallback
let result = OSVersion.runWithFallback(
    onModern: {
        return computeUsingModernAPI()
    },
    fallback: {
        return computeUsingLegacyAPI()
    },
    minimumVersion: .ventura
)
```

### 4. SF Symbols упрощение

```swift
// Простое получение символа
let playIcon = OSVersion.symbol(primary: "play.fill")

// С fallback для старых версий SF Symbols
let advancedIcon = OSVersion.symbol(
    primary: "square.stack.3d.up.fill", // SF Symbols 3+
    fallback: "square.stack.fill" // SF Symbols 1/2
)

// Проверить доступность символа
if OSVersion.symbolAvailable("new.symbol.name") {
    // Использовать новый символ
}
```

### 5. UI Helpers

```swift
// Создать современный table view
let tableView = OSVersion.createModernTableView()
// Автоматически применит .fullWidth и другие настройки

// Применить материалы к окну
OSVersion.applyModernMaterial(to: window)
// Автоматически выберет лучший материал для версии
```

---

## Практические примеры

### Пример 1: Настройка иконок

```swift
class IconProvider {
    static var serverIcon: NSImage {
        OSVersion.symbol(
            primary: "server.rack", // Предпочтительный символ
            fallback: "square.grid.2x2" // Fallback
        )
    }

    static var connectionIcon: NSImage {
        OSVersion.symbol(primary: "network")
    }

    static var statusIcon: NSImage {
        if OSVersion.supportsSFSymbols4 {
            return OSVersion.symbol(primary: "light.beacon.max.fill")
        } else {
            return OSVersion.symbol(primary: "dot.radiowaves.left.and.right")
        }
    }
}
```

### Пример 2: Настройка окна

```swift
class PreferencesWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()

        guard let window = window else { return }

        // Базовая настройка (Big Sur+)
        window.titlebarAppearsTransparent = true

        // Улучшения для новых версий
        OSVersion.onMontereyOrLater {
            if #available(macOS 12.0, *) {
                window.toolbarStyle = .unified
            }
        }

        OSVersion.onVenturaOrLater {
            if #available(macOS 13.0, *) {
                window.titlebarSeparatorStyle = .none
            }
        }

        // Применить материалы
        OSVersion.applyModernMaterial(to: window)
    }
}
```

### Пример 3: Feature flag

```swift
class FeatureManager {

    // Простые feature flags на основе версии
    var widgetsEnabled: Bool {
        OSVersion.supportsWidgets
    }

    var appIntentsEnabled: Bool {
        OSVersion.supportsAppIntents
    }

    func setupFeatures() {
        // Базовые фичи (Big Sur+)
        setupStatusBar()
        setupMenuBar()

        // Условные фичи
        OSVersion.onVenturaOrLater {
            self.setupAppIntents()
        }

        OSVersion.onSonomaOrLater {
            self.setupWidgets()
        }
    }

    @available(macOS 13.0, *)
    private func setupAppIntents() {
        // App Intents код
    }

    @available(macOS 14.0, *)
    private func setupWidgets() {
        // Widget код
    }
}
```

### Пример 4: Property Wrapper для ленивых фич

```swift
class AppDelegate: NSObject, NSApplicationDelegate {

    // Лениво инициализируется только на поддерживаемых версиях
    @VersionDependent(
        minimumVersion: .ventura,
        builder: {
            if #available(macOS 13.0, *) {
                return AppIntentsManager()
            }
            return nil
        },
        fallback: EmptyIntentsManager()
    )
    var intentsManager: IntentsManager

    func applicationDidFinishLaunching(_ notification: Notification) {
        // intentsManager автоматически будет правильным для версии
        intentsManager.register()
    }
}
```

### Пример 5: Table View с версионными улучшениями

```swift
class ServerListViewController: NSViewController {

    private lazy var tableView: NSTableView = {
        let table = OSVersion.createModernTableView()

        // Дополнительные настройки
        table.rowSizeStyle = .default
        table.allowsMultipleSelection = true

        // Улучшения для Monterey+
        OSVersion.onMontereyOrLater {
            if #available(macOS 12.0, *) {
                table.effectiveRowSizeStyle = .medium
            }
        }

        return table
    }()
}
```

### Пример 6: Цвета и стили

```swift
extension NSColor {

    // Статические цвета (Big Sur+ всегда поддерживает)
    static var appPrimaryBackground: NSColor {
        .controlBackgroundColor
    }

    static var appSecondaryBackground: NSColor {
        .textBackgroundColor
    }

    // Расширенные цвета для новых версий
    static var appAccentBackground: NSColor {
        OSVersion.runWithFallback(
            onModern: {
                if #available(macOS 12.0, *) {
                    return .controlAccentColor.withAlphaComponent(0.1)
                }
                return .controlAccentColor
            },
            fallback: {
                return .controlAccentColor
            },
            minimumVersion: .monterey
        )
    }
}
```

---

## Отладка и диагностика

### Вывести информацию о системе

```swift
// В applicationDidFinishLaunching или при запуске
OSVersion.printSystemInfo()

// Выведет:
// === System Information ===
// macOS Version: 14.0.1
// Minimum Supported: 11.0 (Big Sur)
//
// Feature Support:
//   SF Symbols 3: true
//   SF Symbols 4: true
//   App Intents: true
//   Widgets: true
//   Menu Bar Extras: true
// =========================
```

### Проверить минимальную версию при запуске

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    // Проверить, что пользователь на поддерживаемой версии
    guard OSVersion.validateMinimumVersion() else {
        showUnsupportedVersionAlert()
        NSApp.terminate(nil)
        return
    }

    // Продолжить загрузку...
}

func showUnsupportedVersionAlert() {
    let alert = NSAlert()
    alert.messageText = "Unsupported macOS Version"
    alert.informativeText = """
        This version of ShadowsocksX-NG requires macOS 11.0 (Big Sur) or later.
        Your current version: \(OSVersion.fullVersionString)

        Please upgrade your macOS or download an older version of the app.
        """
    alert.alertStyle = .critical
    alert.runModal()
}
```

---

## Best Practices

### ✅ DO

1. **Используйте OSVersion для всех проверок версий**

   ```swift
   if OSVersion.isVenturaOrLater { }
   ```

2. **Используйте feature flags вместо прямых проверок версий**

   ```swift
   if OSVersion.supportsAppIntents { }
   ```

3. **Используйте conditional execution для опциональных фич**

   ```swift
   OSVersion.onSonomaOrLater {
       setupWidgets()
   }
   ```

4. **Добавляйте новые feature flags в OSVersion при необходимости**

### ❌ DON'T

1. **Не используйте прямые `#available` проверки без необходимости**

   ```swift
   // Плохо - boilerplate
   if #available(macOS 13.0, *) { }

   // Хорошо - читаемо
   if OSVersion.supportsAppIntents { }
   ```

2. **Не дублируйте проверки версий по всему коду**

   ```swift
   // Плохо - дублирование
   if #available(macOS 13.0, *) {
       setupAppIntents()
   }
   // В другом месте
   if #available(macOS 13.0, *) {
       configureAppIntents()
   }

   // Хорошо - один feature flag
   if OSVersion.supportsAppIntents {
       setupAppIntents()
       configureAppIntents()
   }
   ```

3. **Не забывайте про fallback для фич**

---

## Расширение OSVersion

При добавлении новых фич:

```swift
// В OSVersion.swift
extension OSVersion {

    /// Новая фича в macOS 16.0
    static var supportsNewFeature: Bool {
        if #available(macOS 16.0, *) { return true }
        return false
    }

    /// Helper для новой фичи
    static func onNewVersionOrLater(_ closure: () -> Void) {
        guard supportsNewFeature else { return }
        closure()
    }
}

// Использование
if OSVersion.supportsNewFeature {
    enableNewFeature()
}
```

---

## Тестирование

### Unit тесты

```swift
class OSVersionTests: XCTestCase {

    func testMinimumVersion() {
        // Big Sur всегда поддерживается
        XCTAssertTrue(OSVersion.isBigSurOrLater)
    }

    func testVersionString() {
        let version = OSVersion.versionString
        XCTAssertFalse(version.isEmpty)
    }

    func testSymbolAvailability() {
        // Базовые символы всегда доступны на Big Sur+
        XCTAssertTrue(OSVersion.symbolAvailable("star.fill"))
        XCTAssertTrue(OSVersion.symbolAvailable("circle.fill"))
    }
}
```

---

## FAQ

**Q: Нужно ли использовать `@available` вообще?**

A: Да, но только внутри функций, которые используют новые API. `OSVersion` упрощает проверку, но компилятор все равно требует `@available` при вызове новых API:

```swift
// OSVersion убирает boilerplate проверки
if OSVersion.supportsAppIntents {
    setupIntents() // Эта функция должна быть помечена @available
}

@available(macOS 13.0, *)
func setupIntents() {
    // Новые API здесь
}
```

**Q: Что если мне нужна специфичная проверка, которой нет в OSVersion?**

A: Добавьте ее в расширение `OSVersion` и сделайте PR. Либо используйте прямой `#available` для специфичных случаев.

**Q: Как тестировать код на разных версиях?**

A: Используйте CI/CD матрицу с разными версиями macOS, либо локальные VM. `OSVersion.printSystemInfo()` поможет в отладке.

---

**Создан:** 2025-11-07
**Минимальная версия:** macOS 11.0 Big Sur
**Файл утилиты:** `ShadowsocksX-NG/OSVersion.swift`
