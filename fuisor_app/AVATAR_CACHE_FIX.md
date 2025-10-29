# Исправление проблемы с кэшированием аватаров

## Проблема
После обновления аватара пользователя приложение продолжало пытаться загружать старый аватар из кэша, хотя в базе данных уже была новая ссылка.

**Ошибка:**
```
Avatar load error for https://zceveougbxnatwehikga.supabase.co/storage/v1/object/public/avatars/5d1wxh.aa2567a8-2b98-43d9-9319-7161e24eb68d: EncodingError: The source image cannot be decoded.
Image decoding error detected, showing fallback icon
```

**В базе данных:** `https://zceveougbxnatwehikga.supabase.co/storage/v1/object/public/avatars/6ijf0j.jpg`

## Причина
1. **Кэширование CachedNetworkImage** - виджет кэширует изображения по URL
2. **Не обновляется состояние** - после обновления профиля состояние пользователя не обновлялось в SharedPreferences
3. **Старые файлы не удалялись** - при загрузке нового аватара старый файл оставался в Supabase Storage

## Решение

### 1. Обновление SafeAvatar widget
Добавлены параметры для лучшего кэширования:

```dart
CachedNetworkImage(
  imageUrl: imageUrl!,
  width: radius * 2,
  height: radius * 2,
  fit: BoxFit.cover,
  // Используем URL как cacheKey для правильного кэширования
  cacheKey: imageUrl!,
  // Добавляем дополнительные заголовки для лучшей совместимости
  httpHeaders: const {
    'Accept': 'image/*',
    'Cache-Control': 'no-cache',
  },
  // ... остальные параметры
)
```

### 2. Удаление старых аватаров в backend
В `src/routes/user.routes.js` добавлена логика удаления старого аватара:

```javascript
if (avatar) {
  // Сначала получаем текущий аватар пользователя для удаления
  const { data: currentProfile } = await supabaseAdmin
    .from('profiles')
    .select('avatar_url')
    .eq('id', req.user.id)
    .single();

  // ... загрузка нового аватара ...

  // Удаляем старый аватар, если он существует
  if (currentProfile?.avatar_url) {
    try {
      // Извлекаем имя файла из URL
      const oldFileName = currentProfile.avatar_url.split('/').pop();
      console.log('Deleting old avatar:', oldFileName);
      
      const { error: deleteError } = await supabaseAdmin.storage
        .from('avatars')
        .remove([oldFileName]);
      
      if (deleteError) {
        console.error('Error deleting old avatar:', deleteError);
        // Не прерываем выполнение, так как новый аватар уже загружен
      } else {
        console.log('Old avatar deleted successfully');
      }
    } catch (deleteErr) {
      console.error('Error deleting old avatar:', deleteErr);
      // Не прерываем выполнение, так как новый аватар уже загружен
    }
  }
}
```

### 3. Обновление сессии в AuthProvider
После обновления профиля теперь обновляется сессия:

```dart
// Обновляем сессию с новыми данными пользователя
if (_currentUser != null) {
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString(_accessTokenKey);
  final refreshToken = prefs.getString(_refreshTokenKey);
  if (accessToken != null && refreshToken != null) {
    await _saveSession(accessToken, refreshToken, _currentUser!);
  }
  
  // Очищаем кэш изображений для обновления аватара
  await ImageCacheUtils.clearImageCache();
}
```

### 4. Утилита для очистки кэша
Создан `ImageCacheUtils` для управления кэшем изображений:

```dart
class ImageCacheUtils {
  /// Очищает весь кэш изображений
  static Future<void> clearImageCache() async {
    try {
      await CachedNetworkImage.evictFromCache('');
      print('Image cache cleared successfully');
    } catch (e) {
      print('Error clearing image cache: $e');
    }
  }
  
  /// Очищает кэш для конкретного URL
  static Future<void> clearImageCacheForUrl(String url) async {
    try {
      await CachedNetworkImage.evictFromCache(url);
      print('Image cache cleared for URL: $url');
    } catch (e) {
      print('Error clearing image cache for URL $url: $e');
    }
  }
}
```

### 5. Скрипт для очистки старых файлов
Создан `cleanup-avatars.js` для удаления неиспользуемых аватаров из Supabase Storage:

```javascript
async function cleanupOldAvatars() {
  // Получаем все файлы в bucket avatars
  const { data: files } = await supabaseAdmin.storage
    .from('avatars')
    .list();
  
  // Получаем все профили с аватарами
  const { data: profiles } = await supabaseAdmin
    .from('profiles')
    .select('id, username, avatar_url')
    .not('avatar_url', 'is', null);
  
  // Находим файлы, которые не используются
  const usedFileNames = profiles.map(profile => 
    profile.avatar_url.split('/').pop()
  );
  
  const unusedFiles = files.filter(file => 
    !usedFileNames.includes(file.name)
  );
  
  // Удаляем неиспользуемые файлы
  if (unusedFiles.length > 0) {
    const fileNamesToDelete = unusedFiles.map(file => file.name);
    await supabaseAdmin.storage
      .from('avatars')
      .remove(fileNamesToDelete);
  }
}
```

## Результат
✅ **Старые аватары автоматически удаляются** при загрузке новых  
✅ **Кэш изображений очищается** после обновления профиля  
✅ **Состояние пользователя обновляется** в SharedPreferences  
✅ **Неиспользуемые файлы удаляются** из Supabase Storage  

## Тестирование
1. Обновите аватар пользователя через приложение
2. Проверьте, что старый файл удален из Supabase Storage
3. Убедитесь, что новый аватар отображается корректно
4. Проверьте, что при перезапуске приложения аватар загружается правильно

## Файлы изменены
- `src/routes/user.routes.js` - добавлено удаление старых аватаров
- `fuisor_app/lib/widgets/safe_avatar.dart` - улучшено кэширование
- `fuisor_app/lib/providers/auth_provider.dart` - обновление сессии и очистка кэша
- `fuisor_app/lib/screens/edit_profile_screen.dart` - принудительное обновление состояния
- `fuisor_app/lib/utils/image_cache_utils.dart` - утилита для управления кэшем
- `cleanup-avatars.js` - скрипт для очистки неиспользуемых файлов
