# Исправление хештегов в ленте (PostCard)

## Проблема
Хештеги с кириллицей работали в комментариях (развернутом состоянии), но не работали в ленте постов (PostCard).

## Причина
В `PostCard` использовался обычный `RichText` без обработки хештегов через `HashtagUtils`.

## Решение

### 1. Добавлены импорты
```dart
import '../screens/hashtag_screen.dart';
import '../utils/hashtag_utils.dart';
```

### 2. Добавлен метод навигации
```dart
void _navigateToHashtag(String hashtag) {
  print('PostCard: Navigating to hashtag: $hashtag');
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => HashtagScreen(hashtag: hashtag),
    ),
  );
}
```

### 3. Обновлен Caption
```dart
// Старый код
RichText(
  text: TextSpan(
    style: const TextStyle(color: Colors.white),
    children: [
      TextSpan(
        text: '${widget.post.user?.name ?? widget.post.user?.username ?? 'Unknown'} ',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      TextSpan(text: widget.post.caption),
    ],
  ),
),

// Новый код
Text.rich(
  TextSpan(
    children: [
      TextSpan(
        text: '${widget.post.user?.name ?? widget.post.user?.username ?? 'Unknown'} ',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      ...HashtagUtils.parseTextWithHashtags(
        widget.post.caption,
        defaultStyle: const TextStyle(color: Colors.white),
        hashtagStyle: const TextStyle(
          color: Color(0xFF0095F6),
          fontWeight: FontWeight.w600,
        ),
        onHashtagTap: _navigateToHashtag,
      ),
    ],
  ),
),
```

### 4. Обновлены комментарии
Аналогично обновлены комментарии в ленте для поддержки хештегов.

## Тестирование
1. Создайте пост с хештегом: `#писька`
2. Проверьте ленту - хештег должен отображаться синим цветом
3. Нажмите на хештег - должна открыться страница с постами по этому хештегу
4. Проверьте комментарии в ленте - хештеги тоже должны работать

## Статус
✅ Добавлена поддержка хештегов в PostCard
✅ Обновлен Caption с поддержкой хештегов
✅ Обновлены комментарии с поддержкой хештегов
✅ Добавлена навигация к хештегам
✅ Поддержка кириллических хештегов в ленте
