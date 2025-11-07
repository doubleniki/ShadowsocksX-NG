# Добавление Новых swift файлов в проект

## Быстрая инструкция

### Шаг 1: Добавить файл в Xcode

1. Откройте **ShadowsocksX-NG.xcworkspace** в Xcode
2. В Project Navigator найдите папку **ShadowsocksX-NG**
3. Файл **{YourFileName}.swift** уже создан в папке `ShadowsocksX-NG/`
4. Перетащите файл из Finder в Xcode Project Navigator, либо:
   - ПКМ на папку ShadowsocksX-NG → Add Files to "ShadowsocksX-NG"
   - Выберите `ShadowsocksX-NG/{YourFileName}.swift`
   - Убедитесь, что отмечен target **ShadowsocksX-NG**
   - Нажмите Add

### Шаг 2: Добавить тесты в проект

1. В Project Navigator найдите папку **ShadowsocksX-NGTests**
2. Файл **{YourFileName}Tests.swift** уже создан в папке `ShadowsocksX-NGTests/`
3. Добавьте его аналогично, но выберите target **ShadowsocksX-NGTests**

### Шаг 3: Проверить компиляцию

```bash
# В терминале
cd /Users/doubleniki/Repo/Personal/ShadowsocksX-NG

# Компиляция
xcodebuild -workspace ShadowsocksX-NG.xcworkspace \
           -scheme ShadowsocksX-NG \
           -configuration Debug \
           build

# Запуск тестов
xcodebuild -workspace ShadowsocksX-NG.xcworkspace \
           -scheme ShadowsocksX-NG \
           -configuration Debug \
           test
```

### Или в Xcode

1. **Cmd + B** - компиляция
2. **Cmd + U** - запуск тестов

---

## Проверка

После добавления файлов:

- [ ] Файлы видны в Project Navigator
- [ ] Файлы отображаются синим цветом (не серым)
- [ ] При нажатии Cmd+B проект компилируется без ошибок
- [ ] При нажатии Cmd+U тесты запускаются

---

## Альтернативный способ (через командную строку)

Если вы предпочитаете автоматизацию, можно использовать Ruby gem `xcodeproj`:

```bash
# Установить gem
gem install xcodeproj

# Скрипт для добавления файлов
cat > add_newFile.rb << 'EOF'
require 'xcodeproj'

project_path = 'ShadowsocksX-NG.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Найти главный target
main_target = project.targets.find { |t| t.name == 'ShadowsocksX-NG' }
test_target = project.targets.find { |t| t.name == 'ShadowsocksX-NGTests' }

# Найти группу ShadowsocksX-NG
main_group = project.main_group.find_subpath('ShadowsocksX-NG', true)

# Добавить {YourFileName}.swift
new_file = main_group.new_file('{YourFileName}')
main_target.add_file_references([new_file])

# Найти группу ShadowsocksX-NGTests
test_group = project.main_group.find_subpath('ShadowsocksX-NGTests', true)

# Добавить {YourFileName}Tests.swift
new_tests_file = test_group.new_file('{YourFileName}Tests.swift')
test_target.add_file_references([new_tests_file])

project.save

puts "✅ Файлы добавлены в проект"
EOF

# Запустить скрипт
ruby add_newFile.rb

# Удалить скрипт
rm add_newFile.rb
```

---

## Troubleshooting

### Проблема: Файл серый в Project Navigator

**Решение:** Файл не добавлен в target. ПКМ на файл → Target Membership → включить нужный target.

### Проблема: Cannot find 'OSVersion' in scope

**Решение:**

1. Проверьте, что файл добавлен в правильный target
2. Clean Build Folder (Cmd + Shift + K)
3. Rebuild (Cmd + B)

### Проблема: Duplicate symbol errors

**Решение:** Файл добавлен дважды. Проверьте в Project Navigator и в Build Phases → Compile Sources.

---

**Создан:** 2025-11-07
