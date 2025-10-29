# Исправление сохранения хештегов при создании поста

## Проблема
Хештеги не сохранялись в базе данных при создании поста, поэтому при поиске по хештегам посты не находились.

## Причина
В `CreatePostScreen` не извлекались хештеги из текста описания поста и не передавались в API.

## Решение

### 1. Добавлен импорт HashtagUtils
```dart
import '../utils/hashtag_utils.dart';
```

### 2. Обновлен метод _createPost
```dart
// Extract hashtags from caption
final captionText = _captionController.text.trim();
final hashtags = HashtagUtils.extractHashtags(captionText)
    .map((tag) => tag.substring(1).toLowerCase()) // Remove # and convert to lowercase
    .toList();

print('CreatePostScreen: Extracted hashtags: $hashtags');

await postsProvider.createPost(
  caption: captionText,
  mediaBytes: mediaBytes,
  mediaFileName: mediaFileName,
  mediaType: mediaType,
  hashtags: hashtags.isNotEmpty ? hashtags : null,
  accessToken: accessToken,
);
```

### 3. Добавлена отладочная информация в HashtagScreen
```dart
print('HashtagScreen: Loading posts for hashtag: ${widget.hashtag}');
print('HashtagScreen: Page: $_currentPage, Limit: $_limit');
// ... after API call ...
print('HashtagScreen: Received ${posts.length} posts');
```

## Логика работы
1. При создании поста извлекаются хештеги из текста описания
2. Хештеги очищаются (убирается # и приводится к нижнему регистру)
3. Хештеги передаются в API для сохранения в базе данных
4. При поиске по хештегам API возвращает соответствующие посты

## Тестирование
1. Создайте новый пост с описанием: `"Тестовый пост #писька"`
2. Проверьте логи - должно появиться:
   ```
   CreatePostScreen: Extracted hashtags: [писька]
   ```
3. Сохраните пост
4. Нажмите на хештег `#писька` в ленте
5. Проверьте логи - должно появиться:
   ```
   HashtagScreen: Loading posts for hashtag: писька
   HashtagScreen: Received 1 posts
   ```
6. Должна открыться страница с вашим постом

## Статус
✅ Добавлено извлечение хештегов при создании поста
✅ Хештеги передаются в API
✅ Добавлена отладочная информация
✅ Исправлено сохранение хештегов в базе данных
