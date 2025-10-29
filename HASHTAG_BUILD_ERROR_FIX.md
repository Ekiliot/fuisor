# Исправление ошибки setState() during build для хештегов

## Проблема
При попытке нажать на хештег в комментариях возникала ошибка:
```
Another exception was thrown: setState() or markNeedsBuild() called during build.
```

## Причина
Ошибка возникала потому, что в `HashtagUtils.parseTextWithHashtags` мы вызывали `Navigator.push` прямо в `onTap` callback, который выполняется во время `build` процесса.

## Решение

### 1. Исправление HashtagUtils
- Добавили `WidgetsBinding.instance.addPostFrameCallback` для отложенной навигации
- Добавили отладочную информацию для диагностики
- Обновили регулярное выражение для более точного поиска хештегов

### 2. Исправление CommentsScreen
- Создали отдельный метод `_navigateToHashtag` для навигации
- Заменили все inline callback'и на вызов этого метода
- Это предотвращает вызов `setState` во время `build`

### 3. Обновленное регулярное выражение
```dart
// Старое выражение
static final RegExp _hashtagRegex = RegExp(r'#\w+');

// Новое выражение - более точное
static final RegExp _hashtagRegex = RegExp(r'#[a-zA-Z0-9_]+');
```

## Тестирование
1. Создайте комментарий с хештегом: `#gbcmrf`
2. Проверьте, что хештег отображается синим цветом
3. Нажмите на хештег - должна открыться страница с постами по этому хештегу
4. Проверьте консоль на наличие отладочной информации

## Отладочная информация
Теперь в консоли будет выводиться:
- `HashtagUtils: Parsing text: "текст с #хештегом"`
- `HashtagUtils: Found hashtags: [#хештег]`
- `HashtagUtils: Text parts: [части текста]`
- `HashtagUtils: Adding hashtag: #хештег`
- `HashtagUtils: Created X text spans`
- `CommentsScreen: Navigating to hashtag: хештег`

## Статус
✅ Исправлена ошибка setState() during build
✅ Добавлена отладочная информация
✅ Обновлено регулярное выражение
✅ Создан отдельный метод навигации
