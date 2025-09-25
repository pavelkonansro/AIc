#!/bin/bash

# 🏥 Health Check скрипт для проверки состояния всех сервисов
# Проверяет что все необходимые сервисы запущены перед началом разработки

set -e

API_HOST=${API_HOST:-"192.168.68.65"}
API_PORT=${API_PORT:-"3001"}
TIMEOUT=10

echo "🏥 Проверка состояния сервисов..."
echo ""

# Функция проверки HTTP эндпоинта
check_http() {
    local url="$1"
    local name="$2"

    echo "🔍 Проверяем $name ($url)..."

    if curl -s --max-time $TIMEOUT "$url" > /dev/null 2>&1; then
        echo "✅ $name - OK"
        return 0
    else
        echo "❌ $name - НЕДОСТУПЕН"
        return 1
    fi
}

# Функция проверки порта
check_port() {
    local host="$1"
    local port="$2"
    local name="$3"

    echo "🔍 Проверяем $name ($host:$port)..."

    if nc -z "$host" "$port" 2>/dev/null; then
        echo "✅ $name - порт открыт"
        return 0
    else
        echo "❌ $name - порт недоступен"
        return 1
    fi
}

# Проверки
HEALTH_OK=0

# 1. API Server Health
if ! check_http "http://$API_HOST:$API_PORT/health" "API Server Health"; then
    HEALTH_OK=1
fi

# 2. API Server Base
if ! check_http "http://$API_HOST:$API_PORT/" "API Server Base"; then
    HEALTH_OK=1
fi

# 3. Swagger UI
if ! check_http "http://$API_HOST:$API_PORT/api" "Swagger UI"; then
    HEALTH_OK=1
fi

# 4. Проверка Firebase Auth Emulator (если запущен)
if check_port "localhost" "9099" "Firebase Auth Emulator (опционально)"; then
    echo "ℹ️  Firebase Auth Emulator запущен"
else
    echo "ℹ️  Firebase Auth Emulator не запущен (это нормально для продакшн)"
fi

echo ""

if [ $HEALTH_OK -eq 0 ]; then
    echo "🎉 Все основные сервисы доступны!"
    echo "🚀 Можно начинать разработку"

    # Показываем полезную информацию
    echo ""
    echo "📋 Полезные ссылки:"
    echo "   API Health: http://$API_HOST:$API_PORT/health"
    echo "   Swagger UI: http://$API_HOST:$API_PORT/api"
    echo "   API Base:   http://$API_HOST:$API_PORT/"

    exit 0
else
    echo "💥 Некоторые сервисы недоступны!"
    echo "🔧 Возможные решения:"
    echo "   1. Запустите API сервер: cd apps/api && HOST=0.0.0.0 PORT=3001 node dist/main.js"
    echo "   2. Проверьте что IP адрес правильный: $API_HOST"
    echo "   3. Проверьте что порт свободен: lsof -i :$API_PORT"

    exit 1
fi