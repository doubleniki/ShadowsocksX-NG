# UI Modernization Documentation

Документация по модернизации пользовательского интерфейса ShadowsocksX-NG для macOS 11.0+

---

## 📚 Документы

### Основные руководства

1. **[BACKWARD_COMPATIBILITY.md](./BACKWARD_COMPATIBILITY.md)**
   - Быстрое руководство по обратной совместимости
   - Таблица поддержки версий и фич
   - Общие паттерны и best practices
   - Testing checklist

2. **[VERSION_DETECTION_GUIDE.md](./VERSION_DETECTION_GUIDE.md)** ⭐
   - Полное руководство по утилите `OSVersion`
   - Практические примеры использования
   - Best practices и FAQ
   - Рекомендуется прочитать первым!

3. **[MIGRATION_TO_OSVERSION.md](./MIGRATION_TO_OSVERSION.md)**
   - Инструкция по миграции существующего кода
   - Чеклист и приоритеты
   - Скрипты для поиска кандидатов на замену
   - Примеры рефакторинга

4. **[MODERNIZATION_ROADMAP.md](./MODERNIZATION_ROADMAP.md)**
   - Полный план модернизации UI
   - Roadmap по фазам
   - Архитектурные решения

---

## 🛠 Утилиты

### OSVersion - Централизованная проверка версий

**Файл:** `ShadowsocksX-NG/OSVersion.swift`
**Тесты:** `ShadowsocksX-NGTests/OSVersionTests.swift`

Утилита для упрощения работы с версиями macOS и избежания boilerplate кода.

#### Основные возможности

```swift
// Проверка версий
OSVersion.isMontereyOrLater
OSVersion.isVenturaOrLater
OSVersion.isSonomaOrLater

// Проверка фич
OSVersion.supportsWidgets
OSVersion.supportsAppIntents
OSVersion.supportsSFSymbols3

// Условное выполнение
OSVersion.onVenturaOrLater {
    setupAdvancedFeatures()
}

// SF Symbols
OSVersion.symbol(primary: "star.fill", fallback: "star")

// UI Helpers
OSVersion.createModernTableView()
OSVersion.applyModernMaterial(to: window)
```

---

## 🎯 Быстрый старт

### Для новых разработчиков

1. **Прочитайте** [VERSION_DETECTION_GUIDE.md](./VERSION_DETECTION_GUIDE.md)
2. **Используйте** `OSVersion` для всех проверок версий
3. **Следуйте** паттернам из [BACKWARD_COMPATIBILITY.md](./BACKWARD_COMPATIBILITY.md)

### Для рефакторинга существующего кода

1. **Прочитайте** [MIGRATION_TO_OSVERSION.md](./MIGRATION_TO_OSVERSION.md)
2. **Найдите** кандидатов на замену (скрипты в документе)
3. **Мигрируйте** постепенно, используя чеклист

### Для понимания общей картины

1. **Прочитайте** [MODERNIZATION_ROADMAP.md](./MODERNIZATION_ROADMAP.md)
2. **Посмотрите** roadmap и текущую фазу
3. **Планируйте** новые фичи согласно roadmap

---

## 📋 Чек-листы

### При добавлении нового кода

- [ ] Используете `OSVersion` вместо прямых `#available`?
- [ ] Проверили доступность фич через feature flags?
- [ ] Протестировали на минимальной версии (macOS 11.0)?
- [ ] Добавили fallback для новых фич (12.0+)?
- [ ] Обновили тесты?

### При рефакторинге

- [ ] Заменили `#available` на `OSVersion`?
- [ ] Использовали семантичные feature flags?
- [ ] Упростили повторяющиеся проверки?
- [ ] Запустили линтер?
- [ ] Протестировали изменения?

---

## 🎨 Поддерживаемые версии

| macOS Version | Status | Features |
|--------------|--------|----------|
| **11.0 Big Sur** | ✅ Минимальная | SF Symbols 1/2, SwiftUI 2.0, Semantic Colors |
| **12.0 Monterey** | ✅ Поддерживается | SF Symbols 3 |
| **13.0 Ventura** | ✅ Поддерживается | App Intents, Menu Bar Extras |
| **14.0 Sonoma** | ✅ Поддерживается | Widgets, SF Symbols 4 |
| **15.0 Sequoia** | ✅ Поддерживается | Последние фичи |

---

## 📊 Матрица фич

| Feature | 11.0 | 12.0 | 13.0 | 14.0+ | OSVersion Flag |
|---------|------|------|------|-------|----------------|
| SF Symbols | ✅ | ✅ | ✅ | ✅ | N/A (всегда доступно) |
| Semantic Colors | ✅ | ✅ | ✅ | ✅ | N/A (всегда доступно) |
| Dark Mode | ✅ | ✅ | ✅ | ✅ | N/A (всегда доступно) |
| SwiftUI 2.0 | ✅ | ✅ | ✅ | ✅ | N/A (всегда доступно) |
| SF Symbols 3 | ❌ | ✅ | ✅ | ✅ | `supportsSFSymbols3` |
| App Intents | ❌ | ❌ | ✅ | ✅ | `supportsAppIntents` |
| Menu Bar Extras | ❌ | ❌ | ✅ | ✅ | `supportsMenuBarExtras` |
| Widgets | ❌ | ❌ | ❌ | ✅ | `supportsWidgets` |
| SF Symbols 4 | ❌ | ❌ | ❌ | ✅ | `supportsSFSymbols4` |

