# Инструкции AIc для Copilot

Этот проект — **AIc**, AI-компаньон в виде сенбернара для подростков (9-18 лет), построенный как безопасный freemium monorepo с поддержкой подписок.

## Основная архитектура

**Мульти-сервисная структура:** NestJS API (`apps/api`) + Flutter мобильное (`apps/mobile`) + CMS (`cms/`) + общие пакеты
- **Фокус на Prisma схеме:** Все модели данных в `/apps/api/prisma/schema.prisma` - User, ChatSession, ChatMessage, SafetyLog, Purchase
- **Безопасность прежде всего:** Каждое чат-взаимодействие логируется в `SafetyLog` с флагами безопасности (`safe`/`warning`/`blocked`)
- **Age gate и согласие:** Пользователи <16 (DE), <15 (CZ) требуют родительского согласия, поле `consentFlags`
- **Логика по возрасту:** У пользователей есть поле `ageGroup` (`9-12`, `13-15`, `16-18`), влияющее на фильтрацию контента
- **Локализация:** Поддержка `cs-CZ`, `de-DE`, `en-US` локалей повсюду, планы расширения (FR, PL)
- **Freemium модель:** 7 дней бесплатно → подписка через RevenueCat

## Критически важные процессы

**Последовательность запуска разработки (обязательно):**
```bash
npm run infra:up      # Контейнеры PostgreSQL + Redis
npm run db:migrate    # Применить миграции Prisma
npm run dev          # Запустить одновременно API + мобильное приложение
```

**WebSocket chat pattern:** Реал-тайм чат использует Socket.io namespace `/chat` с комнатами сессий
- Клиент присоединяется к сессии: `join_session` → `joined_session`
- Поток сообщений: `chat:message` → проверка безопасности → ответ AI → broadcast в сессию
- **API эндпоинты:** POST `/chat/session` (создание), WS `/chat/stream` (стриминг AI ответов)
- **REST паттерны:** GET `/content/topics`, GET `/sos/resources?country=CZ`, RevenueCat webhooks

**Разработка с приоритетом безопасности:** Весь контент пользователей должен проходить через фильтрацию безопасности
- Обращайтесь к `/packages/safety/src/policies.ts` для паттернов обнаружения кризисов
- Используйте `CRISIS_RESPONSE_TEMPLATES` для обработки деликатных тем
- Логируйте все взаимодействия с соответствующими значениями `safetyFlag`
- **AI модерация:** Используется Azure OpenAI/Vertex AI (EU region) с safety pipeline

**AI + RAG архитектура:** AI-компаньон "Айк" (дружелюбный сенбернар) с персонализированными ответами
- **pgvector интеграция:** Эмбеддинги для поиска по локальному контенту (эмоции, учеба, семья, право)
- **CMS контент:** Статьи, аффирмации, медитации через headless CMS (Strapi)
- **Возрастные промпты:** Разные AI промпты для каждой возрастной группы
- **Safety pipeline:** Классификаторы входа (self-harm, NSFW), SOS-шаблоны, policy-промпты
- **Streaming ответы:** WebSocket `/chat/stream` для стриминг-ответов AI

## Проектные паттерны

**Структура модулей NestJS:** Модули по функциям (`auth`, `chat`, `sos`, `users`) все импортируют общий `PrismaService`

**Конвенции Prisma:**
- Используйте `cuid()` для всех ID
- Включайте timestamps `createdAt`/`updatedAt`
- Каскадное удаление для данных пользователя (`onDelete: Cascade`)
- **Основные таблицы:** users, profiles, chat_sessions, chat_messages, articles, sos_contacts, purchases
- **JSONB поля:** profiles.settings, chat_messages.safety_flags для гибких данных
- **Именование:** snake_case для таблиц/полей, camelCase в TypeScript моделях

**Паттерны безопасности:**
```typescript
// Всегда логируйте user interactions:
await prisma.safetyLog.create({
  data: { userId, content, flag: 'safe|warning|blocked', action: 'none|warning|escalate' }
})
```

**Архитектура Flutter:**
- Структура папок по функциям под `lib/features/`
- Riverpod для управления состоянием
- go_router для навигации
- SharedPreferences для persistence сессий
- Интеграция Socket.io для реал-тайм чата
- Firebase Messaging + flutter_local_notifications для пуш-уведомлений
- RevenueCat Flutter SDK для подписок и фритриала
- Rive/Lottie для анимаций маскота Айка
- **HTTP клиент:** dio для API запросов
- **Локальное хранилище:** hive (кэш), flutter_secure_storage (токены)
- **Аудио:** just_audio + audio_service для фоновых медитаций

