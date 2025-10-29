# Обновление дизайна иконки хештега

## Задача
Изменить иконку хештега в `HashtagScreen` - сделать её квадратной с закругленными краями и выровнять по левому краю.

## Изменения

### 1. Обновлена иконка хештега
```dart
// Старый код - круглая иконка по центру
Container(
  width: 80,
  height: 80,
  decoration: BoxDecoration(
    color: const Color(0xFF0095F6),
    borderRadius: BorderRadius.circular(40), // Круглая
  ),
  child: const Icon(
    EvaIcons.hash,
    color: Colors.white,
    size: 40,
  ),
),

// Новый код - квадратная с закругленными краями, выровнена по левому краю
Align(
  alignment: Alignment.centerLeft,
  child: Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      color: const Color(0xFF0095F6),
      borderRadius: BorderRadius.circular(12), // Квадратная с закругленными краями
    ),
    child: const Icon(
      EvaIcons.hash,
      color: Colors.white,
      size: 40,
    ),
  ),
),
```

### 2. Выровнен текст по левому краю
```dart
// Название хештега
Align(
  alignment: Alignment.centerLeft,
  child: Text(
    '#${widget.hashtag}',
    style: const TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  ),
),

// Количество постов
Align(
  alignment: Alignment.centerLeft,
  child: Text(
    '${_posts.length} ${_posts.length == 1 ? 'post' : 'posts'}',
    style: const TextStyle(
      color: Colors.grey,
      fontSize: 16,
    ),
  ),
),
```

## Результат
- ✅ Иконка хештега теперь квадратная с закругленными краями (borderRadius: 12)
- ✅ Иконка выровнена по левому краю
- ✅ Текст хештега выровнен по левому краю
- ✅ Количество постов выровнено по левому краю
- ✅ Единообразное выравнивание всех элементов

## Тестирование
1. Откройте страницу с хештегом (например, `#писька`)
2. Проверьте, что иконка хештега квадратная с закругленными краями
3. Проверьте, что иконка и текст выровнены по левому краю
4. Проверьте общий вид страницы

## Статус
✅ Обновлен дизайн иконки хештега
✅ Изменена форма с круглой на квадратную с закругленными краями
✅ Выравнивание по левому краю
✅ Улучшен внешний вид страницы хештега
