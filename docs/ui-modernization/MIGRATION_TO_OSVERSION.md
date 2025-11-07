# Миграция на OSVersion утилиту

## Краткая инструкция по рефакторингу существующего кода

Этот документ поможет быстро мигрировать существующий код на использование утилиты `OSVersion`.

---

## Чеклист миграции

### Шаг 1: Найти все проверки версий

```bash
# Найти все #available проверки
grep -r "#available" ShadowsocksX-NG/ --include="*.swift"

# Найти проверки ProcessInfo
grep -r "ProcessInfo.*operatingSystemVersion" ShadowsocksX-NG/ --include="*.swift"
```

### Шаг 2: Заменить паттерны

#### До → После

| До (старый код) | После (OSVersion) |
|----------------|-------------------|
| `if #available(macOS 12.0, *) { }` | `if OSVersion.isMontereyOrLater { }` |
| `if #available(macOS 13.0, *) { }` | `if OSVersion.isVenturaOrLater { }` |
| `if #available(macOS 14.0, *) { }` | `if OSVersion.isSonomaOrLater { }` |
| `NSImage(systemSymbolName: "star.fill")!` | `OSVersion.symbol(primary: "star.fill")` |

### Шаг 3: Примеры конкретных замен

#### Пример 1: Простая проверка версии

```swift
// ДО
if #available(macOS 12.0, *) {
    tableView.rowSizeStyle = .default
}

// ПОСЛЕ
if OSVersion.isMontereyOrLater {
    if #available(macOS 12.0, *) {
        tableView.rowSizeStyle = .default
    }
}

// ЕЩЕ ЛУЧШЕ (с conditional execution)
OSVersion.onMontereyOrLater {
    if #available(macOS 12.0, *) {
        tableView.rowSizeStyle = .default
    }
}
```

#### Пример 2: Повторяющиеся проверки

```swift
// ДО - дублирование по всему коду
// В файле A:
if #available(macOS 13.0, *) {
    setupAppIntents()
}

// В файле B:
if #available(macOS 13.0, *) {
    configureIntents()
}

// ПОСЛЕ - единая проверка
// В обоих файлах:
if OSVersion.supportsAppIntents {
    setupAppIntents()
}

if OSVersion.supportsAppIntents {
    configureIntents()
}
```

#### Пример 3: SF Symbols

```swift
// ДО
func getIcon() -> NSImage {
    if #available(macOS 11.0, *) {
        if let image = NSImage(systemSymbolName: "star.fill",
                               accessibilityDescription: nil) {
            return image
        }
    }
    return NSImage(named: "star-icon") ?? NSImage()
}

// ПОСЛЕ
func getIcon() -> NSImage {
    return OSVersion.symbol(primary: "star.fill")
}
```

#### Пример 4: Feature flags

```swift
// ДО - разбросано по коду
func applicationDidFinishLaunching(_ notification: Notification) {
    setupBasicFeatures()

    if #available(macOS 14.0, *) {
        setupWidgets()
    }

    if #available(macOS 13.0, *) {
        setupAppIntents()
    }
}

// ПОСЛЕ
func applicationDidFinishLaunching(_ notification: Notification) {
    setupBasicFeatures()

    if OSVersion.supportsWidgets {
        if #available(macOS 14.0, *) {
            setupWidgets()
        }
    }

    if OSVersion.supportsAppIntents {
        if #available(macOS 13.0, *) {
            setupAppIntents()
        }
    }
}

// ЕЩЕ ЛУЧШЕ - вынести в отдельный метод
func applicationDidFinishLaunching(_ notification: Notification) {
    setupBasicFeatures()
    setupVersionSpecificFeatures()
}

private func setupVersionSpecificFeatures() {
    OSVersion.onSonomaOrLater {
        if #available(macOS 14.0, *) {
            setupWidgets()
        }
    }

    OSVersion.onVenturaOrLater {
        if #available(macOS 13.0, *) {
            setupAppIntents()
        }
    }
}
```

---

## Автоматизация поиска и замены

### Regex паттерны для поиска

1. **Найти все #available проверки:**

   ```regex
   if\s+#available\(macOS\s+(\d+\.\d+),\s*\*\)
   ```

2. **Найти создание SF Symbols:**

   ```regex
   NSImage\(systemSymbolName:\s*"[^"]+"\s*[,)]
   ```

3. **Найти feature flags:**

   ```regex
   if\s+#available\(macOS\s+1[3-5]\.\d+,\s*\*\)\s*\{[^}]*setup
   ```

### Скрипт для поиска кандидатов на замену

