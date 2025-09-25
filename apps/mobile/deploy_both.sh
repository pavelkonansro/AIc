#!/bin/bash

# Скрипт для деплоя приложения на симулятор и физический телефон
# Автор: AI Assistant
# Дата: $(date)

echo "🚀 Начинаем деплой AIc Mobile на симулятор и телефон..."

# Проверяем доступные устройства
echo "📱 Проверяем доступные устройства..."
flutter devices

echo ""
echo "📲 Деплой на симулятор iPhone 16 Pro..."
flutter run -d "iPhone 16 Pro" &
SIMULATOR_PID=$!

# Ждем завершения деплоя на симулятор
sleep 30

echo ""
echo "📱 Проверяем подключение физического телефона..."
PHONE_DEVICE=$(flutter devices | grep -E "iPhone.*\(mobile\)" | grep -v "simulator" | head -1 | awk '{print $1}')

if [ -n "$PHONE_DEVICE" ]; then
    echo "✅ Физический телефон найден: $PHONE_DEVICE"
    echo "📲 Деплой на физический телефон..."
    flutter run -d "$PHONE_DEVICE"
else
    echo "❌ Физический телефон не найден!"
    echo "📋 Инструкции для подключения телефона:"
    echo "1. Подключите iPhone к Mac через USB-кабель"
    echo "2. Разблокируйте телефон и доверьте компьютеру"
    echo "3. Включите режим разработчика:"
    echo "   Настройки → Конфиденциальность и безопасность → Режим разработчика → Включить"
    echo "4. Перезагрузите телефон"
    echo "5. Запустите этот скрипт снова"
fi

echo ""
echo "✅ Деплой завершен!"
echo "🔧 Доступные команды:"
echo "   r - Hot reload"
echo "   R - Hot restart" 
echo "   q - Quit"
echo "   d - Detach"

