# AIc Mobile App - Comprehensive Testing Guide

## Overview

Этот проект использует **Patrol** для comprehensive integration testing. Patrol позволяет тестировать реальные пользовательские сценарии, включая взаимодействие с нативными элементами устройства.

## Тестирование Architecture

### Test Structure
```
integration_test/
├── app_comprehensive_test.dart     # Основные пользовательские флоу
├── chat_feature_test.dart          # Тесты чат-функциональности  
├── api_integration_test.dart       # API интеграция и сетевые запросы
└── ui_ux_test.dart                # UI/UX компоненты и анимации
```

### Test Categories

#### 🚀 **Critical Tests** (app_comprehensive_test.dart)
- Запуск приложения и инициализация
- Основная навигация между экранами
- Loading states и переходы
- Основные пользовательские флоу

#### 💬 **Chat Feature Tests** (chat_feature_test.dart) 
- UI компоненты чата
- Отправка и получение сообщений
- Обработка разных типов сообщений (длинные, пустые, специальные символы)
- Scroll функциональность
- Keyboard interactions

#### 🌐 **API Integration Tests** (api_integration_test.dart)
- Подключение к API серверу
- Реальные API запросы через OpenRouter
- Обработка ошибок сети
- Timeout handling
- Fallback scenarios

#### 🎨 **UI/UX Tests** (ui_ux_test.dart)
- Dynamic content rendering
- Mood selector interactions
- Quick actions grid
- Responsive design
- Accessibility features
- Performance testing

## Quick Start

### Prerequisites

1. **API Server Running**:
   ```bash
   cd ../api
   npm install
   npm start
   ```

2. **Flutter Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Device/Simulator Ready**:
   ```bash
   flutter devices
   ```

### Running Tests

#### Option 1: Full Test Suite (Recommended)
```bash
./run_comprehensive_tests.sh
```

#### Option 2: Specific Test Category
```bash
# Chat tests only
flutter test integration_test/chat_feature_test.dart

# API tests only  
flutter test integration_test/api_integration_test.dart

# UI tests only
flutter test integration_test/ui_ux_test.dart

# All integration tests
flutter test integration_test/
```

#### Option 3: Specific Device
```bash
./run_comprehensive_tests.sh -d AC592D75-12E9-40A3-BCCD-E71A95A3F37A
```

## Test Coverage

### 📱 **App Flow Coverage**
- ✅ App startup and initialization (2s loading)
- ✅ Home screen dynamic content loading  
- ✅ Navigation to all main sections
- ✅ Back navigation and state preservation
- ✅ Error handling and fallbacks

### 💬 **Chat Functionality Coverage**
- ✅ Chat UI components (TextField, FloatingActionButton, ListView)
- ✅ Message sending and display
- ✅ Multiple messages conversation flow
- ✅ Empty/long/special character message handling
- ✅ Chat scroll functionality
- ✅ Keyboard interactions
- ✅ Response time tolerance
- ✅ Navigation to/from chat

### 🌐 **API Integration Coverage**
- ✅ API health check and connectivity
- ✅ Real API requests to OpenRouter
- ✅ Network error handling
- ✅ Multiple concurrent API calls
- ✅ Authentication flow (guest mode)
- ✅ API response time tolerance
- ✅ Fallback scenarios when API unavailable

### 🎨 **UI/UX Coverage**
- ✅ Dynamic screen rendering from JSON data
- ✅ Mood selector interactions (😄😊😐😕😢)
- ✅ Quick actions grid (Чат, Медитация, Советы, Поддержка)
- ✅ Screen scrolling and responsive design
- ✅ Loading animations and states
- ✅ Navigation transitions
- ✅ Touch targets and gesture handling
- ✅ Performance under intensive navigation
- ✅ Memory usage optimization

## Expected Test Results

### ✅ **Should PASS**
- App startup and loading screen
- Home screen with all dynamic blocks
- Basic navigation between screens
- Chat interface rendering
- Message sending (local display)
- Mood selector interactions
- Quick actions navigation

### ⚠️ **May WARN/FAIL (Expected)**
- API responses (if server not running)
- Real AI message responses (network dependent)
- Some advanced native interactions
- Performance tests on slower devices

### ❌ **Should NOT CRASH**
- Empty message sending
- Rapid navigation
- Network errors
- Long messages
- Special characters
- Multiple API calls

## Troubleshooting

### Common Issues

#### Tests Fail Immediately
```bash
# Check Flutter doctor
flutter doctor

# Clean and reinstall
flutter clean && flutter pub get

# Check device connection
flutter devices
```

#### API Tests Fail
```bash
# Start API server
cd ../api && npm start

# Check API health
curl http://localhost:3000/health

# Run with specific device
./run_comprehensive_tests.sh -d YOUR_DEVICE_ID
```

#### Chat Tests Fail
- Ensure OpenRouter API is configured
- Check `api_client_simple.dart` configuration
- Verify guest user creation works

#### UI Tests Fail
- Check dynamic content loading from `assets/data/screens.json`
- Verify block renderer components work
- Test on different screen sizes

### Debug Mode

Для более детального отладочного вывода:
```bash
flutter test integration_test/ --verbose
```

Для запуска отдельного теста:
```bash
flutter test integration_test/chat_feature_test.dart -n "Chat UI components are present"
```

## Test Data

### Dynamic Content
Тесты используют реальные данные из:
- `assets/data/screens.json` - структура экранов
- `assets/data/situations.json` - данные ситуаций

### Test Messages
Стандартные тестовые сообщения:
- "Привет, как дела?" - базовый тест
- "Это тестовое сообщение" - проверка отображения
- Long messages для scroll testing
- Special characters: "Тест 123 !@#$%^&*() 😊🎉💝"

## Continuous Integration

### GitHub Actions Integration
```yaml
# .github/workflows/test.yml
name: Flutter Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test integration_test/
```

### Local Pre-commit Hook
```bash
# .git/hooks/pre-commit
#!/bin/bash
cd apps/mobile
./run_comprehensive_tests.sh
```

## Performance Benchmarks

### Expected Test Duration
- **Unit Tests**: ~30 seconds
- **Integration Tests**: ~5-10 minutes
- **Full Suite**: ~10-15 minutes

### Memory Usage
- **App Startup**: <100MB
- **Chat with Messages**: <150MB
- **After Intensive Navigation**: <200MB

## Questions & Support

**Q: Тесты падают на simulator, но работают на реальном устройстве?**
A: Проверьте настройки simulator, особенно hardware keyboard settings.

**Q: API тесты всегда падают?**
A: Убедитесь что API server запущен на localhost:3000 и доступен.

**Q: Как добавить новый тест?**
A: Добавьте `patrolTest` в соответствующий файл, следуя existing patterns.

**Q: Можно ли запускать тесты на реальном iPhone?**
A: Да, используйте device ID: `./run_comprehensive_tests.sh -d 00008130-00115021348A001C`

---

## Next Steps

1. **Запустите полный test suite**: `./run_comprehensive_tests.sh`
2. **Проверьте результаты** в `test_results/` directory
3. **Исправьте failing tests** начиная с critical
4. **Настройте CI/CD** для автоматических тестов
5. **Добавьте monitoring** для production testing

Happy Testing! 🚀