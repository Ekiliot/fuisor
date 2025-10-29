# ✅ ПОЛЕ "ИМЯ" ДОБАВЛЕНО! Username + Name в БД

## 🎉 **ЧТО СДЕЛАНО:**

### ✅ **База данных обновлена:**
- **Добавлено поле `name`** в таблицу `profiles`
- **Миграция создана** для существующих записей
- **Валидация добавлена** для поля name

### ✅ **Backend API обновлен:**
- **Регистрация** теперь принимает `name`
- **Логин** возвращает `name` в профиле
- **Обновление профиля** поддерживает `name`
- **Валидация** для поля name (1-50 символов)

### ✅ **Frontend обновлен:**
- **Модель User** включает поле `name`
- **Экран регистрации** с полем "Full Name"
- **Отображение имени** в постах и профиле
- **API сервис** поддерживает `name`

---

## 🗄️ **ИЗМЕНЕНИЯ В БАЗЕ ДАННЫХ:**

### **1. Схема profiles:**
```sql
CREATE TABLE profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,                    -- ✅ НОВОЕ ПОЛЕ
    email TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (id)
);
```

### **2. Миграция:**
```sql
-- Добавить поле name
ALTER TABLE profiles ADD COLUMN name TEXT;

-- Обновить существующие записи
UPDATE profiles SET name = username WHERE name IS NULL;

-- Сделать поле обязательным
ALTER TABLE profiles ALTER COLUMN name SET NOT NULL;
```

---

## 🔧 **ИЗМЕНЕНИЯ В BACKEND:**

### **1. Валидация (validation.middleware.js):**
```javascript
// Регистрация
export const validateSignup = [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 6 }),
  body('username').isLength({ min: 3, max: 30 }),
  body('name').isLength({ min: 1, max: 50 }),  // ✅ НОВОЕ
  validateRequest
];

// Обновление профиля
export const validateProfileUpdate = [
  body('username').optional().isLength({ min: 3, max: 30 }),
  body('name').optional().isLength({ min: 1, max: 50 }),  // ✅ НОВОЕ
  body('bio').optional().isLength({ max: 500 }),
  validateRequest
];
```

### **2. Регистрация (auth.routes.js):**
```javascript
router.post('/signup', validateSignup, async (req, res) => {
  const { email, password, username, name } = req.body;  // ✅ НОВОЕ
  
  const { error: profileError } = await supabaseAdmin
    .from('profiles')
    .insert([{
      id: data.user.id,
      username,
      name,        // ✅ НОВОЕ
      email,
    }]);
});
```

### **3. Логин (auth.routes.js):**
```javascript
const { data: userProfile } = await supabase
  .from('profiles')
  .select('username, name, avatar_url, bio')  // ✅ НОВОЕ
  .eq('id', data.user.id)
  .single();
```

### **4. Обновление профиля (user.routes.js):**
```javascript
router.put('/profile', validateAuth, upload.single('avatar'), validateProfileUpdate, async (req, res) => {
  const { username, name, bio } = req.body;  // ✅ НОВОЕ
  
  const updates = {
    ...(username && { username }),
    ...(name && { name }),        // ✅ НОВОЕ
    ...(bio && { bio }),
    ...(avatarUrl && { avatar_url: avatarUrl }),
    updated_at: new Date()
  };
});
```

---

## 📱 **ИЗМЕНЕНИЯ В FRONTEND:**

### **1. Модель User (user.dart):**
```dart
class User {
  final String id;
  final String username;
  final String name;        // ✅ НОВОЕ ПОЛЕ
  final String email;
  final String? avatarUrl;
  final String? bio;
  // ... остальные поля

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',        // ✅ НОВОЕ
      email: json['email'] ?? '',
      // ... остальные поля
    );
  }
}
```

### **2. Экран регистрации (signup_screen.dart):**
```dart
class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();  // ✅ НОВОЕ

  // Поле Full Name
  TextFormField(
    controller: _nameController,
    decoration: const InputDecoration(
      labelText: 'Full Name',  // ✅ НОВОЕ ПОЛЕ
    ),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Please enter your full name';
      }
      if (value.length > 50) {
        return 'Name must be less than 50 characters';
      }
      return null;
    },
  ),

  // Вызов signup с name
  final success = await authProvider.signup(
    _emailController.text.trim(),
    _passwordController.text,
    _usernameController.text.trim(),
    _nameController.text.trim(),  // ✅ НОВОЕ
  );
}
```