---

## 🧪 Тестирование

### Запуск тестов

```bash
# Все тесты
xcodebuild -workspace ShadowsocksX-NG.xcworkspace \
           -scheme ShadowsocksX-NG \
           test

# Только OSVersion тесты
xcodebuild -workspace ShadowsocksX-NG.xcworkspace \
           -scheme ShadowsocksX-NG \
           -only-testing:ShadowsocksX-NGTests/OSVersionTests \
           test
```

### Линтер

```bash
# Проверка кода
swiftlint lint

# Строгий режим
swiftlint lint --strict
```

---

## 📖 Примеры кода

### Пример 1: Простая проверка версии

```swift
// ❌ Плохо - boilerplate
if #available(macOS 13.0, *) {
    setupAppIntents()
}

// ✅ Хорошо - читаемо
if OSVersion.supportsAppIntents {
    setupAppIntents()
}
```

### Пример 2: SF Symbols

```swift
// ❌ Плохо - может вернуть nil
let icon = NSImage(systemSymbolName: "star.fill")

// ✅ Хорошо - безопасно
let icon = OSVersion.symbol(primary: "star.fill")
```

### Пример 3: Условное выполнение

```swift
// ❌ Плохо - повторяющиеся проверки
if #available(macOS 14.0, *) {
    setupFeatureA()
}
if #available(macOS 14.0, *) {
    setupFeatureB()
}

// ✅ Хорошо - единая проверка
if OSVersion.supportsWidgets {
    if #available(macOS 14.0, *) {
        setupFeatureA()
        setupFeatureB()
    }
}

// ✅ Еще лучше - conditional execution
OSVersion.onSonomaOrLater {
    if #available(macOS 14.0, *) {
        setupFeatureA()
        setupFeatureB()
    }
}
```

---

## 🔗 Связанные документы

- [../../CLAUDE.md](../../CLAUDE.md) - Общий обзор проекта
- [../../README.md](../../README.md) - Главный README
- [../code-quality/](../code-quality/) - Документация по качеству кода

---

## 💡 Best Practices

1. **✅ Всегда используйте `OSVersion`** для проверок версий
2. **✅ Используйте feature flags** вместо прямых версий
3. **✅ Тестируйте на минимальной версии** (macOS 11.0)
4. **✅ Добавляйте fallback** для фич 12.0+
5. **❌ Не используйте `#available`** без крайней необходимости

---

## 🤝 Contributing

При добавлении новых версионно-зависимых фич:

1. Добавьте feature flag в `OSVersion.swift`
2. Добавьте тесты в `OSVersionTests.swift`
3. Обновите документацию в этой папке
4. Используйте новый flag в коде

Пример:

```swift
// 1. В OSVersion.swift
extension OSVersion {
    static var supportsNewFeature: Bool {
        if #available(macOS 16.0, *) { return true }
        return false
    }
}

// 2. В OSVersionTests.swift
func testNewFeatureAvailability() {
    let expected = OSVersion.isNewVersionOrLater
    XCTAssertEqual(OSVersion.supportsNewFeature, expected)
}

// 3. В коде
if OSVersion.supportsNewFeature {
    if #available(macOS 16.0, *) {
        setupNewFeature()
    }
}
```

---

## 📝 Changelog

### 2025-11-18

- ✅ **Phase 2 Complete** - Visual & Component Modernization
- ✨ SF Symbols migration (status bar icons, password visibility)
- 🎨 Semantic colors migration (dark mode adaptation)
- ✨ Vibrancy effects for toast notifications
- 🎨 Modern table view styles (.fullWidth)
- 📝 Form input enhancements with localized placeholders
- 🐛 Multiple bug fixes and improvements
- 📄 Created detailed completion report

### 2025-11-07

- ✨ Добавлена утилита `OSVersion`
- 📝 Создана документация по использованию
- 🧪 Добавлены юнит-тесты
- 📋 Обновлен BACKWARD_COMPATIBILITY.md для Big Sur baseline

---

## ❓ FAQ

**Q: Какой документ читать первым?**

A: [VERSION_DETECTION_GUIDE.md](./VERSION_DETECTION_GUIDE.md) - полное руководство с примерами.

**Q: Как мигрировать существующий код?**

A: См. [MIGRATION_TO_OSVERSION.md](./MIGRATION_TO_OSVERSION.md) с чеклистом и скриптами.

**Q: Нужно ли использовать OSVersion для всего?**

A: Да, для всех проверок версий и фич. Это упрощает код и улучшает читаемость.

**Q: Как добавить новую фичу?**

A: Добавьте feature flag в `OSVersion`, напишите тест, используйте в коде.

---

**Минимальная версия:** macOS 11.0 Big Sur
**Последнее обновление:** 2025-11-18
**Версия документации:** 2.0
