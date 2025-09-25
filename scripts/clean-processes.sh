#!/bin/bash

# 🧹 Скрипт очистки всех процессов разработки
# Используется перед запуском dev среды для предотвращения конфликтов

echo "🧹 Очистка процессов разработки..."

# Остановка Flutter процессов
echo "📱 Остановка Flutter процессов..."
pkill -f "flutter run" 2>/dev/null || true
pkill -f "dart" 2>/dev/null || true

# Остановка API серверов
echo "🚀 Остановка API серверов..."
pkill -f "node dist/main.js" 2>/dev/null || true
pkill -f "nest start" 2>/dev/null || true

# Освобождение портов
echo "🔌 Освобождение портов 3000, 3001, 9099..."
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
lsof -ti:3001 | xargs kill -9 2>/dev/null || true
lsof -ti:9099 | xargs kill -9 2>/dev/null || true

# Очистка временных файлов Flutter
echo "🗑️  Очистка временных файлов..."
cd "$(dirname "$0")/../apps/mobile" 2>/dev/null && flutter clean 2>/dev/null || true

echo "✅ Очистка завершена!"
echo ""