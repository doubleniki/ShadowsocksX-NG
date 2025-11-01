# 🔐 Keychain Password Storage Migration

## Обзор

Начиная с этой версии, ShadowsocksX-NG использует **macOS Keychain** для безопасного хранения паролей серверов вместо незащищенного хранения в UserDefaults.

## 🎯 Что изменилось?

### ДО (небезопасно)
```
~/Library/Preferences/com.qiuyuzhou.ShadowsocksX-NG.plist
└── ServerProfiles
    └── Password: "my-secret-password" ❌ В открытом виде!
```

### ПОСЛЕ (безопасно)
```
~/Library/Preferences/com.qiuyuzhou.ShadowsocksX-NG.plist
└── ServerProfiles
    └── Password: "" ✅ Пусто

macOS Keychain (зашифровано)
└── com.qiuyuzhou.ShadowsocksX-NG
    └── [UUID сервера]: "my-secret-password" ✅ Зашифровано!
```

## ✨ Преимущества

1. **Аппаратное шифрование** - Keychain использует шифрование на уровне чипа T2/Apple Silicon
2. **Защита паролем** - Доступ к Keychain защищен паролем пользователя macOS
3. **Изолированное хранилище** - Только авторизованные приложения могут получить доступ
4. **Стандарт безопасности** - Keychain - это рекомендуемый Apple способ хранения секретов

## 🔄 Автоматическая миграция

При первом запуске обновленного приложения:

1. ✅ Все существующие пароли автоматически мигрируют в Keychain
2. ✅ Поле Password в UserDefaults очищается
3. ✅ Приложение работает без перебоев
4. ✅ Никаких действий от пользователя не требуется

**Логи миграции:**
```
NSLog: Migrating password to Keychain for server: 12345-UUID-ABCDE
NSLog: KeychainManager: Successfully saved password for account: 12345-UUID-ABCDE
```

## 🔍 Проверка безопасности

### Просмотр UserDefaults (должно быть пусто):
```bash
defaults read com.qiuyuzhou.ShadowsocksX-NG ServerProfiles | grep Password
```
Ожидаемый результат: `Password = "";`

### Просмотр Keychain:
1. Открыть **Keychain Access.app** (Связка ключей)
2. Поиск: `com.qiuyuzhou.ShadowsocksX-NG`
3. Вы увидите записи для каждого сервера
4. Пароли можно просмотреть только после ввода пароля macOS

## 🛠️ Технические детали

### KeychainManager.swift

Новый класс для управления Keychain:

```swift
// Сохранить пароль
KeychainManager.shared.savePassword(password, forAccount: uuid)

// Получить пароль
let password = KeychainManager.shared.getPassword(forAccount: uuid)

// Удалить пароль
KeychainManager.shared.deletePassword(forAccount: uuid)
```

### Атрибуты Keychain

- **kSecClass**: `kSecClassGenericPassword`
- **kSecAttrService**: `com.qiuyuzhou.ShadowsocksX-NG`
- **kSecAttrAccount**: UUID сервера
- **kSecAttrAccessible**: `kSecAttrAccessibleAfterFirstUnlock`

## 📝 Изменения в коде

### ServerProfile.swift
```swift
// Пароль теперь - computed property
@objc dynamic var password: String {
    get {
        // Читает из Keychain
        KeychainManager.shared.getPassword(forAccount: uuid) ?? ""
    }
    set {
        // Сохраняет в Keychain
        KeychainManager.shared.savePassword(newValue, forAccount: uuid)
    }
}
```

### Удаление профиля
```swift
// При удалении сервера - удаляется и пароль из Keychain
profile.removePasswordFromKeychain()
```

## ⚠️ Важные заметки

### iCloud Keychain
- Пароли НЕ синхронизируются через iCloud Keychain
- Это сделано намеренно для дополнительной безопасности
- Каждый Mac хранит пароли локально

### Backup
- Пароли включены в резервные копии Time Machine
- При миграции на новый Mac - используйте Migration Assistant
- Keychain мигрирует вместе с системой

### Совместимость
- **Новая → Старая версия**: Старая версия не сможет получить пароли (они в Keychain)
- **Старая → Новая версия**: Автоматическая миграция при первом запуске

## 🔐 Сравнение с менеджерами паролей

| Функция | macOS Keychain | Bitwarden/1Password |
|---------|----------------|---------------------|
| Назначение | Хранилище для приложений | Хранилище для пользователя |
| Где хранит | Локально (зашифровано) | Облако (зашифровано) |
| Доступ | Программный API | Ручное копирование/автозаполнение |
| Синхронизация | Нет | Да (между устройствами) |
| Использование | Автоматическое | Ручное |

**Рекомендация:**
- Keychain - для хранения паролей **внутри** приложения
- Bitwarden/1Password - для **управления** вашими паролями

## 🐛 Troubleshooting

### "Пароли пропали после обновления"
```bash
# Проверьте Keychain
open -a "Keychain Access"
# Поиск: com.qiuyuzhou.ShadowsocksX-NG
```

### "Приложение не может получить доступ к Keychain"
```bash
# Проверьте доступность Keychain
security list-keychains
security find-generic-password -s "com.qiuyuzhou.ShadowsocksX-NG"
```

### Ручная очистка (для отладки)
```bash
# Удалить ВСЕ пароли из Keychain (ОСТОРОЖНО!)
security delete-generic-password -s "com.qiuyuzhou.ShadowsocksX-NG"
```

## 📚 Дополнительная информация

- [Apple Keychain Services Documentation](https://developer.apple.com/documentation/security/keychain_services)
- [Security Best Practices](https://developer.apple.com/library/archive/documentation/Security/Conceptual/SecureCodingGuide/)

---

**Вопросы?** Создайте issue на GitHub с меткой `security` или `keychain`.
