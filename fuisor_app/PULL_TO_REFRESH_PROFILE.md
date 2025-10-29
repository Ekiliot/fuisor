# Pull-to-Refresh для страницы профиля

## Описание
Добавлена функциональность pull-to-refresh на страницу профиля пользователя. Теперь пользователи могут обновить данные профиля свайпом вниз, как это принято в современных мобильных приложениях.

## Реализованные изменения

### 1. AuthProvider - метод refreshProfile()
```dart
// Обновить данные профиля пользователя
Future<void> refreshProfile() async {
  try {
    _setLoading(true);
    _setError(null);

    // Получаем обновленные данные профиля с сервера
    final updatedUser = await _apiService.getCurrentUser();
    _currentUser = updatedUser;
    
    // Обновляем сессию с новыми данными
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(_accessTokenKey);
      final refreshToken = prefs.getString(_refreshTokenKey);
      if (accessToken != null && refreshToken != null) {
        await _saveSession(accessToken, refreshToken, _currentUser!);
      }
    }
    
    _setLoading(false);
  } catch (e) {
    _setError(e.toString());
    _setLoading(false);
  }
}
```

### 2. ApiService - метод getCurrentUser()
```dart
// Получить текущего пользователя
Future<User> getCurrentUser() async {
  final response = await http.get(
    Uri.parse('$baseUrl/users/profile'),
    headers: _headers,
  );

  if (response.statusCode == 200) {
    return User.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load current user');
  }
}
```

### 3. ProfileScreen - SmartRefresher
```dart
class _ProfileScreenState extends State<ProfileScreen> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  Future<void> _onRefresh() async {
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.refreshProfile();
      
      if (mounted) {
        _refreshController.refreshCompleted();
        
        // Показываем уведомление об успешном обновлении
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated!'),
            backgroundColor: Color(0xFF0095F6),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _refreshController.refreshFailed();
        
        // Показываем уведомление об ошибке
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            enablePullDown: true,
            enablePullUp: false,
            header: const WaterDropHeader(
              waterDropColor: Color(0xFF0095F6),
              complete: Icon(
                EvaIcons.checkmarkCircle,
                color: Color(0xFF0095F6),
                size: 20,
              ),
              failed: Icon(
                EvaIcons.closeCircle,
                color: Colors.red,
                size: 20,
              ),
            ),
            child: SingleChildScrollView(
              // ... содержимое профиля
            ),
          );
        },
      ),
    );
  }
}
```

## Функциональность

### ✅ **Что происходит при pull-to-refresh:**

1. **Свайп вниз** - пользователь тянет страницу вниз
2. **Анимация загрузки** - показывается WaterDropHeader с анимацией
3. **Запрос к серверу** - вызывается `authProvider.refreshProfile()`
4. **Обновление данных** - получаются актуальные данные профиля с сервера
5. **Обновление сессии** - новые данные сохраняются в SharedPreferences
6. **Уведомление** - показывается SnackBar с результатом операции

### 🎨 **UI элементы:**

- **WaterDropHeader** - красивая анимация с каплей воды в цвете Instagram (#0095F6)
- **Иконки состояния** - ✅ для успеха, ❌ для ошибки
- **SnackBar уведомления** - синий для успеха, красный для ошибки

### 🔄 **Обновляемые данные:**

- **Аватар** - новое изображение профиля
- **Имя и username** - актуальная информация
- **Био** - описание профиля
- **Статистика** - количество постов, подписчиков, подписок
- **Кэш изображений** - очищается для корректного отображения

## Использование

### Для пользователя:
1. Откройте страницу профиля
2. Потяните страницу вниз (свайп вниз)
3. Дождитесь завершения обновления
4. Увидите уведомление об успешном обновлении

### Для разработчика:
```dart
// Программное обновление профиля
final authProvider = context.read<AuthProvider>();
await authProvider.refreshProfile();
```

## Зависимости

Используется пакет `pull_to_refresh` который уже добавлен в `pubspec.yaml`:
```yaml
dependencies:
  pull_to_refresh: ^2.0.0
```

## Результат

✅ **Современный UX** - pull-to-refresh как в Instagram и других популярных приложениях  
✅ **Актуальные данные** - профиль всегда показывает последнюю информацию  
✅ **Красивая анимация** - WaterDropHeader с фирменными цветами  
✅ **Обратная связь** - уведомления о результате операции  
✅ **Надежность** - обработка ошибок и состояний загрузки  

Теперь страница профиля работает как в современных социальных сетях! 🎉