```bash
#!/bin/bash
# find_migration_candidates.sh

echo "=== Checking for migration candidates ==="
echo ""

echo "1. #available checks for macOS 12.0+:"
grep -rn "if #available(macOS 12" ShadowsocksX-NG/ --include="*.swift" | wc -l

echo "2. #available checks for macOS 13.0+:"
grep -rn "if #available(macOS 13" ShadowsocksX-NG/ --include="*.swift" | wc -l

echo "3. #available checks for macOS 14.0+:"
grep -rn "if #available(macOS 14" ShadowsocksX-NG/ --include="*.swift" | wc -l

echo "4. Direct NSImage(systemSymbolName:) calls:"
grep -rn "NSImage(systemSymbolName:" ShadowsocksX-NG/ --include="*.swift" | wc -l

echo ""
echo "Run with --details for full list"

if [ "$1" == "--details" ]; then
    echo ""
    echo "=== Detailed results ==="
    grep -rn "if #available(macOS 1[2-5]" ShadowsocksX-NG/ --include="*.swift"
fi
```

---

## Приоритеты миграции

### Высокий приоритет (сделать первым)

1. ✅ **Повторяющиеся проверки версий** - больше всего выигрыша
2. ✅ **Feature flags** (widgets, app intents) - улучшение читаемости
3. ✅ **SF Symbols без fallback** - потенциальные крэши

### Средний приоритет

4. ⚠️ **Простые #available проверки** - косметическое улучшение
5. ⚠️ **UI helpers** - удобство

### Низкий приоритет

6. 📝 **Единичные проверки** - если уже редактируете файл
7. 📝 **Комментарии и документация** - по мере возможности

---

## Тестирование после миграции

### Чек-лист

- [ ] Код компилируется без ошибок
- [ ] Линтер не показывает новых предупреждений
- [ ] Юнит-тесты проходят
- [ ] Вручную протестировано на macOS 11.0 (если доступно)
- [ ] Вручную протестировано на текущей версии
- [ ] Проверены все пути с fallback

### Команды для проверки

```bash
# Компиляция
xcodebuild -workspace ShadowsocksX-NG.xcworkspace \
           -scheme ShadowsocksX-NG \
           -configuration Debug \
           build

# Линтер
swiftlint lint --strict

# Тесты
xcodebuild -workspace ShadowsocksX-NG.xcworkspace \
           -scheme ShadowsocksX-NG \
           -configuration Debug \
           test
```

---

## FAQ по миграции

**Q: Нужно ли мигрировать весь код сразу?**

A: Нет. Можно мигрировать постепенно, файл за файлом. Старый и новый подходы совместимы.

**Q: Что делать с `@available` аннотациями на функциях?**

A: Оставить их! `@available` на функциях нужен для безопасности типов. `OSVersion` только упрощает проверки перед вызовом.

```swift
// Правильно - оба используются вместе
if OSVersion.supportsAppIntents {
    setupIntents() // Эта функция помечена @available
}

@available(macOS 13.0, *)
func setupIntents() {
    // Код использующий App Intents API
}
```

**Q: Как мигрировать сложные условия?**

A: Разбить на несколько проверок:

```swift
// ДО
if #available(macOS 13.0, *) {
    if userEnabled && hasPermission {
        setupFeature()
    }
}

// ПОСЛЕ
if OSVersion.supportsAppIntents && userEnabled && hasPermission {
    if #available(macOS 13.0, *) {
        setupFeature()
    }
}
```

**Q: Что если нужна проверка на конкретную patch версию?**

A: Используйте `OSVersion.current` напрямую:

```swift
let version = OSVersion.current
if version.majorVersion == 13 && version.minorVersion >= 2 {
    // Специфичная проверка для 13.2+
}
```

**Q: Можно ли расширять OSVersion своими проверками?**

A: Да! Добавляйте в extension:

```swift
extension OSVersion {
    static var supportsMyNewFeature: Bool {
        if #available(macOS 15.0, *) { return true }
        return false
    }
}
```

---

## Примеры коммитов

### Хорошие commit messages

```
refactor: migrate version checks to OSVersion utility

- Replace #available checks with OSVersion.isVenturaOrLater
- Use OSVersion.supportsAppIntents for feature detection
- Simplify SF Symbols loading with OSVersion.symbol()

Files changed: AppDelegate.swift, PreferencesController.swift
```

```
refactor: use OSVersion helpers for UI components

- Replace manual table view setup with OSVersion.createModernTableView()
- Apply modern materials using OSVersion.applyModernMaterial()

Files changed: ServerListViewController.swift
```

---

## Полезные ссылки

- [OSVersion.swift](../../ShadowsocksX-NG/OSVersion.swift) - исходный код утилиты
- [VERSION_DETECTION_GUIDE.md](./VERSION_DETECTION_GUIDE.md) - полное руководство
- [BACKWARD_COMPATIBILITY.md](./BACKWARD_COMPATIBILITY.md) - общие паттерны

---

**Создан:** 2025-11-07
**Для версии:** macOS 11.0+ (Big Sur baseline)
