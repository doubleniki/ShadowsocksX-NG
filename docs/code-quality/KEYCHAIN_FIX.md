# Исправление утечки записей в Keychain при дублировании профилей

## Проблема

При дублировании профиля серверов создавались "осиротевшие" записи в Keychain:

1. Метод `copy(with:)` создавал новый `ServerProfile` с новым UUID
2. При копировании пароля (`copy.password = self.password`) пароль сохранялся в Keychain под этим временным UUID
3. Метод `duplicate()` затем вызывал `removePasswordFromKeychain()`, удаляя пароль под временным UUID
4. Затем создавался еще один новый UUID
5. Пароль сохранялся под третьим UUID
6. В итоге: оригинальный пароль под первым UUID оставался, временная запись под вторым UUID удалялась, и создавалась новая запись под третьим UUID

Это приводило к:

- Ненужным операциям записи/удаления в Keychain
- Потенциальным проблемам с синхронизацией
- Неоптимальному использованию ресурсов

## Решение

### Изменения в `ServerProfile.swift`

Метод `copy(with:)` теперь копирует пароль **только в кэш**, не сохраняя его в Keychain:

```swift
public func copy(with zone: NSZone? = nil) -> Any {
    let copy = ServerProfile()
    // ...
    // Копируем пароль только в кэш, без сохранения в Keychain
    copy._cachedPassword = self.password
    // ...
    return copy
}
```

### Изменения в `PreferencesWindowController.swift`

Метод `duplicate()` упрощен - убран ненужный вызов `removePasswordFromKeychain()`:

```swift
// Копируем профиль (пароль в кэше, но не в Keychain)
guard let duplicateProfile = profile.copy() as? ServerProfile else {
    return
}

// Устанавливаем новый UUID
duplicateProfile.uuid = UUID().uuidString

// Сохраняем пароль из кэша в Keychain под новым UUID
let passwordToSave = duplicateProfile.password
duplicateProfile.password = passwordToSave
```

## Результат

Теперь процесс дублирования:

1. Копирует профиль с паролем в кэше (без записи в Keychain)
2. Устанавливает новый UUID
3. Сохраняет пароль в Keychain **один раз** под новым UUID

Преимущества:

- ✅ Нет "осиротевших" записей в Keychain
- ✅ Меньше операций записи/удаления
- ✅ Более понятный и предсказуемый поток данных
- ✅ Оригинальный профиль не затрагивается

## Тесты

Обновлены тесты в `ServerProfileTests.swift`:

- `testCopyProfile()` - проверяет корректное дублирование профиля
- `testCopyProfileDoesNotLeaveOrphanedKeychainEntries()` - проверяет отсутствие утечек записей в Keychain
