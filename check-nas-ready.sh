#!/bin/bash

# Скрипт для проверки готовности NAS и развертывания AIc

NAS_IP="192.168.68.69"
API_PORT="3000"
DB_PORT="5432"
REDIS_PORT="6379"
PGADMIN_PORT="8080"

echo "🔍 Проверка подключения к Synology NAS..."
echo "IP адрес NAS: $NAS_IP"
echo

# Проверка доступности NAS
echo "1. Проверка доступности NAS..."
if ping -c 1 $NAS_IP >/dev/null 2>&1; then
    echo "   ✅ NAS доступен по адресу $NAS_IP"
else
    echo "   ❌ NAS недоступен по адресу $NAS_IP"
    exit 1
fi

# Проверка доступа к DSM (порт 5001)
echo "2. Проверка доступности DSM..."
if nc -z $NAS_IP 5001 2>/dev/null; then
    echo "   ✅ DSM доступен на https://$NAS_IP:5001"
else
    echo "   ⚠️  DSM не отвечает на порту 5001"
fi

# Проверка портов для Docker
echo "3. Проверка портов для Docker контейнеров..."
declare -A ports=(
    [$DB_PORT]="PostgreSQL"
    [$REDIS_PORT]="Redis"
    [$API_PORT]="API Server"
    [$PGADMIN_PORT]="PgAdmin"
)

for port in "${!ports[@]}"; do
    if nc -z $NAS_IP $port 2>/dev/null; then
        echo "   ✅ Порт $port (${ports[$port]}) открыт"
    else
        echo "   ⚠️  Порт $port (${ports[$port]}) закрыт (это нормально, если контейнеры не запущены)"
    fi
done

echo
echo "📋 Следующие шаги:"
echo "1. Откройте DSM: https://$NAS_IP:5001"
echo "2. Установите Container Manager из Package Center"
echo "3. Скопируйте файлы проекта в папку /docker/aic-app/"
echo "4. Импортируйте docker-compose.nas.yml в Container Manager"
echo "5. Запустите проект и проверьте: http://$NAS_IP:$API_PORT/health"

echo
echo "🔧 Команды для тестирования API (после развертывания):"
echo "curl http://$NAS_IP:$API_PORT/health"
echo "curl -X POST http://$NAS_IP:$API_PORT/auth/guest -H \"Content-Type: application/json\""

echo
echo "📱 Настройка Flutter приложения:"
echo "В api_config.dart уже настроен IP: $_nasIp = '$NAS_IP'"
echo "Переключение: ServerEnvironment._currentEnv = ServerEnvironment.nas"