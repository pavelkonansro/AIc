# 🏠 Развертывание AIc на Synology NAS DS218

Пошаговая инструкция для настройки тестового сервера AIc на Synology NAS для 24/7 тестирования.

## 📋 Требования

- Synology NAS DS218 с DSM 7.0+
- Container Manager (бывший Docker) установлен
- Доступ к админ панели NAS
- Фиксированный IP адрес для NAS

## 🔧 Шаг 1: Подготовка NAS

### 1.1 Установка Container Manager
1. Откройте **Package Center** в DSM
2. Найдите и установите **Container Manager**
3. Дождитесь завершения установки

### 1.2 Настройка сети
1. **Control Panel** → **Network** → **Network Interface**
2. Настройте статический IP для NAS: `192.168.68.69` (ваш текущий IP)
3. Обновите DNS настройки если необходимо

### 1.3 Настройка файрвола
1. **Control Panel** → **Security** → **Firewall**
2. Создайте правила для портов:
   - **5432** - PostgreSQL
   - **6379** - Redis  
   - **3000** - API Server
   - **8080** - PgAdmin (опционально)

## 📁 Шаг 2: Загрузка файлов на NAS

### 2.1 Создание папки проекта
```bash
# В File Station создайте папку:
/docker/aic-app/
```

### 2.2 Копирование файлов
Скопируйте эти файлы в `/docker/aic-app/`:

```
/docker/aic-app/
├── docker-compose.nas.yml          # Docker Compose конфигурация
├── simple-test-server-nas.js       # API сервер для NAS
├── package-nas.json                # Зависимости Node.js
└── apps/
    └── api/
        └── create-pii-fixed-schema.sql  # SQL схема БД
```

## 🐳 Шаг 3: Запуск через Container Manager

### 3.1 Импорт проекта
1. Откройте **Container Manager**
2. **Project** → **Create**
3. **Project Name**: `aic-app`
4. **Path**: `/docker/aic-app`
5. **Source**: `Create docker-compose.yml`

### 3.2 Настройка docker-compose.yml
Вставьте содержимое файла `docker-compose.nas.yml` или загрузите готовый файл.

### 3.3 Настройка переменных среды
В Container Manager можно отредактировать переменные:
```env
DATABASE_URL=postgresql://postgres:postgres123@postgres-nas:5432/aic
REDIS_URL=redis://redis-nas:6379
NODE_ENV=development
PORT=3000
```

### 3.4 Запуск проекта
1. Нажмите **Build** для сборки контейнеров
2. После успешной сборки нажмите **Run** 
3. Дождитесь запуска всех сервисов

## 🔍 Шаг 4: Проверка работы

### 4.1 Проверка контейнеров
В Container Manager проверьте статус:
- ✅ `aic-postgres-nas` - Running
- ✅ `aic-redis-nas` - Running  
- ✅ `aic-api-nas` - Running

### 4.2 Тестирование API
```bash
# Health check
curl http://192.168.68.69:3000/health

# Должен вернуть:
{
  "status": "OK",
  "message": "AIc NAS Test Server is running!",
  "environment": "nas-development",
  "services": {
    "database": "connected",
    "redis": "connected", 
    "api": "running"
  }
}
```

### 4.3 Тестирование создания пользователя
```bash
# Создание guest пользователя
curl -X POST http://192.168.68.69:3000/auth/guest \
  -H "Content-Type: application/json"

# Регистрация пользователя  
curl -X POST http://192.168.68.69:3000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"birthYear": 2010, "ageGroup": "teen", "locale": "cs-CZ"}'
```

## 📱 Шаг 5: Настройка Flutter приложения

### 5.1 Обновление IP адреса
В файле `apps/mobile/lib/config/api_config.dart`:

```dart
// Измените IP адрес на IP вашего NAS
static const String _nasIp = '192.168.68.69';  // ← IP вашего NAS

// Переключение на NAS сервер
static const ServerEnvironment _currentEnv = ServerEnvironment.nas;
```

### 5.2 Тестирование подключения
1. Запустите Flutter приложение
2. Проверьте подключение к NAS серверу
3. Протестируйте создание пользователей

## 🔧 Дополнительные настройки

### Администрирование БД (опционально)
Если нужен веб-интерфейс для PostgreSQL:

```bash
# Запуск с PgAdmin
docker-compose -f docker-compose.nas.yml --profile admin up -d

# Доступ: http://192.168.68.69:8080
# Email: admin@aic-app.com  
# Пароль: admin123
```

### Логирование
Просмотр логов контейнеров:
1. Container Manager → **Container** 
2. Выберите контейнер → **Details** → **Log**

### Автозапуск
Container Manager автоматически перезапустит контейнеры при:
- Перезагрузке NAS
- Падении сервиса (restart: unless-stopped)

## 🎯 Результат

После выполнения всех шагов у вас будет:

✅ **Постоянно работающий API сервер** на http://192.168.68.69:3000
✅ **PostgreSQL база данных** с GDPR-совместимой схемой  
✅ **Redis кэш** для быстрой работы
✅ **Flutter приложение**, настроенное на NAS сервер
✅ **24/7 доступность** для тестирования с любых устройств

## 🆘 Решение проблем

### Контейнер не запускается
- Проверьте логи в Container Manager
- Убедитесь, что порты не заняты
- Проверьте права доступа к папкам

### API недоступен
- Проверьте файрвол NAS
- Убедитесь, что контейнеры в одной сети
- Проверьте статус PostgreSQL

### База данных не инициализируется  
- Проверьте SQL файл схемы
- Убедитесь в правильности переменных среды
- Удалите том базы данных для пересоздания

---

**Готово!** Теперь у вас есть надежная тестовая среда на Synology NAS! 🚀