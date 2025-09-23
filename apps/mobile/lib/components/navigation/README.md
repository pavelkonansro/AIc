# Система навигации AIc 🧭

## Обзор

Создана единая система навигации для всего приложения AIc, которая обеспечивает консистентный UX и упрощает разработку.

## Компоненты

### 🏗️ **AicScaffold** - основной компонент
```dart
AicScaffold(
  title: 'Заголовок страницы',
  body: widget(), 
  showBottomNavigation: true,
  currentRoute: '/route',
)
```

### 🎯 **Специализированные scaffolds:**

#### **AicMainScaffold** - для главных страниц
```dart
AicMainScaffold(
  title: 'Главная',
  body: widget(),
  currentRoute: '/home',
)
```
- ✅ Показывает bottom navigation
- ✅ Скрывает кнопку назад
- ✅ Подсвечивает текущий раздел

#### **AicDetailScaffold** - для детальных страниц  
```dart
AicDetailScaffold(
  title: 'Детали',
  body: widget(),
  transparentAppBar: true,
)
```
- ✅ Показывает кнопку назад
- ✅ Скрывает bottom navigation
- ✅ Опциональный прозрачный AppBar

#### **AicChatScaffold** - для чата
```dart
AicChatScaffold(
  title: 'Чат с AIc',
  body: Chat(...),
  currentRoute: '/chat',
)
```
- ✅ Прозрачный AppBar
- ✅ Кнопка назад
- ✅ Оптимизирован для чата

## 📍 **Навигационные элементы**

### **AppBar действия:**
- 🏠 **Главная** - быстрый переход на home
- 💬 **Чат** - быстрый переход в чат
- ⋮ **Меню** - PopupMenu со всеми разделами

### **Bottom Navigation:**
- 🏠 **Главная** - `/home`
- 💬 **Чат** - `/chat` 
- 🧠 **Ситуации** - `/situations`
- 🧘 **Медитация** - `/meditation`
- 👤 **Профиль** - `/profile`

### **PopupMenu разделы:**
- 👤 Профиль
- ❤️ Мотивация  
- 🧘 Медитация
- 💡 Советы
- 🧠 Ситуации
- 🆘 Поддержка
- 🚨 SOS
- ⚙️ Настройки
- 🚪 Выйти

## 🔧 **Как использовать**

### 1. Обновить существующую страницу:
```dart
// Было:
return Scaffold(
  appBar: AppBar(title: Text('Профиль')),
  body: widget(),
);

// Стало:
return AicMainScaffold(
  title: 'Профиль',
  currentRoute: '/profile',
  body: widget(),
);
```

### 2. Добавить кастомные действия:
```dart
AicMainScaffold(
  title: 'Профиль',
  appBarActions: [
    IconButton(
      icon: Icon(Icons.edit),
      onPressed: () => editProfile(),
    ),
  ],
  body: widget(),
)
```

### 3. Создать детальную страницу:
```dart
AicDetailScaffold(
  title: 'Детали статьи',
  body: ArticleContent(),
  onBackPressed: () => customBackLogic(),
)
```

## ✅ **Преимущества**

1. **Консистентность** - единый дизайн навигации
2. **DRY принцип** - один раз написали, везде используем  
3. **Легкость использования** - простые API для разных случаев
4. **Централизованная логика** - все маршруты в одном месте
5. **Автоматическая подсветка** - активный раздел выделяется
6. **Responsive** - адаптируется под разные экраны

## 🔄 **Миграция**

Для обновления существующих страниц:
1. Импортировать `../../components/navigation/navigation.dart`
2. Заменить `Scaffold` на подходящий `Aic*Scaffold`
3. Передать `currentRoute` для корректной подсветки
4. Удалить дублирующуюся навигационную логику

## 🎨 **Кастомизация**

```dart
AicScaffold(
  title: 'Custom Page',
  transparentAppBar: true,           // Прозрачный AppBar
  showBottomNavigation: false,       // Скрыть bottom nav
  showBackButton: false,             // Скрыть кнопку назад  
  appBarBackgroundColor: Colors.red, // Цвет AppBar
  onBackPressed: () => customLogic(), // Кастомная логика назад
)
```