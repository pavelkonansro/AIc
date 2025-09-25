# 🚀 Быстрый старт: AIc на Synology NAS

## ✅ Готово к развертыванию!

**Ваш NAS:** https://192.168.68.69:5001/ - ✅ Доступен и готов

## 🔥 Быстрое развертывание (5 минут)

### 1. Откройте DSM
```
https://192.168.68.69:5001/
```

### 2. Установите Container Manager
- Package Center → Container Manager → Install

### 3. Создайте папку проекта
- File Station → docker → create folder `aic-app`

### 4. Загрузите файлы
Скопируйте в `/docker/aic-app/`:
- ✅ `docker-compose.nas.yml`
- ✅ `simple-test-server-nas.js`  
- ✅ `package-nas.json`
- ✅ `apps/api/create-pii-fixed-schema.sql`

### 5. Запустите в Container Manager
1. Project → Create
2. Project Name: `aic-app`
3. Path: `/docker/aic-app`
4. Загрузите `docker-compose.nas.yml`
5. Build → Run

## 🧪 Тестирование

### Проверка API:
```bash
curl http://192.168.68.69:3000/health
```

### Создание пользователя:
```bash
curl -X POST http://192.168.68.69:3000/auth/guest \
  -H "Content-Type: application/json"
```

## 📱 Flutter App

В `api_config.dart` уже настроено:
```dart
static const ServerEnvironment _currentEnv = ServerEnvironment.nas;
```

Просто переключите и запустите приложение!

## 🎯 Результат

После развертывания:
- ✅ API: http://192.168.68.69:3000
- ✅ PostgreSQL: 192.168.68.69:5432
- ✅ Redis: 192.168.68.69:6379
- ✅ PgAdmin: http://192.168.68.69:8080 (опционально)

**24/7 доступность для тестирования!** 🎉