**Архитектура Backend:**
- Redis + BullMQ для очередей и обработки пушей
- pgvector для эмбеддингов и RAG поиска
- Strapi CMS для контента и SOS-контактов
- RevenueCat webhooks для обработки подписок
- **Auth:** Auth0/Stytch/Clerk (JWT + age-gate)
- **Observability:** Sentry, OpenTelemetry, Grafana/Prometheus

**Общие типы:** Общие TypeScript типы в `/packages/common/src/index.ts`

## Безопасность и разработка для подростков

**Обработка кризисного контента:** Любое упоминание самоповреждения/суицида запускает пути эскалации, определенные в политиках безопасности
**Ответы по возрасту:** Фильтрация контента зависит от `ageGroup` - реализуйте проверки возраста в новых функциях
**Локализованные SOS ресурсы:** Экстренные контакты хранятся по стране/локали в модели `SosContact`
**Privacy by design:** Минимум PII, шифрование AES-256, соответствие GDPR-K
**Age gate комплаенс:** DE <16, CZ <15 лет требуют родительского согласия в `consentFlags`

## MVP функции

**Основные модули:** Аутентификация → Профиль/анкета → AI-чат → SOS-модуль → Контент (статьи/медитации) → Кастомизация собачки → Подписки
**Уведомления:** Локальные напоминания + push-кампании через Firebase
**Монетизация:** 7-дневный фритриал → RevenueCat подписка с A/B тестированием retention

## Ключевые файлы для понимания

- `/apps/api/src/chat/chat.gateway.ts` - Паттерны WebSocket реал-тайм
- `/apps/api/prisma/schema.prisma` - Полная модель данных
- `/packages/safety/src/policies.ts` - Правила системы безопасности
- `/apps/mobile/lib/features/chat/chat_page.dart` - Клиентская реализация чата

## Критические workflow'ы для разработчиков

**Добавление нового API с safety логированием:**
```typescript
// 1. Создать endpoint в контроллере с валидацией возраста
// 2. Добавить safety логирование через SafetyLog модель
// 3. Обновить Swagger документацию
```

**Обработка кризисного контента:**
```typescript
// Всегда: user input → safety check → log to SafetyLog → 
// если blocked/warning → показать SOS ресурсы → escalate
```

**Локализация нового контента:**
- Добавить в `/apps/mobile/lib/l10n/app_*.arb` файлы
- Обновить CMS контент для каждого locale
- Проверить SOS контакты для страны

## Точки интеграции

**Внешние сервисы:** RevenueCat (подписки), Firebase (уведомления), Amplitude (аналитика)
**URLs баз данных:** PostgreSQL на `:5432`, Redis на `:6379`, Swagger docs на `:3000/api`

При реализации новых функций всегда учитывайте последствия для безопасности, соответствие возрасту и потребности локализации. Начинайте с политик безопасности и работайте оттуда.

## Best Practices & Частые задачи

### Тестирование безопасности
```typescript
// Crisis detection тест - обязательно для всех chat features
describe('Crisis Detection', () => {
  it('should trigger SOS for suicide keywords', async () => {
    const result = await chatService.processMessage('я хочу покончить с собой');
    expect(result.safetyFlag).toBe('blocked');
    expect(result.sosTriggered).toBe(true);
  });
});
```

### Environment & Secrets
```bash
# Обязательные переменные (apps/api/.env)
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
AZURE_OPENAI_KEY=...        # Никогда не коммитить!
REVENUECAT_WEBHOOK_SECRET=... # Валидация webhooks
```

### Error Handling Patterns
```typescript
// AI API fallback - всегда иметь запасной план
try {
  const aiResponse = await azureOpenAI.chat(prompt);
} catch (error) {
  logger.error('AI API failed', { userId, error });
  return FALLBACK_RESPONSES[user.ageGroup].generic;
}
```

### Performance & Limits
- **Chat sessions:** Макс 100 сообщений, затем архивировать
- **API rate limiting:** 10 req/min per user для chat endpoints
- **pgvector queries:** Лимит 50 документов в RAG поиске
- **WebSocket:** Таймаут 30s для неактивных соединений