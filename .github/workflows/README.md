# GitHub Actions Workflows

## Активные Workflows

### 🚀 release.yml
**Триггер:** Push tag (v*)

Создаёт production релиз с оптимизациями:
- ✅ Кеширование зависимостей (deps/, CocoaPods, Homebrew)
- ✅ Установка build tools (automake, autoconf, libtool, pcre)
- ✅ Release конфигурация
- ✅ Создание DMG с контрольной суммой
- ✅ Автоматическая публикация на GitHub Releases

**Примерное время:** ~10 минут (при cache hit)

### 🔧 feature.yml
**Триггер:** Push/PR на любую ветку (с фильтрацией)

Умная сборка для разработки:
- ✅ Проверка типа коммита (feat/fix/feature/bugfix запускают сборку)
- ✅ Пропуск для docs/style/chore коммитов
- ✅ Пропуск для изменений только в .md файлах
- ✅ Debug конфигурация (быстрее)
- ✅ DMG только для develop ветки
- ✅ Для PR: только .app без DMG

**Примерное время:** ~5 минут (при cache hit)

**Сборка запускается для коммитов:**
```
feat: Add new feature
fix: Fix bug in proxy
feature: Implement dark mode
bugfix: Resolve crash on startup
perf: Optimize PAC generation
refactor: Restructure server profiles
build: Update dependencies
```

**Сборка НЕ запускается для:**
```
docs: Update README
style: Format code
chore: Update gitignore
ci: Fix workflow
test: Add unit tests
Update CLAUDE.md
Fix typo in documentation
```

### 📦 build-deps-cache.yml
**Триггер:** Вручную или при изменении deps/

Создаёт/обновляет кеш нативных зависимостей:
- Собирает ss-local, privoxy, плагины для обеих архитектур
- Создаёт universal binaries через lipo
- Сохраняет в GitHub Actions cache
- Создаёт архив deps-dist.tar.gz

**Примерное время:** ~25 минут (только при изменении deps/)

**Запуск вручную:**
1. GitHub → Actions → Build Dependencies Cache
2. Run workflow → force_rebuild: true

## Старые Workflows (Отключены)

- `release.yml.old` - Оригинальный release без оптимизаций
- `feature.yml.old` - Оригинальный feature без оптимизаций
- `objective-c-xcode.yml.old` - Дублирующий build workflow

Сохранены для справки, можно удалить после проверки новых workflows.

## Кеширование

### Уровни кеша

1. **Homebrew** (`~/Library/Caches/Homebrew`)
   - Пакеты: automake, autoconf, libtool, pcre
   - Ключ: `brew-${{ runner.os }}-build-tools-v2`
   - Экономия: ~2-3 минуты

2. **Native Dependencies** (`deps/dist/`)
   - Ключ: `deps-${{ runner.os }}-${{ hashFiles('deps/**') }}`
   - Экономия: ~20-25 минут
   - Инвалидация: при изменении файлов в deps/

3. **CocoaPods** (`Pods/`)
   - Ключ: `pods-${{ hashFiles('Podfile.lock') }}`
   - Экономия: ~1-2 минуты
   - Инвалидация: при изменении Podfile.lock

### Управление кешем

**Просмотр:**
- GitHub → Settings → Actions → Caches

**Очистка:**
- Автоматическая через 7 дней неиспользования
- Вручную: Settings → Actions → Caches → Delete

**Пересборка deps:**
- Запустите `build-deps-cache.yml` с `force_rebuild: true`

## Примеры Использования

### Создание релиза

```bash
# 1. Подготовьте код
git checkout develop
git pull

# 2. Создайте тег
git tag -a v1.9.5 -m "Release version 1.9.5"
git push origin v1.9.5

# 3. GitHub Actions автоматически:
#    - Соберёт release build
#    - Создаст DMG
#    - Опубликует на GitHub Releases
```

### Разработка feature

```bash
# Коммит запустит сборку
git commit -m "feat: Add Quick Add Domain to User Rules"
git push

# Коммит НЕ запустит сборку
git commit -m "docs: Update README with new features"
git push
```

### Тестирование без сборки

Если нужно запушить изменения без запуска CI:

```bash
# Вариант 1: Используйте [skip ci]
git commit -m "docs: Update README [skip ci]"

# Вариант 2: Используйте docs: prefix
git commit -m "docs: Update installation instructions"

# Вариант 3: Меняйте только .md файлы (paths-ignore)
```

## Troubleshooting

### Сборка не запускается

**Причины:**
1. Коммит начинается с `docs:`, `style:`, `chore:`
2. Изменены только .md файлы
3. Использован `[skip ci]` в сообщении

**Решение:**
- Используйте `feat:` или `fix:` prefix
- Или измените код (.swift, .m, .h файлы)

### Долгая сборка

**Причины:**
1. Cache miss - кеш не найден
2. deps/ изменились

**Решение:**
- Дождитесь создания кеша (первый раз ~25 мин)
- Последующие сборки будут быстрыми

### Кеш не работает

**Диагностика:**
1. Откройте workflow run
2. Найдите шаг "Cache native dependencies"
3. Проверьте "Cache hit" в логах

**Решение:**
- Запустите `build-deps-cache.yml` вручную
- Проверьте Settings → Actions → Caches

## Метрики

### Производительность

| Workflow | Без кеша | С кешем | Экономия |
|----------|----------|---------|----------|
| Release | 35 мин | 10 мин | 71% |
| Feature | 35 мин | 5 мин | 86% |
| PR check | 35 мин | 5 мин | 86% |

### GitHub Actions минуты/месяц

Активная разработка (10 PR + 5 branches + 2 releases):

- **До:** 595 минут
- **После:** 120 минут
- **Экономия:** 80% 💰

## Документация

См. [OPTIMIZATION.md](./OPTIMIZATION.md) для подробностей об оптимизациях.
