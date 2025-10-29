# Добавление навигации к постам в HashtagScreen

## Задача
Сделать так, чтобы при нажатии на пост в странице хештега открывался экран с деталями поста, как в ленте рекомендаций.

## Решение

### 1. Добавлен импорт CommentsScreen
```dart
import 'comments_screen.dart';
```

### 2. Обновлена навигация при нажатии на пост
```dart
// Старый код - навигация к заглушке PostDetailScreen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PostDetailScreen(
      post: post,
      onPostUpdated: (updatedPost) {
        setState(() {
          _posts[index] = updatedPost;
        });
      },
    ),
  ),
);

// Новый код - навигация к CommentsScreen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CommentsScreen(
      postId: post.id,
      post: post,
    ),
  ),
);
```

### 3. Удалена заглушка PostDetailScreen
- Убрана временная реализация `PostDetailScreen`
- Теперь используется полнофункциональный `CommentsScreen`

## Функциональность
Теперь при нажатии на пост в `HashtagScreen`:
1. Открывается `CommentsScreen` с полной функциональностью
2. Пользователь может просматривать комментарии
3. Может добавлять новые комментарии
4. Может лайкать/дизлайкать посты и комментарии
5. Может нажимать на хештеги в комментариях

## Тестирование
1. Откройте страницу с хештегом (например, `#писька`)
2. Нажмите на любой пост в сетке
3. Должен открыться экран комментариев с полной функциональностью
4. Проверьте, что все функции работают (лайки, комментарии, хештеги)

## Статус
✅ Добавлена навигация к CommentsScreen
✅ Удалена заглушка PostDetailScreen
✅ Полная функциональность постов в HashtagScreen
✅ Единообразный UX с основной лентой
