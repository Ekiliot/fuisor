# Загрузка постов с медиа как в Instagram

## Описание
Реализована полноценная система загрузки постов с фотографиями и видео, аналогичная Instagram. Пользователи могут выбирать медиа из галереи, просматривать предпросмотр и создавать посты с подписями.

## Архитектура

### 1. MediaSelectionScreen - Выбор медиа
**Файл:** `fuisor_app/lib/screens/media_selection_screen.dart`

**Функциональность:**
- Выбор фото из галереи через `ImagePicker`
- Выбор видео из галереи (до 5 минут)
- Предпросмотр выбранного медиа
- Кнопки "Photo" и "Video" для выбора типа контента

**Ключевые методы:**
```dart
Future<void> _pickFromGallery() async {
  final XFile? image = await _picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1920,
    maxHeight: 1920,
    imageQuality: 85,
  );
}

Future<void> _pickVideoFromGallery() async {
  final XFile? video = await _picker.pickVideo(
    source: ImageSource.gallery,
    maxDuration: const Duration(minutes: 5),
  );
}
```

### 2. CreatePostScreen - Создание поста
**Файл:** `fuisor_app/lib/screens/create_post_screen.dart`

**Функциональность:**
- Предпросмотр выбранного медиа (фото/видео)
- Поле для ввода подписи (caption)
- Кнопка "Share" для публикации
- Обработка ошибок и состояний загрузки

**Ключевые методы:**
```dart
Future<void> _createPost() async {
  // Определение типа медиа по расширению файла
  String mediaType = 'image';
  if (widget.selectedFile!.path.toLowerCase().contains('.mp4')) {
    mediaType = 'video';
  }
  
  // Создание поста через PostsProvider
  await postsProvider.createPost(
    caption: _captionController.text.trim(),
    mediaBytes: mediaBytes,
    mediaFileName: mediaFileName,
    mediaType: mediaType,
  );
}
```

### 3. PostsProvider - Управление состоянием
**Файл:** `fuisor_app/lib/providers/posts_provider.dart`

**Новый метод:**
```dart
Future<void> createPost({
  required String caption,
  required Uint8List? mediaBytes,
  required String mediaFileName,
  required String mediaType,
  List<String>? mentions,
  List<String>? hashtags,
}) async {
  final newPost = await _apiService.createPost(
    caption: caption,
    mediaBytes: mediaBytes,
    mediaFileName: mediaFileName,
    mediaType: mediaType,
    mentions: mentions,
    hashtags: hashtags,
  );

  // Добавляем новый пост в начало списка
  _posts.insert(0, newPost);
}
```

### 4. ApiService - API интеграция
**Файл:** `fuisor_app/lib/services/api_service.dart`

**Новый метод:**
```dart
Future<Post> createPost({
  required String caption,
  required Uint8List? mediaBytes,
  required String mediaFileName,
  required String mediaType,
  List<String>? mentions,
  List<String>? hashtags,
}) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/posts'),
  );

  // Добавляем поля
  request.fields['caption'] = caption;
  request.fields['media_type'] = mediaType;
  
  // Добавляем медиа файл
  if (mediaBytes != null) {
    request.files.add(
      http.MultipartFile.fromBytes(
        'media',
        mediaBytes,
        filename: mediaFileName,
      ),
    );
  }
}
```

### 5. MainScreen - Навигация
**Файл:** `fuisor_app/lib/screens/main_screen.dart`

**Обновленная навигация:**
```dart
onTap: (index) {
  if (index == 2) {
    // Кнопка создания поста - открываем MediaSelectionScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MediaSelectionScreen(),
      ),
    );
  } else {
    setState(() {
      _currentIndex = index;
    });
  }
},
```

## Пользовательский интерфейс

### 🎨 **Дизайн в стиле Instagram:**

1. **MediaSelectionScreen:**
   - Темная тема с черным фоном (#000000)
   - Кнопки "Photo" (синяя) и "Video" (серая)
   - Предпросмотр медиа в квадратном формате
   - Кнопка "Next" для перехода к созданию поста

2. **CreatePostScreen:**
   - Предпросмотр медиа сверху (300px высота)
   - Поле для подписи с темным дизайном
   - Кнопка "Share" в правом верхнем углу
   - Индикатор загрузки при создании поста

### 📱 **Навигация:**
```
MainScreen (кнопка +) 
    ↓
MediaSelectionScreen (выбор медиа)
    ↓
CreatePostScreen (создание поста)
    ↓
MainScreen (возврат с уведомлением)
```

## Технические детали

### 📦 **Зависимости:**
```yaml
dependencies:
  image_picker: ^1.0.4  # Выбор медиа из галереи
  video_player: ^2.8.1  # Воспроизведение видео
  photo_manager: ^3.0.0 # (опционально) для сетки медиа
```

### 🔄 **Обработка медиа:**

1. **Изображения:**
   - Максимальный размер: 1920x1920
   - Качество: 85%
   - Форматы: JPG, PNG, GIF, WebP

2. **Видео:**
   - Максимальная длительность: 5 минут
   - Форматы: MP4, MOV, AVI
   - Предпросмотр через VideoPlayerController

### 🚀 **Процесс создания поста:**

1. **Выбор медиа** → пользователь выбирает фото/видео
2. **Предпросмотр** → показывается выбранное медиа
3. **Ввод подписи** → пользователь пишет описание
4. **Загрузка** → медиа отправляется на сервер
5. **Создание поста** → пост добавляется в базу данных
6. **Обновление UI** → новый пост появляется в ленте

## Результат

✅ **Полноценная загрузка постов** как в Instagram  
✅ **Поддержка фото и видео** с предпросмотром  
✅ **Красивый UI** в темной теме  
✅ **Обработка ошибок** и состояний загрузки  
✅ **Интеграция с API** через наш backend  
✅ **Обновление ленты** после создания поста  

## Использование

1. **Нажмите кнопку "+"** в нижней навигации
2. **Выберите "Photo" или "Video"** для выбора медиа
3. **Просмотрите предпросмотр** выбранного файла
4. **Нажмите "Next"** для перехода к созданию поста
5. **Введите подпись** в текстовое поле
6. **Нажмите "Share"** для публикации поста

**Теперь приложение поддерживает полноценную загрузку постов с медиа!** 🎉