### **3. API сервис (api_service.dart):**
```dart
Future<void> signup(String email, String password, String username, String name) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/signup'),
    headers: _headers,
    body: jsonEncode({
      'email': email,
      'password': password,
      'username': username,
      'name': name,        // ✅ НОВОЕ
    }),
  );
}
```

### **4. Отображение в постах (post_card.dart):**
```dart
// Заголовок поста
Text(
  widget.post.user?.name ?? widget.post.user?.username ?? 'Unknown',  // ✅ ИМЯ
  style: const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: Colors.white,
  ),
),
Text(
  '@${widget.post.user?.username ?? 'unknown'}',  // ✅ USERNAME
  style: const TextStyle(
    color: Color(0xFF8E8E8E),
    fontSize: 12,
  ),
),

// Caption поста
TextSpan(
  text: '${widget.post.user?.name ?? widget.post.user?.username ?? 'Unknown'} ',  // ✅ ИМЯ
  style: const TextStyle(fontWeight: FontWeight.w600),
),
```

### **5. Профиль пользователя (profile_screen.dart):**
```dart
Text(
  user.name,        // ✅ ИМЯ
  style: const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: Colors.white,
  ),
),
Text(
  '@${user.username}',  // ✅ USERNAME
  style: const TextStyle(
    fontSize: 14,
    color: Color(0xFF8E8E8E),
  ),
),
```

---

## 🎯 **РЕЗУЛЬТАТ:**

### **Теперь у пользователей есть:**
- ✅ **Username** - уникальный идентификатор (@username)
- ✅ **Name** - отображаемое имя (Full Name)
- ✅ **Email** - для входа
- ✅ **Bio** - описание профиля

### **Отображение:**
- ✅ **В постах:** "John Doe @johndoe • 2h"
- ✅ **В профиле:** "John Doe" + "@johndoe"
- ✅ **В комментариях:** "John Doe comment text"
- ✅ **При регистрации:** поля Email, Full Name, Username, Password

### **Валидация:**
- ✅ **Name:** 1-50 символов
- ✅ **Username:** 3-30 символов, только буквы, цифры, подчеркивания
- ✅ **Email:** валидный email
- ✅ **Password:** минимум 6 символов

---

## 🚀 **КАК ПРИМЕНИТЬ:**

### **1. Применить миграцию в Supabase:**
```sql
-- Выполнить в SQL Editor Supabase
ALTER TABLE profiles ADD COLUMN name TEXT;
UPDATE profiles SET name = username WHERE name IS NULL;
ALTER TABLE profiles ALTER COLUMN name SET NOT NULL;
```

### **2. Перезапустить сервер:**
```bash
cd E:\fuisorbk\fuisorbk
npm start
```

### **3. Запустить Flutter приложение:**
```bash
cd E:\fuisorbk\fuisorbk\fuisor_app
flutter run -d windows
```

### **4. Протестировать:**
- ✅ Регистрация с полем "Full Name"
- ✅ Отображение имени в постах
- ✅ Профиль показывает имя + @username
- ✅ Обновление профиля с именем

---

## 📋 **ФАЙЛЫ ИЗМЕНЕНЫ:**

### **Backend:**
- ✅ `supabase/schema.sql` - добавлено поле name
- ✅ `supabase/migration_add_name_field.sql` - миграция
- ✅ `src/middleware/validation.middleware.js` - валидация name
- ✅ `src/routes/auth.routes.js` - регистрация и логин с name
- ✅ `src/routes/user.routes.js` - обновление профиля с name

### **Frontend:**
- ✅ `fuisor_app/lib/models/user.dart` - модель с полем name
- ✅ `fuisor_app/lib/screens/signup_screen.dart` - поле Full Name
- ✅ `fuisor_app/lib/providers/auth_provider.dart` - signup с name
- ✅ `fuisor_app/lib/services/api_service.dart` - API с name
- ✅ `fuisor_app/lib/widgets/post_card.dart` - отображение имени
- ✅ `fuisor_app/lib/screens/profile_screen.dart` - профиль с именем

---

**ПОЛЕ "ИМЯ" ПОЛНОСТЬЮ ДОБАВЛЕНО!** ✨

**Теперь пользователи могут иметь и username, и отображаемое имя!** 👤
