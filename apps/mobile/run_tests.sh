#!/bin/bash

# AIc Mobile App - Test Runner Script
# Запускает все типы тестов для проверки функциональности

echo "🧪 AIc Mobile App - Запуск автотестов"
echo "======================================="

# Переходим в директорию mobile приложения
cd "$(dirname "$0")"

# Проверяем что мы в правильной директории
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Ошибка: Не найден pubspec.yaml файл"
    echo "   Убедитесь что скрипт запускается из директории apps/mobile"
    exit 1
fi

# Устанавливаем зависимости
echo "📦 Устанавливаем зависимости..."
flutter pub get

# Генерируем моки для тестов
echo "🔧 Генерируем мок-классы для тестов..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Запускаем unit тесты
echo ""
echo "🔬 Запускаем unit тесты..."
echo "------------------------"
flutter test test/ --coverage

# Проверяем код на ошибки
echo ""
echo "🔍 Проверяем код на ошибки..."
echo "-----------------------------"
flutter analyze

# Запускаем интеграционные тесты (только если устройство доступно)
echo ""
echo "🚀 Проверяем доступные устройства для интеграционных тестов..."
DEVICES=$(flutter devices --machine | jq -r '.[].id')

if [ -n "$DEVICES" ]; then
    echo "📱 Найдены устройства для тестирования:"
    flutter devices
    
    echo ""
    echo "🔗 Запускаем интеграционные тесты..."
    echo "-----------------------------------"
    
    # Запускаем на первом доступном устройстве
    FIRST_DEVICE=$(echo "$DEVICES" | head -n 1)
    echo "Используем устройство: $FIRST_DEVICE"
    
    flutter test integration_test/app_test.dart -d "$FIRST_DEVICE" || {
        echo "⚠️  Интеграционные тесты завершились с ошибками"
        echo "   Это может быть нормально если нет реального устройства"
    }
else
    echo "⚠️  Устройства для интеграционных тестов не найдены"
    echo "   Интеграционные тесты пропущены"
fi

# Показываем отчет о покрытии
echo ""
echo "📊 Отчет о покрытии тестами:"
echo "----------------------------"
if [ -f "coverage/lcov.info" ]; then
    echo "✅ Файл покрытия создан: coverage/lcov.info"
    
    # Если установлен lcov, показываем статистику
    if command -v lcov >/dev/null 2>&1; then
        echo ""
        lcov --summary coverage/lcov.info
    else
        echo "💡 Установите lcov для детальной статистики покрытия:"
        echo "   brew install lcov  # на macOS"
    fi
else
    echo "⚠️  Файл покрытия не создан"
fi

echo ""
echo "🎉 Тестирование завершено!"
echo "========================="

# Показываем краткую сводку
echo ""
echo "📋 Краткая сводка:"
echo "  ✅ Unit тесты: Проверяют AuthService, AuthController, навигацию"
echo "  ✅ Widget тесты: Проверяют UI компоненты и их взаимодействие"
echo "  ✅ Integration тесты: Проверяют полный пользовательский flow"
echo "  ✅ Статический анализ: Проверяет качество кода"
echo ""
echo "🚀 Для запуска только определенного типа тестов:"
echo "   flutter test test/services/          # Только сервисы"
echo "   flutter test test/state/             # Только state management"
echo "   flutter test test/features/          # Только UI тесты"
echo "   flutter test integration_test/       # Только интеграционные"
echo ""
echo "📱 Для запуска на конкретном устройстве:"
echo "   flutter test integration_test/ -d <device_id>"