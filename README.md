# AIc - AI Companion for Teens 🐶

AIc — это дружелюбный AI-компаньон в виде сенбернара, созданный специально для подростков 9-18 лет. Приложение предоставляет эмоциональную поддержку, помощь в решении проблем и доступ к ресурсам экстренной помощи.

## 🏗️ Архитектура

Проект построен как monorepo и включает:

- **`apps/mobile/`** - Flutter приложение для iOS и Android
- **`apps/api/`** - NestJS backend с WebSocket поддержкой
- **`packages/common/`** - Общие типы и утилиты
- **`packages/safety/`** - Правила безопасности и SOS шаблоны
- **`infra/`** - Docker Compose для локальной разработки
- **`tests/`** - E2E тесты и тесты безопасности

## 🚀 Быстрый старт

### Предварительные требования

- Node.js 18+
- Flutter 3.22+
- Docker и Docker Compose
- PostgreSQL 15+ (или используйте Docker)

### 1. Локальная инфраструктура

```bash
# Запуск PostgreSQL и Redis
npm run infra:up

# Остановка
npm run infra:down
```

Доступные сервисы:
- PostgreSQL: `localhost:5432`
- Redis: `localhost:6379`
- Adminer (БД интерфейс): `http://localhost:8080`
- Redis Commander: `http://localhost:8081`

### 2. Настройка API

```bash
cd apps/api

# Установка зависимостей
npm install

# Копирование конфигурации
cp env.example .env

# Генерация Prisma клиента
npm run prisma:gen

# Запуск миграций
npm run prisma:migrate

# Заполнение тестовыми данными
npm run seed

# Запуск в режиме разработки
npm run dev
```

API будет доступен по адресу: `http://localhost:3000`  
Swagger документация: `http://localhost:3000/api`

### 3. Настройка мобильного приложения

```bash
cd apps/mobile

# Установка зависимостей
flutter pub get

# Запуск на эмуляторе/устройстве
flutter run

# Или для веб-версии
flutter run -d chrome
```

### 4. Сборка packages

```bash
# Сборка общих пакетов
npm run build:packages
```

## 📋 Основные команды

```bash
# Разработка (API + Mobile параллельно)
npm run dev

# Тестирование
npm test

# Линтинг
npm run lint

# Сборка
npm run build

# Очистка
npm run clean

# Работа с БД
npm run db:migrate    # Применить миграции
npm run db:seed       # Заполнить тестовыми данными
```

## 🌐 API Endpoints (MVP)

### Аутентификация
- `POST /auth/signup` — Регистрация пользователя
- `POST /auth/guest` — Создание гостевого аккаунта

### Чат
- `POST /chat/session` — Создание сессии чата
- `GET /chat/session/:id` — Информация о сессии
- `WS /chat` — WebSocket для real-time сообщений

### SOS и безопасность
- `GET /sos/resources?country=CZ&locale=cs-CZ` — Контакты экстренной помощи
- `GET /sos/crisis-check?text=...` — Проверка на кризисный контент

### Контент
- `GET /content/articles?topic=emotions&locale=cs-CZ` — Образовательные статьи

### Подписки
- `POST /subscriptions/revenuecat/webhook` — RevenueCat webhook

## 🔒 Безопасность

Ike использует многоуровневую систему безопасности:

1. **Детекция контента**: Автоматическое обнаружение кризисных ситуаций
2. **Возрастная фильтрация**: Контент адаптирован под возрастные группы
3. **SOS система**: Быстрый доступ к экстренной помощи
4. **Логирование**: Все взаимодействия логируются для анализа

### Тестирование безопасности

```bash
# Запуск тестов безопасности
cd tests/safety
npm test

# Проверка кризисных триггеров
npm run test:crisis-triggers
```

## 🔧 Разработка

### Структура проекта

```
ike-app/
├── apps/
│   ├── mobile/          # Flutter клиент
│   │   ├── lib/
│   │   │   ├── features/    # UI экраны по фичам
│   │   │   ├── services/    # API клиент, уведомления
│   │   │   ├── state/       # Состояние приложения (Riverpod)
│   │   │   └── l10n/        # Локализация
│   │   └── pubspec.yaml
│   └── api/             # NestJS backend
│       ├── src/
│       │   ├── auth/        # Аутентификация
│       │   ├── chat/        # Чат и WebSocket
│       │   ├── sos/         # Экстренная помощь
│       │   └── prisma/      # База данных
│       └── prisma/schema.prisma
├── packages/
│   ├── common/          # Общие типы
│   └── safety/          # Правила безопасности
└── infra/               # Docker Compose
```

### Добавление новых функций

1. **Новый API endpoint**:
   ```bash
   cd apps/api/src
   nest generate module feature-name
   nest generate controller feature-name
   nest generate service feature-name
   ```

2. **Новый экран в мобильном приложении**:
   ```bash
   cd apps/mobile/lib/features
   mkdir new-feature
   # Создать page.dart, state.dart и необходимые файлы
   ```

3. **Новые типы**:
   - Добавить в `packages/common/src/index.ts`
   - Обновить в обоих приложениях

### Миграции базы данных

```bash
cd apps/api

# Создание новой миграции
npx prisma migrate dev --name migration-name

# Применение в продакшене
npx prisma migrate deploy

# Сброс БД (только для разработки!)
npx prisma migrate reset
```

## 📱 Интеграции

### RevenueCat (подписки)
```typescript
// Flutter
import 'package:purchases_flutter/purchases_flutter.dart';

await Purchases.setup('your_api_key');
```

### Firebase (push-уведомления)
```typescript
// Flutter  
import 'package:firebase_messaging/firebase_messaging.dart';

FirebaseMessaging messaging = FirebaseMessaging.instance;
```

### Amplitude (аналитика)
```typescript
// Flutter
import 'package:amplitude_flutter/amplitude.dart';

Amplitude.getInstance().logEvent('event_name');
```

## 🌍 Локализация

Поддерживаемые языки:
- 🇺🇸 Английский (en-US)
- 🇨🇿 Чешский (cs-CZ)  
- 🇩🇪 Немецкий (de-DE)

Файлы локализации: `apps/mobile/lib/l10n/`

## 🚀 Деплой

### Staging
```bash
# API
docker build -t ike-api:staging apps/api
docker run -d -p 3000:3000 ike-api:staging

# Mobile - см. GitHub Actions
```

### Production
- API: Docker + Kubernetes
- Mobile: App Store + Google Play
- БД: Managed PostgreSQL (AWS RDS/Google Cloud SQL)

## 🤝 Участие в разработке

1. Fork репозитория
2. Создай feature branch: `git checkout -b feature/amazing-feature`
3. Коммит изменений: `git commit -m 'Add amazing feature'`
4. Push в branch: `git push origin feature/amazing-feature`
5. Открой Pull Request

### Правила кода

- **API**: ESLint + Prettier
- **Mobile**: Flutter/Dart conventions
- **Commit messages**: Conventional Commits
- **Tests**: Обязательны для новых функций

## 📞 Поддержка

- 📧 Email: dev@ike-app.com
- 🐛 Issues: GitHub Issues
- 📖 Wiki: GitHub Wiki

## 📄 Лицензия

MIT License - подробности в файле [LICENSE](LICENSE)

---

**⚠️ Важно**: Это приложение предназначено для поддержки, но не заменяет профессиональную психологическую помощь. В случае кризиса всегда обращайтесь к специалистам.
