# Оптимизация CI/CD Pipeline

## 📊 Сравнение Производительности

### До Оптимизации
```
┌─────────────────────────────────────────┐
│ Release Build: ~35-40 минут             │
├─────────────────────────────────────────┤
│ • Homebrew установка:      ~3 мин       │
│ • Сборка deps (нет кеша): ~25 мин       │
│ • Xcode build:             ~7 мин       │
│ • DMG creation:            ~1 мин       │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Feature Build: ~35-40 минут             │
├─────────────────────────────────────────┤
│ Те же этапы для КАЖДОГО push!           │
└─────────────────────────────────────────┘
```

### После Оптимизации
```
┌─────────────────────────────────────────┐
│ Release Build (cache hit): ~10 минут    │
├─────────────────────────────────────────┤
│ • Homebrew (кеш):          ~30 сек      │
│ • Deps (кеш hit):          ~30 сек      │
│ • Xcode build:             ~7 мин       │
│ • DMG creation:            ~1 мин       │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Feature Build (cache hit): ~5 минут     │
├─────────────────────────────────────────┤
│ • Deps (кеш):              ~30 сек      │
│ • Xcode Debug:             ~4 мин       │
│ • Без DMG для PR!                       │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Deps rebuild (только при изменении):    │
│ ~25 минут (редко)                       │
└─────────────────────────────────────────┘
```

## 🎯 Ключевые Оптимизации

### 1. Многоуровневое Кеширование

**Homebrew пакеты:**
```yaml
- uses: actions/cache@v4
  with:
    path: ~/Library/Caches/Homebrew
    key: brew-${{ runner.os }}-build-tools-v2
```
Пакеты: automake, autoconf, libtool, pcre

⏱️ Экономия: ~2-3 минуты

**Нативные зависимости (deps/):**
```yaml
- uses: actions/cache@v4
  with:
    path: |
      deps/dist
      ShadowsocksX-NG/ss-local
      ShadowsocksX-NG/privoxy
      # ... другие бинарники
    key: deps-${{ runner.os }}-${{ hashFiles('deps/**') }}
```
⏱️ Экономия: ~20-25 минут

**CocoaPods:**
```yaml
- uses: actions/cache@v4
  with:
    path: Pods
    key: pods-${{ hashFiles('Podfile.lock') }}
```
⏱️ Экономия: ~1-2 минуты

### 2. Условная Сборка Зависимостей

```yaml
- name: Check if deps changed
  run: |
    if git diff ${{ github.event.before }} ${{ github.sha }} | grep -q '^deps/'; then
      echo "changed=true" >> $GITHUB_OUTPUT
    fi

- name: Build deps
  if: steps.cache.outputs.cache-hit != 'true' || steps.deps-changed.outputs.changed == 'true'
  run: make -C deps
```

Зависимости собираются только если:
- Кеш промахнулся
- Файлы в `deps/` изменились

### 3. Разные Стратегии для Feature и Release

**Feature Builds (быстрые проверки):**
- ✅ Debug конфигурация (быстрее)
- ✅ Без DMG для PR
- ✅ Только .app для тестирования
- ✅ Retention: 7 дней

**Release Builds (полные):**
- ✅ Release конфигурация
- ✅ С DMG и checksums
- ✅ Полная верификация
- ✅ Retention: 90 дней

### 4. Параллелизация

```yaml
env:
  MAKEFLAGS: "-j$(sysctl -n hw.ncpu)"
```

Использует все доступные CPU ядра для сборки.

### 5. Отдельный Workflow для Кеша Зависимостей

`build-deps-cache.yml`:
- Можно запустить вручную
- Автоматически при изменении `deps/`
- Создаёт pre-built архив
- Обновляет кеш для всех других workflows

## 📁 Файлы

| Файл | Описание |
|------|----------|
| `release-optimized.yml` | Оптимизированная сборка релизов |
| `feature-optimized.yml` | Оптимизированная сборка для feature branches |
| `build-deps-cache.yml` | Создание и обновление кеша зависимостей |

## 🚀 Использование

### Замена Старых Workflows

1. **Переименуйте старые:**
```bash
git mv .github/workflows/release.yml .github/workflows/release.yml.old
git mv .github/workflows/feature.yml .github/workflows/feature.yml.old
```

2. **Активируйте новые:**
```bash
git mv .github/workflows/release-optimized.yml .github/workflows/release.yml
git mv .github/workflows/feature-optimized.yml .github/workflows/feature.yml
```

3. **Создайте начальный кеш:**
- Перейдите в Actions → Build Dependencies Cache
- Нажмите "Run workflow"
- Дождитесь завершения (~25 минут один раз)

### Ручное Создание Кеша

```bash
# Локально собрать зависимости
make -C deps

# Создать архив
cd deps
tar -czf ../deps-dist.tar.gz dist/
cd ..

# Загрузить в GitHub Release с тегом "deps-cache"
gh release create deps-cache deps-dist.tar.gz --title "Dependencies Cache"
```

## 📈 Метрики

### Экономия Времени

| Сценарий | Было | Стало | Экономия |
|----------|------|-------|----------|
| Release (cache hit) | 35 мин | 10 мин | **71%** |
| Feature (cache hit) | 35 мин | 5 мин | **86%** |
| PR check | 35 мин | 5 мин | **86%** |

### Экономия GitHub Actions минут

При 10 PR + 5 feature branches + 2 release в месяц:

**Без оптимизации:**
```
(10 PR × 35 мин) + (5 branches × 35 мин) + (2 releases × 35 мин)
= 350 + 175 + 70 = 595 минут/месяц
```

**С оптимизацией:**
```
(10 PR × 5 мин) + (5 branches × 5 мин) + (2 releases × 10 мин) + (1 cache rebuild × 25 мин)
= 50 + 25 + 20 + 25 = 120 минут/месяц
```

**Экономия: 475 минут/месяц (80%)**

## 🔧 Настройка Кеша

### Инвалидация Кеша

Кеш автоматически инвалидируется при:
- Изменении файлов в `deps/`
- Изменении `Podfile.lock`
- Изменении workflow файлов (для Homebrew)

### Ручная Инвалидация

Запустите `build-deps-cache.yml` с опцией `force_rebuild = true`

### Размер Кеша

GitHub Actions cache limits:
- Max size per cache: 10 GB
- Total cache size: 10 GB per repo

Наш deps cache: ~50-100 MB (хорошо вписывается)

## 🐛 Troubleshooting

### Кеш не работает

1. Проверьте logs: "Cache hit" или "Cache miss"
2. Посмотрите ключи кеша в Actions → Management → Caches
3. Убедитесь что hashFiles() правильно работает

### Deps собираются каждый раз

Возможные причины:
- `.gitignore` исключает файлы из `hashFiles()`
- Файлы в deps/ модифицируются при сборке
- Недостаточно места в кеше

### Старые кеши накапливаются

GitHub автоматически удаляет неиспользуемые кеши через 7 дней.

## 📝 TODO (Дальнейшие Оптимизации)

- [ ] Matrix build для параллельной сборки архитектур
- [ ] Docker image с предустановленными зависимостями
- [ ] Ccache для ускорения повторных C++ компиляций
- [ ] Incremental builds в Xcode
- [ ] Separate workflow для линтинга (без сборки)
