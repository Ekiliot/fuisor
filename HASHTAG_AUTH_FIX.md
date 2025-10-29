# Исправление ошибки 401 Unauthorized для хештегов

## Проблема
При нажатии на хештег возникала ошибка 401 (Unauthorized):
```
GET http://localhost:3000/api/posts/hashtag/%D0%BF%D0%B8%D1%81%D1%8C%D0%BA%D0%B0?page=1&limit=10 401 (Unauthorized)
```

## Причина
В `HashtagScreen` создавался новый экземпляр `ApiService`, но не устанавливался токен авторизации. Поэтому запросы к API выполнялись без токена.

## Решение

### 1. Добавлены импорты в HashtagScreen
```dart
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
```

### 2. Обновлен метод _loadHashtagPosts
```dart
Future<void> _loadHashtagPosts({bool loadMore = false}) async {
  try {
    // ... existing code ...
    
    // Get access token from AuthProvider
    final authProvider = context.read<AuthProvider>();
    final accessToken = await authProvider.getAccessToken();
    
    if (accessToken == null) {
      throw Exception('No access token available');
    }

    // Set token in ApiService
    _apiService.setAccessToken(accessToken);

    final posts = await _apiService.getPostsByHashtag(
      widget.hashtag,
      page: _currentPage,
      limit: _limit,
    );
    
    // ... rest of the code ...
  } catch (e) {
    // ... error handling ...
  }
}
```

### 3. Логика работы
1. Получаем токен из `AuthProvider`
2. Устанавливаем токен в `ApiService`
3. Выполняем запрос к API с токеном
4. Обрабатываем результат

## Тестирование
1. Создайте пост с хештегом: `#писька`
2. Нажмите на хештег в ленте
3. Проверьте логи - должно появиться:
   ```
   PostCard: Navigating to hashtag: писька
   ApiService: Setting access token: Present (eyJhbGciOiJIUzI1NiIs...)
   ```
4. Должна открыться страница с постами по этому хештегу без ошибок 401

## Статус
✅ Добавлена авторизация в HashtagScreen
✅ Получение токена из AuthProvider
✅ Установка токена в ApiService
✅ Исправлена ошибка 401 Unauthorized
✅ Поддержка кириллических хештегов
